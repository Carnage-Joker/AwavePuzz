-- MapManager.lua
-- Loads and manages the active map for multi-map support

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.MapConfig)

local MapManager = {}
MapManager.__index = MapManager

function MapManager.new()
        local self = setmetatable({}, MapManager)
        self.currentMapId = nil
        self.currentMapModel = nil
        self.zombieSpawnPoints = {}
        self.resourceSpawnPoints = {}
        self:extractPoints()
        return self
end

function MapManager:load(mapId)
        local id = mapId
        local data = MapConfig.get(mapId)
        if not data then
                id, data = MapConfig.getDefault()
        end

        if not data then
                warn("No map data found, map manager fallback to workspace folders")
                self:extractPoints()
                return
        end

        self.currentMapId = id

        -- Clone model into workspace
        local mapsFolder = ServerStorage:FindFirstChild("Maps")
        if mapsFolder then
                local template = mapsFolder:FindFirstChild(data.Model)
                if template then
                        if self.currentMapModel then
                                self.currentMapModel:Destroy()
                        end
                        self.currentMapModel = template:Clone()
                        self.currentMapModel.Name = "ActiveMap"
                        self.currentMapModel.Parent = workspace
                else
                        warn("Map model " .. data.Model .. " missing in ServerStorage.Maps")
                end
        end

        self:extractPoints()
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
                for _, point in ipairs(spawnFolder:GetChildren()) do
                        if point:IsA("BasePart") then
                                table.insert(self.zombieSpawnPoints, point.Position)
                        elseif point:IsA("Attachment") then
                                table.insert(self.zombieSpawnPoints, point.WorldPosition)
                        elseif point:IsA("Model") and point.PrimaryPart then
                                table.insert(self.zombieSpawnPoints, point.PrimaryPart.Position)
                        end
                end
        end

        local resourceFolder = root:FindFirstChild("ResourceSpawnPoints")
        if resourceFolder then
                for _, point in ipairs(resourceFolder:GetChildren()) do
                        if point:IsA("BasePart") then
                                table.insert(self.resourceSpawnPoints, point.Position)
                        elseif point:IsA("Attachment") then
                                table.insert(self.resourceSpawnPoints, point.WorldPosition)
                        elseif point:IsA("Model") and point.PrimaryPart then
                                table.insert(self.resourceSpawnPoints, point.PrimaryPart.Position)
                        end
                end
        end

        -- Fallback if no spawn points provided
        if #self.zombieSpawnPoints == 0 then
                local defaultFolder = workspace:FindFirstChild("ZombieSpawnPoints")
                if defaultFolder then
                        for _, point in ipairs(defaultFolder:GetChildren()) do
                                if point:IsA("BasePart") then
                                        table.insert(self.zombieSpawnPoints, point.Position)
                                end
                        end
                end
        end

        if #self.resourceSpawnPoints == 0 then
                local defaultResourceFolder = workspace:FindFirstChild("ResourceSpawnPoints")
                if defaultResourceFolder then
                        for _, point in ipairs(defaultResourceFolder:GetChildren()) do
                                if point:IsA("BasePart") then
                                        table.insert(self.resourceSpawnPoints, point.Position)
                                end
                        end
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
