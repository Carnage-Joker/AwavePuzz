-- FPSHUD.client.lua
-- First-person shooter HUD with dynamic crosshair, ammo counter, hitmarkers, and weapon info
-- Integrates with FPSWeaponController for real-time feedback

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))

-- Initialize scale manager
UIScaleManager.initialize()

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- CROSSHAIR SYSTEM
--------------------------------------------------------------------------------

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Name = "CrosshairContainer"
crosshairContainer.Size = UDim2.new(0, 100, 0, 100)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.Parent = screenGui

-- Crosshair lines
local crosshairConfig = FPSConfig.HUD
local baseSize = crosshairConfig.CrosshairSize
local thickness = crosshairConfig.CrosshairThickness
local gap = crosshairConfig.CrosshairGap
local crosshairColor = crosshairConfig.CrosshairColor
local outlineColor = crosshairConfig.CrosshairOutlineColor

local function createCrosshairLine(name, sizeX, sizeY, posX, posY, anchorX, anchorY)
	-- Outline
	if crosshairConfig.CrosshairOutline then
		local outline = Instance.new("Frame")
		outline.Name = name .. "Outline"
		outline.Size = UDim2.new(0, sizeX + 2, 0, sizeY + 2)
		outline.Position = UDim2.new(0.5, posX, 0.5, posY)
		outline.AnchorPoint = Vector2.new(anchorX, anchorY)
		outline.BackgroundColor3 = outlineColor
		outline.BorderSizePixel = 0
		outline.Parent = crosshairContainer
	end
	
	-- Main line
	local line = Instance.new("Frame")
	line.Name = name
	line.Size = UDim2.new(0, sizeX, 0, sizeY)
	line.Position = UDim2.new(0.5, posX, 0.5, posY)
	line.AnchorPoint = Vector2.new(anchorX, anchorY)
	line.BackgroundColor3 = crosshairColor
	line.BorderSizePixel = 0
	line.Parent = crosshairContainer
	
	return line
end

-- Create crosshair lines (top, bottom, left, right)
local topLine = createCrosshairLine("Top", thickness, baseSize, 0, -gap, 0.5, 1)
local bottomLine = createCrosshairLine("Bottom", thickness, baseSize, 0, gap, 0.5, 0)
local leftLine = createCrosshairLine("Left", baseSize, thickness, -gap, 0, 1, 0.5)
local rightLine = createCrosshairLine("Right", baseSize, thickness, gap, 0, 0, 0.5)

-- Center dot (optional)
local centerDot = nil
if crosshairConfig.CrosshairDot then
	centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, thickness, 0, thickness)
	centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	centerDot.BackgroundColor3 = crosshairColor
	centerDot.BorderSizePixel = 0
	centerDot.Parent = crosshairContainer
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = centerDot
end

-- Dynamic crosshair state
local currentCrosshairGap = gap
local targetCrosshairGap = gap

local function updateCrosshairSpread(spreadDegrees)
	if not crosshairConfig.DynamicCrosshair then return end
	
	-- Convert spread degrees to pixel gap
	-- Base gap is 4 pixels at 0 spread, max gap is about 30 pixels at max spread
	local spreadMultiplier = 3 -- pixels per degree of spread
	targetCrosshairGap = gap + (spreadDegrees * spreadMultiplier)
end

local function updateCrosshairPositions()
	local g = math.floor(currentCrosshairGap + 0.5)
	
	-- Update line positions
	topLine.Position = UDim2.new(0.5, 0, 0.5, -g)
	bottomLine.Position = UDim2.new(0.5, 0, 0.5, g)
	leftLine.Position = UDim2.new(0.5, -g, 0.5, 0)
	rightLine.Position = UDim2.new(0.5, g, 0.5, 0)
	
	-- Update outlines
	local topOutline = crosshairContainer:FindFirstChild("TopOutline")
	local bottomOutline = crosshairContainer:FindFirstChild("BottomOutline")
	local leftOutline = crosshairContainer:FindFirstChild("LeftOutline")
	local rightOutline = crosshairContainer:FindFirstChild("RightOutline")
	
	if topOutline then topOutline.Position = UDim2.new(0.5, 0, 0.5, -g) end
	if bottomOutline then bottomOutline.Position = UDim2.new(0.5, 0, 0.5, g) end
	if leftOutline then leftOutline.Position = UDim2.new(0.5, -g, 0.5, 0) end
	if rightOutline then rightOutline.Position = UDim2.new(0.5, g, 0.5, 0) end
