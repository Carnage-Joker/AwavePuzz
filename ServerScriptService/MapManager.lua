-- MapManager.lua
-- Loads and manages the active map for multi-map support

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local MapConfig = require(SharedFolder:WaitForChild("MapConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local BaseCampSetup = require(script.Parent:WaitForChild("BaseCampSetup"))

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
		elseif point:IsA("Model") then
			local primary = point.PrimaryPart
				or (point:IsA("Model") and point:GetPrimaryPartCFrame() and point.PrimaryPart)
			if primary then
				table.insert(outTable, primary.Position)
			end
		end
	end
end

function MapManager.new()
	local self = setmetatable({}, MapManager)
	self.currentMapId = nil
	self.currentMapModel = nil
	self.zombieSpawnPoints = {}
	self.resourceSpawnPoints = {}
	self.baseCampSetup = BaseCampSetup.new()
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
	else
		local template = mapsFolder:FindFirstChild(data.Model)
		if template then
			if self.currentMapModel and self.currentMapModel.Parent then
				self.currentMapModel:Destroy()
			end
			self.currentMapModel = template:Clone()
			self.currentMapModel.Name = "ActiveMap"
			self.currentMapModel.Parent = workspace
		else
			warn("[MapManager] Map model '" .. tostring(data.Model) .. "' missing in ServerStorage.Maps")
		end
	end

	self:extractPoints()
	
	-- Setup base camp after extracting spawn points (if enabled in config)
	if GameConfig.AUTO_CREATE_BASE_CAMP and #self.zombieSpawnPoints > 0 then
		self.baseCampSetup:setupForMap(self)
	elseif not GameConfig.AUTO_CREATE_BASE_CAMP then
		print("[MapManager] Auto base camp creation is disabled in GameConfig")
	else
		warn("[MapManager] No zombie spawn points found, skipping base camp setup")
	end
end

function MapManager:loadDefault()
	local defaultId = select(1, MapConfig.getDefault())
	self:load(defaultId)
end

function MapManager:extractPoints()
	self.zombieSpawnPoints = {}
	self.resourceSpawnPoints = {}

	local root = self.currentMapModel or workspace

	local spawnFolder = root:FindFirstChild("ZombieSpawnPoints")
	if spawnFolder then
		collectPointsFromFolder(self.zombieSpawnPoints, spawnFolder)
	end

	local resourceFolder = root:FindFirstChild("ResourceSpawnPoints")
	if resourceFolder then
		collectPointsFromFolder(self.resourceSpawnPoints, resourceFolder)
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
end

function MapManager:getZombieSpawnPoints()
	return self.zombieSpawnPoints
end

function MapManager:getResourceSpawnPoints()
	return self.resourceSpawnPoints
end

function MapManager:getCurrentMapId()
	return self.currentMapId
end

return MapManager
