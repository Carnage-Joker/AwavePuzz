-- CureUI.client.lua
-- Client script for displaying cure progress and puzzle interface
-- Place in StarterGui as a LocalScript
-- Features:
-- - When 5 like components are collected, player must solve puzzle at cure station
-- - After all 5 component puzzles solved, final synthesis puzzle triggers cure win
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "hudElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config with fallback
local MIN_TOUCH_TARGET = (UIScaleConfig.MinSizes.touchTarget and UIScaleConfig.MinSizes.touchTarget.width) or 44

-- Prevent duplicate UI instances
local existing = playerGui:FindFirstChild("CureUI")
if existing then
	UIDebugConfig.warnDuplicate("CureUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("CureUI", "Creating ScreenGui", "CureUI.lua")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CureUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.Parent = playerGui

-- Progress Frame (always visible - positioned top-right with safe area)
local progressFrame = Instance.new("Frame")
progressFrame.Name = "ProgressFrame"
progressFrame.Size = UIScaleManager.scaleSize(300, 100, "hudElements", "cureProgress")
progressFrame.Position = UIScaleManager.getPositionWithSafeArea("topRight", 10, 0)
progressFrame.AnchorPoint = Vector2.new(1, 0)
progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
progressFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
progressFrame.BorderSizePixel = 2
progressFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
progressFrame.Active = true
progressFrame.Parent = screenGui

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
progressCorner.Parent = progressFrame

-- Title
local progressTitle = Instance.new("TextLabel")
progressTitle.Name = "Title"
progressTitle.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
progressTitle.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(5, "padding"))
progressTitle.BackgroundTransparency = 1
progressTitle.Text = "Cure Progress"
progressTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
progressTitle.TextSize = getScaledTextSize(18)
progressTitle.Font = Enum.Font.GothamBold
progressTitle.TextXAlignment = Enum.TextXAlignment.Left
progressTitle.Parent = progressFrame

-- Progress Bar Background
local progressBarBg = Instance.new("Frame")
progressBarBg.Name = "ProgressBarBg"
progressBarBg.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
progressBarBg.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(35, "padding"))
progressBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressBarBg.BorderSizePixel = 0
progressBarBg.Parent = progressFrame

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
progressBarCorner.Parent = progressBarBg

-- Progress Bar Fill
local progressBarFill = Instance.new("Frame")
progressBarFill.Name = "ProgressBarFill"
progressBarFill.Size = UDim2.new(0, 0, 1, 0)
progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
progressBarFill.BorderSizePixel = 0
progressBarFill.Parent = progressBarBg

local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
progressFillCorner.Parent = progressBarFill

-- Progress Text
local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "0%"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextSize = getScaledTextSize(16)
progressText.Font = Enum.Font.GothamBold
progressText.ZIndex = 2
progressText.Parent = progressBarBg

-- Components Info
local componentsLabel = Instance.new("TextLabel")
componentsLabel.Name = "ComponentsLabel"
componentsLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
componentsLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(70, "padding"))
componentsLabel.BackgroundTransparency = 1
componentsLabel.Text = "0 / 0 Components"
componentsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
componentsLabel.TextSize = getScaledTextSize(14)
componentsLabel.Font = Enum.Font.Gotham
componentsLabel.TextXAlignment = Enum.TextXAlignment.Left
componentsLabel.Parent = progressFrame

-- Detailed Components Frame (shows on click or interaction - centered, scaled for menus)
local detailFrame = Instance.new("Frame")
detailFrame.Name = "DetailFrame"
detailFrame.Size = UIScaleManager.scaleSize(350, 250, "menuElements", "menuDialog")
detailFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
detailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
detailFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
detailFrame.BackgroundTransparency = 0.1
detailFrame.BorderSizePixel = 3
detailFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
detailFrame.Visible = false
detailFrame.ZIndex = 10
detailFrame.Active = true
detailFrame.Parent = screenGui

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
detailCorner.Parent = detailFrame

