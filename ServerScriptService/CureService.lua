-- CureService
-- ACTIVE cure system with puzzle integration and alliance support (PRIMARY implementation)
--
-- NOTE: This is the ACTIVE cure system used in the main game (MainServer.lua)
-- For a simpler cure progress calculator, see CureCraftingManager.lua
--
-- Features:
-- - Per-player component tracking
-- - Alliance resource pooling (allied players share cure progress)
-- - Integration with PuzzleService for puzzle-based component unlocking
-- - Integration with AllianceService for shared resources
-- - Server-authoritative cure progress validation
--
-- See CODE_ARCHITECTURE.md for details on cure system architecture.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local CureService = {}
CureService.__index = CureService

-- Constructor for CureService
function CureService.new(gameManager, playerManager)
	local self = setmetatable({}, CureService)
	self.gameManager = gameManager
	self.playerManager = playerManager
	self.puzzleService = nil -- Will be set later
	self.allianceService = nil -- Will be set later

	-- Track component collection per player
	-- Structure: playerComponents[userId] = {componentName = count}
	self.playerComponents = {}

	-- Track which players have triggered puzzle prompts
	self.puzzlePromptShown = {}

	-- Setup remote events for cure progress
	self:setupRemoteEvents()

	print("[CureService] Initialized")

	return self
end

-- Setup remote events for cure progress updates
function CureService:setupRemoteEvents()
	-- Use shared utility to create remote events
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"PlayerCureProgressUpdate"
	})
end

-- Set puzzle service reference (called after both services are created)
function CureService:setPuzzleService(puzzleService)
	self.puzzleService = puzzleService
	print("[CureService] PuzzleService linked")
end

-- Set alliance service reference (called after both services are created)
function CureService:setAllianceService(allianceService)
	self.allianceService = allianceService
	print("[CureService] AllianceService linked")
end

-- Initialize player component tracking
function CureService:initializePlayer(player)
	local userId = player.UserId

	if not self.playerComponents[userId] then
		self.playerComponents[userId] = {}
		self.puzzlePromptShown[userId] = {}

		-- Initialize counters for each component
		for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
			self.playerComponents[userId][componentName] = 0
			self.puzzlePromptShown[userId][componentName] = false
		end
	end
end

-- Handle component deposit (called when player collects a component)
function CureService:handleDepositComponent(player, componentName)
	print("[CureService] Player", player.Name, "collected", componentName)

	-- Initialize player if needed
	self:initializePlayer(player)

	local userId = player.UserId
	local playerData = self.playerManager:GetPlayerData(player)

	if not playerData then
		warn("[CureService] No player data found for", player.Name)
		return false
	end

	-- Initialize CureComponents if not exists
	if not playerData.CureComponents then
		playerData.CureComponents = {}
	end

	-- Add component to player's inventory
	table.insert(playerData.CureComponents, componentName)

	-- Update component counter
	self.playerComponents[userId][componentName] = self.playerComponents[userId][componentName] + 1

	local componentCount = self.playerComponents[userId][componentName]
	print("[CureService]", player.Name, "now has", componentCount, "of", componentName)

	-- Get the effective component count (pooled if in alliance)
	local effectiveCount = self:getEffectiveComponentCount(player, componentName)

	-- Check if player (or alliance) has collected 5 of this component
	if effectiveCount >= GameConfig.CURE_COMPONENTS_REQUIRED then
		if not self.puzzlePromptShown[userId][componentName] then
			self:notifyPuzzleAvailable(player, componentName)
			self.puzzlePromptShown[userId][componentName] = true
		end
	end

	-- Update cure progress for this player and their allies
	self:updatePlayerCureProgress(player)

	-- Fire event to update UI
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("CureUpdate") then
		remoteEvents.CureUpdate:FireClient(player, {
			type = "component_collected",
			componentName = componentName,
			count = effectiveCount,
			total = GameConfig.CURE_COMPONENTS_REQUIRED
		})
	end

	return true
end

-- Notify player that puzzle is available
function CureService:notifyPuzzleAvailable(player, componentName)
	print("[CureService] Puzzle available for", player.Name, "-", componentName)

	-- Send notification to client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("CureUpdate") then
		remoteEvents.CureUpdate:FireClient(player, {
			type = "puzzle_available",
			componentName = componentName,
			message = "You have collected 5 " .. componentName .. " pieces! Visit a cure station to solve the puzzle."
		})
	end
end

-- Get the effective component count for a player (pooled with allies if in alliance)
function CureService:getEffectiveComponentCount(player, componentName)
	local userId = player.UserId
	self:initializePlayer(player)
	
	local baseCount = self.playerComponents[userId][componentName] or 0
	
	-- If alliance service is available, pool with allies
	if self.allianceService then
		local allies = self.allianceService:getAllies(player)
		for _, ally in ipairs(allies) do
			self:initializePlayer(ally)
			local allyUserId = ally.UserId
			if self.playerComponents[allyUserId] then
				baseCount = baseCount + (self.playerComponents[allyUserId][componentName] or 0)
			end
		end
	end
	
	return baseCount
