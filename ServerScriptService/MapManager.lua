-- @ScriptType: ModuleScript
-- MapManager.lua
-- Loads and manages the active map for multi-map support
-- Fixes:
-- 1) Maps now load with their pivot placed at EXACTLY (5000,0,0) instead of "current + offset"
-- 2) No more noisy "Workspace" warnings on startup; only validates/logs when a map is actually loaded
-- 3) Uses :PivotTo() (preferred) and keeps rotation from the template pivot

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[MapManager] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local MapConfig = require(SharedFolder:WaitForChild("MapConfig", 5))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig", 5))
local BaseCampSetup = require(script.Parent:WaitForChild("BaseCampSetup", 5))
local MapValidator = require(script.Parent:WaitForChild("MapValidator", 5))

local MapManager = {}
MapManager.__index = MapManager

-- Desired world pivot position for ActiveMap
local MAP_PIVOT_POSITION = Vector3.new(5000, 0, 0)

-- Helper to check if we should attempt to load default map as fallback
local function shouldLoadDefaultMap(currentMapId, defaultMapId)
	return defaultMapId ~= nil and defaultMapId ~= currentMapId
end

local function collectPointsFromFolder(outTable, folder)
	if not folder then return end

	for _, point in ipairs(folder:GetChildren()) do
		if point:IsA("BasePart") then
			table.insert(outTable, point.Position)
		elseif point:IsA("Attachment") then
			table.insert(outTable, point.WorldPosition)
		elseif point:IsA("Model") and point.PrimaryPart then
			table.insert(outTable, point.PrimaryPart.Position)
		end
	end
end

-- Moves the cloned map so its pivot position becomes MAP_PIVOT_POSITION.
-- Keeps current rotation from template.
local function pivotMapModelTo(model, desiredPos)
	if not model then return end

	-- GetPivot works for Models even without PrimaryPart
	local currentPivot = model:GetPivot()
	local currentPos = currentPivot.Position

	-- Preserve rotation, change translation only
	local rotationOnly = currentPivot - currentPos
	local desiredPivot = rotationOnly + desiredPos

	model:PivotTo(desiredPivot)
end

function MapManager.new()
	local self = setmetatable({}, MapManager)

	self.currentMapId = nil
	self.currentMapModel = nil

	self.zombieSpawnPoints = {}
	self.resourceSpawnPoints = {}
	self.itemSpawnPoints = {}

	self.baseCampSetup = nil
	
	-- Spawn point cache: mapId -> {zombie, resource, item}
	-- Reduces redundant folder traversal on map transitions
	self.spawnPointCache = {}

	-- IMPORTANT: do NOT extract from workspace here.
	-- That’s what was causing the noisy "Workspace has no spawn points" warnings on server boot.
	return self
end

function MapManager:load(mapId)
	local id, data

	if mapId ~= nil then
		id = mapId
		data = MapConfig.get(mapId)
	end

	if not data then
		id, data = MapConfig.getDefault()
	end

	if not data then
		warn("[MapManager] No map data found. No map loaded.")
		self.currentMapId = nil
		self.currentMapModel = nil
		self:extractPoints(true) -- silent
		return false
	end

	self.currentMapId = id

	-- Clone model into workspace from ServerStorage.Maps
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("[MapManager] Maps folder missing in ServerStorage")
		self.currentMapId = nil
		self.currentMapModel = nil
		self:extractPoints(true)
		return false
	end

	local template = mapsFolder:FindFirstChild(data.Model)
	if not template then
		warn(string.format("[MapManager] Map model '%s' missing in ServerStorage.Maps, falling back to default", tostring(data.Model)))

		local defaultId, defaultData = MapConfig.getDefault()
		if shouldLoadDefaultMap(id, defaultId) and defaultData then
			local defaultTemplate = mapsFolder:FindFirstChild(defaultData.Model)
			if defaultTemplate then
				print("[MapManager] Loading default map: " .. tostring(defaultId))
				return self:load(defaultId)
			end
		end

		self.currentMapId = nil
		self.currentMapModel = nil
		self:extractPoints(true)
		return false
	end

	-- Validate the map model before loading
	local isValid, errors, warnings, counts = MapValidator.validateMapModel(template)
	MapValidator.logValidation(data.Model, isValid, errors, warnings, counts)

	if not isValid then
		warn(string.format("[MapManager] Map validation failed for '%s', attempting default map", tostring(data.Model)))
		local defaultId, defaultData = MapConfig.getDefault()
		if shouldLoadDefaultMap(id, defaultId) and defaultData then
			print("[MapManager] Falling back to default map: " .. tostring(defaultId))
			return self:load(defaultId)
		end

		self.currentMapId = nil
		self.currentMapModel = nil
		self:extractPoints(true)
		return false
	end

	-- Destroy previous active map
	if self.currentMapModel and self.currentMapModel.Parent then
		self.currentMapModel:Destroy()
	end

	-- Clone and place the new map
	self.currentMapModel = template:Clone()
	self.currentMapModel.Name = "ActiveMap"

	-- Reposition map so its pivot is exactly at (5000,0,0)
	pivotMapModelTo(self.currentMapModel, MAP_PIVOT_POSITION)

	-- Helpful attribute for debugging other systems (BaseCampSetup etc.)
	self.currentMapModel:SetAttribute("MapPivot", MAP_PIVOT_POSITION)

	self.currentMapModel.Parent = workspace

	-- Extract points from ActiveMap (not workspace)
	self:extractPoints(false)

	-- Setup base camp after extracting spawn points (if enabled)
	if not GameConfig.AUTO_CREATE_BASE_CAMP then
		print("[MapManager] Auto base camp creation is disabled in GameConfig")
	elseif #self.zombieSpawnPoints == 0 then
		warn("[MapManager] No zombie spawn points found, skipping base camp setup")
	else
		if self.baseCampSetup then
			self.baseCampSetup:cleanup()
		end

		self.baseCampSetup = BaseCampSetup.new(data)
		self.baseCampSetup:setupForMap(self)
	end
	
	return true
