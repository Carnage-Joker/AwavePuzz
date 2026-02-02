-- @ScriptType: ModuleScript
-- GameManager.lua
-- Main server-side game manager that orchestrates waves, base health, win/lose conditions
-- Supports server disable via disableServer() method
-- Includes spectator mode for dead players (dead players remain in game to watch)
-- Scoreboard stats tracked per player: kills, deaths, round wins/losses
-- Now includes lobby-based map voting and single-life per round system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[GameManager] Loading shared configuration...")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[GameManager] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))
local WaveConfig = require(SharedFolder:WaitForChild("WaveConfig", 5))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil", 5))

local BaseManager = require(script.Parent.BaseManager)
local Spawner = require(script.Parent.Spawner)
local PlayerManager = require(script.Parent.PlayerManager)
local ResourceSpawner = require(script.Parent.ResourceSpawner)
local ItemSpawner = require(script.Parent.ItemSpawner)

local WeaponService = require(script.Parent.WeaponService)
local FPSWeaponService = require(script.Parent.FPSWeaponService)
local FPSAnimationService = require(script.Parent.FPSAnimationService)

local ShopService = require(script.Parent.ShopService)
local MapManager = require(script.Parent.MapManager)
local LobbyManager = require(script.Parent.LobbyManager)
local SpectatorManager = require(script.Parent.SpectatorManager)
local PlayerSpawnManager = require(script.Parent.PlayerSpawnManager)
local LobbySetup = require(script.Parent.LobbySetup)

-- Portal matchmaking (conditional load based on feature flag)
local PortalMatchmakingService
if GameConfig and GameConfig.USE_PORTAL_MATCHMAKING then
	PortalMatchmakingService = require(script.Parent.PortalMatchmakingService)
end

local GameManager = {}
GameManager.__index = GameManager

GameManager.States = {
	TITLE_SCREEN = "TitleScreen",
	EPILOGUE = "Epilogue",
	WAITING = "Waiting",
	LOBBY = "Lobby",
	COUNTDOWN = "Countdown",
	WAVE_ACTIVE = "WaveActive",
	INTERMISSION = "Intermission",
	VICTORY = "Victory",
	DEFEAT = "Defeat",
	SCOREBOARD = "Scoreboard"
}

-- Constants
local DEFAULT_WEAPON_SYNC_DELAY = 0.5  -- Fallback delay in seconds before sending weapon updates on character respawn
local WEAPON_SYNC_DELAY = (type(GameConfig) == "table" and type(GameConfig.WEAPON_SYNC_DELAY) == "number")
	and GameConfig.WEAPON_SYNC_DELAY
	or DEFAULT_WEAPON_SYNC_DELAY

function GameManager.new(allianceService)
	local self = setmetatable({}, GameManager)

	self.allianceService = allianceService
	self.serverEnabled = true

	-- Managers
	self.baseManager = BaseManager.getInstance()

	-- ✅ IMPORTANT: use singleton instance
	self.playerManager = PlayerManager.getInstance()

	-- ✅ Services (wire FPS ammo to WeaponService properly)
	self.weaponService = WeaponService.new(self.playerManager, allianceService, self)
	self.fpsWeaponService = FPSWeaponService.new(self.playerManager, self.weaponService)
	self.weaponService:setFPSWeaponService(self.fpsWeaponService)

	-- FPS Animation replication service
	self.fpsAnimationService = FPSAnimationService.new()

	self.shopService = ShopService.new(self.playerManager, self.weaponService)
	self.resourceSpawner = ResourceSpawner.new()
	self.itemSpawner = ItemSpawner.new()
	self.itemSpawner:setPlayerManager(self.playerManager)
	self.itemSpawner:setFPSWeaponService(self.fpsWeaponService)

	self.mapManager = MapManager.new()
	self.spawner = Spawner.new(self.weaponService, self.baseManager, self.playerManager)

	self.lobbyManager = LobbyManager.new()
	self.lobbyManager:setMapManager(self.mapManager)
	self.lobbyManager:setGameManager(self)

	self.spectatorManager = SpectatorManager.new()

	-- Player spawn manager (controls when and where players spawn)
	self.playerSpawnManager = PlayerSpawnManager.new()
	self.playerSpawnManager:setGameManager(self)

	-- Lobby setup (creates lobby area for players before map loads)
	self.lobbySetup = LobbySetup.new()
	self.lobbySetup:getOrCreateLobby()

	-- Portal matchmaking service (if enabled)
	if GameConfig.USE_PORTAL_MATCHMAKING and PortalMatchmakingService then
		self.portalMatchmakingService = PortalMatchmakingService.new(self)
		print("[GameManager] Portal matchmaking service initialized")
	else
		self.portalMatchmakingService = nil
	end

	self.playerManager:setWeaponService(self.weaponService)

	-- Achievement tracking (will be initialized later to avoid circular dependency)
	self.achievementService = nil

	-- State
	if GameConfig.SHOW_TITLE_SCREEN then
		self.currentState = GameManager.States.TITLE_SCREEN
		print("[GameManager] Starting in TITLE_SCREEN state")
	else
		self.currentState = GameManager.States.WAITING
		print("[GameManager] Starting in WAITING state (title screen disabled)")
	end
	self.currentWave = 0
	self.cureProgress = 0

	self.playerStats = {}

	self.stateTimer = 0
	self.waveTimeLimit = 0
	self.waveTimeRemaining = 0

	-- Title screen and epilogue tracking
	self.playersReadyForEpilogue = {} -- Track which players have passed title screen
	self.playersCompletedEpilogue = {} -- Track which players have finished epilogue

	self.remoteEvents = {}
	self:setupRemoteEvents()

	-- ✅ Debounce + broadcast control
	self._deathDebounce = {}              -- userId -> true (for current round)
	self._deathConnections = {}           -- userId -> array of connections for cleanup
	self._lastWaveBroadcastSec = nil      -- last second we broadcast WaveUpdate
	self._spectatorCycleCooldown = {}     -- userId -> last os.clock()

	-- ✅ FIX: prevents double map load / double base setup / double spawning
	self._lobbyResolved = false
	self._lastLobbyResolveAttempt = 0     -- Time-based debounce for lobby resolution
	
	-- Cleanup tracking
	self._heartbeatConnection = nil       -- Will be set by MainServer

	-- ✅ FIX: Do NOT load map on server boot! Map should only load after portal queue or lobby voting.
	-- Maps will be loaded by:
	-- 1. Portal matchmaking when a queue is ready (PortalMatchmakingService:launchMatch -> GameManager:startMatch)
	-- 2. Lobby voting when voting completes (GameManager:updateLobby -> MapManager:load)
	-- 
	-- Loading the map here causes the "player joins -> map loads immediately" bug.
	-- Legacy boot-time map loading logic has been removed; refer to version control history if needed.
	
	print("[GameManager] Boot complete - no map loaded yet (maps load after lobby/portal selection)")

	-- Discover portals if portal matchmaking is enabled
	if self.portalMatchmakingService then
		self.portalMatchmakingService:discoverPortals()
	end

	-- ✅ REMOVED: Do NOT call _hookSpectatorRemotes()
	-- SpectatorManager owns and handles SpectatorCycleTarget remote.
	-- Duplicate handling caused confusion and potential race conditions.

	return self
