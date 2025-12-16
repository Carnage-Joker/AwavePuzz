-- GameServer.lua
-- LEGACY game controller (NOT CURRENTLY USED)
--
-- NOTE: This is a LEGACY file kept for reference.
-- The ACTIVE game controller is GameManager.lua (used in MainServer.lua)
--
-- This file is not currently used in the main game flow.
-- See GameManager.lua for the active implementation.
--
-- See CODE_ARCHITECTURE.md for details on the migration from GameServer to GameManager.

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

	-- Core state
	self.gameState = GameState.new()

	-- Use singletons so everything (zombies, UI, etc.) shares the same managers
	self.playerManager = PlayerManager.getInstance()
	self.baseManager = BaseManager.getInstance()

	-- Wave + cure systems can stay as regular instances
	self.waveManager = WaveManager.new()
	self.cureManager = CureCraftingManager.new()

	self.waveTimer = 0
	self.gameStarted = false

	return self
end

----------------------------------------------------------------
-- Game flow
----------------------------------------------------------------

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

	-- Sync gameState base health from the BaseManager
	self.gameState:setBaseHealth(self.baseManager:getHealth())

	-- Start first wave
	self:startNextWave()

	return true, "Game started"
end

function GameServer:startNextWave()
	local waveInfo = self.waveManager:startWave()
	self.gameState:incrementWave()
	return waveInfo
end

----------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------

function GameServer:onPlayerJoin(player)
	local success, message = self.playerManager:addPlayer(player)
	return success, message
end

function GameServer:onPlayerLeave(player)
	self.playerManager:removePlayer(player)
end

----------------------------------------------------------------
-- Damage routing
----------------------------------------------------------------

function GameServer:damagePlayer(player, damage)
	-- Delegate to PlayerManager; it handles health, UI, and Humanoid death.
	local died = self.playerManager:damagePlayer(player, damage)

	if died then
		self:checkLoseCondition()
	end

	return died
end

function GameServer:damageBase(damage)
	-- Delegate to BaseManager for actual HP changes
	local destroyed = self.baseManager:damageBase(damage)

	-- Keep GameState's base health synced to the manager
	self.gameState:setBaseHealth(self.baseManager:getHealth())

	if destroyed then
		self:onDefeat("Base destroyed")
	end

	return destroyed
end

----------------------------------------------------------------
-- Cure components / victory
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Alliances
----------------------------------------------------------------

function GameServer:createAlliance(player1, player2)
	return self.playerManager:addAlliance(player1, player2)
end

function GameServer:breakAlliance(player1, player2)
	return self.playerManager:removeAlliance(player1, player2)
end

----------------------------------------------------------------
-- Zombies / waves
----------------------------------------------------------------

function GameServer:onZombieKilled()
	local waveComplete = self.waveManager:onZombieDeath()

	if waveComplete then
		-- Start next wave after a delay
		self.waveTimer = GameConfig.WAVE_DELAY
	end
end

----------------------------------------------------------------
-- Lose / win conditions
----------------------------------------------------------------

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
	-- You can log or broadcast 'reason' if needed
	self.gameState:setState(GameState.States.DEFEAT)
	self.gameStarted = false
end

----------------------------------------------------------------
-- Per-frame update
----------------------------------------------------------------

function GameServer:update(deltaTime)
	if not self.gameStarted then
		return
	end

	-- Wave delay timer between waves
	if self.waveTimer > 0 then
		self.waveTimer -= deltaTime

		if self.waveTimer <= 0 then
			self:startNextWave()
		end
	end

	-- Check game conditions (all players dead, etc.)
	self:checkLoseCondition()
end

----------------------------------------------------------------
-- Snapshot for UI / clients
----------------------------------------------------------------

function GameServer:getGameState()
	-- Always pull current base health from BaseManager singleton
	local baseHealth = self.baseManager:getHealth()
	self.gameState:setBaseHealth(baseHealth)

	return {
		state = self.gameState:getState(),
		wave = self.gameState.currentWave,
		baseHealth = baseHealth,
		baseHealthPercent = self.baseManager:getHealthPercentage(),
		cureProgress = self.cureManager:getCureProgress(),
		zombiesRemaining = self.waveManager:getZombiesRemaining(),
		playersAlive = #self.playerManager:getActivePlayers(),
	}
end

return GameServer
