-- @ScriptType: Script
-- IntelligentSpawnGenerator.lua
-- Generates intelligent zombie spawn points at the beginning of each round
-- Ensures zombies spawn on ground, not inside structures, trees, or water

local Workspace = game:GetService("Workspace")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load config to check debug flags
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
local GameConfig = nil
if SharedFolder then
	local configModule = SharedFolder:FindFirstChild("GameConfig")
	if configModule then
		local success, result = pcall(require, configModule)
		if success then
			GameConfig = result
		end
	end
end

-- Try to require visualizer from Tests folder only if in Studio and debug is enabled
local SpawnPointVisualizer
local debugEnabled = GameConfig and (GameConfig.DEBUG or GameConfig.DEBUG_SPAWNS)
local isStudio = RunService:IsStudio()

if isStudio and debugEnabled then
	local success, result = pcall(function()
		local testsFolder = script.Parent:FindFirstChild("Tests")
		if testsFolder then
			local visualizerModule = testsFolder:FindFirstChild("SpawnPointVisualizer")
			if visualizerModule then
				return require(visualizerModule)
			end
		end
		return nil
	end)
	
	if success and result then
		SpawnPointVisualizer = result
		print("[SpawnGenerator] Debug visualizer loaded")
	end
	-- No error message if visualizer not found - it's purely optional
end

local IntelligentSpawnGenerator = {}
IntelligentSpawnGenerator.__index = IntelligentSpawnGenerator

-- Configuration
local CONFIG = {
	MIN_SPAWN_POINTS = 8,
	MAX_SPAWN_POINTS = 16,
	SPAWN_POINT_SPACING = 25, -- Minimum distance between spawn points
	GROUND_CHECK_DISTANCE = 50, -- How far down to check for ground
	SPAWN_HEIGHT_OFFSET = 3, -- How high above ground to spawn zombies
	VALIDATION_RADIUS = 10, -- Radius to check for obstacles
	MAP_BOUNDARY_MARGIN = 20, -- Margin from map edges
	MAX_GENERATION_ATTEMPTS = 100 -- Max attempts to find valid spawn points
}

-- Zombie type spawn preferences
local SPAWN_PREFERENCES = {
	Walker = { preferDistance = "medium", minDistance = 30, maxDistance = 80 },
	Runner = { preferDistance = "close",  minDistance = 20, maxDistance = 60 },
	Brute  = { preferDistance = "far",    minDistance = 50, maxDistance = 120 },
	Spitter= { preferDistance = "medium", minDistance = 40, maxDistance = 90 },
	Boss   = { preferDistance = "far",    minDistance = 60, maxDistance = 150 }
}

local function ensureGeneratedFolder()
	local folder = Workspace:FindFirstChild("GeneratedZombieSpawnPoints")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GeneratedZombieSpawnPoints"
		folder.Parent = Workspace
	end
	return folder
end

local function createGeneratedMarker(pos, index)
	local folder = ensureGeneratedFolder()
	local p = Instance.new("Part")
	p.Name = "GeneratedSpawn_" .. tostring(index)
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Parent = folder
	p:SetAttribute("IsGeneratedZombieSpawn", true)
end

function IntelligentSpawnGenerator.new()
	local self = setmetatable({}, IntelligentSpawnGenerator)
	self.generatedSpawnPoints = {}
	self.mapBounds = nil
	self.playerCenter = Vector3.new(0, 0, 0)
	self.debugMode = false

	-- Initialize visualizer if available
	if SpawnPointVisualizer then
		self.visualizer = SpawnPointVisualizer.new()
	end

	return self
end

