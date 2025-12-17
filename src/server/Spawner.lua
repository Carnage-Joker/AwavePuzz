-- Spawner.lua
-- Server script that spawns zombies based on wave configuration
-- Features tactical AI, dynamic pressure, and intelligent composition

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ZombieTypes = require(ReplicatedStorage.Shared.ZombieTypes)
local ZombieBrain = require(script.Parent.AI.ZombieBrain)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local IntelligentSpawnGenerator = require(script.Parent.IntelligentSpawnGenerator)

-- AI Services
local TargetingService = require(script.Parent.AI.TargetingService)
local SurroundService = require(script.Parent.AI.SurroundService)
local AIDirector = require(script.Parent.AI.AIDirector)
local BossAuraService = require(script.Parent.AI.BossAuraService)

local DEFAULT_SPAWN_INTERVAL = 0.5

local Spawner = {}
Spawner.__index = Spawner

function Spawner.new(weaponService, baseManager, playerManager)
	local self = setmetatable({}, Spawner)

	self.weaponService = weaponService
	self.baseManager = baseManager
	self.playerManager = playerManager
	self.spawnPoints = {}
	self.activeZombies = {}
	self.zombieBrains = {}
	self.zombieCount = 0

	self.spawnQueue = {}
	self.spawnTimer = 0
	self.spawnInterval = GameConfig.Spawning and GameConfig.Spawning.SPAWN_INTERVAL or DEFAULT_SPAWN_INTERVAL
	self.lastUsedSpawnIndex = 0

	self.spawnGenerator = IntelligentSpawnGenerator.new()
	self.allSpawnPoints = {}

	-- Optional integration
	self.resourceSpawner = nil
	
	-- AI Services
	self.targetingService = TargetingService.new(baseManager)
	self.surroundService = SurroundService.new()
	self.aiDirector = AIDirector.new(baseManager, playerManager)
	self.bossAuraService = BossAuraService.new()
	
	-- Current wave tracking
	self.currentWave = 0

	if not workspace:FindFirstChild("Zombies") then
		local zombiesFolder = Instance.new("Folder")
		zombiesFolder.Name = "Zombies"
		zombiesFolder.Parent = workspace
	end
	
	-- Enable debug mode if configured
	if GameConfig.AI.DEBUG_MODE then
		self.bossAuraService:setDebugMode(true)
	end

	return self
end

-- NEW (non-breaking)
function Spawner:setResourceSpawner(resourceSpawner)
	self.resourceSpawner = resourceSpawner
end

function Spawner:setSpawnPoints(points)
	if typeof(points) ~= "table" then
		return
	end
	self.spawnPoints = points
end

function Spawner:addSpawnPoint(position)
	table.insert(self.spawnPoints, position)
end

