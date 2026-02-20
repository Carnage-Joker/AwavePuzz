-- @ScriptType: Script
-- MainServerScript.lua
-- SINGLE SERVER ENTRY POINT for Aether Wave: Convergence
-- Boots all server systems in deterministic order
-- Deterministic boot order with duplicate execution guard

-- Guard against duplicate execution
if script:GetAttribute("Initialized") then
	warn("[MainServerScript] Already initialized, skipping duplicate execution")
	return
end
script:SetAttribute("Initialized", true)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== [BOOT][SERVER] Aether Wave: Convergence Server Starting ===")

----------------------------------------------------------------
-- PHASE 0: CHARACTER AUTO-LOAD CONTROL
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 0: Disabling character auto-load...")

-- CRITICAL: Disable auto character spawning
-- Characters will only spawn after:
-- 1. Server is fully ready
-- 2. Player completes title screen
-- 3. Server explicitly calls player:LoadCharacter()
Players.CharacterAutoLoads = false

print("[BOOT][SERVER] Phase 0 complete: CharacterAutoLoads = false")

----------------------------------------------------------------
-- PHASE 1: Initialize Remote Registry
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 1: Initializing remote registry...")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[MainServerScript] CRITICAL: Failed to load Shared folder after 10 seconds")
end

-- RemoteRegistry moved from Remotes/ to Shared/ (ModuleScripts belong in Shared, not in Remotes/)
local RemotesFolder = SharedFolder:WaitForChild("Remotes", 5)
if not RemotesFolder then
	error("[MainServerScript] CRITICAL: Shared.Remotes folder missing after 5 seconds")
end

local RemoteRegistryModule = SharedFolder:WaitForChild("RemoteRegistry", 5)

if not RemoteRegistryModule then
	error("[MainServerScript] CRITICAL: Shared.RemoteRegistry ModuleScript missing")
end

if not RemoteRegistryModule:IsA("ModuleScript") then
	error("[MainServerScript] CRITICAL: Shared.RemoteRegistry is not a ModuleScript")
end

local RemoteRegistry = require(RemoteRegistryModule)
local remotes = RemoteRegistry.initializeServer()
print("[BOOT][SERVER] Phase 1 complete: Remote registry initialized")

----------------------------------------------------------------
-- PHASE 2: Load Configuration
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 2: Loading shared configuration...")
local GameConfigModule = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfigModule then
	error("[MainServerScript] CRITICAL: Failed to load GameConfig module after 5 seconds")
end
local GameConfig = require(GameConfigModule)

-- Validate animation and sound asset IDs at boot time
local AssetConfig = require(SharedFolder:WaitForChild("AssetConfig", 5))
local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation", 5))
local invalidAssetCount = AssetValidation.runBootTimeValidation(AssetConfig)
if invalidAssetCount > 0 then
	warn(string.format(
		"[BOOT][SERVER] ⚠️ Boot-time validation found %d invalid asset(s). Game will continue but assets may not load correctly.",
		invalidAssetCount
		))
else
	print("[BOOT][SERVER] ✅ All assets validated successfully")
end
print("[BOOT][SERVER] Phase 2 complete: Configuration loaded")

----------------------------------------------------------------
-- PHASE 3: Initialize Services
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 3: Initializing services...")

-- Load service modules
local GameManager = require(script.Parent.GameManager)
local AllianceService = require(script.Parent.AllianceServiceV2)
local CureService = require(script.Parent.CureService)
local PuzzleService = require(script.Parent.PuzzleService)
local SprintService = require(script.Parent.SprintService)
local AchievementService = require(script.Parent.AchievementService)
local FunFactService = require(script.Parent.FunFactService)
local CureSynthesisService = require(script.Parent.CureSynthesisService)
local VoiceoverService = require(script.Parent.VoiceoverService)

-- Initialize services
local allianceService = AllianceService.new()
print("[BOOT][SERVER] AllianceService initialized")

local gameManager = GameManager.new(allianceService)
print("[BOOT][SERVER] GameManager initialized")

-- Optional non-breaking wiring for resource spawner
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

-- Get shared managers
local playerManager = gameManager:getPlayerManager()
local weaponService = gameManager:getWeaponService()
local fpsWeaponService = gameManager.fpsWeaponService

-- Link FPSWeaponService to WeaponService if needed
if not weaponService.fpsWeaponService then
	weaponService:setFPSWeaponService(fpsWeaponService)
	print("[BOOT][SERVER] FPSWeaponService linked to WeaponService")
end

-- Initialize remaining services
local sprintService = SprintService.new(playerManager)
print("[BOOT][SERVER] SprintService initialized")

local cureService = CureService.new(gameManager, playerManager)
print("[BOOT][SERVER] CureService initialized")

local puzzleService = PuzzleService.new(cureService, playerManager)
print("[BOOT][SERVER] PuzzleService initialized")

local achievementService = AchievementService.new(playerManager, gameManager)
print("[BOOT][SERVER] AchievementService initialized")

local funFactService = FunFactService.new()
print("[BOOT][SERVER] FunFactService initialized")

