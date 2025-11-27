-- AllianceService.lua
-- Server script that manages player alliances and betrayals
-- Features:
-- - Allied players share resources and puzzles automatically
-- - Betraying allies transfers 3/4 of resources/puzzles to the betrayer
-- - Surviving a betrayal (when victim kills betrayer) transfers all to survivor
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local AllianceService = {}
AllianceService.__index = AllianceService

function AllianceService.new()
	local self = setmetatable({}, AllianceService)

	-- Alliance tracking
	self.alliances = {}           -- player UserId -> set of allied UserIds
	self.pendingRequests = {}     -- player UserId -> set of pending request UserIds
	self.betrayalCooldowns = {}   -- player UserId -> timestamp of last betrayal
	
	-- Track recent betrayals for survivor mechanics
	self.recentBetrayals = {}     -- betrayer UserId -> victim UserId

	-- References to other services
	self.puzzleService = nil      -- Will be set later
	self.cureService = nil        -- Will be set later
	self.playerManager = nil      -- Will be set later

	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()

	return self
end

-- Set puzzle service reference
function AllianceService:setPuzzleService(puzzleService)
	self.puzzleService = puzzleService
end

-- Set cure service reference
function AllianceService:setCureService(cureService)
	self.cureService = cureService
end

-- Set player manager reference
function AllianceService:setPlayerManager(playerManager)
	self.playerManager = playerManager
end

function AllianceService:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	-- Request Alliance
	local requestEvent = remoteEventsFolder:FindFirstChild("RequestAlliance")
	if not requestEvent then
		requestEvent = Instance.new("RemoteEvent")
		requestEvent.Name = "RequestAlliance"
		requestEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.RequestAlliance = requestEvent

	-- Respond to Alliance
	local respondEvent = remoteEventsFolder:FindFirstChild("RespondAlliance")
	if not respondEvent then
		respondEvent = Instance.new("RemoteEvent")
		respondEvent.Name = "RespondAlliance"
		respondEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.RespondAlliance = respondEvent

	-- Break Alliance
	local breakEvent = remoteEventsFolder:FindFirstChild("BreakAlliance")
	if not breakEvent then
		breakEvent = Instance.new("RemoteEvent")
		breakEvent.Name = "BreakAlliance"
		breakEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.BreakAlliance = breakEvent

	-- Alliance Update (server to client)
	local updateEvent = remoteEventsFolder:FindFirstChild("AllianceUpdate")
	if not updateEvent then
		updateEvent = Instance.new("RemoteEvent")
		updateEvent.Name = "AllianceUpdate"
		updateEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.AllianceUpdate = updateEvent

	-- Connect event handlers
	requestEvent.OnServerEvent:Connect(function(player, targetPlayer)
		self:handleAllianceRequest(player, targetPlayer)
	end)

	respondEvent.OnServerEvent:Connect(function(player, requesterPlayer, accept)
		self:handleAllianceResponse(player, requesterPlayer, accept)
	end)

	breakEvent.OnServerEvent:Connect(function(player, targetPlayer)
		self:handleBreakAlliance(player, targetPlayer)
	end)
end

function AllianceService:initializePlayer(player)
	self.alliances[player.UserId] = {}
	self.pendingRequests[player.UserId] = {}
	self.betrayalCooldowns[player.UserId] = 0
end

function AllianceService:removePlayer(player)
	-- Break all alliances
	local userId = player.UserId

	if self.alliances[userId] then
		for allyId, _ in pairs(self.alliances[userId]) do
			-- Remove from ally's list
			if self.alliances[allyId] then
				self.alliances[allyId][userId] = nil
			end
		end
	end

	-- Clean up
	self.alliances[userId] = nil
	self.pendingRequests[userId] = nil
	self.betrayalCooldowns[userId] = nil
end

function AllianceService:handleAllianceRequest(requester, target)
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

	-- Check betrayal cooldown
	if self:isOnBetrayalCooldown(requester) then
		print(requester.Name .. " is on betrayal cooldown")
		-- Notify requester
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

function AllianceService:handleAllianceResponse(responder, requester, accept)
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
		-- Create alliance
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

function AllianceService:handleBreakAlliance(player, target)
	if not player or not target then
		return
	end

	-- Check if allied
	if not self:areAllied(player, target) then
		print(player.Name .. " is not allied with " .. target.Name)
		return
	end

	-- Break alliance
	self:breakAlliance(player, target)

	-- Set betrayal cooldown
	self.betrayalCooldowns[player.UserId] = os.time()
	
	-- Track this betrayal for survivor mechanics
	self.recentBetrayals[player.UserId] = target.UserId

	-- Transfer 3/4 of victim's resources and puzzles to betrayer
	self:transferBetrayalResources(player, target, 0.75)

	-- Trigger puzzle stealing mechanics
	if self.puzzleService then
		self.puzzleService:onBetrayal(player, target)
	end

	-- Notify both players
	self.remoteEvents.AllianceUpdate:FireClient(player, {
		type = "broken",
		with = target,
		withName = target.Name,
		betrayer = true,
	})

	self.remoteEvents.AllianceUpdate:FireClient(target, {
		type = "broken",
		with = player,
		withName = player.Name,
		betrayer = false,
	})

	print(player.Name .. " betrayed alliance with " .. target.Name)