end

-- Get pooled components for a player (including allies if in alliance)
function CureService:getPooledComponents(player)
	local userId = player.UserId
	self:initializePlayer(player)
	
	local pooledComponents = {}
	
	-- Initialize with player's own components
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		pooledComponents[componentName] = self.playerComponents[userId][componentName] or 0
	end
	
	-- If alliance service is available, add allies' components
	if self.allianceService then
		local allies = self.allianceService:getAllies(player)
		for _, ally in ipairs(allies) do
			self:initializePlayer(ally)
			local allyUserId = ally.UserId
			if self.playerComponents[allyUserId] then
				for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
					pooledComponents[componentName] = pooledComponents[componentName] + 
						(self.playerComponents[allyUserId][componentName] or 0)
				end
			end
		end
	end
	
	return pooledComponents
end

-- Calculate cure progress for a player (individual or pooled with allies)
function CureService:calculatePlayerCureProgress(player)
	local pooledComponents = self:getPooledComponents(player)
	
	local totalCollected = 0
	local totalRequired = #GameConfig.CURE_COMPONENT_NAMES * GameConfig.CURE_COMPONENTS_REQUIRED
	
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		local count = pooledComponents[componentName] or 0
		totalCollected = totalCollected + math.min(count, GameConfig.CURE_COMPONENTS_REQUIRED)
	end
	
	return (totalCollected / totalRequired) * 100
end

-- Update cure progress for a player and their allies
function CureService:updatePlayerCureProgress(player)
	local progress = self:calculatePlayerCureProgress(player)
	local pooledComponents = self:getPooledComponents(player)
	
	-- Send update to this player
	self:sendCureProgressUpdate(player, progress, pooledComponents)
	
	-- Send update to all allies (they share the same progress)
	if self.allianceService then
		local allies = self.allianceService:getAllies(player)
		for _, ally in ipairs(allies) do
			self:sendCureProgressUpdate(ally, progress, pooledComponents)
		end
	end
	
	-- Update global progress for GameManager (use the best progress among all players/alliances)
	self:updateGlobalCureProgress()
end

-- Send cure progress update to a specific player
function CureService:sendCureProgressUpdate(player, progress, components)
	-- Check if player is still valid before sending updates
	if not player or not Players:GetPlayerByUserId(player.UserId) then
		return
	end
	
	if self.remoteEvents and self.remoteEvents.PlayerCureProgressUpdate then
		local success, err = pcall(function()
			self.remoteEvents.PlayerCureProgressUpdate:FireClient(player, {
				progress = progress,
				components = components,
				isPooled = self.allianceService and #self.allianceService:getAllies(player) > 0
			})
		end)
		if not success then
			warn("[CureService] Failed to send cure progress update to " .. player.Name .. ": " .. tostring(err))
		end
	end
	
	-- Also update via CureUpdate for compatibility
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("CureUpdate") then
		local success, err = pcall(function()
			remoteEvents.CureUpdate:FireClient(player, {
				type = "progress",
				progress = progress,
				components = components
			})
		end)
		if not success then
			warn("[CureService] Failed to send CureUpdate to " .. player.Name .. ": " .. tostring(err))
		end
	end
end

-- Update global cure progress (for GameManager/victory condition)
function CureService:updateGlobalCureProgress()
	-- Find the maximum progress among all players/alliances
	local maxProgress = 0
	local processedAlliances = {} -- Track which alliances we've already counted
	
	for userId, _ in pairs(self.playerComponents) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			-- Check if we've already processed this player's alliance
			local allianceKey = self:getAllianceKey(player)
			if not processedAlliances[allianceKey] then
				processedAlliances[allianceKey] = true
				local progress = self:calculatePlayerCureProgress(player)
				if progress > maxProgress then
					maxProgress = progress
				end
			end
		end
	end
	
	-- Update GameManager with the best progress
	if self.gameManager then
		self.gameManager:updateCureProgress(maxProgress)
	end
end

-- Get a unique key for a player's alliance group (for deduplication)
function CureService:getAllianceKey(player)
	local userId = player.UserId
	
	if not self.allianceService then
		return tostring(userId)
	end
	
	local allies = self.allianceService:getAllies(player)
	if #allies == 0 then
		return tostring(userId)
	end
	
	-- Create a sorted list of all alliance member IDs
	local memberIds = {userId}
	for _, ally in ipairs(allies) do
		table.insert(memberIds, ally.UserId)
	end
	table.sort(memberIds)
	
	-- Create a unique key from sorted IDs
	local keyParts = {}
	for _, id in ipairs(memberIds) do
		table.insert(keyParts, tostring(id))
	end
	return table.concat(keyParts, "-")