-- Detail Title
local detailTitle = Instance.new("TextLabel")
detailTitle.Name = "Title"
detailTitle.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
detailTitle.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
detailTitle.BackgroundTransparency = 1
detailTitle.Text = "Cure Components"
detailTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
detailTitle.TextSize = getScaledTextSize(20)
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Parent = detailFrame

-- Close Button (ensure minimum touch target size on mobile)
local closeButtonSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
closeButton.Position = UDim2.new(1, -closeButtonSize - getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = getScaledTextSize(18)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = detailFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	detailFrame.Visible = false
end)

-- Components List (ScrollingFrame)
local componentsList = Instance.new("ScrollingFrame")
componentsList.Name = "ComponentsList"
componentsList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(60, "padding"))
componentsList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(50, "padding"))
componentsList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
componentsList.BackgroundTransparency = 0.5
componentsList.BorderSizePixel = 0
componentsList.ScrollBarThickness = getScaledValue(6, "padding")
componentsList.CanvasSize = UDim2.new(0, 0, 0, 0)
componentsList.Parent = detailFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, getScaledValue(5, "padding"))
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = componentsList

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	progressFrame.Size = UIScaleManager.scaleSize(300, 100, "hudElements", "cureProgress")
	progressFrame.Position = UIScaleManager.getPositionWithSafeArea("topRight", 10, 0)
	progressFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
	progressCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))

	progressTitle.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
	progressTitle.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(5, "padding"))
	progressTitle.TextSize = getScaledTextSize(18)

	progressBarBg.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
	progressBarBg.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(35, "padding"))
	progressBarCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
	progressFillCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
	progressText.TextSize = getScaledTextSize(16)

	componentsLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
	componentsLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(70, "padding"))
	componentsLabel.TextSize = getScaledTextSize(14)

	detailFrame.Size = UIScaleManager.scaleSize(350, 250, "menuElements", "menuDialog")
	detailCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
	detailTitle.TextSize = getScaledTextSize(20)

	local newCloseSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
	closeButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
	closeButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
	closeButton.TextSize = getScaledTextSize(18)
	closeCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))

	componentsList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(60, "padding"))
	componentsList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(50, "padding"))
	componentsList.ScrollBarThickness = getScaledValue(6, "padding")
	listLayout.Padding = UDim.new(0, getScaledValue(5, "padding"))
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

-- State
local cureProgress = 0
local componentsCollected = {}

local function getTotalNeeded()
	if type(GameConfig) ~= "table" then
		return 0
	end

	local names = GameConfig.CURE_COMPONENT_NAMES
	local required = GameConfig.CURE_COMPONENTS_REQUIRED

	if type(names) ~= "table" or type(required) ~= "number" then
		return 0
	end

	return #names * required
end

-- Functions
local function updateProgress(progress, components)
	if type(progress) == "number" then
		cureProgress = math.clamp(progress, 0, 100)
	end

	if type(components) == "table" then
		componentsCollected = components
	end

	-- Update progress bar
	local targetSize = UDim2.new(cureProgress / 100, 0, 1, 0)
	pcall(function()
		progressBarFill:TweenSize(
			targetSize,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.5,
			true
		)
	end)

	-- Update text
	progressText.Text = string.format("%d%%", math.floor(cureProgress + 0.5))

	-- Calculate total components
	local totalCollected = 0
	for _, count in pairs(componentsCollected) do
		if type(count) == "number" then
			totalCollected = totalCollected + count
		end
	end

	local totalNeeded = getTotalNeeded()
	if totalNeeded > 0 then
		componentsLabel.Text = totalCollected .. " / " .. totalNeeded .. " Components"
	else
		componentsLabel.Text = totalCollected .. " Components"
	end

	-- Change color based on progress
	if cureProgress >= 100 then
		progressBarFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	elseif cureProgress >= 75 then
		progressBarFill.BackgroundColor3 = Color3.fromRGB(150, 255, 150) -- Light green
	else
		progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green
	end
