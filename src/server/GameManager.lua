-- GameManager.lua
-- Main server-side game manager that orchestrates waves, base health, win/lose conditions
-- Supports server disable via disableServer() method
-- Includes spectator mode for dead players (dead players remain in game to watch)
-- Scoreboard stats tracked per player: kills, deaths, round wins/losses
-- Now includes lobby-based map voting and single-life per round system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local BaseManager = require(script.Parent.BaseManager)
local Spawner = require(script.Parent.Spawner)
local PlayerManager = require(script.Parent.PlayerManager)
local ResourceSpawner = require(script.Parent.ResourceSpawner)
local WeaponService = require(script.Parent.WeaponService)
local ShopService = require(script.Parent.ShopService)
local MapManager = require(script.Parent.MapManager)
local LobbyManager = require(script.Parent.LobbyManager)
local SpectatorManager = require(script.Parent.SpectatorManager)

local GameManager = {}
GameManager.__index = GameManager

-- Game states - now includes LOBBY and SCOREBOARD for the new flow
GameManager.States = {
	WAITING = "Waiting",
	LOBBY = "Lobby",         -- Map voting lobby
	COUNTDOWN = "Countdown",
	WAVE_ACTIVE = "WaveActive",
	INTERMISSION = "Intermission",
	VICTORY = "Victory",
	DEFEAT = "Defeat",
	SCOREBOARD = "Scoreboard" -- End of round scoreboard display
}