end

--------------------------------------------------------------------------------
-- HITMARKER SYSTEM
--------------------------------------------------------------------------------

local hitmarkerContainer = Instance.new("Frame")
hitmarkerContainer.Name = "HitmarkerContainer"
hitmarkerContainer.Size = UDim2.new(0, 50, 0, 50)
hitmarkerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
hitmarkerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
hitmarkerContainer.BackgroundTransparency = 1
hitmarkerContainer.Visible = false
hitmarkerContainer.Parent = screenGui

-- Create hitmarker lines (X shape)
local hitmarkerSize = FPSConfig.HUD.HitmarkerSize
local hitmarkerThickness = 2

local function createHitmarkerLine(rotation)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, hitmarkerSize, 0, hitmarkerThickness)
	line.Position = UDim2.new(0.5, 0, 0.5, 0)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Rotation = rotation
	line.BackgroundColor3 = FPSConfig.HUD.HitmarkerColor
	line.BorderSizePixel = 0
	line.Parent = hitmarkerContainer
	return line
end

local hitmarkerLine1 = createHitmarkerLine(45)
local hitmarkerLine2 = createHitmarkerLine(-45)

local function showHitmarker(isHeadshot, isKill)
	local color = FPSConfig.HUD.HitmarkerColor
	
	if isKill then
		color = FPSConfig.HUD.KillHitmarkerColor
	elseif isHeadshot then
		color = FPSConfig.HUD.HeadshotHitmarkerColor
	end
	
	hitmarkerLine1.BackgroundColor3 = color
	hitmarkerLine2.BackgroundColor3 = color
	hitmarkerContainer.Visible = true
	
	-- Animate
	local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	hitmarkerContainer.Size = UDim2.new(0, 30, 0, 30)
	local expandTween = TweenService:Create(hitmarkerContainer, tweenInfo, {
		Size = UDim2.new(0, 50, 0, 50)
	})
	expandTween:Play()
	
	-- Hide after duration
	task.delay(FPSConfig.HUD.HitmarkerDuration, function()
		hitmarkerContainer.Visible = false
	end)
end

--------------------------------------------------------------------------------
-- AMMO DISPLAY
--------------------------------------------------------------------------------

local ammoFrame = Instance.new("Frame")
ammoFrame.Name = "AmmoFrame"
ammoFrame.Size = UIScaleManager.scaleSize(180, 80, "hudElements")
ammoFrame.Position = UIScaleManager.getPositionWithSafeArea("bottomRight", 20, 20)
ammoFrame.AnchorPoint = Vector2.new(1, 1)
ammoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ammoFrame.BackgroundTransparency = 0.3
ammoFrame.BorderSizePixel = 0
ammoFrame.Parent = screenGui

local ammoCorner = Instance.new("UICorner")
ammoCorner.CornerRadius = UDim.new(0, 8)
ammoCorner.Parent = ammoFrame

-- Current ammo (large)
local currentAmmoLabel = Instance.new("TextLabel")
currentAmmoLabel.Name = "CurrentAmmo"
currentAmmoLabel.Size = UDim2.new(0.6, 0, 0.7, 0)
currentAmmoLabel.Position = UDim2.new(0, 10, 0, 5)
currentAmmoLabel.BackgroundTransparency = 1
currentAmmoLabel.TextColor3 = Color3.new(1, 1, 1)
currentAmmoLabel.TextXAlignment = Enum.TextXAlignment.Left
currentAmmoLabel.Font = Enum.Font.GothamBold
currentAmmoLabel.TextSize = 42
currentAmmoLabel.Text = "30"
currentAmmoLabel.Parent = ammoFrame

