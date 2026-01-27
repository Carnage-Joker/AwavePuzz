-- FPSHUD.client.lua
-- First-person shooter HUD with dynamic crosshair, ammo counter, hitmarkers, and weapon info
-- Integrates with FPSWeaponController for real-time feedback

-- Debug flag - set to true to enable detailed logging
local DEBUG_AMMO = true  -- Set to true to debug ammo UI issues

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

-- Constants
local DEFAULT_MAGAZINE_SIZE = 30  -- Fallback magazine size when weapon config is unavailable

-- Track last ammo update for debugging
local lastAmmoUpdate = tick()  -- Initialize to current time to avoid false stale warnings on startup
local lastAmmoData = nil

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

-- Prevent duplicate HUDs on respawn
local existing = playerGui:FindFirstChild("FPSHUD")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- SHARED HUD CONFIG / DEFAULTS
--------------------------------------------------------------------------------

local hudConfig = FPSConfig.HUD or {}
local crosshairConfig = hudConfig

local baseSize = crosshairConfig.CrosshairSize or 10
local thickness = crosshairConfig.CrosshairThickness or 2
local gap = crosshairConfig.CrosshairGap or 4
local crosshairColor = crosshairConfig.CrosshairColor or Color3.new(1, 1, 1)
local outlineColor = crosshairConfig.CrosshairOutlineColor or Color3.new(0, 0, 0)
local lowAmmoThreshold = hudConfig.LowAmmoThreshold or 0.25
local hitmarkerSize = hudConfig.HitmarkerSize or 20
local hitmarkerColor = hudConfig.HitmarkerColor or Color3.new(1, 1, 1)
local killHitmarkerColor = hudConfig.KillHitmarkerColor or Color3.fromRGB(255, 200, 0)
local headshotHitmarkerColor = hudConfig.HeadshotHitmarkerColor or Color3.fromRGB(255, 50, 50)
local damageIndicatorEnabled = (hudConfig.DamageIndicatorEnabled ~= false)
local damageIndicatorDuration = hudConfig.DamageIndicatorDuration or 0.25
local lowHealthVignetteEnabled = (hudConfig.LowHealthVignette ~= false)
local lowHealthThreshold = hudConfig.LowHealthThreshold or 30
local hitmarkerDuration = hudConfig.HitmarkerDuration or 0.15

--------------------------------------------------------------------------------
-- CROSSHAIR SYSTEM
--------------------------------------------------------------------------------

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Name = "CrosshairContainer"
crosshairContainer.Size = UDim2.new(0, 100, 0, 100)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.ZIndex = 20
crosshairContainer.Parent = screenGui

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
		outline.ZIndex = 20
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
	line.ZIndex = 21
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
	centerDot.ZIndex = 21
	centerDot.Parent = crosshairContainer

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = centerDot
end

-- Dynamic crosshair state
local currentCrosshairGap = gap
local targetCrosshairGap = gap

local function updateCrosshairSpread(spreadDegrees)
	if crosshairConfig.DynamicCrosshair == false then
		return
	end

	-- Clamp spread and convert to pixel gap
	local clampedSpread = math.clamp(spreadDegrees or 0, 0, hudConfig.MaxSpread or 10)
	local spreadMultiplier = 3 -- pixels per degree of spread
	targetCrosshairGap = gap + (clampedSpread * spreadMultiplier)
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
hitmarkerContainer.ZIndex = 30
hitmarkerContainer.Parent = screenGui

local hitmarkerThickness = 2

local function createHitmarkerLine(rotation)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, hitmarkerSize, 0, hitmarkerThickness)
	line.Position = UDim2.new(0.5, 0, 0.5, 0)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Rotation = rotation
	line.BackgroundColor3 = hitmarkerColor
	line.BorderSizePixel = 0
	line.ZIndex = 31
	line.Parent = hitmarkerContainer
	return line
end

local hitmarkerLine1 = createHitmarkerLine(45)
local hitmarkerLine2 = createHitmarkerLine(-45)