function GameManager.new(allianceService)
	local self = setmetatable({}, GameManager)

	-- Store alliance service reference
	self.allianceService = allianceService

	-- Server enabled flag
	self.serverEnabled = true

	-- Managers
	self.baseManager = BaseManager.getInstance()
	self.playerManager = PlayerManager.new()
	self.weaponService = WeaponService.new(self.playerManager, allianceService)
	self.shopService = ShopService.new(self.playerManager, self.weaponService)
	self.resourceSpawner = ResourceSpawner.new()

	self.mapManager = MapManager.new()
	self.spawner = Spawner.new(self.weaponService, self.baseManager, self.playerManager)
	
	-- New managers for lobby and spectator system
	self.lobbyManager = LobbyManager.new()
	self.lobbyManager:setMapManager(self.mapManager)
	self.lobbyManager:setGameManager(self)
	
	self.spectatorManager = SpectatorManager.new()

	-- Link WeaponService to PlayerManager for stats calculation
	self.playerManager:setWeaponService(self.weaponService)

	if GameConfig.ENABLE_MULTI_MAP then
		self.mapManager:loadDefault()
		self.spawner:setSpawnPoints(self.mapManager:getZombieSpawnPoints())
		self.resourceSpawner:setSpawnPoints(self.mapManager:getResourceSpawnPoints())
	else
		-- Load spawn points from workspace folders only
		self.spawner:loadSpawnPoints()
		-- Do not overwrite spawn points with potentially empty mapManager data
		-- self.spawner:setSpawnPoints(self.mapManager:getZombieSpawnPoints())
		-- self.resourceSpawner:setSpawnPoints(self.mapManager:getResourceSpawnPoints())
	end

	-- Game state
	self.currentState = GameManager.States.WAITING
	self.currentWave = 0
	self.cureProgress = 0

	-- Scoreboard stats per player (userId -> stats)
	self.playerStats = {}

	-- Timers
	self.stateTimer = 0
	self.waveTimeLimit = 0
	self.waveTimeRemaining = 0

	-- Remote events (will be created if they don't exist)
	self.remoteEvents = {}
	self:setupRemoteEvents()

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
		"BaseHealthUpdate",
		"MapUpdate",
		"ScoreboardUpdate",
		"ShowScoreboard", -- Show scoreboard at end of round
		"HideScoreboard"  -- Hide scoreboard when returning to lobby
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

-- Server enable/disable functionality
function GameManager:disableServer()
	self.serverEnabled = false
	print("Server disabled - game will not start new rounds")
	
	-- Clear any active zombies
	self.spawner:clearAllZombies()
	
	-- Set state to waiting
	if self.currentState ~= GameManager.States.VICTORY and self.currentState ~= GameManager.States.DEFEAT then
		self:setState(GameManager.States.WAITING)
	end
end

function GameManager:enableServer()
	if self.currentState ~= GameManager.States.WAITING then
		warn("Cannot enable server - game already in progress. Current state:", self.currentState)
		return false
	end
	self.serverEnabled = true
	print("Server enabled - game can now start")
	return true
end

function GameManager:isServerEnabled()
	return self.serverEnabled
end

-- Scoreboard stat tracking
function GameManager:initializePlayerStats(player)
	if not self.playerStats[player.UserId] then
		self.playerStats[player.UserId] = {
			playerName = player.Name,
			kills = 0,
			deaths = 0,
			roundWins = 0,
			roundLosses = 0,
			damageDealt = 0,
			componentsCollected = 0
		}
	end
end

function GameManager:incrementPlayerKills(player, amount)
	self:initializePlayerStats(player)
	self.playerStats[player.UserId].kills = self.playerStats[player.UserId].kills + (amount or 1)
	self:broadcastScoreboard()
end

function GameManager:incrementPlayerDeaths(player)
	self:initializePlayerStats(player)
	self.playerStats[player.UserId].deaths = self.playerStats[player.UserId].deaths + 1
	self:broadcastScoreboard()
end

function GameManager:incrementPlayerComponentsCollected(player)
	self:initializePlayerStats(player)
	self.playerStats[player.UserId].componentsCollected = self.playerStats[player.UserId].componentsCollected + 1
	self:broadcastScoreboard()
end

function GameManager:broadcastScoreboard()
	if self.remoteEvents.ScoreboardUpdate then
		-- Build scoreboard data
		local scoreboardData = {}
		for userId, stats in pairs(self.playerStats) do
			table.insert(scoreboardData, {
				userId = userId,
				playerName = stats.playerName,
				kills = stats.kills,
				deaths = stats.deaths,
				roundWins = stats.roundWins,
				roundLosses = stats.roundLosses,
				componentsCollected = stats.componentsCollected
			})
		end
		
		-- Sort by kills descending
		table.sort(scoreboardData, function(a, b)
			return a.kills > b.kills
		end)
		
		self.remoteEvents.ScoreboardUpdate:FireAllClients(scoreboardData)
	end
end

function GameManager:getPlayerStats(player)
	self:initializePlayerStats(player)
	return self.playerStats[player.UserId]
end

function GameManager:broadcastMap()
	if self.remoteEvents.MapUpdate then
		self.remoteEvents.MapUpdate:FireAllClients({
			map = self.mapManager:getCurrentMapId()
		})
	end
end

function GameManager:onPlayerAdded(player)
	local success, message = self.playerManager:addPlayer(player)
	if not success then
		warn("Failed to add player:", message)
		return
	end
	self.weaponService:initializePlayer(player)
	self.shopService:sendCatalog(player)
	
	-- Initialize scoreboard stats for the player
	self:initializePlayerStats(player)
	self:broadcastScoreboard()
end

function GameManager:onPlayerRemoving(player)
	self.playerManager:removePlayer(player)
	self.weaponService:removePlayer(player)
	self.lobbyManager:onPlayerLeave(player)
	self.spectatorManager:onPlayerLeave(player)
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

function GameManager:setCureService(cureService)
	self.cureService = cureService
	if self.resourceSpawner and self.resourceSpawner.setCureService then
		self.resourceSpawner:setCureService(cureService)
	end
end

function GameManager:startGame()
	if self.currentState ~= GameManager.States.WAITING and self.currentState ~= GameManager.States.LOBBY then
		return false
	end
	
	-- Check if server is enabled
	if not self.serverEnabled then
		print("Cannot start game - server is disabled")
		return false
	end

	print("Starting game...")
	self:setState(GameManager.States.COUNTDOWN)
	self.stateTimer = GameConfig.ROUND_COUNTDOWN_TIME or 5 -- Use configured countdown time

	if GameConfig.ENABLE_MULTI_MAP then
		self:broadcastMap()
	end

	return true
end

-- Start the lobby/voting phase
function GameManager:startLobby()
	if self.currentState ~= GameManager.States.WAITING and 
	   self.currentState ~= GameManager.States.SCOREBOARD then
		return false
	end
	
	if not self.serverEnabled then
		print("Cannot start lobby - server is disabled")
		return false
	end

	print("[GameManager] Entering lobby...")
	self:setState(GameManager.States.LOBBY)
	self.stateTimer = GameConfig.LOBBY_VOTING_TIME
	
	-- Reset for new round
	self:resetForNewRound()
	
	-- Start map voting
	self.lobbyManager:startVoting()
	
	return true
end

-- Reset game state for a new round
function GameManager:resetForNewRound()
	-- Reset wave counter
	self.currentWave = 0
	self.cureProgress = 0
	
	-- Reset cure service if it exists
	if self.cureService and self.cureService.reset then
		self.cureService:reset()
	end
	
	-- Reset base health
	self.baseManager:reset()
	
	-- Clear any remaining zombies
	self.spawner:clearAllZombies()
	
	-- Reset spectator manager
	self.spectatorManager:reset()
	
	-- Reset lobby manager for new voting session
	self.lobbyManager:reset()
	
	-- Respawn all players for new round
	for _, player in ipairs(Players:GetPlayers()) do
		-- Reset player health
		local playerData = self.playerManager:getPlayerData(player)
		if playerData then
			playerData.health = GameConfig.STARTING_HEALTH
			playerData.isAlive = true
		end
		
		-- Reload character
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		else
			player:LoadCharacter()
		end
	end
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
	-- Note: Currently uses linear zombie count scaling. Health scaling is already applied via
	-- GameConfig.ZOMBIE_HEALTH_MULTIPLIER; additional scaling (e.g., speed, damage, or more aggressive health scaling)
	-- could be added for increased challenge in endless mode.
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

	-- Award bonus currency for wave completion
	for _, player in ipairs(Players:GetPlayers()) do
		self.playerManager:addCurrency(player, GameConfig.CURRENCY_PER_WAVE)
	end
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
	
	-- Exit all spectators
	self.spectatorManager:endRound()
	
	-- Update scoreboard stats - all surviving players get round win
	for _, player in ipairs(Players:GetPlayers()) do
		self:initializePlayerStats(player)
		self.playerStats[player.UserId].roundWins = self.playerStats[player.UserId].roundWins + 1
	end
	self:broadcastScoreboard()
	
	-- Show scoreboard and start timer to return to lobby
	self:showEndOfRoundScoreboard()
	self.stateTimer = GameConfig.SCOREBOARD_DISPLAY_TIME
end

function GameManager:onDefeat(reason)
	print("DEFEAT! " .. reason)
	self:setState(GameManager.States.DEFEAT)

	-- Stop spawning, clean up zombies
	self.spawner:clearAllZombies()
	
	-- Exit all spectators
	self.spectatorManager:endRound()
	
	-- Update scoreboard stats - all players get round loss
	for _, player in ipairs(Players:GetPlayers()) do
		self:initializePlayerStats(player)
		self.playerStats[player.UserId].roundLosses = self.playerStats[player.UserId].roundLosses + 1
	end
	self:broadcastScoreboard()
	
	-- Show scoreboard and start timer to return to lobby
	self:showEndOfRoundScoreboard()
	self.stateTimer = GameConfig.SCOREBOARD_DISPLAY_TIME
end

-- Show the scoreboard at end of round
function GameManager:showEndOfRoundScoreboard()
	if self.remoteEvents.ShowScoreboard then
		self.remoteEvents.ShowScoreboard:FireAllClients({
			duration = GameConfig.SCOREBOARD_DISPLAY_TIME,
			scores = self:getScoreboardData()
		})
	end
end

-- Get formatted scoreboard data
function GameManager:getScoreboardData()
	local scoreboardData = {}
	for userId, stats in pairs(self.playerStats) do
		table.insert(scoreboardData, {
			userId = userId,
			playerName = stats.playerName,
			kills = stats.kills,
			deaths = stats.deaths,
			roundWins = stats.roundWins,
			roundLosses = stats.roundLosses,
			componentsCollected = stats.componentsCollected
		})
	end
	
	-- Sort by kills descending
	table.sort(scoreboardData, function(a, b)
		return a.kills > b.kills
	end)
	
	return scoreboardData
end

function GameManager:checkLoseConditions()
	-- Check if base is destroyed
	if self.baseManager:isBaseDestroyed() then
		self:onDefeat("Base destroyed")
		return true
	end

	-- Check if all players are dead (using spectator manager tracking)
	local players = game.Players:GetPlayers()
	local anyAlive = false

	for _, player in ipairs(players) do
		-- Skip players already marked as dead in spectator manager
		if not self.spectatorManager:isPlayerDead(player) then
			if player.Character then
				local humanoid = player.Character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					anyAlive = true
					break
				end
			end
		end
	end

	if #players > 0 and not anyAlive then
		self:onDefeat("All players eliminated")
		return true
	end

	return false
end

-- Handle player death - put them in spectator mode
function GameManager:onPlayerDied(player)
	if not player then return end
	
	-- Only handle during active gameplay
	if self.currentState ~= GameManager.States.WAVE_ACTIVE and 
	   self.currentState ~= GameManager.States.INTERMISSION then
		return
	end
	
	-- Track death in scoreboard
	self:incrementPlayerDeaths(player)
	
	-- Put player in spectator mode
	self.spectatorManager:onPlayerDied(player)
	
	-- Notify other spectators if they were watching this player
	self.spectatorManager:onSpectatorTargetDied(player.UserId)
	
	-- Update spectator list for all spectators
	self.spectatorManager:broadcastAliveList()
	
	-- Check if this causes a lose condition
	self:checkLoseConditions()
end

function GameManager:updateCountdown(deltaTime)
	self.stateTimer = self.stateTimer - deltaTime
	-- self.resourceSpawner:update(deltaTime) -- Do not spawn resources during COUNTDOWN

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

	-- Update resource spawner for pickups
	self.resourceSpawner:update(deltaTime)

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

	-- Continue spawning resources during downtime
	self.resourceSpawner:update(deltaTime)

	if self.stateTimer <= 0 then
		-- Start next wave
		self:startWave()
	end
end

function GameManager:update(deltaTime)
	-- Update based on current state
	if self.currentState == GameManager.States.LOBBY then
		self:updateLobby(deltaTime)

	elseif self.currentState == GameManager.States.COUNTDOWN then
		self:updateCountdown(deltaTime)

	elseif self.currentState == GameManager.States.WAVE_ACTIVE then
		self:updateWave(deltaTime)

	elseif self.currentState == GameManager.States.INTERMISSION then
		self:updateIntermission(deltaTime)

	elseif self.currentState == GameManager.States.WAITING then
		-- Check if enough players to start lobby
		local playerCount = #game.Players:GetPlayers()
		if playerCount >= (GameConfig.LOBBY_MIN_PLAYERS or 1) then
			self:startLobby()
		end
		self.resourceSpawner:update(deltaTime)

	elseif self.currentState == GameManager.States.VICTORY or 
	       self.currentState == GameManager.States.DEFEAT then
		-- Wait for scoreboard display time, then return to lobby
		self:updateEndOfRound(deltaTime)

	elseif self.currentState == GameManager.States.SCOREBOARD then
		self:updateScoreboard(deltaTime)
	else
		-- Even when game is over, allow resource spawner to clean up timers
		self.resourceSpawner:update(deltaTime)
	end
end

-- Update during lobby/voting phase
function GameManager:updateLobby(deltaTime)
	-- Update lobby manager
	self.lobbyManager:update(deltaTime)
	
	-- Check if voting has ended
	if not self.lobbyManager:isVotingActive() then
		-- Load the selected map
		local selectedMapId = self.lobbyManager:getSelectedMapId()
		if selectedMapId and GameConfig.ENABLE_MULTI_MAP then
			self.mapManager:load(selectedMapId)
			self.spawner:setSpawnPoints(self.mapManager:getZombieSpawnPoints())
			self.resourceSpawner:setSpawnPoints(self.mapManager:getResourceSpawnPoints())
		end
		
		-- Start the game
		self:startGame()
	end
end

-- Update during end of round (victory/defeat)
function GameManager:updateEndOfRound(deltaTime)
	self.stateTimer = self.stateTimer - deltaTime
	
	if self.stateTimer <= 0 then
		-- Transition to lobby for next round
		self:setState(GameManager.States.SCOREBOARD)
		self.stateTimer = 2 -- Brief pause before lobby
		
		-- Hide the scoreboard
		if self.remoteEvents.HideScoreboard then
			self.remoteEvents.HideScoreboard:FireAllClients({})
		end
	end
end

-- Update during scoreboard state (brief transition to lobby)
function GameManager:updateScoreboard(deltaTime)
	self.stateTimer = self.stateTimer - deltaTime
	
	if self.stateTimer <= 0 then
		-- Check if there are still players
		local playerCount = #game.Players:GetPlayers()
		if playerCount >= (GameConfig.LOBBY_MIN_PLAYERS or 1) then
			self:startLobby()
		else
			self:setState(GameManager.States.WAITING)
		end
	end
end

function GameManager:getPlayerManager()
	return self.playerManager
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

function GameManager:getLobbyManager()
	return self.lobbyManager
end

function GameManager:getSpectatorManager()
	return self.spectatorManager
end

return GameManager