-- Get map boundaries by analyzing existing objects
function IntelligentSpawnGenerator:analyzeMapBounds()
	local positions = {}

	local function collectPositions(folder)
		if not folder then return end
		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(positions, descendant.Position)
			end
		end
	end

	collectPositions(Workspace:FindFirstChild("Structures"))
	collectPositions(Workspace:FindFirstChild("Trees"))
	collectPositions(Workspace:FindFirstChild("Props"))
	collectPositions(Workspace:FindFirstChild("ZombieSpawnPoints"))

	if #positions == 0 then
		self.mapBounds = { minX = -100, maxX = 100, minZ = -100, maxZ = 100 }
	else
		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge

		for _, pos in ipairs(positions) do
			minX = math.min(minX, pos.X)
			maxX = math.max(maxX, pos.X)
			minZ = math.min(minZ, pos.Z)
			maxZ = math.max(maxZ, pos.Z)
		end

		self.mapBounds = {
			minX = minX - CONFIG.MAP_BOUNDARY_MARGIN,
			maxX = maxX + CONFIG.MAP_BOUNDARY_MARGIN,
			minZ = minZ - CONFIG.MAP_BOUNDARY_MARGIN,
			maxZ = maxZ + CONFIG.MAP_BOUNDARY_MARGIN
		}
	end

	print("[SpawnGenerator] Map bounds:", self.mapBounds.minX, self.mapBounds.maxX, self.mapBounds.minZ, self.mapBounds.maxZ)
end

-- Find ground level at a given X,Z position
function IntelligentSpawnGenerator:findGroundLevel(position)
	local rayStart = Vector3.new(position.X, position.Y + CONFIG.GROUND_CHECK_DISTANCE, position.Z)
	local rayDirection = Vector3.new(0, -CONFIG.GROUND_CHECK_DISTANCE * 2, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayStart, rayDirection, raycastParams)

	if result and result.Position.Y > -100 then
		return result.Position.Y, result.Material, result.Instance
	end

	return nil
end

-- Check if a position is valid for spawning (no obstacles)
function IntelligentSpawnGenerator:isValidSpawnPosition(position)
	local region = Region3.new(
		Vector3.new(position.X - CONFIG.VALIDATION_RADIUS, position.Y - 5, position.Z - CONFIG.VALIDATION_RADIUS),
		Vector3.new(position.X + CONFIG.VALIDATION_RADIUS, position.Y + 10, position.Z + CONFIG.VALIDATION_RADIUS)
	)

	local partsInRegion = Workspace:FindPartsInRegion3(region, nil, 100)

	for _, part in ipairs(partsInRegion) do
		if part ~= Terrain and part.Material ~= Enum.Material.Air then
			if part.Size.X > 2 or part.Size.Y > 2 or part.Size.Z > 2 then
				return false
			end
		end
	end

	local rayStart = Vector3.new(position.X, position.Y + 10, position.Z)
	local rayDirection = Vector3.new(0, -15, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayStart, rayDirection, raycastParams)
	if result and (result.Position.Y - position.Y) > 5 then
		return false
	end

	return true
end

function IntelligentSpawnGenerator:isFarEnoughFromOtherSpawns(position, existingSpawns)
	for _, spawnPos in ipairs(existingSpawns) do
		local distance = (position - spawnPos).Magnitude
		if distance < CONFIG.SPAWN_POINT_SPACING then
			return false
		end
	end
	return true
end

function IntelligentSpawnGenerator:generateSpawnPoint(existingSpawns)
	if not self.mapBounds then
		self:analyzeMapBounds()
	end

	for attempt = 1, CONFIG.MAX_GENERATION_ATTEMPTS do
		local x = math.random(self.mapBounds.minX, self.mapBounds.maxX)
		local z = math.random(self.mapBounds.minZ, self.mapBounds.maxZ)
		local testPos = Vector3.new(x, 50, z)

		local groundY = self:findGroundLevel(testPos)
		if groundY then
			local spawnPos = Vector3.new(x, groundY + CONFIG.SPAWN_HEIGHT_OFFSET, z)

			if self:isValidSpawnPosition(spawnPos) and self:isFarEnoughFromOtherSpawns(spawnPos, existingSpawns) then
				return spawnPos
			end
		end
	end

	return nil
end

