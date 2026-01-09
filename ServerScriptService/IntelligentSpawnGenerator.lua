-- @ScriptType: ModuleScript
-- IntelligentSpawnGenerator.lua
-- Robust spawn generation for PARTS-ONLY maps
-- Uses ActiveMap bounds, ignores terrain reliance, returns spawn points + strategic selection

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local IntelligentSpawnGenerator = {}
IntelligentSpawnGenerator.__index = IntelligentSpawnGenerator

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
	MIN_SPAWN_POINTS = 8,
	MAX_SPAWN_POINTS = 16,
	SPAWN_POINT_SPACING = 25,
	SPAWN_HEIGHT_OFFSET = 3,
	VALIDATION_RADIUS = 10,
	MAP_MARGIN = 20,
	MAX_ATTEMPTS_PER_POINT = 40,

	-- Debug: set true if you want to see generated spawn markers in Workspace
	DEBUG_DRAW = false,
	DEBUG_FOLDER_NAME = "GeneratedZombieSpawnPoints",
	DEBUG_MARKER_SIZE = Vector3.new(1.5, 1.5, 1.5)
}

-- Optional spawn preferences per zombie type (Spawner expects this method to exist)
local SPAWN_PREFERENCES = {
	Walker  = { min = 30,  max = 90  },
	Runner  = { min = 20,  max = 70  },
	Brute   = { min = 50,  max = 140 },
	Spitter = { min = 40,  max = 110 },
	Boss    = { min = 70,  max = 170 }
}

----------------------------------------------------------------
-- UTILS
----------------------------------------------------------------
local function getActiveMap()
	return Workspace:FindFirstChild("ActiveMap")
end

local function clamp(n, a, b)
	return math.max(a, math.min(b, n))
end

local function farEnough(pos, list)
	for _, other in ipairs(list) do
		if (pos - other).Magnitude < CONFIG.SPAWN_POINT_SPACING then
			return false
		end
	end
	return true
end

local function getOrCreateDebugFolder()
	local f = Workspace:FindFirstChild(CONFIG.DEBUG_FOLDER_NAME)
	if not f then
		f = Instance.new("Folder")
		f.Name = CONFIG.DEBUG_FOLDER_NAME
		f.Parent = Workspace
	end
	return f
end

local function drawDebugMarker(pos, index)
	if not CONFIG.DEBUG_DRAW then return end
	local folder = getOrCreateDebugFolder()

	local p = Instance.new("Part")
	p.Name = "Spawn_" .. tostring(index)
	p.Anchored = true
	p.CanCollide = false
	p.Size = CONFIG.DEBUG_MARKER_SIZE
	p.CFrame = CFrame.new(pos)
	p.Material = Enum.Material.Neon
	p.Transparency = 0.25
	p.Parent = folder
end

----------------------------------------------------------------
-- CLASS
----------------------------------------------------------------
function IntelligentSpawnGenerator.new()
	return setmetatable({
		mapBounds = nil,
		generatedSpawnPoints = {},
		_debugFolder = nil
	}, IntelligentSpawnGenerator)
end

----------------------------------------------------------------
-- CLEANUP (Spawner expects this method)
----------------------------------------------------------------
function IntelligentSpawnGenerator:cleanupGeneratedSpawnPoints()
	-- Clear remembered generated points
	self.generatedSpawnPoints = {}

	-- Remove debug markers if they exist
	local f = Workspace:FindFirstChild(CONFIG.DEBUG_FOLDER_NAME)
	if f then
		f:Destroy()
	end

	print("[SpawnGenerator] Cleanup complete")
end

----------------------------------------------------------------
-- MAP BOUNDS (FROM ACTIVE MAP GEOMETRY)
----------------------------------------------------------------
function IntelligentSpawnGenerator:analyzeMapBounds()
	local map = getActiveMap()
	if not map then
		self.mapBounds = { minX = -100, maxX = 100, minZ = -100, maxZ = 100, topY = 300, bottomY = -300 }
		warn("[SpawnGenerator] No ActiveMap found, using fallback bounds")
		return
	end

	-- Prefer explicit MapBounds if present
	local boundsObj = map:FindFirstChild("MapBounds")
	local cf, size

	if boundsObj then
		if boundsObj:IsA("BasePart") then
			cf, size = boundsObj.CFrame, boundsObj.Size
		elseif boundsObj:IsA("Model") then
			cf, size = boundsObj:GetBoundingBox()
		else
			-- weird type; fallback
			cf, size = map:GetBoundingBox()
		end
	else
		cf, size = map:GetBoundingBox()
	end

	self.mapBounds = {
		minX = cf.Position.X - size.X / 2 + CONFIG.MAP_MARGIN,
		maxX = cf.Position.X + size.X / 2 - CONFIG.MAP_MARGIN,
		minZ = cf.Position.Z - size.Z / 2 + CONFIG.MAP_MARGIN,
		maxZ = cf.Position.Z + size.Z / 2 - CONFIG.MAP_MARGIN,
		topY = cf.Position.Y + size.Y / 2 + 200,
		bottomY = cf.Position.Y - size.Y / 2 - 200
	}

	print("[SpawnGenerator] Map bounds:",
		self.mapBounds.minX, self.mapBounds.maxX,
		self.mapBounds.minZ, self.mapBounds.maxZ
	)
end

