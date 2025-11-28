-- ShopUI.client.lua
-- Simple in-game shop interface for purchasing weapons and upgrades
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Load UI scaling utilities
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))

-- Initialize scale manager
UIScaleManager.initialize()

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local shopRequest = remoteFolder:WaitForChild("ShopRequest")
local shopUpdate = remoteFolder:WaitForChild("ShopUpdate")

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config
local MIN_TOUCH_TARGET = UIScaleConfig.MinSizes.touchTarget.width

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Center the shop dialog with scaled size
local frame = Instance.new("Frame")
frame.Size = UIScaleManager.scaleSize(300, 320, "menuElements", "menuDialog")
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(30, "padding"))
title.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = getScaledTextSize(20)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Camp Vendor"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Close button with minimum touch target
local closeButtonSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
closeButton.Position = UDim2.new(1, -closeButtonSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = getScaledTextSize(18)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -getScaledValue(10, "padding"), 1, -getScaledValue(70, "padding"))
list.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(40, "padding"))
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarThickness = getScaledValue(6, "padding")
list.BackgroundTransparency = 0.4
list.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
list.BorderSizePixel = 0
list.ClipsDescendants = true
list.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, getScaledValue(4, "padding"))
padding.PaddingBottom = UDim.new(0, getScaledValue(4, "padding"))
padding.PaddingLeft = UDim.new(0, getScaledValue(4, "padding"))
padding.PaddingRight = UDim.new(0, getScaledValue(4, "padding"))
padding.Parent = list

local layout = Instance.new("UIListLayout")
layout.Parent = list
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, getScaledValue(6, "padding"))

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
statusLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 1, -getScaledValue(25, "padding"))
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Arcade
statusLabel.TextSize = getScaledTextSize(14)
statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
statusLabel.Text = "Press B to toggle shop"
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	frame.Size = UIScaleManager.scaleSize(300, 320, "menuElements", "menuDialog")
	frameCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
	
	title.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(30, "padding"))
	title.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	title.TextSize = getScaledTextSize(20)
	
	local newCloseSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
	closeButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
	closeButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	closeButton.TextSize = getScaledTextSize(18)
	closeCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
	
	list.Size = UDim2.new(1, -getScaledValue(10, "padding"), 1, -getScaledValue(70, "padding"))
	list.Position = UDim2.new(0, getScaledValue(5, "padding"), 0, getScaledValue(40, "padding"))
	list.ScrollBarThickness = getScaledValue(6, "padding")
	
	padding.PaddingTop = UDim.new(0, getScaledValue(4, "padding"))
	padding.PaddingBottom = UDim.new(0, getScaledValue(4, "padding"))
	padding.PaddingLeft = UDim.new(0, getScaledValue(4, "padding"))
	padding.PaddingRight = UDim.new(0, getScaledValue(4, "padding"))
	layout.Padding = UDim.new(0, getScaledValue(6, "padding"))
	
	statusLabel.Size = UDim2.new(1, -getScaledValue(10, "padding"), 0, getScaledValue(20, "padding"))
	statusLabel.Position = UDim2.new(0, getScaledValue(5, "padding"), 1, -getScaledValue(25, "padding"))
	statusLabel.TextSize = getScaledTextSize(14)
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

local catalogCache = {}
local debounce = false

local function updateCanvasSize()
	list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

local function rebuildList(items)
	-- Preserve layout and padding while clearing entries
	for _, child in ipairs(list:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	for _, item in ipairs(items) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 60)
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextWrapped = true
		button.Font = Enum.Font.Gotham
		button.TextSize = 14

		local idText = item.Type == "weapon" and item.WeaponId or item.UpgradeId or item.Id or "Unknown"
		local price = tonumber(item.Price) or 0
		local desc = item.Description or ""

		button.Text = string.format("%s\n$%d - %s", idText, price, desc)
		button.AutoButtonColor = true
		button.Parent = list

		button.MouseButton1Click:Connect(function()
			if debounce then return end
			debounce = true

			statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
			statusLabel.Text = "Processing purchase..."
			shopRequest:FireServer("purchase", { itemId = item.Id })

			task.delay(0.25, function()
				debounce = false
			end)
		end)
	end

	updateCanvasSize()
end

shopUpdate.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.type == "catalog" then
		catalogCache = payload.items or {}
		rebuildList(catalogCache)
		statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
		statusLabel.Text = "Select an item to purchase"
	elseif payload.type == "result" then
		local success = payload.success == true
		statusLabel.TextColor3 = success and Color3.new(0.7, 1, 0.7) or Color3.new(1, 0.6, 0.6)
		statusLabel.Text = payload.message or (success and "Purchase successful" or "Purchase failed")
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end

	if input.KeyCode == Enum.KeyCode.B then
		screenGui.Enabled = not screenGui.Enabled

		if screenGui.Enabled then
			statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
			statusLabel.Text = "Loading shop..."
			shopRequest:FireServer("catalog")
		else
			statusLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
			statusLabel.Text = "Press B to toggle shop"
		end
	end
end)