local function showHitmarker(isHeadshot, isKill)
	local color = hitmarkerColor

	if isKill then
		color = killHitmarkerColor
	elseif isHeadshot then
		color = headshotHitmarkerColor
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
	task.delay(hitmarkerDuration, function()
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
ammoFrame.ZIndex = 10
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
currentAmmoLabel.ZIndex = 11
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
ammoSeparator.ZIndex = 11
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
reserveAmmoLabel.ZIndex = 11
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
reloadLabel.ZIndex = 11
reloadLabel.Parent = ammoFrame

local function updateAmmoDisplay(current, reserve, max, isReloading)
	-- Track update time for debugging
	lastAmmoUpdate = tick()
	lastAmmoData = {current = current, reserve = reserve, max = max, isReloading = isReloading}
	
	if DEBUG_AMMO then
		print(string.format("[FPSHUD] updateAmmoDisplay called - current=%s, reserve=%s, max=%s, isReloading=%s", 
			tostring(current), tostring(reserve), tostring(max), tostring(isReloading)))
	end
	
	-- Show ammo UI as long as we have current/reserve data
	-- FIX: Don't hide UI just because max is nil - we can derive or estimate it
	if current == nil and reserve == nil then
		if DEBUG_AMMO then
			print("[FPSHUD] ✗ Hiding ammo frame - no current or reserve data")
		end
		ammoFrame.Visible = false
		return
	end

	ammoFrame.Visible = true

	currentAmmoLabel.Text = tostring(current or 0)
	reserveAmmoLabel.Text = tostring(reserve or 0)

	-- Color based on ammo level
	-- If max is explicitly 0, treat this as a zero-ammo weapon (e.g., melee) and hide the ammo UI
	if max == 0 then
		if DEBUG_AMMO then
			print("[FPSHUD] ✗ Hiding ammo frame - weapon has max=0 (melee weapon)")
		end
		ammoFrame.Visible = false
		return
	end

	local effectiveMax = max or DEFAULT_MAGAZINE_SIZE  -- Fallback to default mag size for weapons that have mags
	-- Final safeguard: ensure effectiveMax is positive to prevent division by zero or invalid ratios
	if not effectiveMax or effectiveMax <= 0 then
		effectiveMax = 1
	end
	local ammoRatio = (current or 0) / effectiveMax
	if ammoRatio <= lowAmmoThreshold then
		currentAmmoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		currentAmmoLabel.TextColor3 = Color3.new(1, 1, 1)
	end

	-- Reload indicator
	reloadLabel.Visible = isReloading and true or false
	if isReloading then
		reloadLabel.Text = "RELOADING..."
	end
	
	if DEBUG_AMMO then
		print(string.format("[FPSHUD] ✓ Ammo display updated - showing %s/%s (max=%s)", 
			tostring(current or 0), tostring(reserve or 0), tostring(effectiveMax)))
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
weaponInfoFrame.ZIndex = 10
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
weaponNameLabel.ZIndex = 11
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
fireModeLabel.ZIndex = 11
fireModeLabel.Parent = weaponInfoFrame

local function updateWeaponInfo(weaponName, fireMode)
	weaponNameLabel.Text = string.upper(weaponName or "UNKNOWN")
	fireModeLabel.Text = string.upper(fireMode or "SEMI")
end

--------------------------------------------------------------------------------
-- DAMAGE INDICATOR (screen vignette when hurt)
--------------------------------------------------------------------------------

local damageVignette = Instance.new("Frame")
damageVignette.Name = "DamageVignette"
damageVignette.Size = UDim2.new(1, 0, 1, 0)
damageVignette.Position = UDim2.new(0, 0, 0, 0)
damageVignette.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
damageVignette.BackgroundTransparency = 1
damageVignette.ZIndex = 50
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
	if not damageIndicatorEnabled then return end

	local t = 1 - (intensity or 0.3)
	damageVignette.BackgroundTransparency = t

	local tweenInfo = TweenInfo.new(damageIndicatorDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(damageVignette, tweenInfo, {
		BackgroundTransparency = 1
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
lowHealthVignette.ZIndex = 40
lowHealthVignette.Parent = screenGui

local lowHealthPulseActive = false
local lowHealthPulseThread = nil
local MAX_PULSE_ITERATIONS = 1000 -- Safety limit to prevent infinite loops

local function updateLowHealthVignette(healthPercent)
	if not lowHealthVignetteEnabled then return end

	if healthPercent <= lowHealthThreshold then
		if not lowHealthPulseActive then
			lowHealthPulseActive = true
			-- Cancel any existing pulse thread with error handling
			if lowHealthPulseThread then
				pcall(function()
					task.cancel(lowHealthPulseThread)
				end)
				lowHealthPulseThread = nil
			end
			-- Start pulsing with iteration limit
			lowHealthPulseThread = task.spawn(function()
				local iterations = 0
				while lowHealthPulseActive and iterations < MAX_PULSE_ITERATIONS do
					iterations = iterations + 1
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
				lowHealthPulseThread = nil
			end)
		end
	else
		lowHealthPulseActive = false
		-- Cancel the pulse thread if it exists with error handling
		if lowHealthPulseThread then
			pcall(function()
				task.cancel(lowHealthPulseThread)
			end)
			lowHealthPulseThread = nil
		end
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
		if DEBUG_AMMO then
			print(string.format("[FPSHUD] AmmoUpdate bindable event received - data type=%s", typeof(data)))
			if typeof(data) == "table" then
				print(string.format("[FPSHUD] AmmoUpdate data - current=%s, reserve=%s, max=%s, isReloading=%s",
					tostring(data.current), tostring(data.reserve), tostring(data.max), tostring(data.isReloading)))
			end
		end
		
		if typeof(data) == "table" then
			updateAmmoDisplay(data.current, data.reserve, data.max, data.isReloading)
		elseif DEBUG_AMMO then
			print("[FPSHUD] ✗ AmmoUpdate received invalid data type")
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

-- Watchdog to detect stale ammo data
local AMMO_STALE_THRESHOLD = 5.0  -- Seconds before ammo data is considered stale
local lastStaleWarning = 0

RunService.RenderStepped:Connect(function(deltaTime)
	-- Smooth crosshair spread animation
	if crosshairConfig.DynamicCrosshair ~= false then
		currentCrosshairGap = currentCrosshairGap + (targetCrosshairGap - currentCrosshairGap) * 0.2
		updateCrosshairPositions()
	end
	
	-- Watchdog: Check if ammo data is stale (only warn once every 10 seconds)
	if DEBUG_AMMO then
		local now = tick()
		local timeSinceUpdate = now - lastAmmoUpdate
		if timeSinceUpdate > AMMO_STALE_THRESHOLD and now - lastStaleWarning > 10 then
			lastStaleWarning = now
			warn(string.format("[FPSHUD] ⚠ Ammo data is stale (%.1fs since last update). Last data: current=%s, reserve=%s, max=%s",
				timeSinceUpdate,
				tostring(lastAmmoData and lastAmmoData.current),
				tostring(lastAmmoData and lastAmmoData.reserve),
				tostring(lastAmmoData and lastAmmoData.max)))
		end
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


--------------------------------------------------------------------------------
-- MODULE EXPORT
--------------------------------------------------------------------------------

local Module = {}

function Module.initialize()
initialize()
end

return Module
