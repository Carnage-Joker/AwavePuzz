-- InventoryUI.client.lua
-- Displays the player's cure components and currency balance
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Load UI scaling utilities
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))

-- Initialize scale manager
UIScaleManager.initialize()

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local inventoryEvent = remoteFolder:WaitForChild("InventoryUpdate")
local currencyEvent = remoteFolder:WaitForChild("CurrencyUpdate")

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "hudElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Calculate position dynamically based on elements above (WaveUI + BaseHealthUI)
local function getInventoryYOffset()
	local waveUIHeight = UIScaleManager.scalePixels(120, "hudElements")
	local baseHealthHeight = UIScaleManager.scalePixels(60, "hudElements")
	local spacing = UIScaleManager.scalePixels(10, "padding")
	return waveUIHeight + baseHealthHeight + spacing * 2
end

local frame = Instance.new("Frame")
frame.Size = UIScaleManager.scaleSize(250, 120, "hudElements", "inventory")
frame.Position = UIScaleManager.getPositionWithSafeArea("topLeft", 10, getInventoryYOffset())
frame.AnchorPoint = Vector2.new(0, 0)
frame.BackgroundTransparency = UIScaleManager.isMobile() and 0.45 or 0.35
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
title.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = getScaledTextSize(16)
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Inventory"
title.Parent = frame

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
currencyLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(30, "padding"))
currencyLabel.BackgroundTransparency = 1
currencyLabel.Font = Enum.Font.GothamBold
currencyLabel.TextSize = getScaledTextSize(14)
currencyLabel.TextColor3 = Color3.new(0.8, 0.95, 0.8)
currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
currencyLabel.Text = "Currency: 0"
currencyLabel.Parent = frame

local componentsLabel = Instance.new("TextLabel")
componentsLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
componentsLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(55, "padding"))
componentsLabel.BackgroundTransparency = 1
componentsLabel.Font = Enum.Font.Gotham
componentsLabel.TextSize = getScaledTextSize(13)
componentsLabel.TextWrapped = true
componentsLabel.TextXAlignment = Enum.TextXAlignment.Left
componentsLabel.TextYAlignment = Enum.TextYAlignment.Top
componentsLabel.TextColor3 = Color3.new(1, 1, 1)
componentsLabel.Text = "Components: none"
componentsLabel.Parent = frame

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	frame.Size = UIScaleManager.scaleSize(250, 120, "hudElements", "inventory")
	frame.Position = UIScaleManager.getPositionWithSafeArea("topLeft", 10, getInventoryYOffset())
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BackgroundTransparency = UIScaleManager.isMobile() and 0.45 or 0.35
	frameCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	
	title.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
	title.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	title.TextSize = getScaledTextSize(16)
	
	currencyLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
	currencyLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(30, "padding"))
	currencyLabel.TextSize = getScaledTextSize(14)
	
	componentsLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
	componentsLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(55, "padding"))
	componentsLabel.TextSize = getScaledTextSize(13)
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

local function formatInventory(inventory)
	local parts = {}

	if type(inventory) ~= "table" then
		return "Components: none"
	end

	for name, count in pairs(inventory) do
		local safeName = tostring(name or "Unknown")
		local safeCount = tonumber(count) or 0
		table.insert(parts, string.format("%s x%d", safeName, safeCount))
	end

	table.sort(parts)

	if #parts == 0 then
		return "Components: none"
	end

	return "Components: " .. table.concat(parts, ", ")
end

inventoryEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	componentsLabel.Text = formatInventory(payload.inventory)
end)

currencyEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	local balance = tonumber(payload.balance) or 0
	currencyLabel.Text = "Currency: " .. tostring(balance)
end)
