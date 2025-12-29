-- MapManager.lua
-- Loads and manages the active map for multi-map support

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local MapConfig = require(SharedFolder:WaitForChild("MapConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local BaseCampSetup = require(script.Parent:WaitForChild("BaseCampSetup"))
local MapValidator = require(script.Parent:WaitForChild("MapValidator"))

local MapManager = {}
MapManager.__index = MapManager

-- Helper to check if we should attempt to load default map as fallback
local function shouldLoadDefaultMap(currentMapId, defaultMapId)
	-- Don't load default if it's the same as current (avoid recursion)
	-- Don't load default if there is no default
	return defaultMapId ~= nil and defaultMapId ~= currentMapId
end

local function collectPointsFromFolder(outTable, folder)
	if not folder then
		return
	end

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

function MapManager.new()
	local self = setmetatable({}, MapManager)
	self.currentMapId = nil
	self.currentMapModel = nil
	self.zombieSpawnPoints = {}
	self.resourceSpawnPoints = {}
	self.itemSpawnPoints = {}
	self.baseCampSetup = nil -- Will be created when loading a map
	self:extractPoints()
	return self
end

function MapManager:load(mapId)
	local id
	local data

	if mapId ~= nil then
		id = mapId
		data = MapConfig.get(mapId)
	end

	if not data then
		id, data = MapConfig.getDefault()
	end

	if not data then
		warn("[MapManager] No map data found, falling back to workspace spawn folders")
		self.currentMapId = nil
		self:extractPoints()
		return
	end

	self.currentMapId = id

	-- Clone model into workspace
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("[MapManager] Maps folder missing in ServerStorage")
		self:extractPoints()
		return
	end
	
	local template = mapsFolder:FindFirstChild(data.Model)
	if not template then
		warn("[MapManager] Map model '" .. tostring(data.Model) .. "' missing in ServerStorage.Maps, falling back to default")
		-- Try to load default map instead (but avoid infinite recursion)
		local defaultId, defaultData = MapConfig.getDefault()
		if shouldLoadDefaultMap(id, defaultId) and defaultData then
			local defaultTemplate = mapsFolder:FindFirstChild(defaultData.Model)
			if defaultTemplate then
				print("[MapManager] Loading default map: " .. defaultId)
				self:load(defaultId)
				return
			end
		end
		-- If default also fails or is the same as current, use workspace spawn points
		self.currentMapId = nil
		self:extractPoints()
		return
	end
	
	-- Validate the map model before loading
	local isValid, errors, warnings, counts = MapValidator.validateMapModel(template)
	MapValidator.logValidation(data.Model, isValid, errors, warnings, counts)
	
	if not isValid then
		warn("[MapManager] Map validation failed for '" .. data.Model .. "', attempting to load default map")
		local defaultId, defaultData = MapConfig.getDefault()
		if shouldLoadDefaultMap(id, defaultId) and defaultData then
			print("[MapManager] Falling back to default map: " .. defaultId)
			self:load(defaultId)
			return
		else
			warn("[MapManager] No valid default map available or default is current map, using workspace spawn points")
			self.currentMapId = nil
			self:extractPoints()
			return
		end
	end
	
	-- Destroy previous map model if exists
	if self.currentMapModel and self.currentMapModel.Parent then
		self.currentMapModel:Destroy()
	end
	
	-- Clone and place the new map
	self.currentMapModel = template:Clone()
	self.currentMapModel.Name = "ActiveMap"
	self.currentMapModel.Parent = workspace

	self:extractPoints()
	
	-- Setup base camp after extracting spawn points (if enabled in config)
	if not GameConfig.AUTO_CREATE_BASE_CAMP then
		print("[MapManager] Auto base camp creation is disabled in GameConfig")
	elseif #self.zombieSpawnPoints == 0 then
		warn("[MapManager] No zombie spawn points found, skipping base camp setup")
	else
		-- Clean up previous BaseCampSetup before creating a new one
		if self.baseCampSetup then
			self.baseCampSetup:cleanup()
		end
		
		-- Create new BaseCampSetup with map-specific config
		self.baseCampSetup = BaseCampSetup.new(data)
		self.baseCampSetup:setupForMap(self)
	end
end

function MapManager:loadDefault()
	local defaultId = select(1, MapConfig.getDefault())
	self:load(defaultId)
end

function MapManager:extractPoints()
	self.zombieSpawnPoints = {}
	self.resourceSpawnPoints = {}
	self.itemSpawnPoints = {}

	-- Determine root: ActiveMap takes priority, workspace is fallback only
	local root = self.currentMapModel or workspace
	local mapName = self.currentMapId or "Workspace"
	local usingActiveMap = (self.currentMapModel ~= nil)

	-- Extract zombie spawn points from ActiveMap
	local spawnFolder = root:FindFirstChild("ZombieSpawnPoints")
	if spawnFolder then
		collectPointsFromFolder(self.zombieSpawnPoints, spawnFolder)
	elseif usingActiveMap then
		-- Only warn if we're using ActiveMap and folder is missing
		warn(string.format("[MapManager] ActiveMap '%s' missing ZombieSpawnPoints folder. Expected: workspace.ActiveMap.ZombieSpawnPoints", mapName))
	end

	-- Fallback to workspace only if ActiveMap doesn't have the folder
	if #self.zombieSpawnPoints == 0 and not spawnFolder then
		local workspaceFolder = workspace:FindFirstChild("ZombieSpawnPoints")
		if workspaceFolder then
			collectPointsFromFolder(self.zombieSpawnPoints, workspaceFolder)
			print(string.format("[MapManager] Using workspace.ZombieSpawnPoints as fallback for '%s'", mapName))
		end
	end

	-- Extract resource spawn points - check both conventions
	-- 1. Legacy convention: ResourceSpawnPoints folder
	local resourceFolder = root:FindFirstChild("ResourceSpawnPoints")
	if resourceFolder then
		collectPointsFromFolder(self.resourceSpawnPoints, resourceFolder)
	end
	
	-- 2. Standard convention: SpawnPoints/ResourceSpawns
	local spawnPointsFolder = root:FindFirstChild("SpawnPoints")
	if spawnPointsFolder then
		local resourceSpawns = spawnPointsFolder:FindFirstChild("ResourceSpawns")
		if resourceSpawns then
			collectPointsFromFolder(self.resourceSpawnPoints, resourceSpawns)
		end
		
		-- Extract item spawn points from standard convention
		local itemSpawns = spawnPointsFolder:FindFirstChild("ItemSpawns")
		if itemSpawns then
			collectPointsFromFolder(self.itemSpawnPoints, itemSpawns)
		end
	end

	-- Warn if resource spawn points missing in ActiveMap
	if usingActiveMap and #self.resourceSpawnPoints == 0 then
		if not resourceFolder and not (spawnPointsFolder and spawnPointsFolder:FindFirstChild("ResourceSpawns")) then
			warn(string.format("[MapManager] ActiveMap '%s' missing resource spawn folders. Expected: workspace.ActiveMap.ResourceSpawnPoints or workspace.ActiveMap.SpawnPoints.ResourceSpawns", mapName))
		end
	end

	-- Helper: apply workspace fallback for spawn points when ActiveMap folders are missing
	local function applyWorkspaceSpawnFallback(spawnPointsArray, primaryFolderName, spawnPointsFolderName, subFolderName, mapId)
		local workspacePrimaryFolder = workspace:FindFirstChild(primaryFolderName)
		if workspacePrimaryFolder then
			collectPointsFromFolder(spawnPointsArray, workspacePrimaryFolder)
			print(string.format("[MapManager] Using workspace.%s as fallback for '%s'", primaryFolderName, mapId))
			return
		end

		-- Check workspace SpawnPoints/<subFolderName>
		local workspaceSpawnPoints = workspace:FindFirstChild(spawnPointsFolderName)
		if workspaceSpawnPoints then
			local subFolder = workspaceSpawnPoints:FindFirstChild(subFolderName)
			if subFolder then
				collectPointsFromFolder(spawnPointsArray, subFolder)
				print(string.format("[MapManager] Using workspace.%s.%s as fallback for '%s'", spawnPointsFolderName, subFolderName, mapId))
			end
		end
	end

	-- Fallback to workspace only if ActiveMap doesn't have resource spawn folders
	if #self.resourceSpawnPoints == 0 and not resourceFolder and not (spawnPointsFolder and spawnPointsFolder:FindFirstChild("ResourceSpawns")) then
		applyWorkspaceSpawnFallback(
			self.resourceSpawnPoints,
			"ResourceSpawnPoints",
			"SpawnPoints",
			"ResourceSpawns",
			mapName
		)
	end
	
	-- Log spawn point counts
	print(string.format("[MapManager] Loaded map '%s':", mapName))
	print(string.format("  - Zombie spawn points: %d", #self.zombieSpawnPoints))
	print(string.format("  - Resource spawn points: %d", #self.resourceSpawnPoints))
	print(string.format("  - Item spawn points: %d", #self.itemSpawnPoints))
	
	-- Warn if spawn points are critically low
	if #self.zombieSpawnPoints == 0 then
		warn(string.format("[MapManager] WARNING: No zombie spawn points found for '%s'! Zombies will not spawn correctly.", mapName))
	end
	if #self.resourceSpawnPoints == 0 then
		warn(string.format("[MapManager] WARNING: No resource spawn points found for '%s'! Resources will not spawn.", mapName))
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
