-- @ScriptType: ModuleScript
-- AllianceServiceV2.lua
-- Server script that manages player alliances and betrayals
-- UPDATED VERSION with networked alliance pools and 3-outcome betrayal system
-- Features:
-- - Undirected alliance graph with component pooling
-- - Alliance edges, direct-ally-only friendly fire
-- - 3-outcome betrayal system with snapshot pooling
-- - Disconnect treated as death

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[AllianceServiceV2] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[AllianceServiceV2] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local RemoteEventUtil = SharedFolder:WaitForChild("RemoteEventUtil", 5)
if not RemoteEventUtil then
	error("[AllianceServiceV2] CRITICAL: Failed to load RemoteEventUtil after 5 seconds")
end
RemoteEventUtil = require(RemoteEventUtil)

-- New modules for networked alliance pooling
local AllianceGraph = require(script.Parent.Alliance.AllianceGraph)
local PoolCalculator = require(script.Parent.Alliance.PoolCalculator)
local InventoryLedger = require(script.Parent.Alliance.InventoryLedger)
local BetrayalService = require(script.Parent.Alliance.BetrayalService)

local AllianceServiceV2 = {}
AllianceServiceV2.__index = AllianceServiceV2

function AllianceServiceV2.new()
	local self = setmetatable({}, AllianceServiceV2)

	-- Pending alliance requests
	self.pendingRequests = {}     -- player UserId -> set of pending request UserIds
	self.betrayalCooldowns = {}   -- player UserId -> timestamp of last betrayal

	-- References to other services
	self.puzzleService = nil      -- Will be set later
	self.cureService = nil        -- Will be set later
	self.playerManager = nil      -- Will be set later
	self.gameManager = nil        -- Will be set later

	-- New networked alliance modules (initialized after playerManager is set)
	self.allianceGraph = nil
	self.poolCalculator = nil
	self.inventoryLedger = nil
	self.betrayalService = nil

	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()

	return self
end

-- Initialize after playerManager is set
function AllianceServiceV2:initialize()
	if not self.playerManager then
		error("[AllianceServiceV2] Cannot initialize without playerManager")
	end

	-- Initialize new modules
	self.allianceGraph = AllianceGraph.new()
	self.poolCalculator = PoolCalculator.new(self.playerManager, self.allianceGraph)
	self.inventoryLedger = InventoryLedger.new(self.playerManager)
	self.betrayalService = BetrayalService.new(
		self.allianceGraph,
		self.poolCalculator,
		self.inventoryLedger,
		self.playerManager,
		self.gameManager
	)

	print("[AllianceServiceV2] Initialized with networked alliance pools")
end

-- Set puzzle service reference
function AllianceServiceV2:setPuzzleService(puzzleService)
	self.puzzleService = puzzleService
end

-- Set cure service reference
function AllianceServiceV2:setCureService(cureService)
	self.cureService = cureService
end

-- Set player manager reference
function AllianceServiceV2:setPlayerManager(playerManager)
	self.playerManager = playerManager
	-- Initialize modules after playerManager is set
	self:initialize()
end

-- Set game manager reference
function AllianceServiceV2:setGameManager(gameManager)
	self.gameManager = gameManager

	-- Pass gameManager to BetrayalService if it's already initialized
	if self.betrayalService then
		self.betrayalService:setGameManager(gameManager)
	end
end

function AllianceServiceV2:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"RequestAlliance",
		"RespondAlliance",
		"BreakAlliance",
		"AllianceUpdate"
	})

	-- Connect event handlers
	self.remoteEvents.RequestAlliance.OnServerEvent:Connect(function(player, targetPlayer)
		self:handleAllianceRequest(player, targetPlayer)
	end)

	self.remoteEvents.RespondAlliance.OnServerEvent:Connect(function(player, requesterPlayer, accept)
		self:handleAllianceResponse(player, requesterPlayer, accept)
	end)

	self.remoteEvents.BreakAlliance.OnServerEvent:Connect(function(player, targetPlayer)
		self:handleBreakAlliance(player, targetPlayer)
	end)
end

function AllianceServiceV2:initializePlayer(player)
	self.pendingRequests[player.UserId] = {}
	self.betrayalCooldowns[player.UserId] = 0
end

function AllianceServiceV2:removePlayer(player)
	local userId = player.UserId

	-- Handle disconnect during betrayal window
	if self.betrayalService then
		self.betrayalService:onPlayerDisconnect(player)
	end

	-- Clean up alliance graph
	if self.allianceGraph then
		self.allianceGraph:cleanupPlayer(player)
	end

	-- Clean up pending requests
	if self.pendingRequests[userId] then
		self.pendingRequests[userId] = nil
	end

	self.betrayalCooldowns[userId] = nil
end

