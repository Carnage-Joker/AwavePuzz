-- @ScriptType: ModuleScript
-- BaseCampSetup.lua
-- Creates and configures a defensive base camp in the center of the map
-- Updated:
-- - Center is derived from map bounds (ActiveMap bounding box or MapBounds) instead of averaging zombie spawns.
-- - Raycasts down to find ground from that true center.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BaseCampSetup = {}
BaseCampSetup.__index = BaseCampSetup

-- Get base camp configuration with optional map-specific overrides
-- mapConfig: optional table from MapConfig containing BaseCampConfig overrides
local function getCampConfig(mapConfig)
	local config = {}
	for key, value in pairs(GameConfig.BASE_CAMP) do
		config[key] = value
	end

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
	self.baseCaptureZoneModel = nil
	self.campConfig = getCampConfig(mapConfig)
	return self
end

---------------------------------------------------------------------
-- Center + Grounding
---------------------------------------------------------------------

local function raycastToGround(origin, includeInstances)
	local rayDirection = Vector3.new(0, -5000, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = includeInstances or {}
	params.IgnoreWater = true
	return Workspace:Raycast(origin, rayDirection, params)
end


-- Derive a good "map center" from ActiveMap bounds.
-- Preference:
-- 1) ActiveMap.MapBounds (Part or Model with bounding box)
-- 2) ActiveMap:GetBoundingBox()
function BaseCampSetup:calculateMapCenterFromMap(mapModel)
	if not mapModel then
		return Vector3.new(0, self.campConfig.DEFAULT_HEIGHT, 0)
	end

	local centerX, centerY, centerZ

	-- If map provides MapBounds, use it
	local mapBounds = mapModel:FindFirstChild("MapBounds")
	if mapBounds then
		if mapBounds:IsA("BasePart") then
			local pos = mapBounds.Position
			centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
		elseif mapBounds:IsA("Model") then
			local cf = mapBounds:GetBoundingBox()
			local pos = cf.Position
			centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
		else
			-- fallback to whole map bbox
			local cf = mapModel:GetBoundingBox()
			local pos = cf.Position
			centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
		end
	else
		local cf = mapModel:GetBoundingBox()
		local pos = cf.Position
		centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
	end

	-- Ground it with raycast
	-- Ground it by raycasting INTO the map (or MapBounds) only
	local rayOrigin = Vector3.new(centerX, centerY + 500, centerZ)

	local include = {}
	local mapBounds = mapModel:FindFirstChild("MapBounds")
	if mapBounds then
		table.insert(include, mapBounds)
	else
		table.insert(include, mapModel)
	end

	local hit = raycastToGround(rayOrigin, include)
	if hit then
		centerY = hit.Position.Y + 0.5
	else
		centerY = self.campConfig.DEFAULT_HEIGHT
	end

	return Vector3.new(centerX, centerY, centerZ)
end

---------------------------------------------------------------------
-- Build Pieces
---------------------------------------------------------------------

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