end

-- ✅ REMOVED: _hookSpectatorRemotes() method
-- SpectatorManager owns and handles SpectatorCycleTarget remote.
-- Duplicate handling caused confusion and potential race conditions.

-- Helper method to configure spawners with map spawn points
function GameManager:configureSpawnersForMap()
	self.spawner:setSpawnPoints(self.mapManager:getZombieSpawnPoints())
	self.resourceSpawner:setSpawnPoints(self.mapManager:getResourceSpawnPoints())
	-- Pass zombie spawn points to ResourceSpawner for intelligent placement
	self.resourceSpawner:setZombieSpawnPoints(self.mapManager:getZombieSpawnPoints())
	
	-- Configure ItemSpawner with item spawn points from the map
	local itemSpawnParts = self.itemSpawner:findItemSpawnPoints()
	self.itemSpawner:setSpawnPoints(itemSpawnParts)
end

function GameManager:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"WaveAnnounce",
		"WaveUpdate",
		"GameStateUpdate",
		"CureUpdate",
		"BaseHealthUpdate",
		"MapUpdate",
		"ScoreboardUpdate",
		"ShowScoreboard",
		"HideScoreboard",
		"ShowTitleScreen",
		"HideTitleScreen",
		"TitleScreenContinue",
		"ShowEpilogue",
		"HideEpilogue",
		"EpilogueComplete",
		"ShowCredits",
		"HideCredits",
		"AchievementUnlocked",
		"BetrayalStarted"
	})

	-- Hook title screen and epilogue events
	self:_hookIntroRemotes()
	
	-- ✅ REMOVED: Do NOT hook SpectatorCycleTarget here
	-- SpectatorManager is the single owner of this remote and handles it correctly
end

function GameManager:_hookIntroRemotes()
	-- Only bind OnServerEvent connections when running on the server
	-- This prevents errors in test/edit contexts where RunService:IsServer() is false
	if not RunService:IsServer() then
		return
	end
	
	-- Hook title screen continue event
	if self.remoteEvents.TitleScreenContinue then
		self.remoteEvents.TitleScreenContinue.OnServerEvent:Connect(function(player)
			self:onPlayerPassedTitleScreen(player)
		end)
	end

	-- Hook epilogue complete event
	if self.remoteEvents.EpilogueComplete then
		self.remoteEvents.EpilogueComplete.OnServerEvent:Connect(function(player)
			self:onPlayerCompletedEpilogue(player)
		end)
	end
end

function GameManager:onPlayerPassedTitleScreen(player)
	if not player then return end

	print(string.format("[Flow] Player %s passed title screen (TitleScreenContinue)", player.Name))
	self.playersReadyForEpilogue[player.UserId] = true

	-- ✅ FIX: Do NOT show epilogue during title screen (removed lines 257-263)
	-- Epilogue should only show after rounds complete, not on first join
	-- Individual players no longer receive epilogue during TITLE_SCREEN state

	-- Check if all players have passed title screen
	self:checkAllPlayersReadyForEpilogue()
end

function GameManager:onPlayerCompletedEpilogue(player)
	if not player then return end

	print(string.format("[GameManager] Player %s completed epilogue", player.Name))
	self.playersCompletedEpilogue[player.UserId] = true

	-- Check if all players have completed epilogue
	self:checkAllPlayersCompletedEpilogue()
end