end

-- Called when an alliance is formed - update progress for both players
function CureService:onAllianceFormed(player1, player2)
	print("[CureService] Alliance formed between", player1.Name, "and", player2.Name, "- pooling resources")
	
	-- Explicitly update progress for both players (they now share pooled resources)
	self:updatePlayerCureProgress(player1)
	self:updatePlayerCureProgress(player2)
end

-- Called when an alliance is broken - update progress for both players
function CureService:onAllianceBroken(player1, player2)
	print("[CureService] Alliance broken between", player1.Name, "and", player2.Name, "- resources no longer pooled")
	
	-- Update progress for both players individually (they no longer share)
	self:updatePlayerCureProgress(player1)
	self:updatePlayerCureProgress(player2)
end

-- DEPRECATED: This method is maintained only for backwards compatibility.
-- Used for GameManager/victory condition checking, not just UI display.
-- Prefer calling updateGlobalCureProgress() directly in new code.
function CureService:updateCureProgress()
	self:updateGlobalCureProgress()
end

-- Called when player completes final synthesis puzzle
function CureService:onFinalSynthesisComplete(player)
	print("[CureService]", player.Name, "completed the final synthesis!")

	-- Trigger victory condition
	if self.gameManager then
		-- The cure is complete - trigger victory
		self.gameManager:updateCureProgress(100)
		print("[CureService] CURE SYNTHESIZED - Victory!")
	end

	-- Broadcast to all players
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("CureUpdate") then
		remoteEvents.CureUpdate:FireAllClients({
			type = "cure_complete",
			synthesizer = player.Name,
			message = player.Name .. " has synthesized the cure! Victory!"
		})
	end
end

-- Get player's component counts (individual, not pooled)
function CureService:getPlayerComponents(player)
	local userId = player.UserId
	self:initializePlayer(player)
	return self.playerComponents[userId]
end

-- Get player's effective component counts (pooled if in alliance)
function CureService:getPlayerEffectiveComponents(player)
	return self:getPooledComponents(player)
end

-- Add components to a player's inventory (used for transfers)
function CureService:addComponentsToPlayer(player, componentName, amount)
	if not player or not componentName or not amount or amount <= 0 then
		return false
	end
	
	self:initializePlayer(player)
	local userId = player.UserId
	
	if self.playerComponents[userId] then
		self.playerComponents[userId][componentName] = 
			(self.playerComponents[userId][componentName] or 0) + amount
		return true
	end
	return false
end

-- Remove components from a player's inventory (used for transfers)
function CureService:removeComponentsFromPlayer(player, componentName, amount)
	if not player or not componentName or not amount or amount <= 0 then
		return 0
	end
	
	self:initializePlayer(player)
	local userId = player.UserId
	
	if self.playerComponents[userId] then
		local currentCount = self.playerComponents[userId][componentName] or 0
		local actualRemoved = math.min(currentCount, amount)
		self.playerComponents[userId][componentName] = currentCount - actualRemoved
		return actualRemoved
	end
	return 0
end

-- Transfer components from one player to another
function CureService:transferComponents(fromPlayer, toPlayer, transferRatio)
	if not fromPlayer or not toPlayer or not transferRatio then
		return
	end
	-- Validate transferRatio is a number between 0 and 1 (inclusive)
	if typeof(transferRatio) ~= "number" or transferRatio < 0 or transferRatio > 1 then
		warn("[CureService] Invalid transferRatio: must be between 0 and 1. Got:", transferRatio)
		return
	end
	
	self:initializePlayer(fromPlayer)
	self:initializePlayer(toPlayer)
	
	local fromUserId = fromPlayer.UserId
	local sourceComponents = self.playerComponents[fromUserId]
	if not sourceComponents then
		return
	end
	
	-- Transfer components based on ratio
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		local count = sourceComponents[componentName] or 0
		local transferCount = math.floor(count * transferRatio)
		if transferCount > 0 then
			local actualTransferred = self:removeComponentsFromPlayer(fromPlayer, componentName, transferCount)
			if actualTransferred > 0 then
				self:addComponentsToPlayer(toPlayer, componentName, actualTransferred)
				print("[CureService] Transferred", actualTransferred, componentName, "from", fromPlayer.Name, "to", toPlayer.Name)
			end
		end
	end
	
	-- Update cure progress for both players
	self:updatePlayerCureProgress(fromPlayer)
	self:updatePlayerCureProgress(toPlayer)
end

-- Check if player can attempt final synthesis
function CureService:canAttemptFinalSynthesis(player)
	-- Player must have solved all 5 component puzzles
	if not self.puzzleService then
		return false
	end

	return self.puzzleService:checkPlayerReadyForFinal(player)
end

return CureService
