-- BaseHealthUI.client.lua
-- Client script for displaying base health
-- Place in StarterGui as a LocalScript
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config (get max health from shared GameConfig)
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))

-- Initialize scale manager
UIScaleManager.initialize()

local DEFAULT_MAX_HEALTH = GameConfig.BASE_HEALTH or 1000

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "hudElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

----------------------------------------------------------------
-- UI creation
----------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseHealthUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main frame positioned below wave info on left side
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UIScaleManager.scaleSize(300, 60, "hudElements", "baseHealth")
-- Position below the WaveUI frame (which is at top-left)
mainFrame.Position = UIScaleManager.getPositionWithSafeArea("topLeft", 10, 130)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(20, "padding"))
titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(5, "padding"))
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Base Health"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = getScaledTextSize(16)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local healthBarBg = Instance.new("Frame")
healthBarBg.Name = "HealthBarBg"
healthBarBg.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
healthBarBg.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(30, "padding"))
healthBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBarBg.BorderSizePixel = 0
healthBarBg.Parent = mainFrame

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
healthBarCorner.Parent = healthBarBg

local healthBarFill = Instance.new("Frame")
healthBarFill.Name = "HealthBarFill"
healthBarFill.Size = UDim2.new(1, 0, 1, 0)
healthBarFill.Position = UDim2.new(0, 0, 0, 0)
healthBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
healthBarFill.BorderSizePixel = 0
healthBarFill.Parent = healthBarBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
fillCorner.Parent = healthBarFill

local healthText = Instance.new("TextLabel")
healthText.Name = "HealthText"
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "0 / 0"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.TextSize = getScaledTextSize(14)
healthText.Font = Enum.Font.GothamBold
healthText.ZIndex = 2
healthText.Parent = healthBarBg

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	mainFrame.Size = UIScaleManager.scaleSize(300, 60, "hudElements", "baseHealth")
	mainFrame.Position = UIScaleManager.getPositionWithSafeArea("topLeft", 10, 130)
	mainFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
	corner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))

	titleLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(20, "padding"))
	titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(5, "padding"))
	titleLabel.TextSize = getScaledTextSize(16)

	healthBarBg.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
	healthBarBg.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(30, "padding"))
	healthBarCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
	fillCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
	healthText.TextSize = getScaledTextSize(14)
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

----------------------------------------------------------------
-- State
----------------------------------------------------------------

local currentHealth = DEFAULT_MAX_HEALTH
local maxHealth = DEFAULT_MAX_HEALTH

----------------------------------------------------------------
-- Update logic
----------------------------------------------------------------

local function updateHealthBar(health, max)
	if type(health) == "number" then
		currentHealth = health
	end
	if type(max) == "number" and max > 0 then
		maxHealth = max
	end

	if maxHealth <= 0 then
		maxHealth = 1
	end

	local healthPercent = math.clamp(currentHealth / maxHealth, 0, 1)

	-- Update bar size
	healthBarFill:TweenSize(
		UDim2.new(healthPercent, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.2,
		true
	)

	-- Update text
	healthText.Text = string.format("%d / %d", math.floor(currentHealth), maxHealth)

	-- Colour + critical effect
	if healthPercent > 0.6 then
		healthBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255) -- Blue
	elseif healthPercent > 0.3 then
		healthBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100) -- Orange
	else
		healthBarFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red

		if healthPercent > 0 then
			-- small pulse
			healthBarFill:TweenSize(
				UDim2.new(healthPercent * 1.05, 0, 1, 0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Sine,
				0.4,
				true
			)
		end
	end
end

----------------------------------------------------------------
-- Remote event wiring
----------------------------------------------------------------

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- 1) Direct BaseHealthUpdate event (if server fires it)
local baseHealthEvent = remoteEvents:FindFirstChild("BaseHealthUpdate")
if baseHealthEvent and baseHealthEvent:IsA("RemoteEvent") then
	baseHealthEvent.OnClientEvent:Connect(function(health, max)
		updateHealthBar(health, max or DEFAULT_MAX_HEALTH)
	end)
end

-- 2) GameStateUpdate snapshot (expects .baseHealth in the payload)
local gameStateEvent = remoteEvents:FindFirstChild("GameStateUpdate")
if gameStateEvent and gameStateEvent:IsA("RemoteEvent") then
	gameStateEvent.OnClientEvent:Connect(function(stateData)
		if stateData and stateData.baseHealth then
			-- Use config max health unless server sends a max
			local max = stateData.baseHealthMax or DEFAULT_MAX_HEALTH
			updateHealthBar(stateData.baseHealth, max)
		end
	end)
end

----------------------------------------------------------------
-- Optional: watch a NumberValue on the base model (BaseCaptureZone.Health)
----------------------------------------------------------------

task.spawn(function()
	-- Match your actual base hierarchy: BaseCaptureZone (Model) with Health (NumberValue)
	local baseModel = workspace:FindFirstChild("BaseCaptureZone")
	if not baseModel then
		return
	end

	local healthValue = baseModel:FindFirstChild("Health", true)
	if healthValue and healthValue:IsA("NumberValue") then
		maxHealth = healthValue.Value
		currentHealth = healthValue.Value
		updateHealthBar(currentHealth, maxHealth)

		healthValue:GetPropertyChangedSignal("Value"):Connect(function()
			updateHealthBar(healthValue.Value, maxHealth)
		end)
	end
end)

----------------------------------------------------------------
-- Initial visual state
----------------------------------------------------------------

updateHealthBar(DEFAULT_MAX_HEALTH, DEFAULT_MAX_HEALTH)

print("BaseHealthUI initialized")

-- Return module table (required for ModuleScript compatibility)
local BaseHealthUI = {}
return BaseHealthUI
