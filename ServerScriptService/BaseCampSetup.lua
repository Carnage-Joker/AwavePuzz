-- BaseCampSetup.lua
-- Creates and configures a defensive base camp in the center of the map
-- Features:
-- - Automatic base camp creation at map center
-- - Defensive walls, gates, and cover structures
-- - Health indicator integration with BaseManager
-- - Zombie targeting integration (BaseCaptureZone model)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BaseCampSetup = {}
BaseCampSetup.__index = BaseCampSetup

-- Get base camp configuration with optional map-specific overrides
-- mapConfig: optional table from MapConfig containing BaseCampConfig overrides
local function getCampConfig(mapConfig)
	local config = {}
	
	-- Start with defaults from GameConfig
	for key, value in pairs(GameConfig.BASE_CAMP) do
		config[key] = value
	end
	
	-- Apply map-specific overrides if provided
	if mapConfig and mapConfig.BaseCampConfig then
		for key, value in pairs(mapConfig.BaseCampConfig) do
			config[key] = value
		end
	end
	
	return config
end

function BaseCampSetup.new(mapConfig)
	local self = setmetatable({}, BaseCampSetup)
	self.baseCampModel = nil
	self.baseCaptureZoneModel = nil -- Track our own BaseCaptureZone
	self.campConfig = getCampConfig(mapConfig) -- Store resolved configuration
	return self
end

