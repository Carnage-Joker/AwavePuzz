-- @ScriptType: Script
-- MainServer.lua
-- Main server initialization script
-- Place this as a Script (not ModuleScript) in ServerScriptService
-- Server can be disabled by calling gameManager:disableServer() or setting ServerEnabled attribute to false

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require shared configuration with timeout
print("[MainServer] Loading shared configuration...")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[MainServer] CRITICAL: Failed to load Shared folder after 10 seconds. Check ReplicatedStorage structure.")
end

local GameConfigModule = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfigModule then
	error("[MainServer] CRITICAL: Failed to load GameConfig module after 5 seconds. Check Shared folder structure.")
end
local GameConfig = require(GameConfigModule)
print("[MainServer] Configuration loaded successfully")

-- Require managers / services
local GameManager = require(script.Parent.GameManager)
local AllianceService = require(script.Parent.AllianceServiceV2) -- Using V2 with networked alliance pools
local CureService = require(script.Parent.CureService)
local PuzzleService = require(script.Parent.PuzzleService)
local SprintService = require(script.Parent.SprintService)
local AchievementService = require(script.Parent.AchievementService)
local FunFactService = require(script.Parent.FunFactService)
local CureSynthesisService = require(script.Parent.CureSynthesisService)

print("=== Aether Wave: Convergence Server Starting ===")

----------------------------------------------------------------
-- Service initialisation
----------------------------------------------------------------

-- Alliance service (used by GameManager and others)
local allianceService = AllianceService.new()
print("AllianceService initialized")

-- GameManager wires up GameServer, Spawner, WeaponService, PlayerManager, BaseManager, etc.
local gameManager = GameManager.new(allianceService)
print("GameManager initialized")

-- Optional non-breaking wiring:
-- If GameManager exposes getSpawner/getResourceSpawner, link them so resources can use zombie spawns.
do
	local ok1, spawner = pcall(function()
		return gameManager.getSpawner and gameManager:getSpawner() or nil
	end)
	local ok2, resourceSpawner = pcall(function()
		return gameManager.getResourceSpawner and gameManager:getResourceSpawner() or nil
	end)

	if ok1 and ok2 and spawner and resourceSpawner and spawner.setResourceSpawner then
		spawner:setResourceSpawner(resourceSpawner)
	end
end

-- Get shared PlayerManager and WeaponService from GameManager
local playerManager = gameManager:getPlayerManager()
local weaponService = gameManager:getWeaponService()

-- Get FPS Weapon Service from GameManager (already created there)
local fpsWeaponService = gameManager.fpsWeaponService
print("FPSWeaponService retrieved from GameManager")

-- Link FPSWeaponService to WeaponService for ammo validation (should already be linked)
if not weaponService.fpsWeaponService then
	weaponService:setFPSWeaponService(fpsWeaponService)
	print("FPSWeaponService linked to WeaponService")
else
	print("FPSWeaponService already linked to WeaponService")
end

-- Sprint service (server-authoritative stamina management)
local sprintService = SprintService.new(playerManager)
print("SprintService initialized")

-- Cure service (needs reference to game manager & player manager)
local cureService = CureService.new(gameManager, playerManager)
print("CureService initialized")

-- Puzzle service (needs cure service and player manager)
local puzzleService = PuzzleService.new(cureService, playerManager)
print("PuzzleService initialized")

-- Link services together
cureService:setPuzzleService(puzzleService)
cureService:setAllianceService(allianceService)
allianceService:setPuzzleService(puzzleService)
allianceService:setCureService(cureService)
allianceService:setPlayerManager(playerManager)
gameManager:setCureService(cureService)
print("Services linked")

-- Achievement service (needs PlayerManager and GameManager)
local achievementService = AchievementService.new(playerManager, gameManager)
gameManager:setAchievementService(achievementService)
print("AchievementService initialized and linked")