function GameManager:checkAllPlayersReadyForEpilogue()
	local allPlayers = Players:GetPlayers()
	if #allPlayers == 0 then return end

	for _, player in ipairs(allPlayers) do
		if not self.playersReadyForEpilogue[player.UserId] then
			return
		end
	end

	print("[Flow] All players passed title screen")
	
	-- Check if we should show epilogue on first join (configurable)
	-- Requires BOTH SHOW_EPILOGUE and INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN to be true
	if self.currentState == GameManager.States.TITLE_SCREEN 
		and GameConfig.SHOW_EPILOGUE 
		and GameConfig.INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN then
		print("[Flow] TitleScreen -> Epilogue (SHOW_EPILOGUE=true, INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN=true)")
		self:setState(GameManager.States.EPILOGUE)
		-- Reset epilogue completion tracking
		self.playersCompletedEpilogue = {}
		-- Show epilogue to all players
		if self.remoteEvents.ShowEpilogue then
			self.remoteEvents.ShowEpilogue:FireAllClients()
		end
	else
		-- ✅ FIX: On first join (from TITLE_SCREEN), go directly to LOBBY, not EPILOGUE
		-- Epilogue should only show after a round ends (VICTORY/DEFEAT -> EPILOGUE -> LOBBY)
		-- This fixes the "nonsense epilogue on first join" bug
		print("[Flow] TitleScreenContinue -> Lobby (entering lobby)")
		self:startLobby()
	end
end

function GameManager:checkAllPlayersCompletedEpilogue()
	local allPlayers = Players:GetPlayers()
	if #allPlayers == 0 then return end

	for _, player in ipairs(allPlayers) do
		if not self.playersCompletedEpilogue[player.UserId] then
			return
		end
	end

	print("[GameManager] All players completed epilogue, transitioning to LOBBY")
	-- Start lobby after epilogue completion
	local playerCount = #Players:GetPlayers()
	if playerCount >= (GameConfig.LOBBY_MIN_PLAYERS or 1) then
		-- Directly transition to LOBBY and initialize lobby, similar to checkAllPlayersReadyForEpilogue
		self:setState(GameManager.States.LOBBY)
		self.stateTimer = GameConfig.LOBBY_VOTING_TIME or 20

		if self.lobbySetup then
			self.lobbySetup:getOrCreateLobby()
		end

		if not GameConfig.USE_PORTAL_MATCHMAKING then
			self.lobbyManager:startVoting()
		end
	else
		self:setState(GameManager.States.WAITING)
	end
end

function GameManager:disableServer()
	self.serverEnabled = false
	print("Server disabled - game will not start new rounds")

	self.spawner:clearAllZombies()

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
	if not self.remoteEvents.ScoreboardUpdate then return end

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

	table.sort(scoreboardData, function(a, b)
		return a.kills > b.kills
	end)

	self.remoteEvents.ScoreboardUpdate:FireAllClients(scoreboardData)
end

function GameManager:getPlayerStats(player)
	self:initializePlayerStats(player)
	return self.playerStats[player.UserId]
end

function GameManager:broadcastMap()
	if self.remoteEvents.MapUpdate then
		self.remoteEvents.MapUpdate:FireAllClients({ map = self.mapManager:getCurrentMapId() })
	end
end

-- ✅ Hook Humanoid.Died -> onPlayerDied (authoritative)
function GameManager:_hookPlayerDeath(player)
	local function hookCharacter(char)
		-- Clear death debounce on respawn to prevent race conditions
		self._deathDebounce[player.UserId] = nil
		
		local humanoid = char:WaitForChild("Humanoid", 5)
		if not humanoid then
			-- Critical error: Humanoid missing after 5 seconds
			warn("[GameManager] CRITICAL: Humanoid not found for player " .. player.Name .. " after 5 seconds. Forcing death.")
			-- Force player death to prevent game state desync
			self:onPlayerDied(player)
			return
		end
		
		-- FIX: Re-send weapon loadout and ammo updates on character respawn
		-- Run asynchronously to avoid blocking other character spawns
		task.spawn(function()
			-- Wait briefly to ensure client's character controller is ready to receive updates
			task.wait(WEAPON_SYNC_DELAY)
			
			-- Verify player is still valid
			if not player or not player.Parent then 
				warn(string.format("[GameManager] Player %s left before weapon sync could complete", tostring(player)))
				return 
			end
			
			-- Verify character is still valid
			if not player.Character or player.Character ~= char then
				warn(string.format("[GameManager] Character changed for %s before weapon sync could complete", player.Name))
				return
			end
			
			if self.playerManager then
				-- Send weapon loadout update
				local equippedWeapon = self.playerManager:getEquippedWeapon(player)
				if equippedWeapon then
					print(string.format("[GameManager] Syncing weapons for %s on respawn - equipped: %s", player.Name, equippedWeapon))
					self.playerManager:sendWeaponLoadout(player)
					
					-- Send ammo update for equipped weapon
					if self.fpsWeaponService then
						-- Ensure ammo is initialized for this weapon
						local ammo = self.fpsWeaponService:getAmmo(player, equippedWeapon)
						if not ammo then
							print(string.format("[GameManager] Initializing ammo for %s weapon %s on respawn", player.Name, equippedWeapon))
							self.fpsWeaponService:initializeWeaponAmmo(player, equippedWeapon)
						else
							-- Ammo already initialized; just send an update to sync client state
							self.fpsWeaponService:sendAmmoUpdate(player, equippedWeapon)
						end
					end
				else
					warn(string.format("[GameManager] No equipped weapon found for %s on respawn", player.Name))
				end
			end
		end)

		-- Store connection for cleanup
		local connection = humanoid.Died:Connect(function()
			if self._deathDebounce[player.UserId] then return end
			self._deathDebounce[player.UserId] = true
			self:onPlayerDied(player)
		end)
		
		-- Store connection for cleanup on player removal
		-- Initialize table on first use
		if not self._deathConnections[player.UserId] then
			self._deathConnections[player.UserId] = {}
		end
		table.insert(self._deathConnections[player.UserId], connection)
	end

	local characterAddedConnection = player.CharacterAdded:Connect(hookCharacter)

	-- Store CharacterAdded connection for cleanup to avoid leaks on respawn
	if not self._deathConnections[player.UserId] then
		self._deathConnections[player.UserId] = {}
	end
	table.insert(self._deathConnections[player.UserId], characterAddedConnection)
	if player.Character then
		hookCharacter(player.Character)
	end