function AllianceServiceV2:handleAllianceRequest(requester, target)
	if not requester or not target then
		return
	end

	local requesterId = requester.UserId
	local targetId = target.UserId

	-- Check if already allied
	if self:areAllied(requester, target) then
		print(requester.Name .. " is already allied with " .. target.Name)
		return
	end

	-- Check if requester is locked (in betrayal window or traitor)
	if self.betrayalService and self.betrayalService:isPlayerLocked(requester) then
		self.remoteEvents.AllianceUpdate:FireClient(requester, {
			type = "locked",
			message = "You cannot form alliances while in a betrayal window"
		})
		return
	end

	if self.betrayalService and self.betrayalService:isTraitor(requester) then
		self.remoteEvents.AllianceUpdate:FireClient(requester, {
			type = "traitor",
			message = "Traitors cannot form alliances"
		})
		return
	end

	-- Check betrayal cooldown
	if self:isOnBetrayalCooldown(requester) then
		print(requester.Name .. " is on betrayal cooldown")
		self.remoteEvents.AllianceUpdate:FireClient(requester, {
			type = "cooldown",
			message = "You must wait before forming new alliances after a betrayal",
		})
		return
	end

	-- Add to pending requests
	if not self.pendingRequests[targetId] then
		self.pendingRequests[targetId] = {}
	end
	self.pendingRequests[targetId][requesterId] = true

	-- Notify target player
	self.remoteEvents.AllianceUpdate:FireClient(target, {
		type = "request",
		from = requester,
		fromName = requester.Name,
	})

	print(requester.Name .. " requested alliance with " .. target.Name)
end

function AllianceServiceV2:handleAllianceResponse(responder, requester, accept)
	if not responder or not requester then
		return
	end

	local responderId = responder.UserId
	local requesterId = requester.UserId

	-- Check if there's a pending request
	if not self.pendingRequests[responderId] or not self.pendingRequests[responderId][requesterId] then
		print("No pending alliance request from " .. requester.Name)
		return
	end

	-- Remove from pending
	self.pendingRequests[responderId][requesterId] = nil

	if accept then
		-- Check if responder is locked
		if self.betrayalService and self.betrayalService:isPlayerLocked(responder) then
			self.remoteEvents.AllianceUpdate:FireClient(responder, {
				type = "locked",
				message = "You cannot form alliances while in a betrayal window"
			})
			return
		end

		-- Create alliance using alliance graph
		self:createAlliance(requester, responder)

		-- Notify both players
		self.remoteEvents.AllianceUpdate:FireClient(requester, {
			type = "formed",
			with = responder,
			withName = responder.Name,
		})

		self.remoteEvents.AllianceUpdate:FireClient(responder, {
			type = "formed",
			with = requester,
			withName = requester.Name,
		})

		print(responder.Name .. " accepted alliance with " .. requester.Name)
	else
		-- Notify requester of rejection
		self.remoteEvents.AllianceUpdate:FireClient(requester, {
			type = "rejected",
			by = responder,
			byName = responder.Name,
		})

		print(responder.Name .. " rejected alliance with " .. requester.Name)
	end
end

function AllianceServiceV2:handleBreakAlliance(player, target)
	if not player or not target then
		return
	end

	-- Check if allied
	if not self:areAllied(player, target) then
		print(player.Name .. " is not allied with " .. target.Name)
		return
	end

	-- Check if player is locked
	if self.betrayalService and self.betrayalService:isPlayerLocked(player) then
		self.remoteEvents.AllianceUpdate:FireClient(player, {
			type = "locked",
			message = "You cannot break alliances while in a betrayal window"
		})
		return
	end

	-- Start betrayal using betrayal service
	local success, err = self.betrayalService:startBetrayal(player, target)
	if not success then
		print("[AllianceServiceV2] Failed to start betrayal:", err)
		self.remoteEvents.AllianceUpdate:FireClient(player, {
			type = "error",
			message = "Failed to start betrayal: " .. (err or "Unknown error")
		})
		return
	end

	-- Set betrayal cooldown
	self.betrayalCooldowns[player.UserId] = os.time()

	-- Notify CureService that alliance is broken
	if self.cureService and self.cureService.onAllianceBroken then
		self.cureService:onAllianceBroken(player, target)
	end

	print(player.Name .. " initiated betrayal against " .. target.Name)
end

function AllianceServiceV2:createAlliance(player1, player2)
	-- Use alliance graph to add edge
	if self.allianceGraph then
		self.allianceGraph:addEdge(player1, player2)
	end

	-- Notify CureService that alliance is formed (resources now pooled)
	if self.cureService and self.cureService.onAllianceFormed then
		self.cureService:onAllianceFormed(player1, player2)
	end
end

function AllianceServiceV2:areAllied(player1, player2)
	if not self.allianceGraph then
		return false
	end

	return self.allianceGraph:areDirectAllies(player1, player2)
end

function AllianceServiceV2:isOnBetrayalCooldown(player)
	local lastBetrayal = self.betrayalCooldowns[player.UserId]
	if not lastBetrayal or lastBetrayal == 0 then
		return false
	end

	local timeSinceBetrayal = os.time() - lastBetrayal
	return timeSinceBetrayal < GameConfig.BETRAYAL_COOLDOWN
end

function AllianceServiceV2:getAllies(player)
	if not self.allianceGraph then
		return {}
	end

	return self.allianceGraph:getDirectAllies(player)
end

-- Integration point: Call from weapon service or game manager when player is killed
function AllianceServiceV2:onPlayerKilled(deadPlayer, killerPlayer)
	if not deadPlayer or not killerPlayer then
		return
	end

	if self.betrayalService then
		self.betrayalService:onPlayerKilled(killerPlayer, deadPlayer)
	end
end

return AllianceServiceV2