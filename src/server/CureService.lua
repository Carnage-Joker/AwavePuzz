-- CureService
-- Handles cure component deposits, puzzle integration, and cure synthesis
-- Integrated with PuzzleService, CureCraftingManager and PuzzleUI for
-- component collection, progress tracking, and final cure completion.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CureService = {}
CureService.__index = CureService

-- Constructor for CureService
function CureService.new(gameManager, playerManager)
	local self = setmetatable({}, CureService)
	self.gameManager = gameManager
	self.playerManager = playerManager
	self.puzzleService = nil -- Will be set later

	-- Track component collection per player
	-- Structure: playerComponents[userId] = {componentName = count}
	self.playerComponents = {}

	-- Track which players have triggered puzzle prompts
	self.puzzlePromptShown = {}

	print("[CureService] Initialized")

	return self
end

-- Set puzzle service reference (called after both services are created)
function CureService:setPuzzleService(puzzleService)
	self.puzzleService = puzzleService
	print("[CureService] PuzzleService linked")
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

	-- Check if player has collected 5 of this component
	if componentCount >= GameConfig.CURE_COMPONENTS_REQUIRED then
		if not self.puzzlePromptShown[userId][componentName] then
			self:notifyPuzzleAvailable(player, componentName)
			self.puzzlePromptShown[userId][componentName] = true
		end
	end

	-- Update cure progress (global progress based on all collected components)
	self:updateCureProgress()

	-- Fire event to update UI
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("CureUpdate") then
		remoteEvents.CureUpdate:FireClient(player, {
			type = "component_collected",
			componentName = componentName,
			count = componentCount,
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

-- Update global cure progress (for UI display)
function CureService:updateCureProgress()
	-- Calculate total progress based on all players' components
	local totalCollected = 0
	local totalRequired = #GameConfig.CURE_COMPONENT_NAMES * GameConfig.CURE_COMPONENTS_REQUIRED

	for userId, components in pairs(self.playerComponents) do
		for _, count in pairs(components) do
			totalCollected = totalCollected + math.min(count, GameConfig.CURE_COMPONENTS_REQUIRED)
		end
	end

	local progress = (totalCollected / totalRequired) * 100

	-- Update GameManager
	if self.gameManager then
		self.gameManager:updateCureProgress(progress)
	end
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

-- Get player's component counts
function CureService:getPlayerComponents(player)
	local userId = player.UserId
	self:initializePlayer(player)
	return self.playerComponents[userId]
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