local cureSynthesisService = CureSynthesisService.new(cureService, gameManager:getWaveManager(), gameManager)
cureSynthesisService:setPuzzleService(puzzleService)
print("[BOOT][SERVER] CureSynthesisService initialized")

local voiceoverService = VoiceoverService.new()
print("[BOOT][SERVER] VoiceoverService initialized")

-- Link services together
cureService:setPuzzleService(puzzleService)
cureService:setAllianceService(allianceService)
allianceService:setPuzzleService(puzzleService)
allianceService:setCureService(cureService)
allianceService:setPlayerManager(playerManager)
allianceService:setGameManager(gameManager)
gameManager:setCureService(cureService)
gameManager:setAchievementService(achievementService)
gameManager:setFunFactService(funFactService)
gameManager:setCureSynthesisService(cureSynthesisService)
gameManager:setVoiceoverService(voiceoverService)
print("[BOOT][SERVER] Services linked")

print("[BOOT][SERVER] Phase 3 complete: All services initialized")

----------------------------------------------------------------
-- PHASE 4: Player Connection Handlers
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 4: Setting up player connection handlers...")

Players.PlayerAdded:Connect(function(player)
	print(string.format("[STATE] Player %s joined the game", player.Name))

	-- Initialize player across systems
	gameManager:onPlayerAdded(player)
	allianceService:initializePlayer(player)
	cureService:initializePlayer(player)
	puzzleService:initializePlayer(player)
	sprintService:initializePlayer(player)
	achievementService:initializePlayer(player)

	-- Character lifecycle
	player.CharacterAdded:Connect(function(character)
		print(string.format("[STATE] Player %s's character loaded", player.Name))

		-- Initialize sprint service for new character
		sprintService:onCharacterAdded(player, character)

		-- BUG-005 FIX: Clear kill tracking attributes on respawn
		-- This ensures kill rewards are granted on each death, not just the first
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid:SetAttribute("WeaponServiceDiedConnected", nil)
			humanoid:SetAttribute("LastAttackerUserId", nil)
			humanoid:SetAttribute("LastVictimUserId", nil)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print(string.format("[STATE] Player %s left the game", player.Name))

	-- Clean up player from services
	gameManager:onPlayerRemoving(player)
	allianceService:removePlayer(player)
	sprintService:removePlayer(player)

	if fpsWeaponService then
		fpsWeaponService:removePlayer(player)
	end

	achievementService:removePlayer(player)
end)

print("[BOOT][SERVER] Phase 4 complete: Player handlers connected")

----------------------------------------------------------------
-- PHASE 5: Main Game Loop
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 5: Starting main game loop...")

-- Disconnect old heartbeat connection if it exists (prevents memory leak on server reload)
-- Store in shared table to persist across script reloads
if not shared.AwavePuzzHeartbeat then
	shared.AwavePuzzHeartbeat = {}
end

if shared.AwavePuzzHeartbeat.connection then
	shared.AwavePuzzHeartbeat.connection:Disconnect()
	shared.AwavePuzzHeartbeat.connection = nil
	print("[BOOT][SERVER] Disconnected old heartbeat connection from previous reload")
end

-- Create and store heartbeat connection for game loop
-- Use Heartbeat's built-in deltaTime parameter instead of manual calculation
local heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
	-- GameManager handles waves, timers, and update logic
	gameManager:update(deltaTime)
end)

-- Store connection in both shared (for reload persistence) and gameManager (for runtime access)
shared.AwavePuzzHeartbeat.connection = heartbeatConnection
gameManager._heartbeatConnection = heartbeatConnection

print("[BOOT][SERVER] Phase 5 complete: Game loop running")

----------------------------------------------------------------
-- PHASE 6: Auto-Start Logic
----------------------------------------------------------------

print("[BOOT][SERVER] Phase 6: Setting up auto-start logic...")

task.spawn(function()
	print("[STATE] Waiting for minimum players to start...")

	-- Get minimum player count from config (default: 1)
	local minPlayers = 1
	if GameConfig and GameConfig.MIN_PLAYERS_TO_START then
		minPlayers = GameConfig.MIN_PLAYERS_TO_START
	end

	repeat
		task.wait(1)
	until #Players:GetPlayers() >= minPlayers

	print(string.format("[STATE] Minimum players reached (%d). Lobby ready.", #Players:GetPlayers()))
end)

print("[BOOT][SERVER] Phase 6 complete: Auto-start configured")

----------------------------------------------------------------
-- Server Ready
----------------------------------------------------------------

print("=== [BOOT][SERVER] Server Ready ===")
print(string.format("[BOOT][SERVER] Game version: %s", RemoteRegistry.VERSION))
print(string.format("[BOOT][SERVER] Multi-map enabled: %s", tostring(GameConfig.ENABLE_MULTI_MAP)))
print(string.format("[BOOT][SERVER] Portal matchmaking enabled: %s", tostring(GameConfig.USE_PORTAL_MATCHMAKING)))
print("=== [BOOT][SERVER] Aether Wave: Convergence is now running ===")