function Spawner:loadSpawnPoints()
	local spawnPointsFolder = workspace:FindFirstChild("ZombieSpawnPoints")
	if spawnPointsFolder then
		self.spawnPoints = {}
		for _, point in ipairs(spawnPointsFolder:GetChildren()) do
			if point:IsA("BasePart") or point:IsA("Model") then
				local position = point:IsA("Model") and point:GetPivot().Position or point.Position
				self:addSpawnPoint(position)
			end
		end
	end
	print("Loaded " .. #self.spawnPoints .. " manual zombie spawn points")
end

function Spawner:generateSpawnPointsForRound()
	print("[Spawner] Generating intelligent spawn points for new round...")

	self:loadSpawnPoints()

	self.allSpawnPoints = self.spawnGenerator:generateSpawnPointsForRound()

	-- Optional: inform ResourceSpawner about zombie spawns (manual + generated)
	if self.resourceSpawner and self.resourceSpawner.setZombieSpawnPoints then
		self.resourceSpawner:setZombieSpawnPoints(self.allSpawnPoints)
	end

	print("[Spawner] Total spawn points available:", #self.allSpawnPoints)
end

function Spawner:cleanupGeneratedSpawnPoints()
	if self.spawnGenerator then
		self.spawnGenerator:cleanupGeneratedSpawnPoints()
	end
	self.allSpawnPoints = {}
	print("[Spawner] Cleaned up generated spawn points")
end

function Spawner:getNextSpawnPoint()
	if #self.spawnPoints == 0 then
		warn("No spawn points available! Using default position.")
		return Vector3.new(0, 10, 0)
	end

	self.lastUsedSpawnIndex = self.lastUsedSpawnIndex + 1
	if self.lastUsedSpawnIndex > #self.spawnPoints then
		self.lastUsedSpawnIndex = 1
	end

	return self.spawnPoints[self.lastUsedSpawnIndex]
end

function Spawner:getRandomSpawnPoint()
	if #self.spawnPoints == 0 then
		warn("No spawn points available! Using default position.")
		return Vector3.new(0, 10, 0)
	end
	return self.spawnPoints[math.random(1, #self.spawnPoints)]
end

function Spawner:getStrategicSpawnPoint(zombieType)
	if #self.allSpawnPoints == 0 then
		warn("[Spawner] No spawn points available! Using default position.")
		return Vector3.new(0, 10, 0)
	end

	local playerPositions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(playerPositions, player.Character.HumanoidRootPart.Position)
		end
	end

	return self.spawnGenerator:getStrategicSpawnPoint(zombieType, self.allSpawnPoints, playerPositions)
end

function Spawner:getZombieModel(zombieType)
	local zombieModels = ServerStorage:FindFirstChild("ZombieModels")
	if not zombieModels then
		warn("ZombieModels folder not found in ServerStorage!")
		return nil
	end

	local modelTemplate = zombieModels:FindFirstChild(zombieType)
	if not modelTemplate then
		warn("Zombie model '" .. zombieType .. "' not found in ServerStorage.ZombieModels!")
		return nil
	end

	return modelTemplate:Clone()
end

function Spawner:spawnZombie(zombieType)
	local stats = ZombieTypes[zombieType]
	if not stats then
		warn("Unknown zombie type: " .. zombieType)
		return nil
	end

	local zombieModel = self:getZombieModel(stats.Model)
	if not zombieModel then
		zombieModel = self:createBasicZombieModel(zombieType)
	end

	local spawnPosition = self:getStrategicSpawnPoint(zombieType)
	if zombieModel.PrimaryPart then
		zombieModel:PivotTo(CFrame.new(spawnPosition + Vector3.new(0, 3, 0)))
	elseif zombieModel:FindFirstChild("HumanoidRootPart") then
		zombieModel.HumanoidRootPart.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 3, 0))
	end

	zombieModel:SetAttribute("IsZombie", true)
	zombieModel:SetAttribute("ZombieType", zombieType)
	zombieModel:SetAttribute("Reward", stats.Reward)
	print("[Spawner] Set attributes for", zombieModel.Name, "IsZombie:", zombieModel:GetAttribute("IsZombie"))

	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.MaxHealth = stats.Health or 60
		humanoid.Health = stats.Health or 60
		print("[Spawner] Set " .. zombieType .. " health to", humanoid.Health, "/", humanoid.MaxHealth)
	else
		warn("[Spawner] No Humanoid found in zombie model:", zombieModel.Name)
	end

	zombieModel.Name = zombieType .. "_" .. self.zombieCount
	zombieModel.Parent = workspace.Zombies

	-- Create brain with AI services
	local brain = ZombieBrain.new(
		zombieModel,
		stats,
		self.baseManager,
		self.playerManager,
		self.targetingService,
		self.surroundService,
		self.bossAuraService,
		self.currentWave
	)
	
	if brain then
		self.zombieBrains[zombieModel] = brain
		table.insert(self.activeZombies, zombieModel)
		self.zombieCount = self.zombieCount + 1
	end

	if humanoid then
		humanoid.Died:Connect(function()
			self:onZombieDied(zombieModel)
		end)
	end

	return zombieModel
end

function Spawner:createBasicZombieModel(zombieType)
	local zombie = Instance.new("Model")
	zombie.Name = zombieType

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = zombie

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.Parent = zombie

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = BrickColor.new("Medium green")
	torso.Parent = zombie

	local weld = Instance.new("Weld")
	weld.Part0 = rootPart
	weld.Part1 = torso
	weld.Parent = rootPart

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.BrickColor = BrickColor.new("Medium green")
	head.Parent = zombie

	local headWeld = Instance.new("Weld")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(0, 1.5, 0)
	headWeld.Parent = torso

	zombie.PrimaryPart = rootPart

	warn("Using basic zombie model for: " .. zombieType)
	return zombie
end

function Spawner:queueSpawn(zombieType)
	table.insert(self.spawnQueue, zombieType)
end

function Spawner:processSpawnQueue(deltaTime)
	if #self.spawnQueue == 0 then
		return
	end

	self.spawnTimer = self.spawnTimer + deltaTime
	if self.spawnTimer >= self.spawnInterval then
		self.spawnTimer = 0

		local zombieType = table.remove(self.spawnQueue, 1)
		if zombieType then
			self:spawnZombie(zombieType)
		end
	end
end

function Spawner:spawnWave(waveComposition)
	self.spawnQueue = {}

	-- Use AI Director composition if not explicitly provided or if an empty composition is provided
	local composition = waveComposition
	local isEmptyWaveComposition = (type(waveComposition) == "table" and next(waveComposition) == nil)
	if self.aiDirector and (composition == nil or isEmptyWaveComposition) then
		local totalZombies = self:calculateTotalZombiesForWave(self.currentWave)
		composition = self.aiDirector:getSpawnComposition(self.currentWave, totalZombies)
		print("[Spawner] AI Director generated composition:", composition)
	end

	-- If we still don't have a valid, non-empty composition, bail out safely
	if type(composition) ~= "table" or next(composition) == nil then
		warn("[Spawner] No valid wave composition for wave " .. tostring(self.currentWave))
		return 0
	end
	local spawnOrder = {"Walker", "Runner", "Spitter", "Brute", "Boss", "Flanker", "Bruiser", "Screamer", "Breacher"}

	local prioritySet = {}
	for _, zombieType in ipairs(spawnOrder) do
		prioritySet[zombieType] = true
	end

	local totalToSpawn = 0

	for _, zombieType in ipairs(spawnOrder) do
		local count = composition[zombieType] or 0
		for _ = 1, count do
			self:queueSpawn(zombieType)
			totalToSpawn = totalToSpawn + 1
		end
	end

	for zombieType, count in pairs(composition) do
		if not prioritySet[zombieType] then
			for _ = 1, count do
				self:queueSpawn(zombieType)
				totalToSpawn = totalToSpawn + 1
			end
		end
	end

	print("Queued " .. totalToSpawn .. " zombies for staggered spawning")
	return totalToSpawn
end

-- Helper to calculate total zombies for wave (for AI Director)
function Spawner:calculateTotalZombiesForWave(waveNumber)
	local baseZombies = GameConfig.BASE_ZOMBIES_PER_WAVE or 5
	local multiplier = GameConfig.ZOMBIES_PER_WAVE_MULTIPLIER or 1.5
	return math.floor(baseZombies * (multiplier ^ (waveNumber - 1)))
end

-- Set current wave number (for AI services)
function Spawner:setCurrentWave(waveNumber)
	self.currentWave = waveNumber
	
	-- Initialize surge timer on first wave
	if waveNumber == 1 and self.aiDirector then
		self.aiDirector:initializeSurgeTimer()
	end
end

function Spawner:onZombieDied(zombie)
	for i, activeZombie in ipairs(self.activeZombies) do
		if activeZombie == zombie then
			table.remove(self.activeZombies, i)
			break
		end
	end

	if self.weaponService then
		self.weaponService:onZombieKilled(zombie)
	end

	if self.zombieBrains[zombie] then
		self.zombieBrains[zombie]:destroy()
		self.zombieBrains[zombie] = nil
	end

	print("Zombie died. Active zombies: " .. #self.activeZombies)
end

function Spawner:update(deltaTime)
	self:processSpawnQueue(deltaTime)

	-- Update AI services
	if self.targetingService then
		self.targetingService:update(deltaTime)
	end
	
	if self.surroundService then
		self.surroundService:update(deltaTime)
	end
	
	if self.aiDirector then
		local totalZombies = #self.activeZombies + #self.spawnQueue
		self.aiDirector:update(deltaTime, self.currentWave, totalZombies)
	end
	
	if self.bossAuraService then
		self.bossAuraService:update(deltaTime, self.activeZombies)
	end

	for zombie, brain in pairs(self.zombieBrains) do
		if brain.isActive then
			brain:update(deltaTime)
		end
	end
end

function Spawner:getActiveZombieCount()
	return #self.activeZombies + #self.spawnQueue
end

function Spawner:clearAllZombies()
	self.spawnQueue = {}

	for _, zombie in ipairs(self.activeZombies) do
		if zombie and zombie.Parent then
			zombie:Destroy()
		end
	end

	self.activeZombies = {}
	self.zombieBrains = {}
	print("All zombies cleared")
end

function Spawner:prepareForNewRound()
	print("[Spawner] Preparing for new round...")

	self:clearAllZombies()
	self:generateSpawnPointsForRound()

	print("[Spawner] Ready for new round with", #self.allSpawnPoints, "spawn points")
end

function Spawner:testSpawnGeneration()
	print("=== Testing Spawn Generation ===")

	if not self.spawnGenerator then
		print("❌ Spawn generator not initialized")
		return
	end

	print("\n1. Testing map analysis...")
	self.spawnGenerator:analyzeMapBounds()

	if self.spawnGenerator.mapBounds then
		print("✅ Map bounds detected:")
		print("   X:", self.spawnGenerator.mapBounds.minX, "to", self.spawnGenerator.mapBounds.maxX)
		print("   Z:", self.spawnGenerator.mapBounds.minZ, "to", self.spawnGenerator.mapBounds.maxZ)
	else
		print("❌ Failed to detect map bounds")
	end

	print("\n2. Testing spawn point generation...")
	local spawnPoints = self.spawnGenerator:generateSpawnPointsForRound()

	print("✅ Generated", #spawnPoints, "spawn points:")
	for i, pos in ipairs(spawnPoints) do
		print("   Spawn Point", i, ":", pos)
	end

	print("\n=== Test Complete ===")
end

return Spawner