end

local function updateComponentsList()
	-- Clear existing items (keep the layout)
	for _, child in ipairs(componentsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local names = GameConfig.CURE_COMPONENT_NAMES
	local required = GameConfig.CURE_COMPONENTS_REQUIRED

	if type(names) ~= "table" or type(required) ~= "number" then
		componentsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
		return
	end

	-- Create items for each component
	for _, componentName in ipairs(names) do
		local count = componentsCollected[componentName] or 0

		local itemFrame = Instance.new("Frame")
		itemFrame.Name = tostring(componentName)
		itemFrame.Size = UDim2.new(1, -10, 0, 35)
		itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = componentsList

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 5)
		itemCorner.Parent = itemFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = tostring(componentName)
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(0.4, -10, 1, 0)
		countLabel.Position = UDim2.new(0.6, 0, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = tostring(count) .. " / " .. tostring(required)
		countLabel.TextColor3 = count >= required and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 100)
		countLabel.TextSize = 14
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		countLabel.Parent = itemFrame

		-- Checkmark if complete
		if count >= required then
			local checkmark = Instance.new("TextLabel")
			checkmark.Size = UDim2.new(0, 20, 0, 20)
			checkmark.Position = UDim2.new(1, -30, 0.5, -10)
			checkmark.BackgroundTransparency = 1
			checkmark.Text = "✓"
			checkmark.TextColor3 = Color3.fromRGB(100, 255, 100)
			checkmark.TextSize = 18
			checkmark.Font = Enum.Font.GothamBold
			checkmark.Parent = itemFrame
		end
	end

	componentsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Show detail frame on click/touch
progressFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		detailFrame.Visible = not detailFrame.Visible
		if detailFrame.Visible then
			updateComponentsList()
		end
	end
end)

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- State for alliance indicator
local isPooledWithAllies = false

-- Cure Update
local cureUpdateEvent = remoteEvents:WaitForChild("CureUpdate")
cureUpdateEvent.OnClientEvent:Connect(function(data)
	local dataType = typeof(data)

	if dataType == "number" then
		updateProgress(data)
	elseif dataType == "table" then
		if data.type == "progress" then
			updateProgress(data.progress, data.components)

			if data.contributor and data.componentAdded then
				print(tostring(data.contributor) .. " added " .. tostring(data.componentAdded))
			end

		elseif data.type == "complete" then
			updateProgress(100, data.components)

		elseif data.type == "openUI" then
			detailFrame.Visible = true
			if type(data.components) == "table" then
				componentsCollected = data.components
			end
			if type(data.progress) == "number" then
				cureProgress = math.clamp(data.progress, 0, 100)
			end
			updateComponentsList()

		elseif data.type == "component_collected" then
			-- Update specific component count
			if data.componentName and data.count then
				componentsCollected[data.componentName] = data.count
				updateProgress(cureProgress, componentsCollected)
				if detailFrame.Visible then
					updateComponentsList()
				end
			end
		end
	end
end)

-- Player Cure Progress Update (per-player progress with alliance pooling)
local playerCureProgressEvent = remoteEvents:WaitForChild("PlayerCureProgressUpdate")
playerCureProgressEvent.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	-- Update progress and components
	if data.progress then
		cureProgress = data.progress
	end
	if data.components then
		componentsCollected = data.components
	end

	-- Track if resources are pooled with allies
	isPooledWithAllies = data.isPooled or false

	-- Update the UI
	updateProgress(cureProgress, componentsCollected)

	-- Update title to show pooled status
	if isPooledWithAllies then
		progressTitle.Text = "Cure Progress (Allied)"
		progressTitle.TextColor3 = Color3.fromRGB(100, 200, 255) -- Blue tint for allied
	else
		progressTitle.Text = "Cure Progress"
		progressTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	if detailFrame.Visible then
		updateComponentsList()
	end
end)

-- Initial state
updateProgress(0, {})

-- ========================================
-- SYNTHESIS UI INTEGRATION
-- ========================================