----------------------------------------------------------------
-- GROUND DETECTION (PARTS ONLY) - RAYCAST INTO ACTIVE MAP
----------------------------------------------------------------
function IntelligentSpawnGenerator:findGround(x, z)
	local map = getActiveMap()
	if not map then return nil end
	if not self.mapBounds then self:analyzeMapBounds() end

	local b = self.mapBounds
	local origin = Vector3.new(x, b.topY, z)
	local direction = Vector3.new(0, -(b.topY - b.bottomY), 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction, params)
	if not result or not result.Instance then
		return nil
	end

	return result.Position, result.Instance
end

----------------------------------------------------------------
-- VALIDATION (DON'T SPAWN INSIDE SOLIDS)
----------------------------------------------------------------
function IntelligentSpawnGenerator:isClear(position, groundPart)
	local box = CFrame.new(position + Vector3.new(0, 6, 0))
	local size = Vector3.new(CONFIG.VALIDATION_RADIUS * 2, 12, CONFIG.VALIDATION_RADIUS * 2)

	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { groundPart }

	local hits = Workspace:GetPartBoundsInBox(box, size, overlap)
	for _, part in ipairs(hits) do
		if part and part:IsA("BasePart") then
			if part.CanCollide and part.Transparency < 0.95 then
				if not CollectionService:HasTag(part, "IgnoreSpawnBlocker") then
					return false
				end
			end
		end
	end

	return true
end

----------------------------------------------------------------
-- GENERATION
----------------------------------------------------------------
function IntelligentSpawnGenerator:generateSpawnPointsForRound()
	print("[SpawnGenerator] Generating intelligent spawn points...")

	-- Clean previous generated markers/points (prevents stacking if you enable debug)
	self:cleanupGeneratedSpawnPoints()

	if not self.mapBounds then
		self:analyzeMapBounds()
	end

	-- Manual spawns live inside ActiveMap.ZombieSpawnPoints (NOT workspace root)
	local baseSpawns = {}
	local map = getActiveMap()
	if map then
		local folder = map:FindFirstChild("ZombieSpawnPoints")
		if folder then
			for _, p in ipairs(folder:GetChildren()) do
				if p:IsA("BasePart") then
					table.insert(baseSpawns, p.Position)
				elseif p:IsA("Model") and p.PrimaryPart then
					table.insert(baseSpawns, p.PrimaryPart.Position)
				end
			end
		end
	end

	local target = math.random(CONFIG.MIN_SPAWN_POINTS, CONFIG.MAX_SPAWN_POINTS)
	local needed = math.max(0, target - #baseSpawns)

	print("[SpawnGenerator] Target:", target, "Manual:", #baseSpawns, "Generate:", needed)

	local all = table.clone(baseSpawns)

	for i = 1, needed do
		local placed = false

		for _ = 1, CONFIG.MAX_ATTEMPTS_PER_POINT do
			local x = math.random(math.floor(self.mapBounds.minX), math.floor(self.mapBounds.maxX))
			local z = math.random(math.floor(self.mapBounds.minZ), math.floor(self.mapBounds.maxZ))

			local hitPos, ground = self:findGround(x, z)
			if hitPos then
				local spawnPos = hitPos + Vector3.new(0, CONFIG.SPAWN_HEIGHT_OFFSET, 0)
				if self:isClear(spawnPos, ground) and farEnough(spawnPos, all) then
					table.insert(all, spawnPos)
					table.insert(self.generatedSpawnPoints, spawnPos)
					drawDebugMarker(spawnPos, i)
					placed = true
					break
				end
			end
		end

		if not placed then
			warn("[SpawnGenerator] Failed to place spawn", i)
		end
	end

	-- Never return zero if manual exists
	if #all == 0 and #baseSpawns > 0 then
		warn("[SpawnGenerator] Falling back to manual spawn points only")
		all = baseSpawns
	end

	print("[SpawnGenerator] Total spawn points:", #all)
	return all
end

----------------------------------------------------------------
-- STRATEGIC PICK (Spawner expects this method)
----------------------------------------------------------------
function IntelligentSpawnGenerator:getStrategicSpawnPoint(zombieType, allSpawnPoints, playerPositions)
	if not allSpawnPoints or #allSpawnPoints == 0 then
		return Vector3.new(0, 10, 0)
	end

	local pref = SPAWN_PREFERENCES[zombieType] or SPAWN_PREFERENCES.Walker
	local minD, maxD = pref.min, pref.max

	-- Compute player center (if none, just pick random)
	if not playerPositions or #playerPositions == 0 then
		return allSpawnPoints[math.random(1, #allSpawnPoints)]
	end

	local center = Vector3.new(0, 0, 0)
	for _, p in ipairs(playerPositions) do
		center += p
	end
	center /= #playerPositions

	-- Score spawns by how close they are to preferred range
	local best = nil
	local bestScore = -math.huge

	for _, sp in ipairs(allSpawnPoints) do
		local d = (sp - center).Magnitude

		-- score: max when inside range, penalty outside
		local score
		if d >= minD and d <= maxD then
			score = 100
		else
			local distToBand
			if d < minD then distToBand = (minD - d) else distToBand = (d - maxD) end
			score = 100 - clamp(distToBand, 0, 100)
		end

		-- small randomness to avoid identical patterns
		score += math.random(-10, 10)

		if score > bestScore then
			bestScore = score
			best = sp
		end
	end

	return best or allSpawnPoints[1]
end

return IntelligentSpawnGenerator
