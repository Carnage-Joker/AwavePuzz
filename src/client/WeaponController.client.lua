-- WeaponController.client.lua
-- Handles local firing input and communicates with the server weapon service

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local fireEvent = remoteFolder:WaitForChild("WeaponFire")
local equipEvent = remoteFolder:WaitForChild("WeaponEquip")
local loadoutEvent = remoteFolder:WaitForChild("WeaponLoadoutUpdate")
local hitEvent = remoteFolder:WaitForChild("WeaponHitConfirm")

-- Require WeaponConfig to get weapon stats for client-side throttling
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

local WeaponController = {}
WeaponController.__index = WeaponController

function WeaponController.new()
        local self = setmetatable({}, WeaponController)
        self.isFiring = false
        self.currentWeapon = nil
        self.weapons = {}
        self.lastShotTime = 0 -- Track last shot time for client-side throttling
        return self
end

function WeaponController:start()
        UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then
                        return
                end

                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        self.isFiring = true
                        self:fire()
                elseif input.KeyCode == Enum.KeyCode.Alpha1 then
                        self:equipSlot(1)
                elseif input.KeyCode == Enum.KeyCode.Alpha2 then
                        self:equipSlot(2)
                elseif input.KeyCode == Enum.KeyCode.Alpha3 then
                        self:equipSlot(3)
                elseif input.KeyCode == Enum.KeyCode.Alpha4 then
                        self:equipSlot(4)
                end
        end)

        UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        self.isFiring = false
                end
        end)

        RunService.RenderStepped:Connect(function()
                if self.isFiring then
                        self:fire()
                end
        end)

        loadoutEvent.OnClientEvent:Connect(function(payload)
                if payload.weapons then
                        self.weapons = payload.weapons
                end
                if payload.equipped then
                        self.currentWeapon = payload.equipped
                end
        end)

        hitEvent.OnClientEvent:Connect(function(payload)
                if payload and payload.position then
                        -- Simple hit indicator
                        print("Hit " .. tostring(payload.target) .. " at " .. tostring(payload.position))
                end
        end)
end

function WeaponController:fire()
        if not self.currentWeapon then
                return
        end

        -- Get weapon stats for client-side fire rate throttling
        local weaponStats = WeaponConfig.getWeapon(self.currentWeapon)
        if not weaponStats then
                return
        end

        -- Check client-side cooldown to prevent excessive RemoteEvent fires
        local now = tick()
        if now - self.lastShotTime < weaponStats.FireRate then
                return -- Still on cooldown
        end

        local character = player.Character
        if not character then
                return
        end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
                return
        end

        -- Update last shot time before firing
        self.lastShotTime = now

        local targetPosition = mouse.Hit and mouse.Hit.Position or (hrp.Position + hrp.CFrame.LookVector * 50)
        local origin = hrp.Position + Vector3.new(0, 2, 0)
        local direction = (targetPosition - origin)

        fireEvent:FireServer({
                weaponId = self.currentWeapon,
                origin = origin,
                direction = direction,
                timestamp = tick()
        })
end

function WeaponController:equipSlot(slot)
        if not self.weapons or #self.weapons == 0 then
                return
        end

        local weaponId = self.weapons[slot]
        if not weaponId then
                return
        end

        self.currentWeapon = weaponId
        self.lastShotTime = 0 -- Reset cooldown when switching weapons
        equipEvent:FireServer(weaponId)
end

local controller = WeaponController.new()
controller:start()
