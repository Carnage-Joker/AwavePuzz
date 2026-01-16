-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- BaseCampSetup.lua
-- Creates and configures a defensive base camp in the center of the map
-- Updated:
-- - Center is derived from map bounds (ActiveMap bounding box or MapBounds) instead of averaging zombie spawns.
-- - Raycasts down to find ground from that true center.
-- - Walls are now segmented to create REAL gate openings (no wall clipping through gates).
-- - Gates are now ACTUAL gates (collidable by default) placed in the openings.
-- - Includes helper to open/close gates by side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BaseCampSetup = {}
BaseCampSetup.__index = BaseCampSetup

-- Get base camp configuration with optional map-specific overrides
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
	self._gatesByName = {} -- "NorthGate" -> Part
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

function BaseCampSetup:calculateMapCenterFromMap(mapModel)
	if not mapModel then
		return Vector3.new(0, self.campConfig.DEFAULT_HEIGHT, 0)
	end

	local centerX, centerY, centerZ

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
			local cf = mapModel:GetBoundingBox()
			local pos = cf.Position
			centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
		end
	else
		local cf = mapModel:GetBoundingBox()
		local pos = cf.Position
		centerX, centerY, centerZ = pos.X, pos.Y, pos.Z
	end

	-- Ground it by raycasting INTO the map (or MapBounds) only
	local rayOrigin = Vector3.new(centerX, centerY + 500, centerZ)

	local include = {}
	local mapBounds2 = mapModel:FindFirstChild("MapBounds")
	if mapBounds2 then
		table.insert(include, mapBounds2)
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

-- Creates segmented walls with a real gap where the gate goes.
-- Two segments per side: left + right of opening (no wall crossing the gate).
function BaseCampSetup:createWalls(centerPos)
	local walls = {}

	local baseSize = self.campConfig.BASE_SIZE
	local halfSize = baseSize / 2
	local wallHeight = self.campConfig.WALL_HEIGHT
	local thickness = self.campConfig.WALL_THICKNESS

	local gateWidth = self.campConfig.GATE_WIDTH

	-- Clamp so we never get negative segment sizes
	gateWidth = math.clamp(gateWidth, 4, baseSize - 6)

	local segLen = (baseSize - gateWidth) / 2
	-- If segLen is too small, just make solid walls (fallback)
	if segLen < 2 then
		segLen = 2
	end

	local function makeWallPart(name, size, pos)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = size
		wall.Position = pos
		wall.Anchored = true
		wall.Color = self.campConfig.WALL_COLOR
		wall.Material = self.campConfig.WALL_MATERIAL
		wall.TopSurface = Enum.SurfaceType.Smooth
		wall.BottomSurface = Enum.SurfaceType.Smooth
		return wall
	end

	-- North/South walls run along X, thickness in Z
	-- Gap centered at X=0 on that wall.
	do
		local zNorth = halfSize
		local zSouth = -halfSize
		local y = wallHeight / 2

		-- Left segment
		local leftCenterX = -(gateWidth / 2 + segLen / 2)
		local rightCenterX = (gateWidth / 2 + segLen / 2)

		local sizeNS = Vector3.new(segLen, wallHeight, thickness)

		table.insert(walls, makeWallPart("NorthWall_L", sizeNS, centerPos + Vector3.new(leftCenterX, y, zNorth)))
		table.insert(walls, makeWallPart("NorthWall_R", sizeNS, centerPos + Vector3.new(rightCenterX, y, zNorth)))

		table.insert(walls, makeWallPart("SouthWall_L", sizeNS, centerPos + Vector3.new(leftCenterX, y, zSouth)))
		table.insert(walls, makeWallPart("SouthWall_R", sizeNS, centerPos + Vector3.new(rightCenterX, y, zSouth)))
	end

	-- East/West walls run along Z, thickness in X
	do
		local xEast = halfSize
		local xWest = -halfSize
		local y = wallHeight / 2

		local leftCenterZ = -(gateWidth / 2 + segLen / 2)
		local rightCenterZ = (gateWidth / 2 + segLen / 2)

		local sizeEW = Vector3.new(thickness, wallHeight, segLen)

		table.insert(walls, makeWallPart("EastWall_L", sizeEW, centerPos + Vector3.new(xEast, y, leftCenterZ)))
		table.insert(walls, makeWallPart("EastWall_R", sizeEW, centerPos + Vector3.new(xEast, y, rightCenterZ)))

		table.insert(walls, makeWallPart("WestWall_L", sizeEW, centerPos + Vector3.new(xWest, y, leftCenterZ)))
		table.insert(walls, makeWallPart("WestWall_R", sizeEW, centerPos + Vector3.new(xWest, y, rightCenterZ)))
	end

	return walls