-- Create synthesis overlay (hidden by default)
local synthesisOverlay = Instance.new("Frame")
synthesisOverlay.Name = "SynthesisOverlay"
synthesisOverlay.Size = UDim2.new(0.8, 0, 0.6, 0)
synthesisOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
synthesisOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
synthesisOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
synthesisOverlay.BackgroundTransparency = 0.2
synthesisOverlay.BorderSizePixel = getScaledValue(3, "padding")
synthesisOverlay.BorderColor3 = Color3.fromRGB(255, 100, 100)
synthesisOverlay.Visible = false
synthesisOverlay.ZIndex = 100
synthesisOverlay.Parent = screenGui

local synthesisCorner = Instance.new("UICorner")
synthesisCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
synthesisCorner.Parent = synthesisOverlay

-- Synthesis title
local synthesisTitle = Instance.new("TextLabel")
synthesisTitle.Name = "SynthesisTitle"
synthesisTitle.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(50, "hudElements"))
synthesisTitle.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
synthesisTitle.BackgroundTransparency = 1
synthesisTitle.Text = "CURE SYNTHESIS IN PROGRESS"
synthesisTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
synthesisTitle.TextSize = getScaledTextSize(24)
synthesisTitle.Font = Enum.Font.GothamBold
synthesisTitle.TextXAlignment = Enum.TextXAlignment.Center
synthesisTitle.Parent = synthesisOverlay

-- Synthesis status label
local synthesisStatus = Instance.new("TextLabel")
synthesisStatus.Name = "SynthesisStatus"
synthesisStatus.Size = UDim2.new(1, -getScaledValue(40, "padding"), 0, getScaledValue(30, "hudElements"))
synthesisStatus.Position = UDim2.new(0, getScaledValue(20, "padding"), 0, getScaledValue(70, "hudElements"))
synthesisStatus.BackgroundTransparency = 1
synthesisStatus.Text = "Initiated by: Unknown"
synthesisStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
synthesisStatus.TextSize = getScaledTextSize(18)
synthesisStatus.Font = Enum.Font.Gotham
synthesisStatus.TextXAlignment = Enum.TextXAlignment.Center
synthesisStatus.Parent = synthesisOverlay

-- Time remaining label
local synthesisTimer = Instance.new("TextLabel")
synthesisTimer.Name = "SynthesisTimer"
synthesisTimer.Size = UDim2.new(1, -getScaledValue(40, "padding"), 0, getScaledValue(40, "hudElements"))
synthesisTimer.Position = UDim2.new(0, getScaledValue(20, "padding"), 0, getScaledValue(110, "hudElements"))
synthesisTimer.BackgroundTransparency = 1
synthesisTimer.Text = "Time Remaining: 120s"
synthesisTimer.TextColor3 = Color3.fromRGB(255, 200, 100)
synthesisTimer.TextSize = getScaledTextSize(20)
synthesisTimer.Font = Enum.Font.GothamBold
synthesisTimer.TextXAlignment = Enum.TextXAlignment.Center
synthesisTimer.Parent = synthesisOverlay

-- Puzzle progress label
local puzzleProgress = Instance.new("TextLabel")
puzzleProgress.Name = "PuzzleProgress"
puzzleProgress.Size = UDim2.new(1, -getScaledValue(40, "padding"), 0, getScaledValue(40, "hudElements"))
puzzleProgress.Position = UDim2.new(0, getScaledValue(20, "padding"), 0, getScaledValue(160, "hudElements"))
puzzleProgress.BackgroundTransparency = 1
puzzleProgress.Text = "Puzzles Completed: 0 / 5"
puzzleProgress.TextColor3 = Color3.fromRGB(100, 200, 255)
puzzleProgress.TextSize = getScaledTextSize(22)
puzzleProgress.Font = Enum.Font.GothamBold
puzzleProgress.TextXAlignment = Enum.TextXAlignment.Center
puzzleProgress.Parent = synthesisOverlay

