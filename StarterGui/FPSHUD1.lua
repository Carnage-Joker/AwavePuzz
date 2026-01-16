-- @ScriptType: LocalScript
-- FPSHUD (LocalScript) - DROP-IN REPLACEMENT
-- Put this LocalScript in StarterGui named "FPSHUD"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("FPSHUDGui")
if existing then existing:Destroy() end
-- ScreenGui (ResetOnSpawn belongs here, not PlayerGui)
local gui = Instance.new("ScreenGui")
gui.Name = "FPSHUDGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Root container
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui

-- Crosshair
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(2, 2)
crosshair.BackgroundTransparency = 0
crosshair.BorderSizePixel = 0
crosshair.Parent = root

local function makeLine(name, size, pos)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BorderSizePixel = 0
	f.Parent = root
	return f
end

local lineLen = 10
local thick = 2
local gap = 6

local up    = makeLine("Up",    UDim2.fromOffset(thick, lineLen), UDim2.fromOffset(0, 0))
local down  = makeLine("Down",  UDim2.fromOffset(thick, lineLen), UDim2.fromOffset(0, 0))
local left  = makeLine("Left",  UDim2.fromOffset(lineLen, thick), UDim2.fromOffset(0, 0))
local right = makeLine("Right", UDim2.fromOffset(lineLen, thick), UDim2.fromOffset(0, 0))

-- Ammo panel
local ammoPanel = Instance.new("Frame")
ammoPanel.Name = "AmmoPanel"
ammoPanel.AnchorPoint = Vector2.new(1, 1)
ammoPanel.Position = UDim2.new(1, -20, 1, -20)
ammoPanel.Size = UDim2.fromOffset(240, 90)
ammoPanel.BorderSizePixel = 0
ammoPanel.BackgroundTransparency = 0.3
ammoPanel.Parent = root

local ammoTitle = Instance.new("TextLabel")
ammoTitle.Name = "WeaponName"
ammoTitle.BackgroundTransparency = 1
ammoTitle.Size = UDim2.new(1, -16, 0, 24)
ammoTitle.Position = UDim2.fromOffset(8, 6)
ammoTitle.TextXAlignment = Enum.TextXAlignment.Left
ammoTitle.Font = Enum.Font.GothamBold
ammoTitle.TextSize = 16
ammoTitle.Text = "Weapon"
ammoTitle.Parent = ammoPanel

local ammoText = Instance.new("TextLabel")
ammoText.Name = "AmmoText"
ammoText.BackgroundTransparency = 1
ammoText.Size = UDim2.new(1, -16, 0, 48)
ammoText.Position = UDim2.fromOffset(8, 30)
ammoText.TextXAlignment = Enum.TextXAlignment.Left
ammoText.Font = Enum.Font.Gotham
ammoText.TextSize = 28
ammoText.Text = "-- / --"
ammoText.Parent = ammoPanel

-- Helper: read attributes from character or player
local function getAttr(name)
	local char = player.Character
	if char and char:GetAttribute(name) ~= nil then
		return char:GetAttribute(name)
	end
	if player:GetAttribute(name) ~= nil then
		return player:GetAttribute(name)
	end
	return nil
end

local function updateCrosshair()
	local cx = root.AbsoluteSize.X * 0.5
	local cy = root.AbsoluteSize.Y * 0.5

	crosshair.Position = UDim2.fromOffset(cx, cy)

	up.Position    = UDim2.fromOffset(cx - thick/2, cy - gap - lineLen)
	down.Position  = UDim2.fromOffset(cx - thick/2, cy + gap)
	left.Position  = UDim2.fromOffset(cx - gap - lineLen, cy - thick/2)
	right.Position = UDim2.fromOffset(cx + gap, cy - thick/2)
end

local function updateAmmo()
	local weaponName = getAttr("WeaponName") or getAttr("EquippedWeapon") or "Weapon"
	local ammo = getAttr("Ammo")
	local maxAmmo = getAttr("MaxAmmo")
	local reserve = getAttr("ReserveAmmo")

	ammoTitle.Text = tostring(weaponName)

	if typeof(ammo) == "number" and typeof(maxAmmo) == "number" then
		if typeof(reserve) == "number" then
			ammoText.Text = string.format("%d / %d  |  %d", ammo, maxAmmo, reserve)
		else
			ammoText.Text = string.format("%d / %d", ammo, maxAmmo)
		end
	else
		ammoText.Text = "-- / --"
	end
end

-- Initial layout
updateCrosshair()
updateAmmo()

-- Keep it updated
RunService.RenderStepped:Connect(function()
	updateCrosshair()
end)

-- Update ammo whenever attributes change
local function hookAttrSignals(obj)
	if not obj then return end
	obj:GetAttributeChangedSignal("WeaponName"):Connect(updateAmmo)
	obj:GetAttributeChangedSignal("EquippedWeapon"):Connect(updateAmmo)
	obj:GetAttributeChangedSignal("Ammo"):Connect(updateAmmo)
	obj:GetAttributeChangedSignal("MaxAmmo"):Connect(updateAmmo)
	obj:GetAttributeChangedSignal("ReserveAmmo"):Connect(updateAmmo)
end

hookAttrSignals(player)
player.CharacterAdded:Connect(function(char)
	hookAttrSignals(char)
	updateAmmo()
end)