end

function MapManager:loadDefault()
	local defaultId = select(1, MapConfig.getDefault())
	return self:load(defaultId)
end

-- silent=true prevents warnings/log spam (used only for fallback/no-map situations)
function MapManager:extractPoints(silent)
	-- Check cache first
	if self.currentMapId and self.spawnPointCache[self.currentMapId] then
		local cached = self.spawnPointCache[self.currentMapId]
		self.zombieSpawnPoints = cached.zombie
		self.resourceSpawnPoints = cached.resource
		self.itemSpawnPoints = cached.item
		
		if not silent then
			print(string.format("[MapManager] Loaded cached spawn points for '%s'", self.currentMapId))
			print(string.format("  - Zombie spawn points: %d", #self.zombieSpawnPoints))
			print(string.format("  - Resource spawn points: %d", #self.resourceSpawnPoints))
			print(string.format("  - Item spawn points: %d", #self.itemSpawnPoints))
		end
		return
	end
	
	-- Not in cache, extract from map
	self.zombieSpawnPoints = {}
	self.resourceSpawnPoints = {}
	self.itemSpawnPoints = {}

	local usingActiveMap = (self.currentMapModel ~= nil)
	local root = self.currentMapModel
	local mapName = self.currentMapId or "None"

	-- If no ActiveMap, do nothing (don't fall back to workspace by default).
	-- This stops the "Workspace has no spawn points" spam at startup.
	if not usingActiveMap then
		if not silent then
			print("[MapManager] No ActiveMap loaded; spawn points remain empty.")
		end
		return
	end

	-- Zombie spawns
	local zombieFolder = root:FindFirstChild("ZombieSpawnPoints")
	if zombieFolder then
		collectPointsFromFolder(self.zombieSpawnPoints, zombieFolder)
	elseif not silent then
		warn(string.format("[MapManager] ActiveMap '%s' missing ZombieSpawnPoints folder", tostring(mapName)))
	end

	-- Resource spawns (legacy + standard)
	local resourceFolderLegacy = root:FindFirstChild("ResourceSpawnPoints")
	if resourceFolderLegacy then
		collectPointsFromFolder(self.resourceSpawnPoints, resourceFolderLegacy)
	end

	local spawnPointsFolder = root:FindFirstChild("SpawnPoints")
	if spawnPointsFolder then
		local resourceSpawns = spawnPointsFolder:FindFirstChild("ResourceSpawns")
		if resourceSpawns then
			collectPointsFromFolder(self.resourceSpawnPoints, resourceSpawns)
		end

		local itemSpawns = spawnPointsFolder:FindFirstChild("ItemSpawns")
		if itemSpawns then
			collectPointsFromFolder(self.itemSpawnPoints, itemSpawns)
		end
	end
	
	-- Cache the spawn points for this map
	if self.currentMapId then
		-- Use table.clone to avoid unintended mutations
		self.spawnPointCache[self.currentMapId] = {
			zombie = table.clone(self.zombieSpawnPoints),
			resource = table.clone(self.resourceSpawnPoints),
			item = table.clone(self.itemSpawnPoints)
		}
		if not silent then
			print(string.format("[MapManager] Cached spawn points for '%s'", self.currentMapId))
		end
	end

	-- Log counts
	if not silent then
		print(string.format("[MapManager] Loaded map '%s':", tostring(mapName)))
		print(string.format("  - Zombie spawn points: %d", #self.zombieSpawnPoints))
		print(string.format("  - Resource spawn points: %d", #self.resourceSpawnPoints))
		print(string.format("  - Item spawn points: %d", #self.itemSpawnPoints))

		if #self.zombieSpawnPoints == 0 then
			warn(string.format("[MapManager] WARNING: No zombie spawn points found for '%s'!", tostring(mapName)))
		end
		if #self.resourceSpawnPoints == 0 then
			warn(string.format("[MapManager] WARNING: No resource spawn points found for '%s'!", tostring(mapName)))
		end
	end
end

function MapManager:getZombieSpawnPoints()
	return self.zombieSpawnPoints
end

function MapManager:getResourceSpawnPoints()
	return self.resourceSpawnPoints
end

function MapManager:getItemSpawnPoints()
	return self.itemSpawnPoints
end

function MapManager:getCurrentMapId()
	return self.currentMapId
end

return MapManager