end

-- Creates actual gates that occupy the opening.
-- Collidable by default, so you can spawn inside and walk out when opened.
function BaseCampSetup:createGates(centerPos)
	local gates = {}

	local baseSize = self.campConfig.BASE_SIZE
	local halfSize = baseSize / 2
	local wallHeight = self.campConfig.WALL_HEIGHT
	local thickness = self.campConfig.WALL_THICKNESS

	local gateWidth = self.campConfig.GATE_WIDTH
	gateWidth = math.clamp(gateWidth, 4, baseSize - 6)

	local function makeGatePart(name, size, pos)
		local gate = Instance.new("Part")
		gate.Name = name
		gate.Size = size
		gate.Position = pos
		gate.Anchored = true
		gate.CanCollide = false

		gate.Color = self.campConfig.GATE_COLOR
		gate.Material = self.campConfig.GATE_MATERIAL

		gate.Transparency = self.campConfig.GATE_TRANSPARENCY or 0
		-- IMPORTANT: gate is the thing that blocks, not the wall behind it
		gate.TopSurface = Enum.SurfaceType.Smooth
		gate.BottomSurface = Enum.SurfaceType.Smooth

		gate:SetAttribute("IsGate", true)
		gate:SetAttribute("Open", false)

		self._gatesByName[name] = gate
		return gate
	end

	-- North/South (width in X, thickness in Z)
	do
		local y = wallHeight / 2
		table.insert(gates, makeGatePart("NorthGate", Vector3.new(gateWidth, wallHeight, thickness), centerPos + Vector3.new(0, y, halfSize)))
		table.insert(gates, makeGatePart("SouthGate", Vector3.new(gateWidth, wallHeight, thickness), centerPos + Vector3.new(0, y, -halfSize)))
	end

	-- East/West (width in Z, thickness in X)
	do
		local y = wallHeight / 2
		table.insert(gates, makeGatePart("EastGate", Vector3.new(thickness, wallHeight, gateWidth), centerPos + Vector3.new(halfSize, y, 0)))
		table.insert(gates, makeGatePart("WestGate", Vector3.new(thickness, wallHeight, gateWidth), centerPos + Vector3.new(-halfSize, y, 0)))
	end

	return gates
end

-- Optional helper: open/close a gate cleanly.
-- "North"|"South"|"East"|"West"
function BaseCampSetup:setGateOpen(side, isOpen)
	if not side then return end
	local name = tostring(side) .. "Gate"
	local gate = self._gatesByName[name]
	if not gate then return end

	local open = (isOpen and true or false)
	gate:SetAttribute("Open", open)

	-- Simple behaviour: opening makes it non-collidable and mostly invisible.
	-- If you want a sliding/hinged animation later, we can tween CFrame instead.
	if open then
		gate.CanCollide = false
		gate.Transparency = math.max(gate.Transparency, 0.85)
	else
		gate.CanCollide = true
		gate.Transparency = self.campConfig.GATE_TRANSPARENCY or 0
	end
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

	local activeMap = mapManager and mapManager.currentMapModel
	local centerPos = self:calculateMapCenterFromMap(activeMap)

	local baseCamp, baseCaptureZone = self:buildBaseCamp(centerPos)

	print("[BaseCampSetup] Base camp setup complete for map:", mapManager and mapManager:getCurrentMapId() or "Unknown")

	return baseCamp, baseCaptureZone
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

	self._gatesByName = {}
end

return BaseCampSetup
