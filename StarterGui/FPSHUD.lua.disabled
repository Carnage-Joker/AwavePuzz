-- @ScriptType: LocalScript
-- StarterGui/FPSHUD (LocalScript) - DROP-IN REPLACEMENT
-- Pattern: LocalScript sits directly under StarterGui.
-- This script creates/owns a ScreenGui named "FPSHUDGui".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- -----------------------
-- ScreenGui owner
-- -----------------------
local function getOrCreateGui()
	local existing = playerGui:FindFirstChild("FPSHUDGui")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "FPSHUDGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = playerGui
	return sg
end

local gui = getOrCreateGui()

-- -----------------------
-- Remote (optional)
-- -----------------------
local function findRemote(name)
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then return nil end
	local r = folder:FindFirstChild(name)
	return (r and r:IsA("RemoteEvent")) and r or nil
end

local WeaponHudRemote = findRemote("WeaponHUDUpdate") -- {weaponName, ammo, reserve, crosshairSpread, hit}

-- -----------------------
-- UI helpers
-- -----------------------
local function ensure(name, className, parent)
	local inst = parent:FindFirstChild(name)
	if inst then return inst end
	inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function corner(parent, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px or 10)
	c.Parent = parent
	return c
end

-- -----------------------
-- Crosshair
-- -----------------------
local cross = ensure("Crosshair", "Frame", gui)
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(40, 40)
cross.BackgroundTransparency = 1

local function mkLine(name, size, pos)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0.15
	f.Parent = cross
	return f
end

local top    = mkLine("Top",    UDim2.fromOffset(4, 10), UDim2.fromOffset(18, 0))
local bottom = mkLine("Bottom", UDim2.fromOffset(4, 10), UDim2.fromOffset(18, 30))
local left   = mkLine("Left",   UDim2.fromOffset(10, 4), UDim2.fromOffset(0, 18))
local right  = mkLine("Right",  UDim2.fromOffset(10, 4), UDim2.fromOffset(30, 18))

local hit = ensure("HitMarker", "TextLabel", gui)
hit.AnchorPoint = Vector2.new(0.5, 0.5)
hit.Position = UDim2.fromScale(0.5, 0.5)
hit.Size = UDim2.fromOffset(60, 60)
hit.BackgroundTransparency = 1
hit.TextScaled = true
hit.Text = "✕"
hit.Visible = false

-- -----------------------
-- Ammo UI
-- -----------------------
local box = ensure("AmmoBox", "Frame", gui)
box.AnchorPoint = Vector2.new(1, 1)
box.Position = UDim2.new(1, -16, 1, -16)
box.Size = UDim2.fromOffset(220, 78)
box.BackgroundTransparency = 0.25
box.BorderSizePixel = 0
corner(box, 14)

local weaponLabel = ensure("Weapon", "TextLabel", box)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Position = UDim2.fromOffset(12, 10)
weaponLabel.Size = UDim2.new(1, -24, 0, 22)
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.TextScaled = true
weaponLabel.Text = "Weapon: --"

local ammoLabel = ensure("Ammo", "TextLabel", box)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Position = UDim2.fromOffset(12, 36)
ammoLabel.Size = UDim2.new(1, -24, 0, 32)
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.TextScaled = true
ammoLabel.Text = "Ammo: -- / --"

-- -----------------------
-- State
-- -----------------------
local currentTool
local weaponName = "--"
local ammo, reserve
local crosshairSpread = 0
local velSpread = 0

local function setCrosshair(spreadPx)
	spreadPx = math.max(0, tonumber(spreadPx) or 0)
	crosshairSpread = spreadPx

	top.Position    = UDim2.fromOffset(18, 0 - spreadPx)
	bottom.Position = UDim2.fromOffset(18, 30 + spreadPx)
	left.Position   = UDim2.fromOffset(0 - spreadPx, 18)
	right.Position  = UDim2.fromOffset(30 + spreadPx, 18)
end

local function updateAmmoText()
	local a = (ammo ~= nil) and tostring(ammo) or "--"
	local r = (reserve ~= nil) and tostring(reserve) or "--"
	weaponLabel.Text = "Weapon: " .. tostring(weaponName or "--")
	ammoLabel.Text = string.format("Ammo: %s / %s", a, r)
end

local function showHitMarker()
	hit.Visible = true
	task.delay(0.12, function()
		hit.Visible = false
	end)
end

-- -----------------------
-- Tool attribute support
-- -----------------------
local function readToolAttrs(tool)
	if not tool then return end

	weaponName = tool:GetAttribute("WeaponName") or tool.Name
	ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
	reserve = tool:GetAttribute("Reserve") or tool:GetAttribute("ReserveAmmo")

	local spread = tool:GetAttribute("CrosshairSpread")
	if spread ~= nil then
		setCrosshair(spread)
	end

	updateAmmoText()
end

local function hookTool(tool)
	currentTool = tool
	if not tool then
		weaponName, ammo, reserve = "--", nil, nil
		setCrosshair(0)
		updateAmmoText()
		return
	end

	readToolAttrs(tool)

	local function safeUpdate()
		if tool == currentTool then
			readToolAttrs(tool)
		end
	end

	tool:GetAttributeChangedSignal("Ammo"):Connect(safeUpdate)
	tool:GetAttributeChangedSignal("CurrentAmmo"):Connect(safeUpdate)
	tool:GetAttributeChangedSignal("Reserve"):Connect(safeUpdate)
	tool:GetAttributeChangedSignal("ReserveAmmo"):Connect(safeUpdate)
	tool:GetAttributeChangedSignal("WeaponName"):Connect(safeUpdate)
	tool:GetAttributeChangedSignal("CrosshairSpread"):Connect(safeUpdate)
end

local function getEquippedTool(character)
	if not character then return nil end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local function onCharacter(char)
	hookTool(getEquippedTool(char))

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			hookTool(child)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child == currentTool then
			hookTool(getEquippedTool(char))
		end
	end)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

-- -----------------------
-- Remote support (optional)
-- -----------------------
if WeaponHudRemote then
	WeaponHudRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then return end
		if payload.weaponName ~= nil then weaponName = payload.weaponName end
		if payload.ammo ~= nil then ammo = payload.ammo end
		if payload.reserve ~= nil then reserve = payload.reserve end
		if payload.crosshairSpread ~= nil then setCrosshair(payload.crosshairSpread) end
		updateAmmoText()
		if payload.hit == true then
			showHitMarker()
		end
	end)
end

-- -----------------------
-- Mild movement spread fallback
-- -----------------------
RunService.RenderStepped:Connect(function()
	local char = player.Character
	if not char then return end

	-- If tool explicitly controls spread, don't override
	if currentTool and currentTool:GetAttribute("CrosshairSpread") ~= nil then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local moving = (speed / 16)
	local airborne = (hum.FloorMaterial == Enum.Material.Air) and 1 or 0
	local target = (moving * 4) + (airborne * 8)

	velSpread = velSpread + (target - velSpread) * 0.15
	setCrosshair(velSpread)
end)

setCrosshair(0)
updateAmmoText()
