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
		if defaultId and defaultId ~= id and defaultData then
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
		if defaultId and defaultId ~= id and defaultData then
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

	local root = self.currentMapModel or workspace

	-- Extract zombie spawn points
	local spawnFolder = root:FindFirstChild("ZombieSpawnPoints")
	if spawnFolder then
		collectPointsFromFolder(self.zombieSpawnPoints, spawnFolder)
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

	-- Fallback if no zombie spawn points provided on the active map
	if #self.zombieSpawnPoints == 0 then
		local defaultFolder = workspace:FindFirstChild("ZombieSpawnPoints")
		if defaultFolder then
			collectPointsFromFolder(self.zombieSpawnPoints, defaultFolder)
		end
	end

	-- Fallback if no resource spawn points provided on the active map
	if #self.resourceSpawnPoints == 0 then
		local defaultResourceFolder = workspace:FindFirstChild("ResourceSpawnPoints")
		if defaultResourceFolder then
			collectPointsFromFolder(self.resourceSpawnPoints, defaultResourceFolder)
		end
	end
	
	-- Log spawn point counts
	local mapName = self.currentMapId or "Workspace"
	print(string.format("[MapManager] Spawn points extracted for '%s':", mapName))
	print(string.format("  - Zombie spawns: %d", #self.zombieSpawnPoints))
	print(string.format("  - Resource spawns: %d", #self.resourceSpawnPoints))
	print(string.format("  - Item spawns: %d", #self.itemSpawnPoints))
	
	-- Warn if spawn points are critically low
	if #self.zombieSpawnPoints == 0 then
		warn("[MapManager] WARNING: No zombie spawn points found! Zombies will not spawn correctly.")
	end
	if #self.resourceSpawnPoints == 0 then
		warn("[MapManager] WARNING: No resource spawn points found! Resources may not spawn optimally.")
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