end

-- Transfer resources from victim to betrayer
function AllianceService:transferBetrayalResources(betrayer, victim, transferRatio)
	if not self.playerManager then
		return
	end
	
	local victimData = self.playerManager:getPlayerData(victim)
	local betrayerData = self.playerManager:getPlayerData(betrayer)
	
	if not victimData or not betrayerData then
		return
	end
	
	-- Transfer currency based on transferRatio (e.g., 0.75 for betrayal, 1.0 for survivor victory)
	local victimCurrency = victimData.currency or 0
	local transferAmount = math.floor(victimCurrency * transferRatio)
	
	if transferAmount > 0 then
		victimData.currency = victimData.currency - transferAmount
		betrayerData.currency = betrayerData.currency + transferAmount
		
		-- Send currency updates to clients (with method existence check)
		if self.playerManager.sendCurrencyUpdate then
			self.playerManager:sendCurrencyUpdate(victim)
			self.playerManager:sendCurrencyUpdate(betrayer)
		end
		
		print(betrayer.Name .. " stole " .. transferAmount .. " currency from " .. victim.Name)
	end
end

-- Called when a betrayer is killed by their recent victim (survivor mechanics)
function AllianceService:onBetrayerKilled(betrayer, killer)
	local victimUserId = self.recentBetrayals[betrayer.UserId]
	if not victimUserId then
		return
	end
	
	-- Check if the killer was the victim of the betrayal
	if killer.UserId ~= victimUserId then
		return
	end
	
	-- Clear the betrayal tracking
	self.recentBetrayals[betrayer.UserId] = nil
	
	-- Transfer ALL resources from betrayer to survivor
	self:transferBetrayalResources(killer, betrayer, 1.0)
	
	-- Transfer all puzzles from betrayer to survivor
	if self.puzzleService then
		self.puzzleService:onSurvivorVictory(killer, betrayer)
	end
	
	-- Notify survivor
	if self.remoteEvents.AllianceUpdate then
		self.remoteEvents.AllianceUpdate:FireClient(killer, {
			type = "survivor_victory",
			betrayer = betrayer.Name,
			message = "You survived the betrayal! All resources and puzzles transferred to you."
		})
	end
	
	print(killer.Name .. " survived betrayal by " .. betrayer.Name .. " and claimed all resources!")
end

-- Integration point: Call this from MainServer.lua or WeaponService.lua when a player is killed
-- deadPlayer: The player who died
-- killerPlayer: The player who killed them (may be nil for non-PvP deaths)
function AllianceService:onPlayerKilled(deadPlayer, killerPlayer)
	if not deadPlayer or not killerPlayer then
		return
	end
	-- Check if deadPlayer was a betrayer and killerPlayer was their recent victim
	local victimUserId = self.recentBetrayals and self.recentBetrayals[deadPlayer.UserId]
	if victimUserId and killerPlayer.UserId == victimUserId then
		self:onBetrayerKilled(deadPlayer, killerPlayer)
	end
end

function AllianceService:createAlliance(player1, player2)
	local userId1 = player1.UserId
	local userId2 = player2.UserId

	if not self.alliances[userId1] then
		self.alliances[userId1] = {}
	end
	if not self.alliances[userId2] then
		self.alliances[userId2] = {}
	end

	self.alliances[userId1][userId2] = true
	self.alliances[userId2][userId1] = true
end

function AllianceService:breakAlliance(player1, player2)
	local userId1 = player1.UserId
	local userId2 = player2.UserId

	if self.alliances[userId1] then
		self.alliances[userId1][userId2] = nil
	end
	if self.alliances[userId2] then
		self.alliances[userId2][userId1] = nil
	end
end

function AllianceService:areAllied(player1, player2)
	local userId1 = player1.UserId
	local userId2 = player2.UserId

	if not self.alliances[userId1] then
		return false
	end

	return self.alliances[userId1][userId2] == true
end

function AllianceService:isOnBetrayalCooldown(player)
	local lastBetrayal = self.betrayalCooldowns[player.UserId]
	if not lastBetrayal or lastBetrayal == 0 then
		return false
	end

	local timeSinceBetrayal = os.time() - lastBetrayal
	return timeSinceBetrayal < GameConfig.BETRAYAL_COOLDOWN
end

function AllianceService:getAllies(player)
	local allies = {}

	if self.alliances[player.UserId] then
		for allyId, _ in pairs(self.alliances[player.UserId]) do
			local ally = Players:GetPlayerByUserId(allyId)
			if ally then
				table.insert(allies, ally)
			end
		end
	end

	return allies
end

return AllianceService
