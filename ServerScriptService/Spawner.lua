--[[
    Spawner Module
    Responsible for cloning zombie models, assigning their runtime attributes, and
    binding AI through ZombieBrain. The GameManager owns an instance of this
    module and provides callbacks for spawn/death/base attacks.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ZombieTypes = require(ReplicatedStorage.Shared:WaitForChild("ZombieTypes"))
local ZombieBrain = require(script.Parent:WaitForChild("AIScripts"):WaitForChild("ZombieBrain"))

local Spawner = {}
Spawner.__index = Spawner

local function ensureWorkspaceFolder()
    local zombiesFolder = workspace:FindFirstChild("Zombies")
    if not zombiesFolder then
        zombiesFolder = Instance.new("Folder")
        zombiesFolder.Name = "Zombies"
        zombiesFolder.Parent = workspace
    end
    return zombiesFolder
end

local function getSpawnPoints()
    local spawnFolder = workspace:FindFirstChild("ZombieSpawns")
    if not spawnFolder then
        return {}
    end

    local points = {}
    for _, child in ipairs(spawnFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(points, child)
        end
    end
    return points
end

local function chooseZombieType(composition)
    local roll = math.random()
    local cumulative = 0
    for zombieType, weight in pairs(composition) do
        cumulative += weight
        if roll <= cumulative then
            return zombieType
        end
    end

    -- If the weights do not sum to 1 we fallback to a random key.
    warn("[Spawner] chooseZombieType: Composition weights do not sum to 1. Falling back to random selection. Composition: " .. game:GetService("HttpService"):JSONEncode(composition))
    local keys = {}
    for zombieType in pairs(composition) do
        table.insert(keys, zombieType)
    end
    if #keys > 0 then
        return keys[math.random(1, #keys)]
    end
    return "Walker"
end

function Spawner.new(options)
    local self = setmetatable({}, Spawner)
    self.targetPart = options.TargetPart
    self.onSpawned = options.OnZombieSpawned
    self.onRemoved = options.OnZombieRemoved
    self.onBaseDamaged = options.OnBaseDamaged
    self.zombieFolder = ensureWorkspaceFolder()
    self.spawnPoints = getSpawnPoints()
    self.active = false
    self.spawnThread = nil
    self.spawnedThisWave = 0
    self.totalToSpawn = 0
    return self
end

function Spawner:CleanupZombie(model)
    if model and model.Parent then
        model:Destroy()
    end
end

function Spawner:OnZombieDied(zombieModel)
    if self.onRemoved then
        self.onRemoved(zombieModel)
    end
end

function Spawner:SpawnZombieOfType(zombieTypeName)
    local zombieType = ZombieTypes[zombieTypeName]
    if not zombieType then
        warn("Attempted to spawn unknown zombie type", zombieTypeName)
        return
    end

    local modelTemplateFolder = ServerStorage:FindFirstChild("ZombieModels")
    if not modelTemplateFolder then
        warn("ServerStorage.ZombieModels folder is missing. Cannot spawn zombies.")
        return
    end

    local template = modelTemplateFolder:FindFirstChild(zombieType.Model)
    if not template then
        warn("Missing zombie model template", zombieType.Model)
        return
    end

    local zombie = template:Clone()
    zombie.Parent = self.zombieFolder
    zombie:SetAttribute("IsZombie", true)
    zombie:SetAttribute("ZombieType", zombieTypeName)

    local humanoid = zombie:FindFirstChildOfClass("Humanoid")
    local root = zombie:FindFirstChild("HumanoidRootPart")
    if humanoid then
        humanoid.WalkSpeed = zombieType.Speed
        humanoid.MaxHealth = zombieType.Health
        humanoid.Health = zombieType.Health
    end

    if root then
        CollectionService:AddTag(root, "Zombie")
    end

    if #self.spawnPoints > 0 then
        local spawnPart = self.spawnPoints[math.random(1, #self.spawnPoints)]
        local primary = zombie.PrimaryPart or zombie:FindFirstChild("HumanoidRootPart")
        if primary and spawnPart then
            local spawnPosition = spawnPart.Position + Vector3.new(0, 2, 0)
            local rayOrigin = spawnPosition
            local rayDirection = Vector3.new(0, -4, 0) -- Check 4 studs below spawn position
            
            -- Use modern Raycast API
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {zombie}
            
            local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            if not raycastResult then
                zombie:MoveTo(spawnPosition)
            else
                -- Try a higher position if obstructed
                local altSpawnPosition = spawnPart.Position + Vector3.new(0, 4, 0)
                local altRayOrigin = altSpawnPosition
                local altRayDirection = Vector3.new(0, -4, 0)
                local altRaycastResult = workspace:Raycast(altRayOrigin, altRayDirection, raycastParams)
                if not altRaycastResult then
                    zombie:MoveTo(altSpawnPosition)
                end
                -- If still obstructed, skip spawning or handle as needed
            end
        end
    end

    local aiHandle = ZombieBrain.start(zombie, {
        TargetPart = self.targetPart,
        Damage = zombieType.Damage,
        AttackInterval = Config.Spawning.DefaultAttackInterval,
        AttackRange = Config.Spawning.DefaultAttackRange,
        OnBaseAttack = function(damageAmount)
            if self.onBaseDamaged then
                self.onBaseDamaged(damageAmount, zombie)
            end
        end,
    })

    local function cleanup()
        if aiHandle then
            aiHandle()
        else
            ZombieBrain.stop(zombie)
        end
        self:OnZombieDied(zombie)
    end

    if humanoid then
        humanoid.Died:Connect(cleanup)
    else
        task.delay(0, cleanup)
    end

    if self.onSpawned then
        self.onSpawned(zombie)
    end
end

function Spawner:StartWave(waveData)
    if self.active then
        self:StopWave()
    end

    self.active = true
    self.spawnedThisWave = 0
    self.totalToSpawn = waveData.zombieCount
    local spawnDelay = waveData.spawnDelay or Config.Spawning.SpawnInterval

    self.spawnThread = task.spawn(function()
        while self.active and self.spawnedThisWave < self.totalToSpawn do
            local zombieType = chooseZombieType(waveData.composition or { Walker = 1 })
            self:SpawnZombieOfType(zombieType)
            self.spawnedThisWave += 1
            task.wait(spawnDelay)
        end
    end)
end

function Spawner:StopWave()
    self.active = false
    if self.spawnThread then
        task.cancel(self.spawnThread)
        self.spawnThread = nil
    end
end

function Spawner:IsFinishedSpawning()
    return self.spawnedThisWave >= self.totalToSpawn
end

return Spawner