-- Separator
local ammoSeparator = Instance.new("TextLabel")
ammoSeparator.Name = "Separator"
ammoSeparator.Size = UDim2.new(0, 20, 0.7, 0)
ammoSeparator.Position = UDim2.new(0.6, 0, 0, 5)
ammoSeparator.BackgroundTransparency = 1
ammoSeparator.TextColor3 = Color3.fromRGB(150, 150, 150)
ammoSeparator.Font = Enum.Font.GothamBold
ammoSeparator.TextSize = 28
ammoSeparator.Text = "/"
ammoSeparator.Parent = ammoFrame

-- Reserve ammo (smaller)
local reserveAmmoLabel = Instance.new("TextLabel")
reserveAmmoLabel.Name = "ReserveAmmo"
reserveAmmoLabel.Size = UDim2.new(0.3, -10, 0.7, 0)
reserveAmmoLabel.Position = UDim2.new(0.65, 10, 0, 5)
reserveAmmoLabel.BackgroundTransparency = 1
reserveAmmoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
reserveAmmoLabel.TextXAlignment = Enum.TextXAlignment.Left
reserveAmmoLabel.Font = Enum.Font.Gotham
reserveAmmoLabel.TextSize = 24
reserveAmmoLabel.Text = "120"
reserveAmmoLabel.Parent = ammoFrame

-- Reload indicator
local reloadLabel = Instance.new("TextLabel")
reloadLabel.Name = "ReloadLabel"
reloadLabel.Size = UDim2.new(1, -20, 0.3, 0)
reloadLabel.Position = UDim2.new(0, 10, 0.7, 0)
reloadLabel.BackgroundTransparency = 1
reloadLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
reloadLabel.TextXAlignment = Enum.TextXAlignment.Left
reloadLabel.Font = Enum.Font.Gotham
reloadLabel.TextSize = 14
reloadLabel.Text = ""
reloadLabel.Visible = false
reloadLabel.Parent = ammoFrame

local function updateAmmoDisplay(current, reserve, max, isReloading)
	currentAmmoLabel.Text = tostring(current or 0)
	reserveAmmoLabel.Text = tostring(reserve or 0)
	
	-- Color based on ammo level
	local ammoRatio = (current or 0) / (max or 30)
	if ammoRatio <= FPSConfig.HUD.LowAmmoThreshold then
		currentAmmoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		currentAmmoLabel.TextColor3 = Color3.new(1, 1, 1)
	end
	
	-- Reload indicator
	reloadLabel.Visible = isReloading
	if isReloading then
		reloadLabel.Text = "RELOADING..."
	end
end

--------------------------------------------------------------------------------
-- WEAPON INFO DISPLAY
--------------------------------------------------------------------------------

local weaponInfoFrame = Instance.new("Frame")
weaponInfoFrame.Name = "WeaponInfoFrame"
weaponInfoFrame.Size = UIScaleManager.scaleSize(180, 30, "hudElements")
weaponInfoFrame.Position = UIScaleManager.getPositionWithSafeArea("bottomRight", 20, 105)
weaponInfoFrame.AnchorPoint = Vector2.new(1, 1)
weaponInfoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
weaponInfoFrame.BackgroundTransparency = 0.5
weaponInfoFrame.BorderSizePixel = 0
weaponInfoFrame.Parent = screenGui

local weaponCorner = Instance.new("UICorner")
weaponCorner.CornerRadius = UDim.new(0, 6)
weaponCorner.Parent = weaponInfoFrame

