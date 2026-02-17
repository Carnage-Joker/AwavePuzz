-- PuzzleMenuUI.lua
-- Client-side UI for selecting which puzzle to attempt at cure station
-- Updated with dynamic UI scaling for mobile devices.
-- Refactored to use UIConnectionMaid and proper keyboard selection

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local PuzzleConfig = require(SharedFolder:WaitForChild("PuzzleConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))
local UIConnectionMaid = require(SharedFolder:WaitForChild("UI"):WaitForChild("UIConnectionMaid"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Connection tracking for cleanup
local maid = UIConnectionMaid.new()
local buttonMaid = UIConnectionMaid.new() -- Separate maid for button connections
local connections = {} -- Track connections that need early setup

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config with fallback
local MIN_TOUCH_TARGET = (UIScaleConfig.MinSizes.touchTarget and UIScaleConfig.MinSizes.touchTarget.width) or 44

-- Prevent duplicate UI instances
local existing = playerGui:FindFirstChild("PuzzleMenuUI")
if existing then
	UIDebugConfig.warnDuplicate("PuzzleMenuUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("PuzzleMenuUI", "Creating ScreenGui", "PuzzleMenuUI.lua")

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

connections.closeButton = closeButton.MouseButton1Click:Connect(function()
	menuFrame.Visible = false
	ModalManager.remove("PuzzleMenuUI")
	-- Disable puzzle menu input actions when closing via close button
	InputActionRegistry.disableOwner("PuzzleMenuUI")
end)

-- ESC/Backspace handled globally by ModalManager

-- Instructions
local instructionLabel = Instance.new("TextLabel")
instructionLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(50, "padding"))
instructionLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
instructionLabel.BackgroundTransparency = 1
instructionLabel.Text = "↑/↓ or W/S: Navigate • Enter: Select • Backspace: Close\nYou need 5 components to unlock each puzzle."
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

-- Register for scale changes (returns unsubscribe function)
local scaleChangedUnsubscribe = UIScaleManager.onScaleChanged(updateUIScaling)
connections.scaleChanged = {
	Disconnect = function()
		if scaleChangedUnsubscribe then
			scaleChangedUnsubscribe()
			scaleChangedUnsubscribe = nil
		end
	end
}

-- Module state
local remotes = nil -- Will be set via bindRemotes()
local puzzleButtons = {}
local puzzleButtonData = {} -- Maps button to its component name and availability
local selectedPuzzleIndex = 1

-- Helper function to request a puzzle from the server
local function requestPuzzle(componentName)
	if not remotes or not remotes.RequestPuzzle then
		warn("[PuzzleMenuUI] RequestPuzzle remote not available")
		return
	end
	print("[PuzzleMenuUI] Requesting puzzle:", componentName)
	remotes.RequestPuzzle:FireServer(componentName)
	menuFrame.Visible = false
end

local function updatePuzzleSelection()
	-- Update visual indication of selected puzzle
	for i, button in ipairs(puzzleButtons) do
		local buttonCorner = button:FindFirstChildOfClass("UICorner")
		
		if i == selectedPuzzleIndex then
			-- Add selection border
			local stroke = button:FindFirstChild("SelectionStroke")
			if not stroke then
				stroke = Instance.new("UIStroke")
				stroke.Name = "SelectionStroke"
				stroke.Parent = button
			end
			stroke.Thickness = 3
			stroke.Color = Color3.fromRGB(100, 200, 255)
		else
			-- Remove selection border
			local stroke = button:FindFirstChild("SelectionStroke")
			if stroke then
				stroke:Destroy()
			end
		end
	end
	
	-- Scroll to selected button if needed
	if #puzzleButtons > 0 and puzzleButtons[selectedPuzzleIndex] then
		local selectedButton = puzzleButtons[selectedPuzzleIndex]
		local buttonPos = selectedButton.AbsolutePosition.Y - puzzleList.AbsolutePosition.Y
		local listHeight = puzzleList.AbsoluteSize.Y
		local canvasPos = puzzleList.CanvasPosition.Y
		
		-- Scroll down if button is below visible area
		if buttonPos + selectedButton.AbsoluteSize.Y > canvasPos + listHeight then
			puzzleList.CanvasPosition = Vector2.new(0, buttonPos + selectedButton.AbsoluteSize.Y - listHeight)
		-- Scroll up if button is above visible area
		elseif buttonPos < canvasPos then
			puzzleList.CanvasPosition = Vector2.new(0, buttonPos)
		end
	end
end

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
		buttonMaid:Give(button.MouseButton1Click:Connect(function()
			requestPuzzle(componentName)
		end))
	end
	
	-- Store button data for keyboard selection
	puzzleButtonData[button] = {
		componentName = componentName,
		available = available
	}

	return button
end

-- Function to populate puzzle menu
local function updatePuzzleMenu(progressData)
	-- Clean up button connections and data
	buttonMaid:Cleanup()
	puzzleButtonData = {}
	
	-- Clear existing buttons
	for _, child in ipairs(puzzleList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Clear button array
	puzzleButtons = {}
	selectedPuzzleIndex = 1

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

			local button = createPuzzleButton(componentName, puzzleConfig, available, componentCount)
			table.insert(puzzleButtons, button)
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
		buttonMaid:Give(finalButton.MouseButton1Click:Connect(function()
			requestPuzzle("FinalSynthesis")
		end))
	end
	
	-- Store button data for keyboard selection
	puzzleButtonData[finalButton] = {
		componentName = "FinalSynthesis",
		available = finalAvailable
	}
	
	-- Add final button to tracked buttons
	table.insert(puzzleButtons, finalButton)
	
	-- Update selection visuals
	if #puzzleButtons > 0 then
		updatePuzzleSelection()
	end
end

-- Show puzzle menu
local function showPuzzleMenu()
	menuFrame.Visible = true
	
	-- Register with ModalManager and enable puzzle menu input actions
	ModalManager.push("PuzzleMenuUI", function()
		menuFrame.Visible = false
		-- Disable puzzle menu input actions when closing
		InputActionRegistry.disableOwner("PuzzleMenuUI")
	end, ModalManager.Priority.MODAL)
	
	-- Enable puzzle menu input actions when opening
	InputActionRegistry.enableOwner("PuzzleMenuUI")
	
	-- Request puzzle progress from server
	if remotes and remotes.RequestPuzzleProgress then
		remotes.RequestPuzzleProgress:FireServer()
	end
end

-- Bind remotes from RemoteRegistry (called by ClientMainModule)
local function bindRemotes(providedRemotes)
	if not providedRemotes then
		warn("[PuzzleMenuUI] bindRemotes: No remotes provided")
		return
	end
	
	remotes = providedRemotes
	
	if not remotes.CureUpdate or not remotes.PuzzleUpdate or not remotes.RequestPuzzle or not remotes.RequestPuzzleProgress then
		warn("[PuzzleMenuUI] Missing required remotes")
		return
	end
	
	-- Listen for puzzle menu requests
	maid:Give(remotes.CureUpdate.OnClientEvent:Connect(function(data)
		if type(data) == "table" and data.type == "show_puzzle_menu" then
			showPuzzleMenu()
		end
	end), "cureUpdate")
	
	-- Listen for puzzle progress updates
	maid:Give(remotes.PuzzleUpdate.OnClientEvent:Connect(function(data)
		if type(data) == "table" and data.type == "progress" then
			updatePuzzleMenu(data.progress)
		end
	end), "puzzleUpdate")
	
	print("[PuzzleMenuUI] Remotes bound successfully")
end

-- Keyboard navigation handler
maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	-- Only process if menu is visible and is the top modal
	if not menuFrame.Visible or not ModalManager.isTopModal("PuzzleMenuUI") then
		return
	end
	
	if #puzzleButtons > 0 then
		-- Navigation when menu is open
		if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
			-- Check if navigate up action is enabled
			local action = InputActionRegistry.getAction("PuzzleMenuNavigateUp")
			if action and action.enabled then
				selectedPuzzleIndex = selectedPuzzleIndex - 1
				if selectedPuzzleIndex < 1 then
					selectedPuzzleIndex = #puzzleButtons
				end
				updatePuzzleSelection()
			end
		elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
			-- Check if navigate down action is enabled
			local action = InputActionRegistry.getAction("PuzzleMenuNavigateDown")
			if action and action.enabled then
				selectedPuzzleIndex = selectedPuzzleIndex + 1
				if selectedPuzzleIndex > #puzzleButtons then
					selectedPuzzleIndex = 1
				end
				updatePuzzleSelection()
			end
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			-- Check if select action is enabled
			local action = InputActionRegistry.getAction("PuzzleMenuSelect")
			if action and action.enabled then
				-- Use stored button data instead of firing signal
				local button = puzzleButtons[selectedPuzzleIndex]
				if button then
					local data = puzzleButtonData[button]
					if data and data.available then
						requestPuzzle(data.componentName)
					end
				end
			end
		end
	end
end), "navigation")

-- Register input actions with InputActionRegistry
-- Navigation and selection actions disabled by default until menu opens to avoid conflicts
InputActionRegistry.register("PuzzleMenuNavigateUp", "PuzzleMenuUI", {Enum.KeyCode.Up, Enum.KeyCode.W}, InputActionRegistry.Priority.MODAL_UI, false)
InputActionRegistry.register("PuzzleMenuNavigateDown", "PuzzleMenuUI", {Enum.KeyCode.Down, Enum.KeyCode.S}, InputActionRegistry.Priority.MODAL_UI, false)
InputActionRegistry.register("PuzzleMenuSelect", "PuzzleMenuUI", {Enum.KeyCode.Return, Enum.KeyCode.Space}, InputActionRegistry.Priority.MODAL_UI, false)

-- Cleanup function
local function cleanup()
	-- Unregister input actions
	InputActionRegistry.unregister("PuzzleMenuNavigateUp")
	InputActionRegistry.unregister("PuzzleMenuNavigateDown")
	InputActionRegistry.unregister("PuzzleMenuSelect")
	
	-- Clean up all connections
	maid:Cleanup()
	buttonMaid:Cleanup()
	
	-- Remove from ModalManager if still open
	if menuFrame.Visible then
		ModalManager.remove("PuzzleMenuUI")
	end
end

-- Handle respawn - cleanup connections
maid:Give(player.CharacterRemoving:Connect(cleanup), "characterRemoving")

print("[PuzzleMenuUI] Module loaded")

-- Return module table (required for ModuleScript compatibility)
local PuzzleMenuUI = {}

PuzzleMenuUI.bindRemotes = bindRemotes

function PuzzleMenuUI.cleanup()
	cleanup()
	
	if screenGui then
		screenGui:Destroy()
	end
end

return PuzzleMenuUI
