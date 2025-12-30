-- MainServer.lua
-- Main server initialization script
-- Place this as a Script (not ModuleScript) in ServerScriptService
-- Server can be disabled by calling gameManager:disableServer() or setting ServerEnabled attribute to false

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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

-- Setup cure stations
local cureStationSetup = require(game.ReplicatedStorage.Shared.CureStationSetup)
if not cureStationSetup then
	warn("Cure station setup failed")
end
print("Cure stations setup complete")

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
	fpsWeaponService:initializePlayer(player)
	achievementService:initializePlayer(player)

	-- Character lifecycle
	player.CharacterAdded:Connect(function(character)
		print(player.Name .. "'s character loaded")

		-- Initialize sprint service for new character
		sprintService:onCharacterAdded(player, character)

		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				print(player.Name .. " died")
				-- Cancel any ongoing reload
				fpsWeaponService:cancelReload(player)
				-- Handle player death - puts them in spectator mode and checks lose conditions
				gameManager:onPlayerDied(player)
			end)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " left the game")

	-- Clean up player from services
	gameManager:onPlayerRemoving(player)
	allianceService:removePlayer(player)
	sprintService:removePlayer(player)
	fpsWeaponService:removePlayer(player)
	achievementService:removePlayer(player)
end)

----------------------------------------------------------------
-- Main game loop
----------------------------------------------------------------

local lastUpdate = tick()

RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	local deltaTime = currentTime - lastUpdate
	lastUpdate = currentTime

	-- GameManager handles waves, timers, and GameServer.update()
	gameManager:update(deltaTime)
end)

----------------------------------------------------------------
-- Auto-start logic
----------------------------------------------------------------

task.spawn(function()
	print("Waiting for players...")

	-- Simple "auto start when someone joins" behaviour
	repeat
		task.wait(1)
	until #Players:GetPlayers() >= 1

	print("Starting lobby with " .. #Players:GetPlayers() .. " players")

	-- GameManager's internal update loop should transition from WAITING to LOBBY
	-- when conditions are met (player count, etc.)
end)

print("=== Server Ready ===")