-- Warning message
local warningLabel = Instance.new("TextLabel")
warningLabel.Name = "WarningLabel"
warningLabel.Size = UDim2.new(1, -getScaledValue(40, "padding"), 0, getScaledValue(60, "hudElements"))
warningLabel.Position = UDim2.new(0, getScaledValue(20, "padding"), 1, -getScaledValue(80, "hudElements"))
warningLabel.BackgroundTransparency = 1
warningLabel.Text = "⚠ WARNING: Zombie intensity increased during synthesis! ⚠"
warningLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
warningLabel.TextSize = getScaledTextSize(16)
warningLabel.Font = Enum.Font.GothamMedium
warningLabel.TextWrapped = true
warningLabel.TextXAlignment = Enum.TextXAlignment.Center
warningLabel.Parent = synthesisOverlay

-- Synthesis state update handler
local synthesisStateUpdateEvent = remoteEvents:WaitForChild("SynthesisStateUpdate", 5)
if synthesisStateUpdateEvent then
	synthesisStateUpdateEvent.OnClientEvent:Connect(function(stateData)
		if type(stateData) ~= "table" then
			return
		end
		
		-- Update overlay visibility based on state
		if stateData.state == "Active" then
			synthesisOverlay.Visible = true
			
			-- Update status
			if stateData.initiator then
				synthesisStatus.Text = "Initiated by: " .. tostring(stateData.initiator)
			end
			
			-- Update timer
			if stateData.timeRemaining then
				synthesisTimer.Text = string.format("Time Remaining: %ds", math.ceil(stateData.timeRemaining))
			elseif stateData.timeLimit then
				synthesisTimer.Text = string.format("Time Limit: %ds", stateData.timeLimit)
			end
			
			-- Update puzzle progress
			if stateData.puzzlesCompleted and stateData.puzzlesTotal then
				puzzleProgress.Text = string.format("Puzzles Completed: %d / %d", stateData.puzzlesCompleted, stateData.puzzlesTotal)
			end
		else
			-- Hide overlay for Success, Failed, or Idle states
			synthesisOverlay.Visible = false
		end
	end)
	print("[CureUI] Synthesis state update listener registered")
else
	warn("[CureUI] SynthesisStateUpdate remote event not found")
end

-- Synthesis complete handler
local synthesisCompleteEvent = remoteEvents:WaitForChild("SynthesisComplete", 5)
if synthesisCompleteEvent then
	synthesisCompleteEvent.OnClientEvent:Connect(function()
		-- Hide synthesis overlay
		synthesisOverlay.Visible = false
		print("[CureUI] Synthesis complete!")
	end)
else
	warn("[CureUI] SynthesisComplete remote event not found")
end

-- Synthesis failed handler
local synthesisFailedEvent = remoteEvents:WaitForChild("SynthesisFailed", 5)
if synthesisFailedEvent then
	synthesisFailedEvent.OnClientEvent:Connect(function(payload)
		-- Hide synthesis overlay
		synthesisOverlay.Visible = false
		
		-- Support both table payloads ({ reason = ..., initiator = ... }) and legacy string payloads
		local reasonText = "Unknown failure"
		local initiatorText
		
		if typeof(payload) == "table" then
			if payload.reason ~= nil then
				reasonText = tostring(payload.reason)
			end
			if payload.initiator ~= nil then
				initiatorText = tostring(payload.initiator)
			end
		elseif payload ~= nil then
			-- Backwards compatibility for string or other simple payloads
			reasonText = tostring(payload)
		end
		
		if initiatorText then
			warn(string.format("[CureUI] Synthesis failed: %s (initiator: %s)", reasonText, initiatorText))
		else
			warn(string.format("[CureUI] Synthesis failed: %s", reasonText))
		end
	end)
else
	warn("[CureUI] SynthesisFailed remote event not found")
end

print("CureUI initialized with synthesis UI integration")

-- Return module table (required for ModuleScript compatibility)
local CureUI = {}
return CureUI
