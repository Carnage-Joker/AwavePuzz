-- PuzzleMenuUI.client.lua
-- Client-side UI for selecting which puzzle to attempt at cure station
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local PuzzleConfig = require(SharedFolder:WaitForChild("PuzzleConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config
local MIN_TOUCH_TARGET = UIScaleConfig.MinSizes.touchTarget.width

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PuzzleMenuUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Menu frame (hidden by default) - centered with scaled size
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UIScaleManager.scaleSize(500, 600, "menuElements", "menuDialog")
menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
menuFrame.BackgroundTransparency = 0.05
menuFrame.BorderSizePixel = 3
menuFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
menuFrame.Visible = false
menuFrame.ZIndex = 100
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
menuCorner.Parent = menuFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, getScaledValue(50, "padding"))
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
titleBarCorner.Parent = titleBar

-- Title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -getScaledValue(60, "padding"), 1, 0)
titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Cure Station - Select Puzzle"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = getScaledTextSize(22)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button with minimum touch target
local closeButtonSize = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
closeButton.Position = UDim2.new(1, -closeButtonSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = getScaledTextSize(24)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	menuFrame.Visible = false
end)

-- Instructions
local instructionLabel = Instance.new("TextLabel")
instructionLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(50, "padding"))
instructionLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
instructionLabel.BackgroundTransparency = 1
instructionLabel.Text = "Select a puzzle to attempt. You need 5 components to unlock each puzzle."
instructionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
instructionLabel.TextSize = getScaledTextSize(14)
instructionLabel.Font = Enum.Font.Gotham
instructionLabel.TextWrapped = true
instructionLabel.TextXAlignment = Enum.TextXAlignment.Left
instructionLabel.Parent = menuFrame

-- Puzzle list (ScrollingFrame)
local puzzleList = Instance.new("ScrollingFrame")
puzzleList.Name = "PuzzleList"
puzzleList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(130, "padding"))
puzzleList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(120, "padding"))
puzzleList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
puzzleList.BackgroundTransparency = 0.5
puzzleList.BorderSizePixel = 0
puzzleList.ScrollBarThickness = getScaledValue(8, "padding")
puzzleList.CanvasSize = UDim2.new(0, 0, 0, 0)
puzzleList.Parent = menuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, getScaledValue(10, "padding"))
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = puzzleList

-- Update canvas size when content changes
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	puzzleList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + getScaledValue(10, "padding"))
end)

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	menuFrame.Size = UIScaleManager.scaleSize(500, 600, "menuElements", "menuDialog")
	menuCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
	
	titleBar.Size = UDim2.new(1, 0, 0, getScaledValue(50, "padding"))
	titleBarCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
	titleLabel.TextSize = getScaledTextSize(22)
	
	local newCloseSize = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
	closeButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
	closeButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	closeButton.TextSize = getScaledTextSize(24)
	closeCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	
	instructionLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(50, "padding"))
	instructionLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
	instructionLabel.TextSize = getScaledTextSize(14)
	
	puzzleList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(130, "padding"))
	puzzleList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(120, "padding"))
	puzzleList.ScrollBarThickness = getScaledValue(8, "padding")
	listLayout.Padding = UDim.new(0, getScaledValue(10, "padding"))
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updatePuzzleMenuScaling)

-- Function to create puzzle button
local function createPuzzleButton(componentName, puzzleConfig, available, componentCount)
	local button = Instance.new("TextButton")
	button.Name = componentName
	button.Size = UDim2.new(1, -10, 0, 80)
	button.BackgroundColor3 = available and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(60, 60, 60)
	button.AutoButtonColor = available
	button.Parent = puzzleList

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	-- Component name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = componentName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	-- Puzzle name
	local puzzleLabel = Instance.new("TextLabel")
	puzzleLabel.Size = UDim2.new(1, -20, 0, 20)
	puzzleLabel.Position = UDim2.new(0, 10, 0, 30)
	puzzleLabel.BackgroundTransparency = 1
	puzzleLabel.Text = puzzleConfig.name .. " (" .. puzzleConfig.type .. ")"
	puzzleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	puzzleLabel.TextSize = 14
	puzzleLabel.Font = Enum.Font.Gotham
	puzzleLabel.TextXAlignment = Enum.TextXAlignment.Left
	puzzleLabel.Parent = button

	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 20)
	statusLabel.Position = UDim2.new(0, 10, 0, 55)
	statusLabel.BackgroundTransparency = 1
	if available then
		statusLabel.Text = string.format("Ready to attempt (%d/5 components)", componentCount)
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		statusLabel.Text = string.format("Need more components (%d/5)", componentCount)
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = button

	-- Click handler
	if available then
		button.MouseButton1Click:Connect(function()
			-- Request puzzle from server
			local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remoteEvents and remoteEvents:FindFirstChild("RequestPuzzle") then
				remoteEvents.RequestPuzzle:FireServer(componentName)
				menuFrame.Visible = false
			end
		end)
	end

	return button
