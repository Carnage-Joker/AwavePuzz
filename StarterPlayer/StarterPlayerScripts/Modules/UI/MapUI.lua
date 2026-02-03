-- MapUI.lua
-- Placeholder for map display system
-- Shows minimap or full map overlay when toggled with M key
-- NOTE: This is a placeholder implementation for Phase 3 input system registration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Prevent duplicate UI instances
local existing = playerGui:FindFirstChild("MapUI")
if existing then
	UIDebugConfig.warnDuplicate("MapUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("MapUI", "Creating ScreenGui", "MapUI.lua")

-- Create placeholder map UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MapUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false  -- Hidden by default, toggle with M key
screenGui.DisplayOrder = 50
screenGui.Parent = playerGui

-- Placeholder frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 400)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(100, 100, 120)
frameStroke.Parent = frame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 50)
titleLabel.Position = UDim2.new(0, 20, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Text = "MAP (Placeholder)"
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = frame

-- Info label
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -40, 1, -80)
infoLabel.Position = UDim2.new(0, 20, 0, 60)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 16
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Text = "Map display functionality will be implemented in a future phase.\n\nPress M or DPad Down to close."
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = frame

-- Toggle map display with M key
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	if input.KeyCode == Enum.KeyCode.M then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

-- Register MAP action with InputActionRegistry
InputActionRegistry.register("MapToggle", "MapUI", {Enum.KeyCode.M}, InputActionRegistry.Priority.TOGGLE_UI)
InputActionRegistry.register("MapToggleGamepad", "MapUI", {Enum.KeyCode.DPadDown}, InputActionRegistry.Priority.TOGGLE_UI)

print("[MapUI] Placeholder map display initialized (toggle with M key)")

-- Return module table
local MapUI = {}
return MapUI