-- Calculate center position of the map based on spawn points
function BaseCampSetup:calculateMapCenter(zombieSpawnPoints)
	if not zombieSpawnPoints or #zombieSpawnPoints == 0 then
		-- Default to workspace center if no spawn points
		return Vector3.new(0, self.campConfig.DEFAULT_HEIGHT, 0)
	end
	
	local totalX, totalY, totalZ = 0, 0, 0
	for _, pos in ipairs(zombieSpawnPoints) do
		totalX = totalX + pos.X
		totalY = totalY + pos.Y
		totalZ = totalZ + pos.Z
	end
	
	local count = #zombieSpawnPoints
	local centerX = totalX / count
	local centerY = totalY / count
	local centerZ = totalZ / count
	
	-- Adjust Y to ground level (use raycasting to find ground)
	local rayOrigin = Vector3.new(centerX, centerY + 100, centerZ)
	local rayDirection = Vector3.new(0, -200, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	-- Build filter list, only include folders that exist
	local filterList = {}
	local zombiesFolder = workspace:FindFirstChild("Zombies")
	if zombiesFolder then
		table.insert(filterList, zombiesFolder)
	end
	local baseCampFolder = workspace:FindFirstChild("BaseCamp")
	if baseCampFolder then
		table.insert(filterList, baseCampFolder)
	end
	raycastParams.FilterDescendantsInstances = filterList
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		centerY = raycastResult.Position.Y + 0.5
	else
		centerY = self.campConfig.DEFAULT_HEIGHT -- Default height if no ground found
	end
	
	return Vector3.new(centerX, centerY, centerZ)
end

-- Create the base platform
function BaseCampSetup:createBasePlatform(centerPos)
	local platform = Instance.new("Part")
	platform.Name = "BasePlatform"
	platform.Size = Vector3.new(self.campConfig.BASE_SIZE, 1, self.campConfig.BASE_SIZE)
	platform.Position = centerPos
	platform.Anchored = true
	platform.Color = self.campConfig.BASE_COLOR
	platform.Material = self.campConfig.BASE_MATERIAL
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	
	return platform
end

-- Create defensive walls around the base
function BaseCampSetup:createWalls(centerPos)
	local walls = {}
	local halfSize = self.campConfig.BASE_SIZE / 2
	local wallHeight = self.campConfig.WALL_HEIGHT
	local thickness = self.campConfig.WALL_THICKNESS
	
	-- Create four walls (North, South, East, West)
	local wallConfigs = {
		{name = "NorthWall", size = Vector3.new(self.campConfig.BASE_SIZE, wallHeight, thickness), 
		 offset = Vector3.new(0, wallHeight/2, halfSize)},
		{name = "SouthWall", size = Vector3.new(self.campConfig.BASE_SIZE, wallHeight, thickness), 
		 offset = Vector3.new(0, wallHeight/2, -halfSize)},
		{name = "EastWall", size = Vector3.new(thickness, wallHeight, self.campConfig.BASE_SIZE), 
		 offset = Vector3.new(halfSize, wallHeight/2, 0)},
		{name = "WestWall", size = Vector3.new(thickness, wallHeight, self.campConfig.BASE_SIZE), 
		 offset = Vector3.new(-halfSize, wallHeight/2, 0)},
	}
	
	for _, config in ipairs(wallConfigs) do
		local wall = Instance.new("Part")
		wall.Name = config.name
		wall.Size = config.size
		wall.Position = centerPos + config.offset
		wall.Anchored = true
		wall.Color = self.campConfig.WALL_COLOR
		wall.Material = self.campConfig.WALL_MATERIAL
		wall.TopSurface = Enum.SurfaceType.Smooth
		wall.BottomSurface = Enum.SurfaceType.Smooth
		
		table.insert(walls, wall)
	end
	
	return walls
end

-- Create gates in the walls
function BaseCampSetup:createGates(centerPos)
	local gates = {}
	local halfSize = self.campConfig.BASE_SIZE / 2
	local gateWidth = self.campConfig.GATE_WIDTH
	local gateHeight = self.campConfig.WALL_HEIGHT * 0.7 -- Gates slightly shorter than walls
	local thickness = self.campConfig.WALL_THICKNESS
	
	-- Gates at cardinal directions
	local gateConfigs = {
		{name = "NorthGate", size = Vector3.new(gateWidth, gateHeight, thickness), 
		 offset = Vector3.new(0, gateHeight/2, halfSize)},
		{name = "SouthGate", size = Vector3.new(gateWidth, gateHeight, thickness), 
		 offset = Vector3.new(0, gateHeight/2, -halfSize)},
		{name = "EastGate", size = Vector3.new(thickness, gateHeight, gateWidth), 
		 offset = Vector3.new(halfSize, gateHeight/2, 0)},
		{name = "WestGate", size = Vector3.new(thickness, gateHeight, gateWidth), 
		 offset = Vector3.new(-halfSize, gateHeight/2, 0)},
	}
	
	for _, config in ipairs(gateConfigs) do
		local gate = Instance.new("Part")
		gate.Name = config.name
		gate.Size = config.size
		gate.Position = centerPos + config.offset
		gate.Anchored = true
		gate.Color = self.campConfig.GATE_COLOR
		gate.Material = self.campConfig.GATE_MATERIAL
		gate.Transparency = self.campConfig.GATE_TRANSPARENCY -- Semi-transparent to show as gates
		gate.CanCollide = false -- Players can pass through
		gate.TopSurface = Enum.SurfaceType.Smooth
		gate.BottomSurface = Enum.SurfaceType.Smooth
		
		-- Add a visual indicator that this is a gate
		gate:SetAttribute("IsGate", true)
		
		table.insert(gates, gate)
	end
	
	return gates
end

-- Create cover positions around the base
function BaseCampSetup:createCover(centerPos)
	local coverObjects = {}
	local coverRadius = self.campConfig.BASE_SIZE / 2 - 5 -- Place cover inside the walls
	local angleStep = (2 * math.pi) / self.campConfig.COVER_COUNT
	
	for i = 1, self.campConfig.COVER_COUNT do
		local angle = angleStep * (i - 1)
		local offsetX = math.cos(angle) * coverRadius
		local offsetZ = math.sin(angle) * coverRadius
		
		local cover = Instance.new("Part")
		cover.Name = "Cover_" .. i
		cover.Size = self.campConfig.COVER_SIZE
		cover.Position = centerPos + Vector3.new(offsetX, self.campConfig.COVER_SIZE.Y/2, offsetZ)
		cover.Anchored = true
		cover.Color = self.campConfig.COVER_COLOR
		cover.Material = self.campConfig.COVER_MATERIAL
		cover.TopSurface = Enum.SurfaceType.Smooth
		cover.BottomSurface = Enum.SurfaceType.Smooth
		
		-- Rotate cover to face outward
		cover.CFrame = CFrame.new(cover.Position) * CFrame.Angles(0, angle, 0)
		
		table.insert(coverObjects, cover)
	end
	
	return coverObjects
end

-- Create the BaseCaptureZone model with HitBox for zombie targeting
function BaseCampSetup:createBaseCaptureZone(centerPos)
	local baseCaptureZone = Instance.new("Model")
	baseCaptureZone.Name = "BaseCaptureZone"
	
	-- Create the main hitbox that zombies will target
	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(self.campConfig.BASE_SIZE - 4, self.campConfig.WALL_HEIGHT - 2, self.campConfig.BASE_SIZE - 4)
	hitBox.Position = centerPos + Vector3.new(0, self.campConfig.WALL_HEIGHT/2, 0)
	hitBox.Anchored = true
	hitBox.Transparency = 1 -- Invisible
	hitBox.CanCollide = false
	hitBox.Parent = baseCaptureZone
	
	-- Set the primary part for the model
	baseCaptureZone.PrimaryPart = hitBox
	
	-- Add health value for visual indicator (optional, BaseManager tracks health)
	local healthValue = Instance.new("NumberValue")
	healthValue.Name = "Health"
	healthValue.Value = GameConfig.BASE_HEALTH
	healthValue.Parent = baseCaptureZone
	
	return baseCaptureZone
end

-- Main function to build the entire base camp
function BaseCampSetup:buildBaseCamp(centerPos, parentModel)
	-- Create main base camp model container
	local baseCamp = Instance.new("Model")
	baseCamp.Name = "BaseCamp"
	
	-- Create all base camp components
	local platform = self:createBasePlatform(centerPos)
	local walls = self:createWalls(centerPos)
	local gates = self:createGates(centerPos)
	local cover = self:createCover(centerPos)
	local baseCaptureZone = self:createBaseCaptureZone(centerPos)
	
	-- Create spawn location for players
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "BaseCampSpawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = centerPos + Vector3.new(0, 0.5, 0) -- On top of platform
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true -- Enable collision so players don't fall through
	spawnLocation.Transparency = 1 -- Invisible
	spawnLocation.Duration = 0 -- Instant respawn
	spawnLocation.Neutral = true -- All players spawn here
	
	-- Parent all parts to the base camp model
	platform.Parent = baseCamp
	spawnLocation.Parent = baseCamp
	
	for _, wall in ipairs(walls) do
		wall.Parent = baseCamp
	end
	
	for _, gate in ipairs(gates) do
		gate.Parent = baseCamp
	end
	
	for _, coverObj in ipairs(cover) do
		coverObj.Parent = baseCamp
	end
	
	-- Set primary part
	baseCamp.PrimaryPart = platform
	
	-- Parent the base camp to the specified parent (or workspace)
	if parentModel then
		baseCamp.Parent = parentModel
	else
		baseCamp.Parent = workspace
	end
	
	-- Parent the BaseCaptureZone separately (zombies need to find it)
	baseCaptureZone.Parent = workspace
	
	self.baseCampModel = baseCamp
	self.baseCaptureZoneModel = baseCaptureZone -- Track our own BaseCaptureZone
	
	print("[BaseCampSetup] Base camp created at position:", centerPos)
	
	return baseCamp, baseCaptureZone
end

-- Setup base camp for a map using MapManager's spawn points
function BaseCampSetup:setupForMap(mapManager)
	-- Clean up existing base camp if any
	self:cleanup()
	
	-- Get zombie spawn points to calculate center
	local zombieSpawnPoints = mapManager:getZombieSpawnPoints()
	
	-- Calculate map center
	local centerPos = self:calculateMapCenter(zombieSpawnPoints)
	
	-- Build the base camp
	local baseCamp, baseCaptureZone = self:buildBaseCamp(centerPos)
	
	print("[BaseCampSetup] Base camp setup complete for map:", mapManager:getCurrentMapId())
	
	return baseCamp, baseCaptureZone
end

-- Cleanup existing base camp
-- Only destroys the instances created by this BaseCampSetup object
-- to avoid interfering with manually placed or alternative camps
function BaseCampSetup:cleanup()
	-- Only destroy the base camp model we created
	if self.baseCampModel and self.baseCampModel.Parent then
		self.baseCampModel:Destroy()
	end
	self.baseCampModel = nil
	
	-- Only destroy the BaseCaptureZone we created
	if self.baseCaptureZoneModel and self.baseCaptureZoneModel.Parent then
		self.baseCaptureZoneModel:Destroy()
	end
	self.baseCaptureZoneModel = nil
end

return BaseCampSetup
