-- @ScriptType: Script
-- GameState.lua
-- Manages the overall game state

local GameState = {}
GameState.__index = GameState

-- Game states
GameState.States = {
	WAITING = "Waiting",
	IN_PROGRESS = "InProgress",
	VICTORY = "Victory",
	DEFEAT = "Defeat"
}

function GameState.new()
	local self = setmetatable({}, GameState)
	self.currentState = GameState.States.WAITING
	self.currentWave = 0
	self.baseHealth = 0
	self.playersAlive = 0
	self.cureProgress = 0
	self.zombiesRemaining = 0
	return self
end

function GameState:setState(newState)
	self.currentState = newState
end

function GameState:getState()
	return self.currentState
end

function GameState:incrementWave()
	self.currentWave = self.currentWave + 1
end

function GameState:setBaseHealth(health)
	self.baseHealth = math.max(0, health)
end

function GameState:getBaseHealth()
	return self.baseHealth
end

function GameState:updateCureProgress(progress)
	self.cureProgress = math.min(100, progress)
end

function GameState:getCureProgress()
	return self.cureProgress
end

function GameState:isGameOver()
	return self.currentState == GameState.States.VICTORY or 
		self.currentState == GameState.States.DEFEAT
end

return GameState
