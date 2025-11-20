-- GameServer.lua
-- Main server-side game controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GameState = require(ReplicatedStorage.Shared.GameState)
local PlayerManager = require(script.Parent.PlayerManager)
local WaveManager = require(script.Parent.WaveManager)
local BaseManager = require(script.Parent.BaseManager)
local CureCraftingManager = require(script.Parent.CureCraftingManager)

local GameServer = {}
GameServer.__index = GameServer

function GameServer.new()
	local self = setmetatable({}, GameServer)
	
	self.gameState = GameState.new()
	self.playerManager = PlayerManager.new()
	self.waveManager = WaveManager.new()
	self.baseManager = BaseManager.new()
	self.cureManager = CureCraftingManager.new()
	
	self.waveTimer = 0
	self.gameStarted = false
	
	return self
end

function GameServer:startGame()
	if self.gameStarted then
		return false, "Game already started"
	end
	
	local activePlayers = self.playerManager:getActivePlayers()
	if #activePlayers < 1 then
		return false, "Not enough players"
	end
	
	self.gameStarted = true
	self.gameState:setState(GameState.States.IN_PROGRESS)
	self.gameState:setBaseHealth(GameConfig.BASE_HEALTH)
	
	-- Start first wave
	self:startNextWave()
	
	return true, "Game started"
end

function GameServer:startNextWave()
	local waveInfo = self.waveManager:startWave()
	self.gameState:incrementWave()
	
	return waveInfo
end

function GameServer:onPlayerJoin(player)
	local success, message = self.playerManager:addPlayer(player)
	return success, message
end

function GameServer:onPlayerLeave(player)
	self.playerManager:removePlayer(player)
end

function GameServer:damagePlayer(player, damage)
	local died = self.playerManager:damagePlayer(player, damage)
	
	if died then
		self:checkLoseCondition()
	end
	
	return died
end

function GameServer:damageBase(damage)
	local destroyed = self.baseManager:damageBase(damage)
	
	self.gameState:setBaseHealth(self.baseManager:getHealth())
	
	if destroyed then
		self:onDefeat("Base destroyed")
	end
	
	return destroyed
end

function GameServer:collectCureComponent(player, componentName)
	local success, message = self.cureManager:addComponent(componentName)
	
	if success then
		self.playerManager:addCureComponent(player, componentName)
		self.gameState:updateCureProgress(self.cureManager:getCureProgress())
		
		if self.cureManager:isCureCrafted() then
			self:onVictory()
		end
	end
	
	return success, message
end

function GameServer:createAlliance(player1, player2)
	return self.playerManager:addAlliance(player1, player2)
end

function GameServer:breakAlliance(player1, player2)
	return self.playerManager:removeAlliance(player1, player2)
end

function GameServer:onZombieKilled()
	local waveComplete = self.waveManager:onZombieDeath()
	
	if waveComplete then
		-- Start next wave after delay
		self.waveTimer = GameConfig.WAVE_DELAY
	end
end

function GameServer:checkLoseCondition()
	local activePlayers = self.playerManager:getActivePlayers()
	
	if #activePlayers == 0 then
		self:onDefeat("All players eliminated")
	end
end

function GameServer:onVictory()
	self.gameState:setState(GameState.States.VICTORY)
	self.gameStarted = false
end

function GameServer:onDefeat(reason)
	self.gameState:setState(GameState.States.DEFEAT)
	self.gameStarted = false
end

function GameServer:update(deltaTime)
	if not self.gameStarted then
		return
	end
	
	-- Update wave timer
	if self.waveTimer > 0 then
		self.waveTimer = self.waveTimer - deltaTime
		
		if self.waveTimer <= 0 then
			self:startNextWave()
		end
	end
	
	-- Check game conditions
	self:checkLoseCondition()
end

function GameServer:getGameState()
	return {
		state = self.gameState:getState(),
		wave = self.gameState.currentWave,
		baseHealth = self.baseManager:getHealth(),
		baseHealthPercent = self.baseManager:getHealthPercentage(),
		cureProgress = self.cureManager:getCureProgress(),
		zombiesRemaining = self.waveManager:getZombiesRemaining(),
		playersAlive = #self.playerManager:getActivePlayers()
	}
end

return GameServer
