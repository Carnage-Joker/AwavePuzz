-- Spawner.lua
-- Server script that spawns zombies based on wave configuration

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ZombieTypes = require(ReplicatedStorage.Shared.ZombieTypes)
local ZombieBrain = require(script.Parent.AIScripts.ZombieBrain)

local Spawner = {}
Spawner.__index = Spawner

function Spawner.new(weaponService)
	local self = setmetatable({}, Spawner)

	self.weaponService = weaponService
	self.spawnPoints = {}
	self.activeZombies = {}
	self.zombieBrains = {}
	self.zombieCount = 0

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


function Spawner:getRandomSpawnPoint()
	if #self.spawnPoints == 0 then
		warn("No spawn points available! Using default position.")
		return Vector3.new(0, 10, 0)
	end

	return self.spawnPoints[math.random(1, #self.spawnPoints)]
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

	-- Position zombie at spawn point
	local spawnPosition = self:getRandomSpawnPoint()
	if zombieModel.PrimaryPart then
		zombieModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition + Vector3.new(0, 3, 0)))
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

	-- Initialize AI
	local brain = ZombieBrain.new(zombieModel, stats)
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

function Spawner:spawnWave(waveComposition)
	local spawnedCount = 0

	for zombieType, count in pairs(waveComposition) do
		for _ = 1, count do
			local zombie = self:spawnZombie(zombieType)
			if zombie then
				spawnedCount = spawnedCount + 1
				-- Stagger spawns slightly
				task.wait(0.2)
			end
		end
	end

	print("Spawned " .. spawnedCount .. " zombies for wave")
	return spawnedCount
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
	-- Update all zombie brains
	for zombie, brain in pairs(self.zombieBrains) do
		if brain.isActive then
			brain:update(deltaTime)
		end
	end
end

function Spawner:getActiveZombieCount()
	return #self.activeZombies
end

function Spawner:clearAllZombies()
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
