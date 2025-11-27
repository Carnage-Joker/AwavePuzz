-- Spawner.lua
-- Server script that spawns zombies based on wave configuration
-- Features staggered spawning timing and strategic spawn point distribution
-- Strategic zombie type spawning based on wave progression

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ZombieTypes = require(ReplicatedStorage.Shared.ZombieTypes)
local ZombieBrain = require(script.Parent.AIScripts.ZombieBrain)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- Constants
local DEFAULT_SPAWN_INTERVAL = 0.5 -- Default seconds between zombie spawns

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
	
	-- Spawn queue for staggered spawning
	self.spawnQueue = {}
	self.spawnTimer = 0
	self.spawnInterval = GameConfig.Spawning and GameConfig.Spawning.SPAWN_INTERVAL or DEFAULT_SPAWN_INTERVAL
	self.lastUsedSpawnIndex = 0

	-- Setup zombie folder in workspace
	if not workspace:FindFirstChild("Zombies") then
		local zombiesFolder = Instance.new("Folder")
		zombiesFolder.Name = "Zombies"
		zombiesFolder.Parent = workspace
	end

	return self
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
	-- Load spawn points from workspace (fallback if MapManager not available)
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

	print("Loaded " .. #self.spawnPoints .. " zombie spawn points")
end

-- Get spawn point using round-robin distribution for better spread
function Spawner:getNextSpawnPoint()
	if #self.spawnPoints == 0 then
		warn("No spawn points available! Using default position.")
		return Vector3.new(0, 10, 0)
	end
	
	-- Round-robin through spawn points
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

-- Strategic spawn point selection based on zombie type
function Spawner:getStrategicSpawnPoint(zombieType)
	if #self.spawnPoints == 0 then
		return Vector3.new(0, 10, 0)
	end
	
	-- For now, use round-robin for better distribution
	-- Future enhancement: select spawn points based on zombie type
	-- (e.g., Brutes spawn farther away, Runners spawn closer)
	return self:getNextSpawnPoint()
end

function Spawner:getZombieModel(zombieType)
	-- Try to get zombie model from ServerStorage
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
	-- Get zombie stats
	local stats = ZombieTypes[zombieType]
	if not stats then
		warn("Unknown zombie type: " .. zombieType)
		return nil
	end

	-- Get zombie model
	local zombieModel = self:getZombieModel(stats.Model)
	if not zombieModel then
		-- Fallback: create a basic zombie model
		zombieModel = self:createBasicZombieModel(zombieType)
	end

	-- Position zombie at spawn point (use strategic for better distribution)
	local spawnPosition = self:getStrategicSpawnPoint(zombieType)
	if zombieModel.PrimaryPart then
		zombieModel:PivotTo(CFrame.new(spawnPosition + Vector3.new(0, 3, 0)))
	elseif zombieModel:FindFirstChild("HumanoidRootPart") then
		zombieModel.HumanoidRootPart.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 3, 0))
	end

	-- Set zombie attributes
	zombieModel:SetAttribute("IsZombie", true)
	zombieModel:SetAttribute("ZombieType", zombieType)
	zombieModel:SetAttribute("Reward", stats.Reward)

	-- Parent to workspace
	zombieModel.Name = zombieType .. "_" .. self.zombieCount
	zombieModel.Parent = workspace.Zombies

	-- Initialize AI with baseManager and playerManager for attack system
	local brain = ZombieBrain.new(zombieModel, stats, self.baseManager, self.playerManager)
	if brain then
		self.zombieBrains[zombieModel] = brain
		table.insert(self.activeZombies, zombieModel)
		self.zombieCount = self.zombieCount + 1
	end

	-- Setup death handler
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			self:onZombieDied(zombieModel)
		end)
	end

	return zombieModel
end

function Spawner:createBasicZombieModel(zombieType)
	-- Fallback: Create a basic zombie model if no model exists
	local zombie = Instance.new("Model")
	zombie.Name = zombieType

	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = zombie

	-- Create root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.Parent = zombie

	-- Create torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = BrickColor.new("Medium green")
	torso.Parent = zombie

	local weld = Instance.new("Weld")
	weld.Part0 = rootPart
	weld.Part1 = torso
	weld.Parent = rootPart

	-- Create head
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

-- Queue zombies for staggered spawning
function Spawner:queueSpawn(zombieType)
	table.insert(self.spawnQueue, zombieType)
end

-- Process spawn queue for staggered spawning
function Spawner:processSpawnQueue(deltaTime)
	if #self.spawnQueue == 0 then
		return
	end
	
	self.spawnTimer = self.spawnTimer + deltaTime
	if self.spawnTimer >= self.spawnInterval then
		self.spawnTimer = 0
		
		-- Spawn the next zombie in queue
		local zombieType = table.remove(self.spawnQueue, 1)
		if zombieType then
			self:spawnZombie(zombieType)
		end
	end
end

-- Strategic wave spawning - queues zombies by type priority
function Spawner:spawnWave(waveComposition)
	-- Clear any existing spawn queue
	self.spawnQueue = {}
	
	-- Sort zombie types by priority for strategic spawning
	-- Priority: Walkers first, then Runners, Spitters, Brutes, Boss last
	local spawnOrder = {"Walker", "Runner", "Spitter", "Brute", "Boss"}
	
	local totalToSpawn = 0
	
	-- Queue zombies in strategic order
	for _, zombieType in ipairs(spawnOrder) do
		local count = waveComposition[zombieType] or 0
		for _ = 1, count do
			self:queueSpawn(zombieType)
			totalToSpawn = totalToSpawn + 1
		end
	end
	
	-- Queue any other zombie types not in the priority list
	for zombieType, count in pairs(waveComposition) do
		local found = false
		for _, priorityType in ipairs(spawnOrder) do
			if zombieType == priorityType then
				found = true
				break
			end
		end
		if not found then
			for _ = 1, count do
				self:queueSpawn(zombieType)
				totalToSpawn = totalToSpawn + 1
			end
		end
	end

	print("Queued " .. totalToSpawn .. " zombies for staggered spawning")
	return totalToSpawn
end

function Spawner:onZombieDied(zombie)
	-- Remove from active list
	for i, activeZombie in ipairs(self.activeZombies) do
		if activeZombie == zombie then
			table.remove(self.activeZombies, i)
			break
		end
	end

	if self.weaponService then
		self.weaponService:onZombieKilled(zombie)
	end

	-- Remove brain
	if self.zombieBrains[zombie] then
		self.zombieBrains[zombie]:destroy()
		self.zombieBrains[zombie] = nil
	end

	print("Zombie died. Active zombies: " .. #self.activeZombies)
end

function Spawner:update(deltaTime)
	-- Process staggered spawn queue
	self:processSpawnQueue(deltaTime)
	
	-- Update all zombie brains
	for zombie, brain in pairs(self.zombieBrains) do
		if brain.isActive then
			brain:update(deltaTime)
		end
	end
end

function Spawner:getActiveZombieCount()
	-- Include zombies still in queue as "alive" for wave completion check
	return #self.activeZombies + #self.spawnQueue
end

function Spawner:clearAllZombies()
	-- Clear spawn queue
	self.spawnQueue = {}
	
	-- Destroy all active zombies
	for _, zombie in ipairs(self.activeZombies) do
		if zombie and zombie.Parent then
			zombie:Destroy()
		end
	end

	self.activeZombies = {}
	self.zombieBrains = {}
	print("All zombies cleared")
end

return Spawner
