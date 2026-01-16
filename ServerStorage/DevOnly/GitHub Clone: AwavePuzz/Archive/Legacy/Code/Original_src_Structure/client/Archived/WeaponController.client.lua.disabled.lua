-- @ScriptType: Script
-- WeaponController.client.lua
-- BASIC weapon input handling (simplified version)
-- 
-- NOTE: This is the BASIC/SIMPLE weapon controller for testing or fallback.
-- For full FPS features (recoil, ADS, spread, reload), use FPSWeaponController.client.lua
--
-- Features:
-- - Simple left-click to fire
-- - Weapon switching with number keys (1-4)
-- - Basic server communication
--
-- See CODE_ARCHITECTURE.md for details on the dual weapon controller setup.

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

local WeaponController = {}
WeaponController.__index = WeaponController

function WeaponController.new()
	local self = setmetatable({}, WeaponController)
	self.isFiring = false
	self.currentWeapon = nil
	self.weapons = {}
	self.lastFireTime = 0
	self.weaponStats = {} -- Store weapon stats for fire rate tracking
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
		elseif input.KeyCode == Enum.KeyCode.One then
			self:equipSlot(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			self:equipSlot(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			self:equipSlot(3)
		elseif input.KeyCode == Enum.KeyCode.Four then
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
		if payload.stats then
			self.weaponStats = payload.stats
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

	-- Client-side fire rate throttling to prevent excessive RemoteEvent calls
	local currentTime = tick()
	local weaponStats = self.weaponStats[self.currentWeapon]
	if weaponStats and weaponStats.FireRate then
		local cooldown = weaponStats.FireRate
		if currentTime - self.lastFireTime < cooldown then
			return -- Still on cooldown
		end
	end

	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Update last fire time after passing cooldown check
	self.lastFireTime = currentTime

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
	self.lastFireTime = 0 -- Reset cooldown when switching weapons to allow immediate firing
	equipEvent:FireServer(weaponId)
end

local controller = WeaponController.new()
controller:start()