end

function GameManager:onPlayerAdded(player)
	local success, message = self.playerManager:addPlayer(player)
	if not success then
		warn("Failed to add player:", message)
		return
	end

	print(string.format("[Flow] Join -> Player %s added to game", player.Name))

	-- ✅ Init FPS ammo tracking first (safe even if WeaponService also triggers ammo setup)
	if self.fpsWeaponService and self.fpsWeaponService.initializePlayer then
		self.fpsWeaponService:initializePlayer(player)
	end

	-- Initialize FPS animation replication
	if self.fpsAnimationService and self.fpsAnimationService.initializePlayer then
		self.fpsAnimationService:initializePlayer(player)
	end

	self.weaponService:initializePlayer(player)
	self.shopService:sendCatalog(player)

	self:initializePlayerStats(player)
	self:broadcastScoreboard()

	self:_hookPlayerDeath(player)

	-- Initialize player spawn manager
	self.playerSpawnManager:onPlayerAdded(player)

	-- Handle title screen and epilogue for new players
	-- Show title screen to ALL joiners (including late joiners) unless in epilogue
	if self.currentState == GameManager.States.EPILOGUE and GameConfig.SHOW_EPILOGUE then
		-- If currently in epilogue, mark player as having seen both title and epilogue
		self.playersReadyForEpilogue[player.UserId] = true
		self.playersCompletedEpilogue[player.UserId] = true
		if self.remoteEvents.ShowEpilogue then
			self.remoteEvents.ShowEpilogue:FireClient(player)
		end
		print(string.format("[Flow] Join -> Epilogue (late joiner during epilogue: %s)", player.Name))
	elseif GameConfig.SHOW_TITLE_SCREEN then
		-- Show title screen to all other joiners (initial + late joiners)
		-- This keeps late joiners out of active matches and in lobby until next round
		print(string.format("[Flow] Join -> TitleScreen (showing to %s)", player.Name))
		if self.remoteEvents.ShowTitleScreen then
			self.remoteEvents.ShowTitleScreen:FireClient(player)
		end
	else
		-- Title screen disabled: mark as ready immediately
		self.playersReadyForEpilogue[player.UserId] = true
		self.playersCompletedEpilogue[player.UserId] = true
		print(string.format("[Flow] Join -> Ready (title screen disabled for %s)", player.Name))
	end
end

function GameManager:onPlayerRemoving(player)
	self.playerManager:removePlayer(player)
	self.weaponService:removePlayer(player)

	if self.fpsWeaponService and self.fpsWeaponService.removePlayer then
		self.fpsWeaponService:removePlayer(player)
	end

	if self.fpsAnimationService and self.fpsAnimationService.removePlayer then
		self.fpsAnimationService:removePlayer(player)
	end

	self.lobbyManager:onPlayerLeave(player)
	self.spectatorManager:onPlayerLeave(player)
	self.playerSpawnManager:onPlayerRemoving(player)

	-- Portal matchmaking cleanup
	if self.portalMatchmakingService then
		self.portalMatchmakingService:onPlayerDisconnect(player)
	end

	-- Cleanup death connections to prevent memory leaks
	if self._deathConnections and self._deathConnections[player.UserId] then
		for _, connection in ipairs(self._deathConnections[player.UserId]) do
			connection:Disconnect()
		end
		self._deathConnections[player.UserId] = nil
	end

	self._deathDebounce[player.UserId] = nil
	self._spectatorCycleCooldown[player.UserId] = nil
	self.playersReadyForEpilogue[player.UserId] = nil
	self.playersCompletedEpilogue[player.UserId] = nil
end

function GameManager:setState(newState)
	self.currentState = newState
	self.stateTimer = 0

	if self.remoteEvents.GameStateUpdate then
		self.remoteEvents.GameStateUpdate:FireAllClients({
			state = newState,
			wave = self.currentWave,
			baseHealth = self.baseManager:getHealth(),
			cureProgress = self.cureProgress
		})
	end

	if newState == GameManager.States.TITLE_SCREEN then
		if self.remoteEvents.ShowTitleScreen then
			self.remoteEvents.ShowTitleScreen:FireAllClients()
		end
	elseif newState == GameManager.States.EPILOGUE then
		if self.remoteEvents.ShowEpilogue then
			for _, player in ipairs(Players:GetPlayers()) do
				if self.playersReadyForEpilogue[player.UserId] and not self.playersCompletedEpilogue[player.UserId] then
					self.remoteEvents.ShowEpilogue:FireClient(player)
				end
			end
		end
	end
end

function GameManager:setCureService(cureService)
	self.cureService = cureService
	if self.resourceSpawner and self.resourceSpawner.setCureService then
		self.resourceSpawner:setCureService(cureService)
	end
end

function GameManager:setAchievementService(achievementService)
	self.achievementService = achievementService
	print("[GameManager] AchievementService linked")
end

