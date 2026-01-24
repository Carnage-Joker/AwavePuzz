-- @ScriptType: ModuleScript
-- CureSynthesisService.lua
-- Server-side cure synthesis system
-- Manages the timed puzzle sequence when all 5 components are collected
-- Intensifies zombie attacks during synthesis
-- Handles synthesis success/failure states

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[CureSynthesisService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[CureSynthesisService] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local PuzzleConfig = SharedFolder:WaitForChild("PuzzleConfig", 5)
if not PuzzleConfig then
	error("[CureSynthesisService] CRITICAL: Failed to load PuzzleConfig after 5 seconds")
end
PuzzleConfig = require(PuzzleConfig)

local RemoteEventUtil = SharedFolder:WaitForChild("RemoteEventUtil", 5)
if not RemoteEventUtil then
	error("[CureSynthesisService] CRITICAL: Failed to load RemoteEventUtil after 5 seconds")
end
RemoteEventUtil = require(RemoteEventUtil)

local CureSynthesisService = {}
CureSynthesisService.__index = CureSynthesisService

-- Synthesis states
CureSynthesisService.States = {
	IDLE = "Idle",
	ACTIVE = "Active",
	SUCCESS = "Success",
	FAILED = "Failed"
}

function CureSynthesisService.new(cureService, waveManager, gameManager)
	local self = setmetatable({}, CureSynthesisService)

	self.cureService = cureService
	self.waveManager = waveManager
	self.gameManager = gameManager
	self.puzzleService = nil -- Will be set later

	-- Synthesis state
	self.synthesisState = CureSynthesisService.States.IDLE
	self.synthesisStartTime = 0
	self.synthesisPlayer = nil -- Player who initiated synthesis
	self.synthesisTimer = nil

	-- Synthesis configuration
	self.SYNTHESIS_TIME_LIMIT = PuzzleConfig.FinalPuzzle.timeLimit or 120 -- seconds
	self.ZOMBIE_INTENSITY_MULTIPLIER = 2.0 -- Zombies spawn/attack faster during synthesis
	self.PUZZLE_COUNT = 5 -- Number of mini-puzzles to complete
	self.puzzlesCompleted = 0

	self:setupRemoteEvents()

	print("[CureSynthesisService] Initialized")

	return self
end

function CureSynthesisService:setPuzzleService(puzzleService)
	self.puzzleService = puzzleService
end

function CureSynthesisService:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"StartSynthesis",           -- Client -> Server: Attempt to start synthesis
		"SynthesisStateUpdate",     -- Server -> Client: Update synthesis state
		"SynthesisPuzzleComplete",  -- Client -> Server: Mini-puzzle completed
		"SynthesisComplete",        -- Server -> All: Synthesis succeeded
		"SynthesisFailed"           -- Server -> All: Synthesis failed
	})

	-- Handle synthesis start requests
	self.remoteEvents.StartSynthesis.OnServerEvent:Connect(function(player)
		self:attemptStartSynthesis(player)
	end)

	-- Handle mini-puzzle completions
	self.remoteEvents.SynthesisPuzzleComplete.OnServerEvent:Connect(function(player, puzzleIndex)
		self:handlePuzzleComplete(player, puzzleIndex)
	end)
end

-- Check if a player has all 5 components
function CureSynthesisService:playerHasAllComponents(player)
	if not self.cureService then
		return false
	end

	-- Get player's components from CureService
	local components = self.cureService:getPlayerComponents(player)
	if not components then
		return false
	end

	-- Check if player has at least 5 of each component
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		local count = components[componentName] or 0
		if count < 5 then
			return false
		end
	end

	return true
end

-- Attempt to start synthesis
function CureSynthesisService:attemptStartSynthesis(player)
	-- Validate player
	if not player or not player:IsDescendantOf(game) then
		return
	end

	-- Check if synthesis is already active
	if self.synthesisState ~= CureSynthesisService.States.IDLE then
		self:sendMessage(player, "Synthesis already in progress", "error")
		return
	end

	-- Check if player has all components
	if not self:playerHasAllComponents(player) then
		self:sendMessage(player, "All 5 components required (5 pieces each)", "error")
		return
	end

	-- Start synthesis
	self:startSynthesis(player)
end

-- Start synthesis process
function CureSynthesisService:startSynthesis(player)
	print("[CureSynthesisService] Starting synthesis for", player.Name)

	self.synthesisState = CureSynthesisService.States.ACTIVE
	self.synthesisStartTime = tick()
	self.synthesisPlayer = player
	self.puzzlesCompleted = 0

	-- Notify all clients
	self:broadcastSynthesisState({
		state = self.synthesisState,
		timeLimit = self.SYNTHESIS_TIME_LIMIT,
		puzzlesTotal = self.PUZZLE_COUNT,
		puzzlesCompleted = 0,
		initiator = player.Name
	})

	-- Intensify zombie attacks
	if self.waveManager then
		self.waveManager:setIntensityMultiplier(self.ZOMBIE_INTENSITY_MULTIPLIER)
		print("[CureSynthesisService] Zombie intensity increased to", self.ZOMBIE_INTENSITY_MULTIPLIER)
	end

	-- Start timer
	self.synthesisTimer = task.delay(self.SYNTHESIS_TIME_LIMIT, function()
		if self.synthesisState == CureSynthesisService.States.ACTIVE then
			self:failSynthesis("Time limit exceeded")
		end
	end)

	-- Log to fun fact service if available
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(player, "cureAttempts")
	end
