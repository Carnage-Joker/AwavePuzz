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

-- Configuration for base camp appearance and layout
local CAMP_CONFIG = {
	-- Base structure
	BASE_SIZE = 30, -- Size of the central base structure (studs)
	WALL_HEIGHT = 12, -- Height of defensive walls
	WALL_THICKNESS = 2, -- Thickness of walls
	DEFAULT_HEIGHT = 5, -- Default Y position if ground detection fails
	
	-- Defensive features
	GATE_WIDTH = 8, -- Width of gates in walls
	GATE_TRANSPARENCY = 0.3, -- Transparency of gates (0=opaque, 1=invisible)
	NUM_GATES = 4, -- Number of gates (one per cardinal direction)
	COVER_COUNT = 8, -- Number of cover positions
	COVER_SIZE = Vector3.new(4, 3, 1), -- Size of cover objects
	
	-- Colors and materials
	WALL_COLOR = Color3.fromRGB(80, 80, 80), -- Gray walls
	BASE_COLOR = Color3.fromRGB(100, 100, 100), -- Base platform color
	GATE_COLOR = Color3.fromRGB(120, 80, 40), -- Brownish gates
	COVER_COLOR = Color3.fromRGB(70, 70, 70), -- Dark gray cover
	
	WALL_MATERIAL = Enum.Material.Concrete,
	BASE_MATERIAL = Enum.Material.Concrete,
	GATE_MATERIAL = Enum.Material.Wood,
	COVER_MATERIAL = Enum.Material.Metal,
}

function BaseCampSetup.new()
	local self = setmetatable({}, BaseCampSetup)
	self.baseCampModel = nil
	return self
end

-- Calculate center position of the map based on spawn points
function BaseCampSetup:calculateMapCenter(zombieSpawnPoints)
	if not zombieSpawnPoints or #zombieSpawnPoints == 0 then
		-- Default to workspace center if no spawn points
		return Vector3.new(0, CAMP_CONFIG.DEFAULT_HEIGHT, 0)
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
		centerY = CAMP_CONFIG.DEFAULT_HEIGHT -- Default height if no ground found
	end
	
	return Vector3.new(centerX, centerY, centerZ)
end

-- Create the base platform
function BaseCampSetup:createBasePlatform(centerPos)
	local platform = Instance.new("Part")
	platform.Name = "BasePlatform"
	platform.Size = Vector3.new(CAMP_CONFIG.BASE_SIZE, 1, CAMP_CONFIG.BASE_SIZE)
	platform.Position = centerPos
	platform.Anchored = true
	platform.Color = CAMP_CONFIG.BASE_COLOR
	platform.Material = CAMP_CONFIG.BASE_MATERIAL
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	
	return platform
end

-- Create defensive walls around the base
function BaseCampSetup:createWalls(centerPos)
	local walls = {}
	local halfSize = CAMP_CONFIG.BASE_SIZE / 2
	local wallHeight = CAMP_CONFIG.WALL_HEIGHT
	local thickness = CAMP_CONFIG.WALL_THICKNESS
	
	-- Create four walls (North, South, East, West)
	local wallConfigs = {
		{name = "NorthWall", size = Vector3.new(CAMP_CONFIG.BASE_SIZE, wallHeight, thickness), 
		 offset = Vector3.new(0, wallHeight/2, halfSize)},
		{name = "SouthWall", size = Vector3.new(CAMP_CONFIG.BASE_SIZE, wallHeight, thickness), 
		 offset = Vector3.new(0, wallHeight/2, -halfSize)},
		{name = "EastWall", size = Vector3.new(thickness, wallHeight, CAMP_CONFIG.BASE_SIZE), 
		 offset = Vector3.new(halfSize, wallHeight/2, 0)},
		{name = "WestWall", size = Vector3.new(thickness, wallHeight, CAMP_CONFIG.BASE_SIZE), 
		 offset = Vector3.new(-halfSize, wallHeight/2, 0)},
	}
	
	for _, config in ipairs(wallConfigs) do
		local wall = Instance.new("Part")
		wall.Name = config.name
		wall.Size = config.size
		wall.Position = centerPos + config.offset
		wall.Anchored = true
		wall.Color = CAMP_CONFIG.WALL_COLOR
		wall.Material = CAMP_CONFIG.WALL_MATERIAL
		wall.TopSurface = Enum.SurfaceType.Smooth
		wall.BottomSurface = Enum.SurfaceType.Smooth
		
		table.insert(walls, wall)
	end
	
	return walls
end

-- Create gates in the walls
function BaseCampSetup:createGates(centerPos)
	local gates = {}
	local halfSize = CAMP_CONFIG.BASE_SIZE / 2
	local gateWidth = CAMP_CONFIG.GATE_WIDTH
	local gateHeight = CAMP_CONFIG.WALL_HEIGHT * 0.7 -- Gates slightly shorter than walls
	local thickness = CAMP_CONFIG.WALL_THICKNESS
	
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
		gate.Color = CAMP_CONFIG.GATE_COLOR
		gate.Material = CAMP_CONFIG.GATE_MATERIAL
		gate.Transparency = CAMP_CONFIG.GATE_TRANSPARENCY -- Semi-transparent to show as gates
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
	local coverRadius = CAMP_CONFIG.BASE_SIZE / 2 - 5 -- Place cover inside the walls
	local angleStep = (2 * math.pi) / CAMP_CONFIG.COVER_COUNT
	
	for i = 1, CAMP_CONFIG.COVER_COUNT do
		local angle = angleStep * (i - 1)
		local offsetX = math.cos(angle) * coverRadius
		local offsetZ = math.sin(angle) * coverRadius
		
		local cover = Instance.new("Part")
		cover.Name = "Cover_" .. i
		cover.Size = CAMP_CONFIG.COVER_SIZE
		cover.Position = centerPos + Vector3.new(offsetX, CAMP_CONFIG.COVER_SIZE.Y/2, offsetZ)
		cover.Anchored = true
		cover.Color = CAMP_CONFIG.COVER_COLOR
		cover.Material = CAMP_CONFIG.COVER_MATERIAL
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
	hitBox.Size = Vector3.new(CAMP_CONFIG.BASE_SIZE - 4, CAMP_CONFIG.WALL_HEIGHT - 2, CAMP_CONFIG.BASE_SIZE - 4)
	hitBox.Position = centerPos + Vector3.new(0, CAMP_CONFIG.WALL_HEIGHT/2, 0)
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
	
	-- Parent all parts to the base camp model
	platform.Parent = baseCamp
	
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
function BaseCampSetup:cleanup()
	if self.baseCampModel and self.baseCampModel.Parent then
		self.baseCampModel:Destroy()
	end
	
	-- Also clean up BaseCaptureZone
	local existingZone = workspace:FindFirstChild("BaseCaptureZone")
	if existingZone then
		existingZone:Destroy()
	end
	
	-- Clean up any existing BaseCamp in workspace
	local existingCamp = workspace:FindFirstChild("BaseCamp")
	if existingCamp then
		existingCamp:Destroy()
	end
	
	self.baseCampModel = nil
end

return BaseCampSetup