function BaseCampSetup:createWalls(centerPos)
	local walls = {}
	local halfSize = self.campConfig.BASE_SIZE / 2
	local wallHeight = self.campConfig.WALL_HEIGHT
	local thickness = self.campConfig.WALL_THICKNESS
	local gateWidth = self.campConfig.GATE_WIDTH
	
	-- Calculate wall segment dimensions
	-- Each wall is split into two segments with a gap for the gate in the center
	local wallSegmentLength = (self.campConfig.BASE_SIZE - gateWidth) / 2
	-- segmentOffset positions the segments correctly so the gap aligns with gates
	local segmentOffset = (wallSegmentLength + gateWidth) / 2

	-- All wall segment configurations
	-- North/South walls split left/right, East/West walls split top/bottom
	local wallConfigs = {
		-- North wall segments (split left and right with gap in center)
		{name = "NorthWallLeft", size = Vector3.new(wallSegmentLength, wallHeight, thickness), offset = Vector3.new(-segmentOffset, wallHeight/2, halfSize)},
		{name = "NorthWallRight", size = Vector3.new(wallSegmentLength, wallHeight, thickness), offset = Vector3.new(segmentOffset, wallHeight/2, halfSize)},
		
		-- South wall segments (split left and right with gap in center)
		{name = "SouthWallLeft", size = Vector3.new(wallSegmentLength, wallHeight, thickness), offset = Vector3.new(-segmentOffset, wallHeight/2, -halfSize)},
		{name = "SouthWallRight", size = Vector3.new(wallSegmentLength, wallHeight, thickness), offset = Vector3.new(segmentOffset, wallHeight/2, -halfSize)},
		
		-- East wall segments (split top and bottom with gap in center)
		{name = "EastWallTop", size = Vector3.new(thickness, wallHeight, wallSegmentLength), offset = Vector3.new(halfSize, wallHeight/2, segmentOffset)},
		{name = "EastWallBottom", size = Vector3.new(thickness, wallHeight, wallSegmentLength), offset = Vector3.new(halfSize, wallHeight/2, -segmentOffset)},
		
		-- West wall segments (split top and bottom with gap in center)
		{name = "WestWallTop", size = Vector3.new(thickness, wallHeight, wallSegmentLength), offset = Vector3.new(-halfSize, wallHeight/2, segmentOffset)},
		{name = "WestWallBottom", size = Vector3.new(thickness, wallHeight, wallSegmentLength), offset = Vector3.new(-halfSize, wallHeight/2, -segmentOffset)},
	}

	-- Create all wall segments
	for _, cfg in ipairs(wallConfigs) do
		local wall = Instance.new("Part")
		wall.Name = cfg.name
		wall.Size = cfg.size
		wall.Position = centerPos + cfg.offset
		wall.Anchored = true
		wall.Color = self.campConfig.WALL_COLOR
		wall.Material = self.campConfig.WALL_MATERIAL
		wall.TopSurface = Enum.SurfaceType.Smooth
		wall.BottomSurface = Enum.SurfaceType.Smooth
		table.insert(walls, wall)
	end

	return walls
end

function BaseCampSetup:createGates(centerPos)
	local gates = {}
	local halfSize = self.campConfig.BASE_SIZE / 2
	local gateWidth = self.campConfig.GATE_WIDTH
	local gateHeight = self.campConfig.WALL_HEIGHT * 0.7
	local thickness = self.campConfig.WALL_THICKNESS

	local gateConfigs = {
		{name = "NorthGate", size = Vector3.new(gateWidth, gateHeight, thickness), offset = Vector3.new(0, gateHeight/2, halfSize)},
		{name = "SouthGate", size = Vector3.new(gateWidth, gateHeight, thickness), offset = Vector3.new(0, gateHeight/2, -halfSize)},
		{name = "EastGate",  size = Vector3.new(thickness, gateHeight, gateWidth), offset = Vector3.new(halfSize, gateHeight/2, 0)},
		{name = "WestGate",  size = Vector3.new(thickness, gateHeight, gateWidth), offset = Vector3.new(-halfSize, gateHeight/2, 0)},
	}

	for _, cfg in ipairs(gateConfigs) do
		local gate = Instance.new("Part")
		gate.Name = cfg.name
		gate.Size = cfg.size
		gate.Position = centerPos + cfg.offset
		gate.Anchored = true
		gate.Color = self.campConfig.GATE_COLOR
		gate.Material = self.campConfig.GATE_MATERIAL
		gate.Transparency = self.campConfig.GATE_TRANSPARENCY
		gate.CanCollide = false
		gate.TopSurface = Enum.SurfaceType.Smooth
		gate.BottomSurface = Enum.SurfaceType.Smooth
		gate:SetAttribute("IsGate", true)
		table.insert(gates, gate)
	end

	return gates
end

function BaseCampSetup:createCover(centerPos)
	local coverObjects = {}
	local coverRadius = self.campConfig.BASE_SIZE / 2 - 5
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
		cover.CFrame = CFrame.new(cover.Position) * CFrame.Angles(0, angle, 0)

		table.insert(coverObjects, cover)
	end

	return coverObjects
end

