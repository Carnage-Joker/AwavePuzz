-- ClientController.lua
-- Client-side game controller for UI and player input

local ClientController = {}
ClientController.__index = ClientController

function ClientController.new()
	local self = setmetatable({}, ClientController)
	
	self.gameState = {
		wave = 0,
		baseHealth = 0,
		cureProgress = 0,
		zombiesRemaining = 0,
		playerHealth = 100,
		isAlive = true
	}
	
	return self
end

function ClientController:updateGameState(stateData)
	self.gameState.wave = stateData.wave or 0
	self.gameState.baseHealth = stateData.baseHealth or 0
	self.gameState.cureProgress = stateData.cureProgress or 0
	self.gameState.zombiesRemaining = stateData.zombiesRemaining or 0
end

function ClientController:updatePlayerHealth(health)
	self.gameState.playerHealth = health
	self.gameState.isAlive = health > 0
end

function ClientController:displayWaveStart(waveNumber)
	-- This would trigger UI to show wave start
	print("Wave " .. waveNumber .. " starting!")
end

function ClientController:displayCureProgress(progress)
	-- This would update a progress bar in the UI
	print("Cure Progress: " .. progress .. "%")
end

function ClientController:displayAlliance(playerName, allied)
	if allied then
		print("Alliance formed with " .. playerName)
	else
		print("Alliance broken with " .. playerName)
	end
end

function ClientController:displayVictory()
	print("VICTORY! Cure has been crafted!")
end

function ClientController:displayDefeat(reason)
	print("DEFEAT! " .. reason)
end

function ClientController:requestAlliance(targetPlayer)
	-- Send request to server
	print("Requesting alliance with " .. targetPlayer.Name)
end

function ClientController:betrayAlliance(targetPlayer)
	-- Send betrayal request to server
	print("Breaking alliance with " .. targetPlayer.Name)
end

function ClientController:collectComponent(componentName)
	-- Send collection request to server
	print("Collecting component: " .. componentName)
end

function ClientController:getGameState()
	return self.gameState
end

return ClientController
