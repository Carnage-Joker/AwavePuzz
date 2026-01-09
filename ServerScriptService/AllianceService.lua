-- @ScriptType: ModuleScript
-- AllianceService.lua
-- Server script that manages player alliances and betrayals
-- Features:
-- - Allied players pool their cure resources and see combined progress
-- - Breaking an alliance initiates a 30-second betrayal window
-- Betrayal Outcomes:
--   Outcome 1: Betrayer (A) kills victim (B) within 30s → A gets 65% of resources
--   Outcome 2: Victim (B) survives 30s → B gets 75% of resources, A gets 25%
--   Outcome 3: Victim (B) kills betrayer (A) within 30s → B gets 100% of resources

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

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

	-- Track pending betrayals (resources transfer based on outcome)
	self.pendingBetrayals = {}    -- betrayer UserId -> {victimUserId, timestamp}

	-- Track active betrayal windows
	self.activeWindows = {}       -- betrayer UserId -> true (for cleanup)

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

-- Set game manager reference
function AllianceService:setGameManager(gameManager)
	self.gameManager = gameManager
end

function AllianceService:setupRemoteEvents()
	-- Use shared utility to create remote events
	-- RemoteEvent Documentation:
	-- - RequestAlliance: Client -> Server, request alliance with another player {targetPlayer = Player}
	-- - RespondAlliance: Client -> Server, respond to alliance request {requesterPlayer = Player, accept = boolean}
	-- - BreakAlliance: Client -> Server, break existing alliance {targetPlayer = Player}
	-- - AllianceUpdate: Server -> Client, updates alliance status {allies = table, status = string}
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

	-- Cancel any active betrayal timers where this player is the betrayer
	if self.activeWindows[userId] then
		self.activeWindows[userId] = nil
	end

	-- Also cancel any active betrayal timers where this player is the victim
	if self.pendingBetrayals then
		for betrayerId, betrayalData in pairs(self.pendingBetrayals) do
			if betrayalData and betrayalData.victimUserId == userId then
				-- Clear the pending betrayal and active window for the betrayer
				self.pendingBetrayals[betrayerId] = nil
				self.activeWindows[betrayerId] = nil
			end
		end
	end
	-- Clean up
	self.alliances[userId] = nil
	self.pendingRequests[userId] = nil
	self.betrayalCooldowns[userId] = nil
	self.pendingBetrayals[userId] = nil
	self.recentBetrayals[userId] = nil
	self.activeWindows[userId] = nil
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

	-- Track this betrayal for mechanics
	self.recentBetrayals[player.UserId] = target.UserId

	-- Mark this as a pending betrayal with timestamp
	self.pendingBetrayals[player.UserId] = {
		victimUserId = target.UserId,
		timestamp = os.time()
	}

	-- Notify CureService that alliance is broken (resources no longer pooled)
	if self.cureService and self.cureService.onAllianceBroken then
		self.cureService:onAllianceBroken(player, target)
	end

	-- Start 30-second betrayal window timer
	self:startBetrayalWindow(player, target)

	-- Notify both players
	self.remoteEvents.AllianceUpdate:FireClient(player, {
		type = "broken",
		with = target,
		withName = target.Name,
		betrayer = true,
		message = "Betrayal initiated! You have 30 seconds to eliminate " .. target.Name .. " to claim 75% of pooled resources."
	})

	self.remoteEvents.AllianceUpdate:FireClient(target, {
		type = "broken",
		with = player,
		withName = player.Name,
		betrayer = false,
		message = "You have been betrayed by " .. player.Name .. "! Survive 30 seconds or defeat them to claim their resources."
	})

	print(player.Name .. " initiated betrayal against " .. target.Name .. " - 30 second window started")
end