function BaseCampSetup:createBaseCaptureZone(centerPos)
	local baseCaptureZone = Instance.new("Model")
	baseCaptureZone.Name = "BaseCaptureZone"

	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(self.campConfig.BASE_SIZE - 4, self.campConfig.WALL_HEIGHT - 2, self.campConfig.BASE_SIZE - 4)
	hitBox.Position = centerPos + Vector3.new(0, self.campConfig.WALL_HEIGHT/2, 0)
	hitBox.Anchored = true
	hitBox.Transparency = 1
	hitBox.CanCollide = false
	hitBox.Parent = baseCaptureZone

	baseCaptureZone.PrimaryPart = hitBox

	local healthValue = Instance.new("NumberValue")
	healthValue.Name = "Health"
	healthValue.Value = GameConfig.BASE_HEALTH
	healthValue.Parent = baseCaptureZone

	return baseCaptureZone
end

function BaseCampSetup:buildBaseCamp(centerPos, parentModel)
	local baseCamp = Instance.new("Model")
	baseCamp.Name = "BaseCamp"

	local platform = self:createBasePlatform(centerPos)
	local walls = self:createWalls(centerPos)
	local gates = self:createGates(centerPos)
	local cover = self:createCover(centerPos)
	local baseCaptureZone = self:createBaseCaptureZone(centerPos)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "BaseCampSpawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = centerPos + Vector3.new(0, 0.5, 0)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.Transparency = 1
	spawnLocation.Duration = 0
	spawnLocation.Neutral = true

	platform.Parent = baseCamp
	spawnLocation.Parent = baseCamp
	for _, wall in ipairs(walls) do wall.Parent = baseCamp end
	for _, gate in ipairs(gates) do gate.Parent = baseCamp end
	for _, coverObj in ipairs(cover) do coverObj.Parent = baseCamp end

	baseCamp.PrimaryPart = platform

	if parentModel then
		baseCamp.Parent = parentModel
	else
		baseCamp.Parent = Workspace
	end

	baseCaptureZone.Parent = Workspace

	self.baseCampModel = baseCamp
	self.baseCaptureZoneModel = baseCaptureZone

	print("[BaseCampSetup] Base camp created at position:", centerPos)

	return baseCamp, baseCaptureZone
end

function BaseCampSetup:setupForMap(mapManager)
	self:cleanup()

	-- Prefer a true map center from ActiveMap bounds.
	local activeMap = mapManager and mapManager.currentMapModel
	local centerPos = self:calculateMapCenterFromMap(activeMap)

	local baseCamp, baseCaptureZone = self:buildBaseCamp(centerPos)
	
	-- If base camp failed to build, create emergency spawn
	if not baseCamp or not baseCaptureZone then
		warn("[BaseCampSetup] Base camp setup failed. Creating emergency spawn point.")
		self:ensureFallbackSpawn(centerPos)
	end

	print("[BaseCampSetup] Base camp setup complete for map:", mapManager and mapManager:getCurrentMapId() or "Unknown")

	return baseCamp, baseCaptureZone
end

-- Create emergency spawn point if base camp setup fails
function BaseCampSetup:ensureFallbackSpawn(centerPos)
	-- Check if there's already a spawn location
	local existingSpawn = Workspace:FindFirstChild("EmergencySpawn")
	if existingSpawn then
		return existingSpawn
	end
	
	warn("[BaseCampSetup] No base camp exists. Creating emergency spawn point at map center.")
	local emergencySpawn = Instance.new("SpawnLocation")
	emergencySpawn.Name = "EmergencySpawn"
	-- Use provided centerPos or default to map offset
	local spawnPos = centerPos or Vector3.new(5000, 5, 0)
	emergencySpawn.Position = spawnPos
	emergencySpawn.Anchored = true
	emergencySpawn.Size = Vector3.new(10, 1, 10)
	emergencySpawn.BrickColor = BrickColor.new("Bright yellow")
	emergencySpawn.Material = Enum.Material.SmoothPlastic
	emergencySpawn.Parent = Workspace
	
	print("[BaseCampSetup] Emergency spawn created at", spawnPos)
	return emergencySpawn
end

function BaseCampSetup:cleanup()
	if self.baseCampModel and self.baseCampModel.Parent then
		self.baseCampModel:Destroy()
	end
	self.baseCampModel = nil

	if self.baseCaptureZoneModel and self.baseCaptureZoneModel.Parent then
		self.baseCaptureZoneModel:Destroy()
	end
	self.baseCaptureZoneModel = nil
end

return BaseCampSetup