function GameManager:setFunFactService(funFactService)
	self.funFactService = funFactService
	print("[GameManager] FunFactService linked")
end

function GameManager:setCureSynthesisService(cureSynthesisService)
	self.cureSynthesisService = cureSynthesisService
	print("[GameManager] CureSynthesisService linked")
end

function GameManager:getWaveManager()
	-- GameManager currently encapsulates wave logic; expose self as the wave manager.
	return self
end

function GameManager:setIntensityMultiplier(multiplier)
	self.intensityMultiplier = multiplier or 1.0
	print("[GameManager] Wave intensity multiplier set to", self.intensityMultiplier)
end

function GameManager:getIntensityMultiplier()
	return self.intensityMultiplier or 1.0
end

function GameManager:showVictoryCredits(alivePlayers)
	local survivorData = {}
	for _, player in ipairs(alivePlayers) do
		local stats = self:getPlayerStats(player)
		table.insert(survivorData, {
			name = player.Name,
			stats = {
				kills = stats.kills,
				components = stats.componentsCollected
			}
		})
	end

	if self.remoteEvents.ShowCredits then
		self.remoteEvents.ShowCredits:FireAllClients(survivorData)
		print("[GameManager] Victory credits shown with", #survivorData, "survivors")
	end
end

function GameManager:startGame()
	if self.currentState ~= GameManager.States.WAITING and self.currentState ~= GameManager.States.LOBBY then
		return false
	end

	if not self.serverEnabled then
		print("Cannot start game - server is disabled")
		return false
	end

	print("Starting game...")
	self:setState(GameManager.States.COUNTDOWN)
	self.stateTimer = GameConfig.ROUND_COUNTDOWN_TIME or 5

	if GameConfig.ENABLE_MULTI_MAP then
		self:broadcastMap()
	end

	return true
end

function GameManager:startLobby()
	if self.currentState ~= GameManager.States.WAITING and self.currentState ~= GameManager.States.SCOREBOARD 
		and self.currentState ~= GameManager.States.TITLE_SCREEN then
		return false
	end

	if not self.serverEnabled then
		print("Cannot start lobby - server is disabled")
		return false
	end

	print("[Flow] Entering lobby (state -> LOBBY)")
	self:setState(GameManager.States.LOBBY)
	self.stateTimer = GameConfig.LOBBY_VOTING_TIME

	-- ✅ FIX: reset latch for this lobby instance
	self._lobbyResolved = false

	self:resetForNewRound()

	if self.lobbySetup then
		self.lobbySetup:getOrCreateLobby()
	end

	if not GameConfig.USE_PORTAL_MATCHMAKING then
		self.lobbyManager:startVoting()
	else
		print("[Flow] Lobby -> Portal matchmaking enabled (players can queue at portals)")
	end

	return true
end

-- Portal matchmaking: Start a match for a specific set of players on a specific map
-- Called by PortalMatchmakingService when a portal queue is ready
function GameManager:startMatch(players, mapId, matchId)
	if not players or #players == 0 then
		warn("[GameManager] startMatch: No players provided")
		return false
	end
	
	if not mapId then
		warn("[GameManager] startMatch: No mapId provided")
		return false
	end
	
	if not self.serverEnabled then
		print("[GameManager] startMatch: Cannot start match - server is disabled")
		return false
	end
	
	print(string.format("[Flow] Lobby -> MapLoading(%s) - Starting match for %d players (matchId: %s)", 
		mapId, #players, tostring(matchId)))
	
	-- Store matchId for cleanup
	self._currentMatchId = matchId
	
	-- Store match participants for round logic to avoid non-participants affecting victory/defeat
	self._matchParticipants = {}
	for _, player in ipairs(players) do
		if player and player.UserId then
			self._matchParticipants[player.UserId] = true
		end
	end
	
	-- Initialize match state BEFORE spawning players to avoid resetting their spawn
	self:resetForNewRound()
	
	-- Load the map
	if GameConfig.ENABLE_MULTI_MAP then
		-- Only clean up the lobby when portal matchmaking is not in use.
		-- With portal matchmaking enabled, the lobby portals are the primary join mechanism
		-- for late joiners/overflow players, so destroying them here would break queueing.
		if self.lobbySetup and not (GameConfig.USE_PORTAL_MATCHMAKING) then
			self.lobbySetup:cleanup()
		end
		
		print(string.format("[Flow] MapLoading(%s) -> Loading map...", mapId))
		local mapLoaded = self.mapManager:load(mapId)
		if not mapLoaded then
			warn(string.format("[GameManager] startMatch: Failed to load map %s", tostring(mapId)))
			return false
		end
		
		print(string.format("[Flow] MapLoaded -> Map %s loaded successfully", mapId))
		
		self:configureSpawnersForMap()
		self.playerSpawnManager:onMapLoaded()
		
		-- Spawn only the match players on the map
		print(string.format("[Flow] MapLoaded -> Spawn -> Spawning %d players on map", #players))
		for _, player in ipairs(players) do
			if player and player.Parent then
				self.playerSpawnManager:spawnPlayerOnMap(player)
			end
		end
		
		print(string.format("[Flow] Spawn -> Countdown -> Starting countdown for %d players", #players))
	end
	
	-- Start game countdown
	self:setState(GameManager.States.COUNTDOWN)
	self.stateTimer = GameConfig.ROUND_COUNTDOWN_TIME or 5
	
	if GameConfig.ENABLE_MULTI_MAP then
		self:broadcastMap()
	end
	
	print("[Flow] Match started successfully - countdown running")
	return true
end

function GameManager:resetForNewRound()
	self.currentWave = 0
	self.cureProgress = 0

	self._deathDebounce = {}

	if self.cureService and self.cureService.reset then
		self.cureService:reset()
	end

	self.baseManager:reset()

	self.spawner:prepareForNewRound()

	self.spectatorManager:reset()
	self.lobbyManager:reset()
	self.playerSpawnManager:resetForNewRound()

	if self.achievementService and self.achievementService.resetRoundStats then
		self.achievementService:resetRoundStats()
	end

	self._lastWaveBroadcastSec = nil

	for _, player in ipairs(Players:GetPlayers()) do
		local playerData = self.playerManager:getPlayerData(player)
		if playerData then
			playerData.health = GameConfig.STARTING_HEALTH
			playerData.isAlive = true
		end

		-- Keep player in lobby if playerSpawnManager is available
		if self.playerSpawnManager then
			self.playerSpawnManager:keepPlayerInLobby(player)
		end
	end
end

function GameManager:startWave()
	self.currentWave += 1

	local waveData = WaveConfig.getWave(self.currentWave)
	if not waveData then
		waveData = self:generateEndlessWave()
	end

	print(string.format("[Flow] Countdown -> Wave%d - Starting wave", self.currentWave))

	if self.funFactService then
		for _, player in ipairs(Players:GetPlayers()) do
			self.funFactService:updatePlayerStat(player, "waveReached", self.currentWave)
		end
	end

	if self.currentWave == 1 then
		self.spectatorManager:startRound()
		print("[GameManager] Spectator mode enabled for this round")
	end

	self:setState(GameManager.States.WAVE_ACTIVE)
	self.waveTimeLimit = waveData.TimeLimit
	self.waveTimeRemaining = waveData.TimeLimit

	if self.remoteEvents.WaveAnnounce then
		self.remoteEvents.WaveAnnounce:FireAllClients({
			waveNumber = self.currentWave,
			timeLimit = waveData.TimeLimit,
			zombieCount = waveData.ZombieCount
		})
	end

	if #self.spawner.allSpawnPoints == 0 then
		print("[GameManager] No spawn points available, generating...")
		self.spawner:generateSpawnPointsForRound()
	end

	self.spawner:setCurrentWave(self.currentWave)
	self.spawner:spawnWave(waveData.Composition)
end

function GameManager:generateEndlessWave()
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
	if self.spawner:getActiveZombieCount() <= 0 then
		print("Wave " .. self.currentWave .. " complete!")
		self:onWaveComplete()
		return true
	end
	return false
end

function GameManager:onWaveComplete()
	self:setState(GameManager.States.INTERMISSION)
	self.stateTimer = GameConfig.WAVE_DELAY

	for _, player in ipairs(Players:GetPlayers()) do
		self.playerManager:addCurrency(player, GameConfig.CURRENCY_PER_WAVE)
	end

	if self.funFactService then
		task.delay(2, function()
			self.funFactService:broadcastFactToAll()
		end)
	end
end

function GameManager:updateCureProgress(progress)
	self.cureProgress = math.min(100, progress)

	if self.remoteEvents.CureUpdate then
		self.remoteEvents.CureUpdate:FireAllClients(self.cureProgress)
	end

	if self.cureProgress >= 100 then
		self:onVictory()
	end
end

-- Helper method to clean up round resources (DRY principle)
function GameManager:_cleanupRoundResources()
	self.spawner:clearAllZombies()
	self.spawner:cleanupGeneratedSpawnPoints()
	self.spectatorManager:endRound()
	
	-- Clean up resources and items for next round
	if self.resourceSpawner and self.resourceSpawner.clearAllResources then
		self.resourceSpawner:clearAllResources()
	end
	if self.itemSpawner and self.itemSpawner.clearAllItems then
		self.itemSpawner:clearAllItems()
	end
	
	-- Clean up portal matches if using portal matchmaking
	if self.portalMatchmakingService and self._currentMatchId then
		self.portalMatchmakingService:endMatch(self._currentMatchId)
		self._currentMatchId = nil
	end
end

function GameManager:onVictory()
	print("VICTORY! Cure completed!")
	self:setState(GameManager.States.VICTORY)

	self:_cleanupRoundResources()

	local alivePlayers = {}
	for _, player in ipairs(Players:GetPlayers()) do
		-- Only count match participants for victory/loss stats
		if not self._matchParticipants or self._matchParticipants[player.UserId] then
			self:initializePlayerStats(player)
			if not self.spectatorManager:isPlayerDead(player) then
				self.playerStats[player.UserId].roundWins += 1
				table.insert(alivePlayers, player)
			else
				self.playerStats[player.UserId].roundLosses += 1
			end
		end
	end
	self:broadcastScoreboard()

	if self.achievementService then
		local baseHealthPercent = self.baseManager:getHealthPercentage()
		self.achievementService:onRoundEnd(true, alivePlayers, baseHealthPercent)
	end

	self:showVictoryCredits(alivePlayers)

	self:showEndOfRoundScoreboard()

	local creditsTime = 20 -- Safe default fallback
	local storyConfigModule = SharedFolder:FindFirstChild("StoryConfig")
	if storyConfigModule then
		local ok, storyConfig = pcall(require, storyConfigModule)
		if ok and type(storyConfig) == "table" then
			local creditsConfig = storyConfig.Credits
			local configuredDisplayTime = creditsConfig and creditsConfig.CreditsDisplayTime
			if typeof(configuredDisplayTime) == "number" and configuredDisplayTime > 0 then
				creditsTime = configuredDisplayTime
			else
				warn("[GameManager] StoryConfig.Credits.CreditsDisplayTime invalid, using default: " .. creditsTime)
			end
		else
			warn("[GameManager] Failed to load StoryConfig, using default credits time: " .. creditsTime)
		end
	else
		warn("[GameManager] StoryConfig module not found, using default credits time: " .. creditsTime)
	end
	
	-- Ensure timer is valid (never NaN)
	local scoreboardTime = GameConfig.SCOREBOARD_DISPLAY_TIME or 10
	self.stateTimer = scoreboardTime + creditsTime
end

function GameManager:onDefeat(reason)
	print("DEFEAT! " .. reason)
	self:setState(GameManager.States.DEFEAT)

	self:_cleanupRoundResources()

	-- Only count match participants for loss stats
	for _, player in ipairs(Players:GetPlayers()) do
		if not self._matchParticipants or self._matchParticipants[player.UserId] then
			self:initializePlayerStats(player)
			self.playerStats[player.UserId].roundLosses += 1
		end
	end
	self:broadcastScoreboard()

	if self.achievementService then
		local baseHealthPercent = self.baseManager:getHealthPercentage()
		self.achievementService:onRoundEnd(false, {}, baseHealthPercent)
	end

	self:showEndOfRoundScoreboard()
	self.stateTimer = GameConfig.SCOREBOARD_DISPLAY_TIME
end

function GameManager:showEndOfRoundScoreboard()
	if self.remoteEvents.ShowScoreboard then
		self.remoteEvents.ShowScoreboard:FireAllClients({
			duration = GameConfig.SCOREBOARD_DISPLAY_TIME,
			scores = self:getScoreboardData()
		})
	end
end

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

	table.sort(scoreboardData, function(a, b)
		return a.kills > b.kills
	end)

	return scoreboardData
end

function GameManager:checkLoseConditions()
	if self.baseManager:isBaseDestroyed() then
		self:onDefeat("Base destroyed")
		return true
	end

	local players = Players:GetPlayers()
	local anyAlive = false
	local participantCount = 0

	for _, player in ipairs(players) do
		-- Only check match participants for defeat condition
		if not self._matchParticipants or self._matchParticipants[player.UserId] then
			participantCount = participantCount + 1
			if not self.spectatorManager:isPlayerDead(player) then
				anyAlive = true
				break
			end
		end
	end

	-- Only trigger defeat if there were participants and all are dead
	if participantCount > 0 and not anyAlive then
		self:onDefeat("All players eliminated")
		return true
	end

	return false
end

function GameManager:onPlayerDied(player)
	if not player then return end

	if self.currentState ~= GameManager.States.WAVE_ACTIVE and self.currentState ~= GameManager.States.INTERMISSION then
		return
	end

	local pd = self.playerManager:getPlayerData(player)
	if pd then
		pd.isAlive = false
	end

	self:incrementPlayerDeaths(player)

	if self.funFactService then
		self.funFactService:incrementPlayerStat(player, "deaths")
	end

	self.spectatorManager:onPlayerDied(player)
	self.spectatorManager:onSpectatorTargetDied(player.UserId)
	self.spectatorManager:broadcastAliveList()

	self:checkLoseConditions()
end

function GameManager:updateCountdown(deltaTime)
	self.stateTimer -= deltaTime
	if self.stateTimer <= 0 then
		self:startWave()
	end
end

function GameManager:updateWave(deltaTime)
	self.waveTimeRemaining -= deltaTime

	self.spawner:update(deltaTime)
	self.resourceSpawner:update(deltaTime)
	self.itemSpawner:update(deltaTime)

	local sec = math.floor(self.waveTimeRemaining)
	if sec >= 0 and (sec % 5 == 0) and (self._lastWaveBroadcastSec ~= sec) then
		self._lastWaveBroadcastSec = sec
		if self.remoteEvents.WaveUpdate then
			self.remoteEvents.WaveUpdate:FireAllClients({
				timeRemaining = sec,
				zombiesAlive = self.spawner:getActiveZombieCount()
			})
		end
	end

	self:checkWaveComplete()

	if self.waveTimeRemaining <= 0 then
		print("Wave time limit reached!")
		self:onWaveComplete()
	end

	self:checkLoseConditions()
end

function GameManager:updateIntermission(deltaTime)
	self.stateTimer -= deltaTime
	self.resourceSpawner:update(deltaTime)
	self.itemSpawner:update(deltaTime)

	if self.stateTimer <= 0 then
		self:startWave()
	end
end

function GameManager:updateLobby(deltaTime)
	self.lobbyManager:update(deltaTime)

	local selectedMapId = self.lobbyManager:getSelectedMapId()

	-- ✅ FIX: one-shot latch to stop double load/spawn with time-based debounce
	if self._lobbyResolved then
		return
	end
	
	-- Time-based debounce to prevent race conditions
	local now = tick()
	local debounceTime = GameConfig.Security and GameConfig.Security.LOBBY_DEBOUNCE_TIME or 1.0
	if self._lastLobbyResolveAttempt and (now - self._lastLobbyResolveAttempt) < debounceTime then
		-- Too soon since last attempt, skip to prevent race
		return
	end
	
	self._lastLobbyResolveAttempt = now

	if not self.lobbyManager:isVotingActive() and selectedMapId then
		-- Mark as resolved immediately to prevent double loading
		self._lobbyResolved = true

		print(string.format("[Flow] Lobby -> MapLoading(%s) - Voting complete, loading map", selectedMapId))

		if GameConfig.ENABLE_MULTI_MAP then
			if self.lobbySetup then
				self.lobbySetup:cleanup()
			end

			-- Trigger map load; MapManager:load() now returns true on success, false on failure
			local mapLoaded = self.mapManager:load(selectedMapId)
			
			-- Validate that map loaded successfully
			if not mapLoaded then
				warn("[GameManager] Failed to load map: " .. tostring(selectedMapId))
				-- Reset flag to allow retry on next updateLobby cycle
				self._lobbyResolved = false
				return
			end
			
			print(string.format("[Flow] MapLoaded -> Map %s loaded successfully", selectedMapId))
			
			self:configureSpawnersForMap()

			-- Notify PlayerSpawnManager that map has loaded
			self.playerSpawnManager:onMapLoaded()

			print("[Flow] MapLoaded -> Spawn -> Spawning all players on map")
			self.playerSpawnManager:spawnAllPlayersOnMap()
		end

		self:startGame()
	end
end

function GameManager:updateEndOfRound(deltaTime)
	self.stateTimer -= deltaTime

	if self.stateTimer <= 0 then
		self:setState(GameManager.States.SCOREBOARD)
		self.stateTimer = 2

		if self.remoteEvents.HideScoreboard then
			self.remoteEvents.HideScoreboard:FireAllClients({})
		end
	end
end

function GameManager:updateTitleScreen(deltaTime)
	if GameConfig.TITLE_SCREEN_TIMEOUT then
		self.stateTimer += deltaTime

		if self.stateTimer >= GameConfig.TITLE_SCREEN_TIMEOUT then
			-- Consistent with checkAllPlayersReadyForEpilogue: require both flags for first-join epilogue
			if GameConfig.SHOW_EPILOGUE and GameConfig.INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN then
				print("[Flow] TitleScreen timeout -> Epilogue (SHOW_EPILOGUE=true, INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN=true)")
				self:setState(GameManager.States.EPILOGUE)
			else
				-- Go directly to lobby (or waiting if not enough players)
				local playerCount = #Players:GetPlayers()
				if playerCount >= (GameConfig.LOBBY_MIN_PLAYERS or 1) then
					print("[Flow] TitleScreen timeout -> Lobby")
					self:startLobby()
				else
					print("[Flow] TitleScreen timeout -> Waiting (not enough players)")
					self:setState(GameManager.States.WAITING)
				end
			end
		end
	end
end

function GameManager:updateEpilogue(deltaTime)
	-- no-op (handled by client events + checkAllPlayersCompletedEpilogue)
end

function GameManager:updateScoreboard(deltaTime)
	self.stateTimer -= deltaTime

	if self.stateTimer <= 0 then
		-- ✅ FIX: After round ends (SCOREBOARD), show EPILOGUE if enabled, then go to LOBBY
		-- This is the correct flow: ROUND_END -> SCOREBOARD -> EPILOGUE -> LOBBY
		if GameConfig.SHOW_EPILOGUE then
			print("[GameManager] Transitioning from SCOREBOARD to EPILOGUE")
			self:setState(GameManager.States.EPILOGUE)
			-- Reset epilogue completion tracking for all players
			self.playersCompletedEpilogue = {}
			-- Show epilogue to all players
			if self.remoteEvents.ShowEpilogue then
				self.remoteEvents.ShowEpilogue:FireAllClients()
			end
		else
			-- No epilogue, go straight to lobby
			local playerCount = #Players:GetPlayers()
			if playerCount >= (GameConfig.LOBBY_MIN_PLAYERS or 1) then
				self:startLobby()
			else
				self:setState(GameManager.States.WAITING)
			end
		end
	end
end

function GameManager:update(deltaTime)
	if self.currentState == GameManager.States.TITLE_SCREEN then
		self:updateTitleScreen(deltaTime)

	elseif self.currentState == GameManager.States.EPILOGUE then
		self:updateEpilogue(deltaTime)

	elseif self.currentState == GameManager.States.LOBBY then
		self:updateLobby(deltaTime)

	elseif self.currentState == GameManager.States.COUNTDOWN then
		self:updateCountdown(deltaTime)

	elseif self.currentState == GameManager.States.WAVE_ACTIVE then
		self:updateWave(deltaTime)

	elseif self.currentState == GameManager.States.INTERMISSION then
		self:updateIntermission(deltaTime)

	elseif self.currentState == GameManager.States.WAITING then
		local playerCount = #Players:GetPlayers()
		-- Only auto-start lobby if not using portal matchmaking
		if not GameConfig.USE_PORTAL_MATCHMAKING and playerCount >= (GameConfig.LOBBY_MIN_PLAYERS or 1) then
			self:startLobby()
		end
		self.resourceSpawner:update(deltaTime)
		self.itemSpawner:update(deltaTime)

	elseif self.currentState == GameManager.States.VICTORY or self.currentState == GameManager.States.DEFEAT then
		self:updateEndOfRound(deltaTime)

	elseif self.currentState == GameManager.States.SCOREBOARD then
		self:updateScoreboard(deltaTime)

	else
		self.resourceSpawner:update(deltaTime)
	end
	
	-- Update portal matchmaking service (if enabled)
	if self.portalMatchmakingService then
		self.portalMatchmakingService:update(deltaTime)
	end
end

function GameManager:getPlayerManager()
	return self.playerManager
end

function GameManager:getWeaponService()
	return self.weaponService
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