-- Start 30-second betrayal window timer
function AllianceService:startBetrayalWindow(betrayer, victim)
	if not betrayer or not victim then
		return
	end

	local betrayerId = betrayer.UserId
	local victimId = victim.UserId

	-- Mark window as active
	self.activeWindows[betrayerId] = true

	-- Create timer using task.delay
	task.delay(GameConfig.BETRAYAL_WINDOW, function()
		-- Check if window is still active (not cancelled)
		if not self.activeWindows[betrayerId] then
			return
		end

		-- Validate players still exist
		local betrayerPlayer = Players:GetPlayerByUserId(betrayerId)
		local victimPlayer = Players:GetPlayerByUserId(victimId)

		if not betrayerPlayer or not victimPlayer then
			-- Cleanup if either player left
			self.activeWindows[betrayerId] = nil
			if self.pendingBetrayals[betrayerId] then
				self.pendingBetrayals[betrayerId] = nil
			end
			return
		end

		-- After 30 seconds, check if betrayal is still pending
		if self.pendingBetrayals[betrayerId] then
			local pendingBetrayal = self.pendingBetrayals[betrayerId]
			if pendingBetrayal.victimUserId == victimId then
				-- Outcome 2: Victim survived the 30-second window
				self:onVictimSurvives(betrayerPlayer, victimPlayer)
			end
		end

		-- Cleanup
		self.activeWindows[betrayerId] = nil
	end)
end

-- Outcome 2: Victim survives the 30-second betrayal window
function AllianceService:onVictimSurvives(betrayer, victim)
	print("[AllianceService]", victim.Name, "survived betrayal by", betrayer.Name, "- victim gets 75%, betrayer gets 25%")

	-- Clear the pending betrayal
	if self.pendingBetrayals[betrayer.UserId] then
		self.pendingBetrayals[betrayer.UserId] = nil
	end

	-- Clear the recent betrayal tracking
	if self.recentBetrayals[betrayer.UserId] then
		self.recentBetrayals[betrayer.UserId] = nil
	end

	-- Transfer 75% of resources from betrayer to victim
	self:transferBetrayalResources(victim, betrayer, 0.75)

	-- Transfer cure components 75% to victim, 25% stays with betrayer
	if self.cureService then
		self:transferCureComponents(victim, betrayer, 0.75)
	end

	-- Transfer puzzles from betrayer to victim
	if self.puzzleService and self.puzzleService.onSurvivorVictory then
		self.puzzleService:onSurvivorVictory(victim, betrayer)
	end

	-- Notify both players
	if self.remoteEvents.AllianceUpdate then
		self.remoteEvents.AllianceUpdate:FireClient(victim, {
			type = "betrayal_survived",
			betrayer = betrayer.Name,
			message = "You survived the betrayal! You received 75% of " .. betrayer.Name .. "'s resources."
		})

		self.remoteEvents.AllianceUpdate:FireClient(betrayer, {
			type = "betrayal_failed",
			victim = victim.Name,
			message = "Betrayal failed! " .. victim.Name .. " survived and took 75% of your resources."
		})
	end

	print(victim.Name .. " survived betrayal and claimed 75% of " .. betrayer.Name .. "'s resources!")

	-- Track betrayal survival for fun facts
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(victim, "betrayalsSurvived")
	end
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

-- Called when a betrayer is killed by their recent victim (Outcome 3: survivor mechanics)
function AllianceService:onBetrayerKilled(betrayer, killer)
	local victimUserId = self.recentBetrayals[betrayer.UserId]
	if not victimUserId then
		return
	end

	-- Check if the killer was the victim of the betrayal
	if killer.UserId ~= victimUserId then
		return
	end

	print("[AllianceService]", killer.Name, "killed betrayer", betrayer.Name, "- victim gets 100% (Outcome 3)")

	-- Cancel the 30-second timer by clearing active window flag
	if self.activeWindows[betrayer.UserId] then
		self.activeWindows[betrayer.UserId] = nil
	end

	-- Clear the pending betrayal
	if self.pendingBetrayals[betrayer.UserId] then
		self.pendingBetrayals[betrayer.UserId] = nil
	end

	-- Clear the betrayal tracking
	self.recentBetrayals[betrayer.UserId] = nil

	-- Outcome 3: Transfer ALL (100%) resources from betrayer to survivor
	self:transferBetrayalResources(killer, betrayer, 1.0)

	-- Transfer all puzzles from betrayer to survivor
	if self.puzzleService then
		self.puzzleService:onSurvivorVictory(killer, betrayer)
	end

	-- Transfer ALL (100%) cure components from betrayer to survivor
	if self.cureService then
		self:transferCureComponents(killer, betrayer, 1.0)
	end

	-- Notify survivor
	if self.remoteEvents.AllianceUpdate then
		self.remoteEvents.AllianceUpdate:FireClient(killer, {
			type = "survivor_victory",
			betrayer = betrayer.Name,
			message = "You defeated your betrayer! All of " .. betrayer.Name .. "'s resources, puzzles, and cure components transferred to you (100%)."
		})
	end

	print(killer.Name .. " defeated betrayer " .. betrayer.Name .. " and claimed all resources (100%)!")

	-- Track betrayal survival for fun facts
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(killer, "betrayalsSurvived")
	end