local weaponNameLabel = Instance.new("TextLabel")
weaponNameLabel.Name = "WeaponName"
weaponNameLabel.Size = UDim2.new(0.7, -10, 1, 0)
weaponNameLabel.Position = UDim2.new(0, 10, 0, 0)
weaponNameLabel.BackgroundTransparency = 1
weaponNameLabel.TextColor3 = Color3.new(1, 1, 1)
weaponNameLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponNameLabel.Font = Enum.Font.Gotham
weaponNameLabel.TextSize = 14
weaponNameLabel.Text = "PISTOL"
weaponNameLabel.Parent = weaponInfoFrame

local fireModeLabel = Instance.new("TextLabel")
fireModeLabel.Name = "FireMode"
fireModeLabel.Size = UDim2.new(0.3, -10, 1, 0)
fireModeLabel.Position = UDim2.new(0.7, 0, 0, 0)
fireModeLabel.BackgroundTransparency = 1
fireModeLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
fireModeLabel.TextXAlignment = Enum.TextXAlignment.Right
fireModeLabel.Font = Enum.Font.GothamBold
fireModeLabel.TextSize = 12
fireModeLabel.Text = "SEMI"
fireModeLabel.Parent = weaponInfoFrame

local function updateWeaponInfo(weaponName, fireMode)
	weaponNameLabel.Text = string.upper(weaponName or "UNKNOWN")
	fireModeLabel.Text = string.upper(fireMode or "SEMI")
end

--------------------------------------------------------------------------------
-- DAMAGE INDICATOR (screen vignette when hurt)
--------------------------------------------------------------------------------

local damageVignette = Instance.new("ImageLabel")
damageVignette.Name = "DamageVignette"
damageVignette.Size = UDim2.new(1, 0, 1, 0)
damageVignette.Position = UDim2.new(0, 0, 0, 0)
damageVignette.BackgroundTransparency = 1
damageVignette.ImageColor3 = Color3.fromRGB(255, 0, 0)
damageVignette.ImageTransparency = 1
damageVignette.ZIndex = 0
damageVignette.Parent = screenGui

-- Create a gradient for vignette effect
local vignetteGradient = Instance.new("UIGradient")
vignetteGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.8),
	NumberSequenceKeypoint.new(1, 1)
})
vignetteGradient.Rotation = 0
vignetteGradient.Parent = damageVignette