end

-- Function to populate puzzle menu
local function updatePuzzleMenu(progressData)
	-- Clear existing buttons
	for _, child in ipairs(puzzleList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	progressData = progressData or {}
	local componentPuzzles = progressData.componentPuzzles or {}
	local componentCounts = progressData.componentCounts or {}

	-- Create buttons for each component puzzle
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		local puzzleConfig = PuzzleConfig.ComponentPuzzles[componentName]
		if puzzleConfig then
			local puzzleProgress = componentPuzzles[componentName] or {}
			local componentCount = componentCounts[componentName] or 0
			local available = componentCount >= GameConfig.CURE_COMPONENTS_REQUIRED and not puzzleProgress.solved

			createPuzzleButton(componentName, puzzleConfig, available, componentCount)
		end
	end

	-- Add final synthesis button
	local finalPuzzleData = progressData.finalPuzzle or {}
	local readyForFinal = progressData.readyForFinal or false
	local finalSolved = finalPuzzleData.solved or false
	local finalAvailable = readyForFinal and not finalSolved
	local finalButton = Instance.new("TextButton")
	finalButton.Name = "FinalSynthesis"
	finalButton.Size = UDim2.new(1, -10, 0, 100)
	finalButton.BackgroundColor3 = finalAvailable and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(60, 60, 60)
	finalButton.AutoButtonColor = finalAvailable
	finalButton.LayoutOrder = 999
	finalButton.Parent = puzzleList

	local finalCorner = Instance.new("UICorner")
	finalCorner.CornerRadius = UDim.new(0, 8)
	finalCorner.Parent = finalButton

	local finalLabel = Instance.new("TextLabel")
	finalLabel.Size = UDim2.new(1, -20, 0, 30)
	finalLabel.Position = UDim2.new(0, 10, 0, 10)
	finalLabel.BackgroundTransparency = 1
	finalLabel.Text = "⚗️ FINAL SYNTHESIS ⚗️"
	finalLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	finalLabel.TextSize = 22
	finalLabel.Font = Enum.Font.GothamBold
	finalLabel.Parent = finalButton

	local finalDesc = Instance.new("TextLabel")
	finalDesc.Size = UDim2.new(1, -20, 0, 50)
	finalDesc.Position = UDim2.new(0, 10, 0, 45)
	finalDesc.BackgroundTransparency = 1
	finalDesc.Text = "Complete all 5 component puzzles to unlock\nThis will synthesize the cure and WIN the game!"
	finalDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	finalDesc.TextSize = 12
	finalDesc.Font = Enum.Font.Gotham
	finalDesc.TextWrapped = true
	finalDesc.TextXAlignment = Enum.TextXAlignment.Left
	finalDesc.Parent = finalButton

	if finalAvailable then
		finalButton.MouseButton1Click:Connect(function()
			local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remoteEvents and remoteEvents:FindFirstChild("RequestPuzzle") then
				remoteEvents.RequestPuzzle:FireServer("FinalSynthesis")
				menuFrame.Visible = false
			end
		end)
	end
end

-- Show puzzle menu
local function showPuzzleMenu()
	menuFrame.Visible = true
	-- Request puzzle progress from server
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("RequestPuzzleProgress") then
		remoteEvents.RequestPuzzleProgress:FireServer()
	end
end

-- Remote event handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Listen for puzzle menu requests
local cureUpdateEvent = remoteEvents:WaitForChild("CureUpdate")
cureUpdateEvent.OnClientEvent:Connect(function(data)
	if type(data) == "table" and data.type == "show_puzzle_menu" then
		showPuzzleMenu()
	end
end)

-- Listen for puzzle progress updates
local puzzleUpdateEvent = remoteEvents:WaitForChild("PuzzleUpdate")
puzzleUpdateEvent.OnClientEvent:Connect(function(data)
	if type(data) == "table" and data.type == "progress" then
		updatePuzzleMenu(data.progress)
	end
end)

print("PuzzleMenuUI initialized")