end

-- Handle mini-puzzle completion
function CureSynthesisService:handlePuzzleComplete(player, puzzleIndex)
	-- Validate state
	if self.synthesisState ~= CureSynthesisService.States.ACTIVE then
		return
	end

	-- Validate player
	if not player or player ~= self.synthesisPlayer then
		return
	end

	-- Validate puzzle index
	if puzzleIndex < 1 or puzzleIndex > self.PUZZLE_COUNT then
		return
	end

	-- Increment completion count
	self.puzzlesCompleted = self.puzzlesCompleted + 1

	print("[CureSynthesisService] Puzzle", puzzleIndex, "completed. Total:", self.puzzlesCompleted, "/", self.PUZZLE_COUNT)

	-- Broadcast progress
	self:broadcastSynthesisState({
		state = self.synthesisState,
		timeLimit = self.SYNTHESIS_TIME_LIMIT,
		timeRemaining = self.SYNTHESIS_TIME_LIMIT - (tick() - self.synthesisStartTime),
		puzzlesTotal = self.PUZZLE_COUNT,
		puzzlesCompleted = self.puzzlesCompleted,
		initiator = player.Name
	})

	-- Check if all puzzles completed
	if self.puzzlesCompleted >= self.PUZZLE_COUNT then
		self:completeSynthesis()
	end
end

-- Complete synthesis successfully
function CureSynthesisService:completeSynthesis()
	print("[CureSynthesisService] Synthesis complete - VICTORY!")

	-- Cancel timer
	if self.synthesisTimer then
		task.cancel(self.synthesisTimer)
		self.synthesisTimer = nil
	end

	-- Update state
	self.synthesisState = CureSynthesisService.States.SUCCESS

	-- Reset zombie intensity
	if self.waveManager then
		self.waveManager:setIntensityMultiplier(1.0)
	end

	-- Notify all clients
	if self.remoteEvents.SynthesisComplete then
		self.remoteEvents.SynthesisComplete:FireAllClients({
			initiator = self.synthesisPlayer and self.synthesisPlayer.Name or "Unknown"
		})
	end

	-- Trigger victory in GameManager
	if self.gameManager then
		task.delay(2, function()
			self.gameManager:triggerVictory()
		end)
	end
end

-- Fail synthesis
function CureSynthesisService:failSynthesis(reason)
	print("[CureSynthesisService] Synthesis failed:", reason)

	-- Cancel timer
	if self.synthesisTimer then
		task.cancel(self.synthesisTimer)
		self.synthesisTimer = nil
	end

	-- Update state
	self.synthesisState = CureSynthesisService.States.FAILED

	-- Reset zombie intensity
	if self.waveManager then
		self.waveManager:setIntensityMultiplier(1.0)
	end

	-- Notify all clients
	if self.remoteEvents.SynthesisFailed then
		self.remoteEvents.SynthesisFailed:FireAllClients({
			reason = reason,
			initiator = self.synthesisPlayer and self.synthesisPlayer.Name or "Unknown"
		})
	end

	-- Reset state after delay
	task.delay(5, function()
		self.synthesisState = CureSynthesisService.States.IDLE
		self.synthesisPlayer = nil
		self.puzzlesCompleted = 0
	end)
end

-- Broadcast synthesis state to all clients
function CureSynthesisService:broadcastSynthesisState(stateData)
	if self.remoteEvents.SynthesisStateUpdate then
		self.remoteEvents.SynthesisStateUpdate:FireAllClients(stateData)
	end
end

-- Send message to specific player
function CureSynthesisService:sendMessage(player, message, messageType)
	-- TODO: Implement messaging system or use existing notification system
	print("[CureSynthesisService] Message to", player.Name, ":", message)
end

-- Get current synthesis state
function CureSynthesisService:getSynthesisState()
	return self.synthesisState
end

-- Check if synthesis is active
function CureSynthesisService:isSynthesisActive()
	return self.synthesisState == CureSynthesisService.States.ACTIVE
end

-- Reset synthesis (for new rounds)
function CureSynthesisService:reset()
	if self.synthesisTimer then
		task.cancel(self.synthesisTimer)
		self.synthesisTimer = nil
	end

	self.synthesisState = CureSynthesisService.States.IDLE
	self.synthesisPlayer = nil
	self.puzzlesCompleted = 0

	-- Reset zombie intensity
	if self.waveManager then
		self.waveManager:setIntensityMultiplier(1.0)
	end

	print("[CureSynthesisService] Reset")
end

return CureSynthesisService