local function flashDamageIndicator(intensity)
	if not FPSConfig.HUD.DamageIndicatorEnabled then return end
	
	local transparency = 1 - (intensity or 0.3)
	damageVignette.ImageTransparency = transparency
	
	local tweenInfo = TweenInfo.new(FPSConfig.HUD.DamageIndicatorDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(damageVignette, tweenInfo, {
		ImageTransparency = 1
	})
	tween:Play()
end

--------------------------------------------------------------------------------
-- LOW HEALTH VIGNETTE
--------------------------------------------------------------------------------

local lowHealthVignette = Instance.new("Frame")
lowHealthVignette.Name = "LowHealthVignette"
lowHealthVignette.Size = UDim2.new(1, 0, 1, 0)
lowHealthVignette.Position = UDim2.new(0, 0, 0, 0)
lowHealthVignette.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
lowHealthVignette.BackgroundTransparency = 1
lowHealthVignette.ZIndex = -1
lowHealthVignette.Parent = screenGui

local lowHealthPulseActive = false

local function updateLowHealthVignette(healthPercent)
	if not FPSConfig.HUD.LowHealthVignette then return end
	
	if healthPercent <= FPSConfig.HUD.LowHealthThreshold then
		if not lowHealthPulseActive then
			lowHealthPulseActive = true
			-- Start pulsing
			task.spawn(function()
				while lowHealthPulseActive do
					local tweenIn = TweenService:Create(lowHealthVignette, TweenInfo.new(0.5), {
						BackgroundTransparency = 0.7
					})
					tweenIn:Play()
					tweenIn.Completed:Wait()
					
					if not lowHealthPulseActive then break end
					
					local tweenOut = TweenService:Create(lowHealthVignette, TweenInfo.new(0.5), {
						BackgroundTransparency = 0.9
					})
					tweenOut:Play()
					tweenOut.Completed:Wait()
				end
			end)
		end
	else
		lowHealthPulseActive = false
		lowHealthVignette.BackgroundTransparency = 1
	end
end

--------------------------------------------------------------------------------
-- BINDABLE EVENT CONNECTIONS
--------------------------------------------------------------------------------

local function setupBindableConnections()
	local bindableFolder = playerGui:WaitForChild("BindableEvents", 10)
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end
	
	-- Ammo update
	local ammoEvent = bindableFolder:FindFirstChild("AmmoUpdate")
	if not ammoEvent then
		ammoEvent = Instance.new("BindableEvent")
		ammoEvent.Name = "AmmoUpdate"
		ammoEvent.Parent = bindableFolder
	end
	ammoEvent.Event:Connect(function(data)
		if typeof(data) == "table" then
			updateAmmoDisplay(data.current, data.reserve, data.max, data.isReloading)
		end
	end)
	
	-- Hitmarker
	local hitmarkerEvent = bindableFolder:FindFirstChild("Hitmarker")
	if not hitmarkerEvent then
		hitmarkerEvent = Instance.new("BindableEvent")
		hitmarkerEvent.Name = "Hitmarker"
		hitmarkerEvent.Parent = bindableFolder
	end
	hitmarkerEvent.Event:Connect(function(data)
		if typeof(data) == "table" then
			showHitmarker(data.isHeadshot, data.isKill)
		end
	end)
	
	-- Crosshair update
	local crosshairEvent = bindableFolder:FindFirstChild("CrosshairUpdate")
	if not crosshairEvent then
		crosshairEvent = Instance.new("BindableEvent")
		crosshairEvent.Name = "CrosshairUpdate"
		crosshairEvent.Parent = bindableFolder
	end
	crosshairEvent.Event:Connect(function(data)
		if typeof(data) == "table" then
			updateCrosshairSpread(data.spread or 0)
			-- Hide crosshair when ADS
			crosshairContainer.Visible = not data.isADS
		end
	end)
	
	-- Weapon info update
	local weaponInfoEvent = bindableFolder:FindFirstChild("WeaponInfoUpdate")
	if not weaponInfoEvent then
		weaponInfoEvent = Instance.new("BindableEvent")
		weaponInfoEvent.Name = "WeaponInfoUpdate"
		weaponInfoEvent.Parent = bindableFolder
	end
	weaponInfoEvent.Event:Connect(function(data)
		if typeof(data) == "table" then
			updateWeaponInfo(data.weaponName or data.weaponId, data.fireMode)
		end
	end)
	
	-- Damage indicator
	local damageEvent = bindableFolder:FindFirstChild("DamageTaken")
	if not damageEvent then
		damageEvent = Instance.new("BindableEvent")
		damageEvent.Name = "DamageTaken"
		damageEvent.Parent = bindableFolder
	end
	damageEvent.Event:Connect(function(data)
		if typeof(data) == "table" then
			flashDamageIndicator(data.intensity or 0.3)
		elseif typeof(data) == "number" then
			flashDamageIndicator(data)
		else
			flashDamageIndicator()
		end
	end)
end

--------------------------------------------------------------------------------
-- HEALTH SYNC (from PlayerHUD or server)
--------------------------------------------------------------------------------

local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local healthEvent = remoteEventsFolder:FindFirstChild("PlayerHealthUpdate")
if healthEvent then
	healthEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			local healthPercent = ((data.current or 100) / (data.max or 100)) * 100
			updateLowHealthVignette(healthPercent)
		end
	end)
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(deltaTime)
	-- Smooth crosshair spread animation
	if crosshairConfig.DynamicCrosshair then
		currentCrosshairGap = currentCrosshairGap + (targetCrosshairGap - currentCrosshairGap) * 0.2
		updateCrosshairPositions()
	end
end)

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	setupBindableConnections()
	
	-- Initial UI state
	updateAmmoDisplay(30, 120, 30, false)
	updateWeaponInfo("Pistol", "Semi")
	
	print("[FPSHUD] Initialized")
end

initialize()

return {}
