-- ResourceSpawner.lua
-- Manages spawning of cure components around the map and awards inventory items on pickup

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ResourceSpawner = {}
ResourceSpawner.__index = ResourceSpawner

function ResourceSpawner.new(playerManager)
        local self = setmetatable({}, ResourceSpawner)
        self.playerManager = playerManager
        self.activeResources = {}
        self.spawnTimer = 0
        self.spawnPoints = {} -- Populated by MapManager
        self.resourceFolder = workspace:FindFirstChild("CureResources")
        if not self.resourceFolder then
                self.resourceFolder = Instance.new("Folder")
                self.resourceFolder.Name = "CureResources"
                self.resourceFolder.Parent = workspace
        end
        return self
end

function ResourceSpawner:setSpawnPoints(points)
        self.spawnPoints = points or {}
end

function ResourceSpawner:addSpawnPoint(position)
        table.insert(self.spawnPoints, position)
end

function ResourceSpawner:getRandomComponent()
        local components = GameConfig.CURE_COMPONENT_NAMES
        return components[math.random(1, #components)]
end

function ResourceSpawner:getRandomSpawnPoint()
        if #self.spawnPoints == 0 then
                return nil
        end
        return self.spawnPoints[math.random(1, #self.spawnPoints)]
end

function ResourceSpawner:spawnResource()
        if self:getActiveResourceCount() >= GameConfig.MAX_RESOURCES_ON_MAP then
                return nil
        end

        local spawnPoint = self:getRandomSpawnPoint()
        if not spawnPoint then
                return nil
        end

        local componentName = self:getRandomComponent()
        local resourceId = "resource_" .. os.time() .. "_" .. math.random(1000, 9999)

        local part = Instance.new("Part")
        part.Name = componentName .. "_Resource"
        part.Color = Color3.fromRGB(85, 170, 255)
        part.Material = Enum.Material.Neon
        part.Size = Vector3.new(2, 0.5, 2)
        part.Position = spawnPoint + Vector3.new(0, 2, 0)
        part.Anchored = true
        part.CanCollide = false
        part:SetAttribute("ComponentName", componentName)
        part.Parent = self.resourceFolder

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.AlwaysOnTop = true
        billboard.ExtentsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = part

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextStrokeTransparency = 0.5
        textLabel.TextScaled = true
        textLabel.Text = componentName
        textLabel.Parent = billboard

        local isCollecting = false
        local touchDetector
        touchDetector = part.Touched:Connect(function(hit)
                -- Debounce to prevent duplicate collection
                if isCollecting then
                        return
                end

                local character = hit and hit.Parent
                if not character then
                        return
                end
                local player = Players:GetPlayerFromCharacter(character)
                if not player then
                        return
                end

                isCollecting = true
                self:onResourceCollected(player, resourceId, componentName, part)
        end)

        self.activeResources[resourceId] = {
                component = componentName,
                instance = part,
                connection = touchDetector
        }

        return part
end

function ResourceSpawner:onResourceCollected(player, resourceId, componentName, part)
        local resource = self.activeResources[resourceId]
        if not resource then
                return
        end

        if self.playerManager then
                self.playerManager:addInventoryItem(player, componentName, 1)
        end

        if resource.connection then
                resource.connection:Disconnect()
        end

        if part and part.Parent then
                part:Destroy()
        end

        self.activeResources[resourceId] = nil
end

function ResourceSpawner:collectResource(resourceId)
        local resource = self.activeResources[resourceId]
        if not resource then
                return nil
        end

        self.activeResources[resourceId] = nil
        return resource.component
end

function ResourceSpawner:update(deltaTime)
        self.spawnTimer = self.spawnTimer + deltaTime

        if self.spawnTimer >= GameConfig.RESOURCE_SPAWN_RATE then
                self.spawnTimer = 0
                self:spawnResource()
        end
end

function ResourceSpawner:getActiveResourceCount()
        local count = 0
        for _ in pairs(self.activeResources) do
                count = count + 1
        end
        return count
end

return ResourceSpawner
