-- BaseHealthUI.client.lua
-- Client script for displaying base health
-- Place in StarterGui as a LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseHealthUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 60)
mainFrame.Position = UDim2.new(0, 10, 0, 140)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
mainFrame.Parent = screenGui

-- Add corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -20, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Base Health"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Health Bar Background
local healthBarBg = Instance.new("Frame")
healthBarBg.Name = "HealthBarBg"
healthBarBg.Size = UDim2.new(1, -20, 0, 25)
healthBarBg.Position = UDim2.new(0, 10, 0, 30)
healthBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBarBg.BorderSizePixel = 0
healthBarBg.Parent = mainFrame

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 5)
healthBarCorner.Parent = healthBarBg

-- Health Bar Fill
local healthBarFill = Instance.new("Frame")
healthBarFill.Name = "HealthBarFill"
healthBarFill.Size = UDim2.new(1, 0, 1, 0)
healthBarFill.Position = UDim2.new(0, 0, 0, 0)
healthBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
healthBarFill.BorderSizePixel = 0
healthBarFill.Parent = healthBarBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = healthBarFill

-- Health Text
local healthText = Instance.new("TextLabel")
healthText.Name = "HealthText"
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "1000 / 1000"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.TextSize = 14
healthText.Font = Enum.Font.GothamBold
healthText.ZIndex = 2
healthText.Parent = healthBarBg

-- State
local currentHealth = 1000
local maxHealth = 1000

-- Functions
local function updateHealthBar(health, max)
	currentHealth = health or currentHealth
	maxHealth = max or maxHealth
	
	local healthPercent = currentHealth / maxHealth
	
	-- Update bar size
	healthBarFill:TweenSize(
		UDim2.new(healthPercent, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.3,
		true
	)
	
	-- Update text
	healthText.Text = math.floor(currentHealth) .. " / " .. maxHealth
	
	-- Change color based on health percentage
	if healthPercent > 0.6 then
		healthBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255) -- Blue
	elseif healthPercent > 0.3 then
		healthBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100) -- Orange
	else
		healthBarFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red
		
		-- Pulse effect when critical
		if healthPercent > 0 then
			healthBarFill:TweenSize(
				UDim2.new(healthPercent * 1.05, 0, 1, 0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Sine,
				0.5,
				true
			)
		end
	end
end

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Base Health Update
local baseHealthEvent = remoteEvents:WaitForChild("BaseHealthUpdate", 10)
if baseHealthEvent then
	baseHealthEvent.OnClientEvent:Connect(function(health, max)
		updateHealthBar(health, max)
	end)
end

-- Game State Update (also contains base health)
local gameStateEvent = remoteEvents:WaitForChild("GameStateUpdate")
gameStateEvent.OnClientEvent:Connect(function(stateData)
	if stateData.baseHealth then
		-- Assuming max health is 1000 (or get from config)
		updateHealthBar(stateData.baseHealth, maxHealth)
	end
end)

-- Monitor base health value if it exists in workspace
task.spawn(function()
	local base = workspace:WaitForChild("Base", 10)
	if base then
		local healthValue = base:FindFirstChild("Health") or base:FindFirstChild("Core")
		if healthValue and healthValue:IsA("NumberValue") then
			-- Initial update
			maxHealth = healthValue.Value
			currentHealth = healthValue.Value
			updateHealthBar(currentHealth, maxHealth)
			
			-- Listen for changes
			healthValue:GetPropertyChangedSignal("Value"):Connect(function()
				updateHealthBar(healthValue.Value, maxHealth)
			end)
		end
	end
end)

-- Initial update
updateHealthBar(1000, 1000)

print("BaseHealthUI initialized")