end

-- Integration point: Call this from MainServer.lua or WeaponService.lua when a player is killed
-- deadPlayer: The player who died
-- killerPlayer: The player who killed them (may be nil for non-PvP deaths)
function AllianceService:onPlayerKilled(deadPlayer, killerPlayer)
	if not deadPlayer or not killerPlayer then
		return
	end

	-- Check if deadPlayer was a betrayer and killerPlayer was their recent victim (survivor mechanics)
	local victimUserId = self.recentBetrayals and self.recentBetrayals[deadPlayer.UserId]
	if victimUserId and killerPlayer.UserId == victimUserId then
		self:onBetrayerKilled(deadPlayer, killerPlayer)
		return
	end

	-- Check if killerPlayer was a betrayer and deadPlayer was their victim (successful betrayal)
	if self.pendingBetrayals and self.pendingBetrayals[killerPlayer.UserId] then
		local pendingBetrayal = self.pendingBetrayals[killerPlayer.UserId]
		if pendingBetrayal.victimUserId == deadPlayer.UserId then
			local success, err = pcall(function()
				self:onBetrayerKillsVictim(killerPlayer, deadPlayer)
			end)
			-- Ensure cleanup of recentBetrayals even if error occurs
			if self.recentBetrayals then
				self.recentBetrayals[killerPlayer.UserId] = nil
			end
			if not success then
				warn("[AllianceService] Error in onBetrayerKillsVictim:", err)
			end
			return
		end
	end
end

-- Called when a betrayer successfully eliminates their victim (Outcome 1)
-- This completes the betrayal within 30 seconds and transfers 65% of resources
function AllianceService:onBetrayerKillsVictim(betrayer, victim)
	print("[AllianceService]", betrayer.Name, "successfully eliminated", victim.Name, "within 30s - completing betrayal (Outcome 1: 65%)")

	-- Clear the pending betrayal and cancel timer by removing active window flag
	if self.pendingBetrayals[betrayer.UserId] then
		self.pendingBetrayals[betrayer.UserId] = nil
	end

	-- Clear the recent betrayal tracking
	if self.recentBetrayals[betrayer.UserId] then
		self.recentBetrayals[betrayer.UserId] = nil
	end

	-- Clear active window flag to cancel timer
	if self.activeWindows[betrayer.UserId] then
		self.activeWindows[betrayer.UserId] = nil
	end

	-- Outcome 1: Transfer 75% of pooled resources since betrayal was successful
	self:transferBetrayalResources(betrayer, victim, 0.75)

	-- Trigger puzzle stealing mechanics
	if self.puzzleService then
		self.puzzleService:onBetrayal(betrayer, victim)
	end

	-- Transfer 75% of cure components from victim to betrayer
	if self.cureService then
		self:transferCureComponents(betrayer, victim, 0.75)
	end

	-- Notify betrayer of successful betrayal
	if self.remoteEvents.AllianceUpdate then
		self.remoteEvents.AllianceUpdate:FireClient(betrayer, {
			type = "betrayal_success",
			victim = victim.Name,
			message = "Betrayal successful! You eliminated " .. victim.Name .. " and claimed 75% of pooled resources."
		})
	end

	print(betrayer.Name .. " completed betrayal of " .. victim.Name .. " and claimed 75% of pooled resources!")

	-- Track betrayal for fun facts
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(betrayer, "betrayalsCommitted")
	end
end

-- Transfer cure components from one player to another
function AllianceService:transferCureComponents(recipient, source, transferRatio)
	if not self.cureService then
		return
	end

	-- Use CureService's transfer method to maintain proper encapsulation
	self.cureService:transferComponents(source, recipient, transferRatio)
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

	-- Notify CureService that alliance is formed (resources now pooled)
	if self.cureService and self.cureService.onAllianceFormed then
		self.cureService:onAllianceFormed(player1, player2)
	end
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