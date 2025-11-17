-- WeaponService.lua
-- Handles player weapon logic, raycast validation, and kill rewards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

local function cloneTable(t)
        local copy = {}
        for key, value in pairs(t) do
                copy[key] = value
        end
        return copy
end

local WeaponService = {}
WeaponService.__index = WeaponService

function WeaponService.new(playerManager)
        local self = setmetatable({}, WeaponService)
        self.playerManager = playerManager
        self.playerWeaponState = {} -- userId -> state
        self.remoteEvents = {}
        self:setupRemoteEvents()
        return self
end

function WeaponService:setupRemoteEvents()
        local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEventsFolder then
                remoteEventsFolder = Instance.new("Folder")
                remoteEventsFolder.Name = "RemoteEvents"
                remoteEventsFolder.Parent = ReplicatedStorage
        end

        local fireEvent = remoteEventsFolder:FindFirstChild("WeaponFire")
        if not fireEvent then
                fireEvent = Instance.new("RemoteEvent")
                fireEvent.Name = "WeaponFire"
                fireEvent.Parent = remoteEventsFolder
        end
        self.remoteEvents.WeaponFire = fireEvent

        local equipEvent = remoteEventsFolder:FindFirstChild("WeaponEquip")
        if not equipEvent then
                equipEvent = Instance.new("RemoteEvent")
                equipEvent.Name = "WeaponEquip"
                equipEvent.Parent = remoteEventsFolder
        end
        self.remoteEvents.WeaponEquip = equipEvent

        local hitEvent = remoteEventsFolder:FindFirstChild("WeaponHitConfirm")
        if not hitEvent then
                hitEvent = Instance.new("RemoteEvent")
                hitEvent.Name = "WeaponHitConfirm"
                hitEvent.Parent = remoteEventsFolder
        end
        self.remoteEvents.WeaponHitConfirm = hitEvent

        fireEvent.OnServerEvent:Connect(function(player, payload)
                self:handleWeaponFire(player, payload)
        end)

        equipEvent.OnServerEvent:Connect(function(player, weaponId)
                self:handleEquipRequest(player, weaponId)
        end)
end

function WeaponService:initializePlayer(player)
        local userId = player.UserId
        self.playerWeaponState[userId] = {
                lastShot = 0,
                upgrades = {}
        }

        local startingWeapon = self.playerManager:getEquippedWeapon(player)
        if not startingWeapon then
                self.playerManager:addWeapon(player, WeaponConfig.DefaultWeapon)
                self.playerManager:equipWeapon(player, WeaponConfig.DefaultWeapon)
        end
end

function WeaponService:removePlayer(player)
        self.playerWeaponState[player.UserId] = nil
end

function WeaponService:handleEquipRequest(player, weaponId)
        if not self.playerManager:ownsWeapon(player, weaponId) then
                return
        end

        self.playerManager:equipWeapon(player, weaponId)
end

function WeaponService:getModifiedStats(player, weaponId)
        local baseStats = WeaponConfig.getWeapon(weaponId)
        if not baseStats then
                return nil
        end

        local state = self.playerWeaponState[player.UserId]
        if not state then
                return baseStats
        end

        local modified = cloneTable(baseStats)
        if state.upgrades then
                for upgradeId in pairs(state.upgrades) do
                        local upgrade = WeaponConfig.getUpgrade(upgradeId)
                        if upgrade and upgrade.Type == "stat" and modified[upgrade.Stat] then
                                modified[upgrade.Stat] = modified[upgrade.Stat] * upgrade.Multiplier
                        end
                end
        end

        return modified
end

function WeaponService:handleWeaponFire(player, payload)
        if typeof(payload) ~= "table" then
                return
        end

        local weaponId = payload.weaponId
        local origin = payload.origin
        local direction = payload.direction
        local timestamp = payload.timestamp

        if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
                return
        end

        if direction.Magnitude < 0.001 then
                return
        end

        local equipped = self.playerManager:getEquippedWeapon(player)
        if not equipped or equipped ~= weaponId then
                return
        end

        local stats = self:getModifiedStats(player, weaponId)
        if not stats then
                return
        end

        local state = self.playerWeaponState[player.UserId]
        if not state then
                return
        end

        local now = tick()
        if now - (state.lastShot or 0) < stats.FireRate then
                return -- still on cooldown
        end

        state.lastShot = now

        local rayDirection = direction.Unit * stats.Range
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {player.Character}
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.IgnoreWater = true

        local result = Workspace:Raycast(origin, rayDirection, params)
        if result then
                local hitInstance = result.Instance
                local zombieModel = hitInstance and hitInstance:FindFirstAncestorOfClass("Model")
                if zombieModel and zombieModel:GetAttribute("IsZombie") then
                        self:damageZombie(zombieModel, player, stats, weaponId)
                        self.remoteEvents.WeaponHitConfirm:FireClient(player, {
                                position = result.Position,
                                target = zombieModel.Name
                        })
                end
        end
end

function WeaponService:damageZombie(zombieModel, player, stats, weaponId)
        local humanoid = zombieModel:FindFirstChild("Humanoid")
        if not humanoid then
                return
        end

        zombieModel:SetAttribute("LastHitBy", player.UserId)
        zombieModel:SetAttribute("LastHitWeapon", weaponId)

        -- Wrap in pcall in case humanoid is destroyed between validation and damage application
        pcall(function()
                humanoid:TakeDamage(stats.Damage)
        end)
end

function WeaponService:onZombieKilled(zombieModel)
        if not zombieModel then
                return
        end

        local reward = zombieModel:GetAttribute("Reward") or 0
        local lastHitUserId = zombieModel:GetAttribute("LastHitBy")
        if not lastHitUserId then
                return
        end

        local player = Players:GetPlayerByUserId(lastHitUserId)
        if not player then
                return
        end

        local weaponId = zombieModel:GetAttribute("LastHitWeapon")
        local weaponStats = weaponId and WeaponConfig.getWeapon(weaponId) or nil
        local bonus = weaponStats and weaponStats.RewardBonus or 0

        self.playerManager:addCurrency(player, reward + bonus)
end

function WeaponService:applyUpgrade(player, upgradeId)
        local upgrade = WeaponConfig.getUpgrade(upgradeId)
        if not upgrade then
                return false
        end

        local state = self.playerWeaponState[player.UserId]
        if not state then
                state = {lastShot = 0, upgrades = {}}
                self.playerWeaponState[player.UserId] = state
        end

        state.upgrades = state.upgrades or {}
        if state.upgrades[upgradeId] then
                return false -- already owned
        end

        state.upgrades[upgradeId] = true
        return true
end

return WeaponService