function IntelligentSpawnGenerator:generateSpawnPointsForRound()
	print("[SpawnGenerator] Generating intelligent spawn points for new round...")

	self.generatedSpawnPoints = {}
	-- clear exported markers each round
	local genFolder = Workspace:FindFirstChild("GeneratedZombieSpawnPoints")
	if genFolder then
		genFolder:ClearAllChildren()
	end

	if not self.mapBounds then
		self:analyzeMapBounds()
	end

	local existingSpawnsFolder = Workspace:FindFirstChild("ZombieSpawnPoints")
	local baseSpawns = {}

	if existingSpawnsFolder then
		for _, spawnPoint in ipairs(existingSpawnsFolder:GetChildren()) do
			if spawnPoint:IsA("BasePart") then
				table.insert(baseSpawns, spawnPoint.Position)
			end
		end
	end

	local targetCount = math.random(CONFIG.MIN_SPAWN_POINTS, CONFIG.MAX_SPAWN_POINTS)
	local pointsToGenerate = math.max(0, targetCount - #baseSpawns)

	print("[SpawnGenerator] Target spawn points:", targetCount, "Existing:", #baseSpawns, "To generate:", pointsToGenerate)

	local allSpawns = {}
	for _, pos in ipairs(baseSpawns) do
		table.insert(allSpawns, pos)
	end

	for i = 1, pointsToGenerate do
		local newSpawn = self:generateSpawnPoint(allSpawns)
		if newSpawn then
			table.insert(allSpawns, newSpawn)
			table.insert(self.generatedSpawnPoints, newSpawn)
			createGeneratedMarker(newSpawn, i)
			print("[SpawnGenerator] Generated spawn point", i, "at", newSpawn)
		else
			warn("[SpawnGenerator] Failed to generate spawn point", i)
		end
	end

	if self.debugMode and self.visualizer then
		self.visualizer:visualizeSpawnPoints(baseSpawns, self.generatedSpawnPoints)
	end

	print("[SpawnGenerator] Total spawn points available:", #allSpawns)
	return allSpawns
end

function IntelligentSpawnGenerator:getStrategicSpawnPoint(zombieType, allSpawnPoints, playerPositions)
	if #allSpawnPoints == 0 then
		return Vector3.new(0, 10, 0)
	end

	local preference = SPAWN_PREFERENCES[zombieType] or SPAWN_PREFERENCES.Walker

	local playerCenter = Vector3.new(0, 0, 0)
	if playerPositions and #playerPositions > 0 then
		for _, pos in ipairs(playerPositions) do
			playerCenter = playerCenter + pos
		end
		playerCenter = playerCenter / #playerPositions
	end

	local scoredSpawns = {}
	for i, spawnPos in ipairs(allSpawnPoints) do
		local distanceToPlayers = (spawnPos - playerCenter).Magnitude
		local score = 0

		if distanceToPlayers >= preference.minDistance and distanceToPlayers <= preference.maxDistance then
			score = score + 100
		else
			local distancePenalty = math.min(50, math.abs(distanceToPlayers - preference.minDistance))
			score = score - distancePenalty
		end

		score = score + math.random(-20, 20)

		table.insert(scoredSpawns, { position = spawnPos, score = score, index = i })
	end

	table.sort(scoredSpawns, function(a, b) return a.score > b.score end)

	local topSpawns = math.min(3, #scoredSpawns)
	local selectedSpawn = scoredSpawns[math.random(1, topSpawns)]

	if self.debugMode and self.visualizer then
		self.visualizer:highlightSelectedSpawn(selectedSpawn.position, zombieType)
	end

	return selectedSpawn.position
end

function IntelligentSpawnGenerator:cleanupGeneratedSpawnPoints()
	self.generatedSpawnPoints = {}
	if self.visualizer then
		self.visualizer:clearVisuals()
	end
	local genFolder = Workspace:FindFirstChild("GeneratedZombieSpawnPoints")
	if genFolder then
		genFolder:ClearAllChildren()
	end
	print("[SpawnGenerator] Cleaned up generated spawn points")
end

function IntelligentSpawnGenerator:setDebugMode(enabled)
	self.debugMode = enabled
	if self.visualizer then
		self.visualizer:enableDebugMode(enabled)
	end
	print("[SpawnGenerator] Debug mode:", enabled and "enabled" or "disabled")
end

return IntelligentSpawnGenerator