-- Fun Fact service (for downtime and loading screen facts)
local funFactService = FunFactService.new()
gameManager:setFunFactService(funFactService)
allianceService:setGameManager(gameManager)
print("FunFactService initialized and linked")

-- Cure Synthesis service (high-pressure endgame system)
local cureSynthesisService = CureSynthesisService.new(cureService, gameManager:getWaveManager(), gameManager)
cureSynthesisService:setPuzzleService(puzzleService)
gameManager:setCureSynthesisService(cureSynthesisService)
print("CureSynthesisService initialized and linked")

-- Note: Cure station setup is owned by ServerScriptService/CureStationSetup.lua
-- which runs automatically on server startup as the single source of truth.
-- Any older duplicates (e.g. ReplicatedStorage/Shared/CureStationSetup.lua) are legacy-only
-- and MUST NOT be used or required; remove them when cleaning up redundant modules.

----------------------------------------------------------------
-- Player connection handlers
----------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	print(player.Name .. " joined the game")

	-- Initialise player across systems
	gameManager:onPlayerAdded(player)
	allianceService:initializePlayer(player)
	cureService:initializePlayer(player)
	puzzleService:initializePlayer(player)
	sprintService:initializePlayer(player)
	-- ✅ REMOVED: fpsWeaponService:initializePlayer(player)
	-- This is already called in GameManager:onPlayerAdded to prevent duplicate ammo initialization
	achievementService:initializePlayer(player)

	-- Character lifecycle
	player.CharacterAdded:Connect(function(character)
		print(player.Name .. "'s character loaded")

		-- Initialize sprint service for new character
		sprintService:onCharacterAdded(player, character)

		-- ✅ REMOVED: Do NOT initialize FPSWeaponService here.
		-- GameManager already calls fpsWeaponService:initializePlayer(player) in onPlayerAdded.
		-- Duplicate calls can reset ammo incorrectly.

		-- ✅ IMPORTANT:
		-- Do NOT hook Humanoid.Died here.
		-- GameManager already hooks deaths (with debounce) in _hookPlayerDeath().
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " left the game")

	-- Clean up player from services with nil guards
	gameManager:onPlayerRemoving(player)
	allianceService:removePlayer(player)
	sprintService:removePlayer(player)
	
	if fpsWeaponService then
		fpsWeaponService:removePlayer(player)
	else
		warn("[MainServer] fpsWeaponService not initialized, skipping cleanup for " .. player.Name)
	end
	
	achievementService:removePlayer(player)
end)

----------------------------------------------------------------
-- Main game loop
----------------------------------------------------------------

local lastUpdate = tick()
local heartbeatConnection -- Store connection for potential cleanup

heartbeatConnection = RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	local deltaTime = currentTime - lastUpdate
	lastUpdate = currentTime

	-- GameManager handles waves, timers, and GameServer.update()
	gameManager:update(deltaTime)
end)

-- Store connection in gameManager for cleanup if needed
gameManager._heartbeatConnection = heartbeatConnection

----------------------------------------------------------------
-- Auto-start logic
----------------------------------------------------------------

task.spawn(function()
	print("Waiting for players...")

	-- Simple "auto start when someone joins" behaviour
	-- Minimum player count from GameConfig (recommended: 2 for alliance mechanics)
	-- Safe fallback to 1 if GameConfig or field is missing
	local minPlayers = 1
	if GameConfig and GameConfig.MIN_PLAYERS_TO_START then
		minPlayers = GameConfig.MIN_PLAYERS_TO_START
	else
		warn("[MainServer] GameConfig.MIN_PLAYERS_TO_START not found, using default: " .. minPlayers)
	end
	
	repeat
		task.wait(1)
	until #Players:GetPlayers() >= minPlayers

	print("Starting lobby with " .. #Players:GetPlayers() .. " players")

	-- GameManager's internal update loop should transition from WAITING to LOBBY
	-- when conditions are met (player count, etc.)
end)

print("=== Server Ready ===")
