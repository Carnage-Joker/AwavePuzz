-- GameManager.lua
-- Main server-side game manager that orchestrates waves, base health, win/lose conditions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local BaseManager = require(script.Parent.BaseManager)
local Spawner = require(script.Parent.Spawner)

local GameManager = {}
GameManager.__index = GameManager

-- Game states
GameManager.States = {
	WAITING = "Waiting",
	COUNTDOWN = "Countdown",
	WAVE_ACTIVE = "WaveActive",
	INTERMISSION = "Intermission",
	VICTORY = "Victory",
	DEFEAT = "Defeat"
}

function GameManager.new()
	local self = setmetatable({}, GameManager)
	
	-- Managers
	self.baseManager = BaseManager.new()
	self.spawner = Spawner.new()
	
	-- Game state
	self.currentState = GameManager.States.WAITING
	self.currentWave = 0
	self.cureProgress = 0
	
	-- Timers
	self.stateTimer = 0
	self.waveTimeLimit = 0
	self.waveTimeRemaining = 0
	
	-- Remote events (will be created if they don't exist)
	self.remoteEvents = {}
	self:setupRemoteEvents()
	
	-- Setup
	self.spawner:loadSpawnPoints()
	
	return self
end

function GameManager:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- Create remote events if they don't exist
	local eventNames = {
		"WaveAnnounce",
		"WaveUpdate",
		"GameStateUpdate",
		"CureUpdate",
		"BaseHealthUpdate"
	}
	
	for _, eventName in ipairs(eventNames) do
		local event = remoteEventsFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteEventsFolder
		end
		self.remoteEvents[eventName] = event
	end
end

function GameManager:setState(newState)
	self.currentState = newState
	self.stateTimer = 0
	
	-- Broadcast state change
	if self.remoteEvents.GameStateUpdate then
		self.remoteEvents.GameStateUpdate:FireAllClients({
			state = newState,
			wave = self.currentWave,
			baseHealth = self.baseManager:getHealth(),
			cureProgress = self.cureProgress
		})
	end
end

function GameManager:startGame()
	if self.currentState ~= GameManager.States.WAITING then
		return false
	end
	
	print("Starting game...")
	self:setState(GameManager.States.COUNTDOWN)
	self.stateTimer = 5 -- 5 second countdown
	
	return true
end

function GameManager:startWave()
	self.currentWave = self.currentWave + 1
	
	local waveData = WaveConfig.getWave(self.currentWave)
	if not waveData then
		-- No more configured waves, generate endless mode
		waveData = self:generateEndlessWave()
	end
	
	print("Starting Wave " .. self.currentWave)
	
	-- Set wave state
	self:setState(GameManager.States.WAVE_ACTIVE)
	self.waveTimeLimit = waveData.TimeLimit
	self.waveTimeRemaining = waveData.TimeLimit
	
	-- Announce wave
	if self.remoteEvents.WaveAnnounce then
		self.remoteEvents.WaveAnnounce:FireAllClients({
			waveNumber = self.currentWave,
			timeLimit = waveData.TimeLimit,
			zombieCount = waveData.ZombieCount
		})
	end
	
	-- Spawn zombies
	self.spawner:spawnWave(waveData.Composition)
end

function GameManager:generateEndlessWave()
	-- Generate procedural waves after configured waves end
	local difficultyMultiplier = (self.currentWave - WaveConfig.getTotalWaves()) * 0.3
	local baseCount = 15 + (self.currentWave * 2)
	
	return {
		Number = self.currentWave,
		TimeLimit = 240,
		ZombieCount = baseCount,
		Composition = {
			Walker = math.floor(baseCount * 0.4),
			Runner = math.floor(baseCount * 0.3),
			Brute = math.floor(baseCount * 0.2),
			Spitter = math.floor(baseCount * 0.1)
		}
	}
end

function GameManager:checkWaveComplete()
	local zombiesAlive = self.spawner:getActiveZombieCount()
	
	if zombiesAlive <= 0 then
		print("Wave " .. self.currentWave .. " complete!")
		self:onWaveComplete()
		return true
	end
	
	return false
end

function GameManager:onWaveComplete()
	self:setState(GameManager.States.INTERMISSION)
	self.stateTimer = GameConfig.WAVE_DELAY
	
	-- Award bonus for wave completion
	-- TODO: Give rewards to players
end

function GameManager:updateCureProgress(progress)
	self.cureProgress = math.min(100, progress)
	
	-- Broadcast cure update
	if self.remoteEvents.CureUpdate then
		self.remoteEvents.CureUpdate:FireAllClients(self.cureProgress)
	end
	
	-- Check win condition
	if self.cureProgress >= 100 then
		self:onVictory()
	end
end

function GameManager:onVictory()
	print("VICTORY! Cure completed!")
	self:setState(GameManager.States.VICTORY)
	
	-- Stop spawning, clean up zombies
	self.spawner:clearAllZombies()
	
	-- TODO: Show victory UI, calculate rewards
end

function GameManager:onDefeat(reason)
	print("DEFEAT! " .. reason)
	self:setState(GameManager.States.DEFEAT)
	
	-- Stop spawning, clean up zombies
	self.spawner:clearAllZombies()
	
	-- TODO: Show defeat UI
end

function GameManager:checkLoseConditions()
	-- Check if base is destroyed
	if self.baseManager:isBaseDestroyed() then
		self:onDefeat("Base destroyed")
		return true
	end
	
	-- Check if all players are dead
	local players = game.Players:GetPlayers()
	local anyAlive = false
	
	for _, player in ipairs(players) do
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				anyAlive = true
				break
			end
		end
	end
	
	if #players > 0 and not anyAlive then
		self:onDefeat("All players eliminated")
		return true
	end
	
	return false
end

function GameManager:updateCountdown(deltaTime)
	self.stateTimer = self.stateTimer - deltaTime
	
	if self.stateTimer <= 0 then
		-- Start first wave
		self:startWave()
	end
end

function GameManager:updateWave(deltaTime)
	-- Update wave timer
	self.waveTimeRemaining = self.waveTimeRemaining - deltaTime
	
	-- Update spawner
	self.spawner:update(deltaTime)
	
	-- Broadcast wave update periodically
	if math.floor(self.waveTimeRemaining) % 5 == 0 then
		if self.remoteEvents.WaveUpdate then
			self.remoteEvents.WaveUpdate:FireAllClients({
				timeRemaining = math.floor(self.waveTimeRemaining),
				zombiesAlive = self.spawner:getActiveZombieCount()
			})
		end
	end
	
	-- Check if wave is complete
	self:checkWaveComplete()
	
	-- Check if time ran out
	if self.waveTimeRemaining <= 0 then
		print("Wave time limit reached!")
		self:onWaveComplete()
	end
	
	-- Check lose conditions
	self:checkLoseConditions()
end

function GameManager:updateIntermission(deltaTime)
	self.stateTimer = self.stateTimer - deltaTime
	
	if self.stateTimer <= 0 then
		-- Start next wave
		self:startWave()
	end
end

function GameManager:update(deltaTime)
	-- Update based on current state
	if self.currentState == GameManager.States.COUNTDOWN then
		self:updateCountdown(deltaTime)
		
	elseif self.currentState == GameManager.States.WAVE_ACTIVE then
		self:updateWave(deltaTime)
		
	elseif self.currentState == GameManager.States.INTERMISSION then
		self:updateIntermission(deltaTime)
		
	elseif self.currentState == GameManager.States.WAITING then
		-- Check if enough players to start
		local playerCount = #game.Players:GetPlayers()
		if playerCount >= 1 then -- Start with at least 1 player
			self:startGame()
		end
	end
end

function GameManager:getGameState()
	return {
		state = self.currentState,
		wave = self.currentWave,
		baseHealth = self.baseManager:getHealth(),
		baseHealthPercent = self.baseManager:getHealthPercentage(),
		cureProgress = self.cureProgress,
		zombiesRemaining = self.spawner:getActiveZombieCount(),
		timeRemaining = math.floor(self.waveTimeRemaining)
	}
end

return GameManager
