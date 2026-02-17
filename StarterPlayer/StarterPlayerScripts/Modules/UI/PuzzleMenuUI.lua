-- PuzzleUI.client.lua
-- Client-side puzzle interface for cure synthesis
-- Displays puzzle mini-games when player has collected 5 of a component type
-- Updated with dynamic UI scaling for mobile devices.

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local PuzzleConfig = require(SharedFolder:WaitForChild("PuzzleConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))
local RemoteRegistry = require(SharedFolder:WaitForChild("RemoteRegistry"))

local remotes = RemoteRegistry.GetClientRemotes()

-- Remotes (RemoteRegistry is single source of truth)
local OpenPuzzleUI = remotes.OpenPuzzleUI
local PuzzleCompleted = remotes.PuzzleCompleted
local PuzzleFailed = remotes.PuzzleFailed
local SubmitPuzzleAnswer = remotes.SubmitPuzzleAnswer

-- Optional/legacy variable (not used, kept only if you reference it elsewhere)
local PuzzleMenuRequest = remotes.PuzzleMenuRequest

-- Initialize scale manager
UIScaleManager.initialize()

-- Connection tracking for cleanup
local connections: { [any]: any } = {}

-- Helper functions
local function getScaledValue(baseValue: number, scaleType: string?): number
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize: number): number
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config
local MIN_TOUCH_TARGET = (UIScaleConfig.MinSizes.touchTarget and UIScaleConfig.MinSizes.touchTarget.width) or 44

-- Prevent duplicate UI instances
local existing = playerGui:FindFirstChild("PuzzleUI")
if existing then
	UIDebugConfig.warnDuplicate("PuzzleUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("PuzzleUI", "Creating ScreenGui", "PuzzleUI.lua")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PuzzleUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main puzzle frame (hidden by default) - centered with scaled size
local puzzleFrame = Instance.new("Frame")
puzzleFrame.Name = "PuzzleFrame"
puzzleFrame.Size = UIScaleManager.scaleSize(600, 500, "menuElements", "menuDialog")
puzzleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
puzzleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
puzzleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
puzzleFrame.BackgroundTransparency = 0.05
puzzleFrame.BorderSizePixel = 3
puzzleFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
puzzleFrame.Visible = false
puzzleFrame.ZIndex = 100
puzzleFrame.Parent = screenGui

local puzzleCorner = Instance.new("UICorner")
puzzleCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
puzzleCorner.Parent = puzzleFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, getScaledValue(50, "padding"))
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = puzzleFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
titleBarCorner.Parent = titleBar

-- Title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -getScaledValue(60, "padding"), 1, 0)
titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Puzzle"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = getScaledTextSize(24)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button with minimum touch target
local closeButtonSize = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
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

-- Description label
local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(40, "padding"))
descLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
descLabel.BackgroundTransparency = 1
descLabel.Text = "Solve the puzzle to progress"
descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
descLabel.TextSize = getScaledTextSize(16)
descLabel.Font = Enum.Font.Gotham
descLabel.TextWrapped = true
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.Parent = puzzleFrame

-- Timer label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.new(0, getScaledValue(150, "padding"), 0, getScaledValue(30, "padding"))
timerLabel.Position = UDim2.new(1, -getScaledValue(160, "padding"), 0, getScaledValue(105, "padding"))
timerLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
timerLabel.Text = "Time: 60s"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
timerLabel.TextSize = getScaledTextSize(18)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = puzzleFrame

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
timerCorner.Parent = timerLabel

-- Content frame (where puzzle is displayed)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(200, "padding"))
contentFrame.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(140, "padding"))
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
contentFrame.BackgroundTransparency = 0.5
contentFrame.BorderSizePixel = 0
contentFrame.Parent = puzzleFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
contentCorner.Parent = contentFrame

-- Submit button with minimum touch target
local submitButtonHeight = math.max(getScaledValue(45, "menuElements"), MIN_TOUCH_TARGET)
local submitButton = Instance.new("TextButton")
submitButton.Name = "SubmitButton"
submitButton.Size = UDim2.new(0, getScaledValue(200, "menuElements"), 0, submitButtonHeight)
submitButton.Position = UDim2.new(0.5, 0, 1, -getScaledValue(60, "padding"))
submitButton.AnchorPoint = Vector2.new(0.5, 0)
submitButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
submitButton.Text = "Submit Answer"
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.TextSize = getScaledTextSize(20)
submitButton.Font = Enum.Font.GothamBold
submitButton.Parent = puzzleFrame

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
submitCorner.Parent = submitButton

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	puzzleFrame.Size = UIScaleManager.scaleSize(600, 500, "menuElements", "menuDialog")
	puzzleCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))

	titleBar.Size = UDim2.new(1, 0, 0, getScaledValue(50, "padding"))
	titleBarCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
	titleLabel.TextSize = getScaledTextSize(24)

	local newCloseSize = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
	closeButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
	closeButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	closeButton.TextSize = getScaledTextSize(24)
	closeCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))

	descLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(40, "padding"))
	descLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
	descLabel.TextSize = getScaledTextSize(16)

	timerLabel.Size = UDim2.new(0, getScaledValue(150, "padding"), 0, getScaledValue(30, "padding"))
	timerLabel.Position = UDim2.new(1, -getScaledValue(160, "padding"), 0, getScaledValue(105, "padding"))
	timerLabel.TextSize = getScaledTextSize(18)
	timerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))

	contentFrame.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(200, "padding"))
	contentFrame.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(140, "padding"))
	contentCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))

	local newSubmitHeight = math.max(getScaledValue(45, "menuElements"), MIN_TOUCH_TARGET)
	submitButton.Size = UDim2.new(0, getScaledValue(200, "menuElements"), 0, newSubmitHeight)
	submitButton.Position = UDim2.new(0.5, 0, 1, -getScaledValue(60, "padding"))
	submitButton.TextSize = getScaledTextSize(20)
	submitCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
end

-- Register for scale changes (returns unsubscribe function)
local scaleChangedUnsubscribe = UIScaleManager.onScaleChanged(updateUIScaling)
connections.scaleChanged = {
	Disconnect = function()
		if scaleChangedUnsubscribe then
			scaleChangedUnsubscribe()
			scaleChangedUnsubscribe = nil
		end
	end,
}

-- State
local currentPuzzle: any = nil
local currentComponentName: string? = nil
local puzzleStartTime = 0.0
local timerConnection: RBXScriptConnection? = nil

-- Helper function to clear content and disconnect dynamic connections
local function clearContent()
	-- Disconnect any dynamic connections (e.g., colorBlock connections)
	for key, connection in pairs(connections) do
		if type(key) == "string" and key:match("^colorBlock_") then
			if typeof(connection) == "RBXScriptConnection" and connection.Connected then
				connection:Disconnect()
			elseif type(connection) == "table" and type(connection.Disconnect) == "function" then
				connection.Disconnect()
			end
			connections[key] = nil
		end
	end

	-- Destroy UI elements
	for _, child in ipairs(contentFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end
end

-- Close puzzle UI
local function closePuzzle()
	puzzleFrame.Visible = false
	ModalManager.remove("PuzzleUI")

	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end

	clearContent()
	currentPuzzle = nil
	currentComponentName = nil
end

connections.closeButton = closeButton.MouseButton1Click:Connect(closePuzzle)

-- Update timer
local function updateTimer()
	if not currentPuzzle or not currentPuzzle.timeLimit then
		return
	end

	local elapsed = tick() - puzzleStartTime
	local remaining = math.max(0, (currentPuzzle.timeLimit :: number) - elapsed)

	timerLabel.Text = string.format("Time: %ds", math.ceil(remaining))

	-- Change color based on remaining time
	if remaining <= 10 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	elseif remaining <= 30 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	end

	-- Auto-close if time runs out
	if remaining <= 0 then
		closePuzzle()
	end
end

-- Mathematical puzzle UI
local function createMathPuzzleUI(puzzleData: any): TextBox
	clearContent()

	local mathLabel = Instance.new("TextLabel")
	mathLabel.Size = UDim2.new(1, -40, 0, 80)
	mathLabel.Position = UDim2.new(0, 20, 0, 20)
	mathLabel.BackgroundTransparency = 1
	mathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	mathLabel.TextSize = 32
	mathLabel.Font = Enum.Font.GothamBold
	mathLabel.Parent = contentFrame

	-- Display the sequence or equation
	if puzzleData.equation then
		mathLabel.Text = puzzleData.equation
	elseif puzzleData.sequence then
		local sequenceText = ""
		for i = 1, #puzzleData.sequence + 1 do
			if puzzleData.sequence[i] then
				sequenceText ..= tostring(puzzleData.sequence[i])
			else
				sequenceText ..= "?"
			end
			if i < #puzzleData.sequence + 1 then
				sequenceText ..= ", "
			end
		end
		mathLabel.Text = sequenceText
	end

	-- Answer input
	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 200, 0, 50)
	answerBox.Position = UDim2.new(0.5, -100, 0, 120)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter answer..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = 24
	answerBox.Font = Enum.Font.Gotham
	answerBox.ClearTextOnFocus = false
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, 8)
	answerCorner.Parent = answerBox

	return answerBox
end

-- Pattern puzzle UI
local function createPatternPuzzleUI(puzzleData: any): TextBox
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 40)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "What comes next in the sequence?"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 20
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.Parent = contentFrame

	-- Display sequence
	local sequenceFrame = Instance.new("Frame")
	sequenceFrame.Size = UDim2.new(1, -40, 0, 80)
	sequenceFrame.Position = UDim2.new(0, 20, 0, 60)
	sequenceFrame.BackgroundTransparency = 1
	sequenceFrame.Parent = contentFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = sequenceFrame

	if puzzleData.sequence then
		for i = 1, #puzzleData.sequence + 1 do
			local item = Instance.new("Frame")
			item.Size = UDim2.new(0, 60, 0, 60)
			item.BackgroundColor3 = puzzleData.sequence[i] and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(100, 100, 100)
			item.Parent = sequenceFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 8)
			itemCorner.Parent = item

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Size = UDim2.new(1, 0, 1, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text = puzzleData.sequence[i] and tostring(puzzleData.sequence[i]) or "?"
			itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemLabel.TextSize = 18
			itemLabel.Font = Enum.Font.GothamBold
			itemLabel.Parent = item
		end
	end

	-- Answer input
	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 200, 0, 50)
	answerBox.Position = UDim2.new(0.5, -100, 0, 160)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter answer..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = 24
	answerBox.Font = Enum.Font.Gotham
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, 8)
	answerCorner.Parent = answerBox

	return answerBox
end

-- Color puzzle UI
local function createColorPuzzleUI(puzzleData: any): { [number]: { frame: TextButton, color: Color3 } }
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 40)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Arrange the colors in the correct order (click two to swap)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 18
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	local colorFrame = Instance.new("Frame")
	colorFrame.Name = "ColorFrame"
	colorFrame.Size = UDim2.new(1, -40, 1, -80)
	colorFrame.Position = UDim2.new(0, 20, 0, 60)
	colorFrame.BackgroundTransparency = 1
	colorFrame.Parent = contentFrame

	local colorLayout = Instance.new("UIGridLayout")
	colorLayout.CellSize = UDim2.new(0, 70, 0, 70)
	colorLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	colorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	colorLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	colorLayout.Parent = colorFrame

	local colorBlocks: { [number]: { frame: TextButton, color: Color3 } } = {}

	if puzzleData.shuffled then
		for i, color: Color3 in ipairs(puzzleData.shuffled) do
			local block = Instance.new("TextButton")
			block.Name = "ColorBlock" .. i
			block.Size = UDim2.new(0, 70, 0, 70)
			block.BackgroundColor3 = color
			block.Text = tostring(i)
			block.TextColor3 = Color3.fromRGB(255, 255, 255)
			block.TextSize = 24
			block.Font = Enum.Font.GothamBold
			block.LayoutOrder = i
			block.Parent = colorFrame

			local blockCorner = Instance.new("UICorner")
			blockCorner.CornerRadius = UDim.new(0, 8)
			blockCorner.Parent = block

			block:SetAttribute("ColorIndex", i)
			colorBlocks[i] = { frame = block, color = color }

			local connectionKey = "colorBlock_" .. i
			connections[connectionKey] = block.MouseButton1Click:Connect(function()
				local currentIndex = block:GetAttribute("ColorIndex")
				if not currentIndex then
					return
				end

				if not colorFrame:GetAttribute("FirstSelected") then
					colorFrame:SetAttribute("FirstSelected", currentIndex)
					block.BorderSizePixel = 3
					block.BorderColor3 = Color3.fromRGB(255, 255, 0)
				else
					local firstIndex = colorFrame:GetAttribute("FirstSelected")
					if firstIndex ~= currentIndex then
						local firstBlock = colorBlocks[firstIndex].frame
						local secondBlock = block

						local tempOrder = firstBlock.LayoutOrder
						firstBlock.LayoutOrder = secondBlock.LayoutOrder
						secondBlock.LayoutOrder = tempOrder

						firstBlock:SetAttribute("ColorIndex", currentIndex)
						block:SetAttribute("ColorIndex", firstIndex)

						colorBlocks[firstIndex], colorBlocks[currentIndex] = colorBlocks[currentIndex], colorBlocks[firstIndex]
						firstBlock.BorderSizePixel = 0
						secondBlock.BorderSizePixel = 0
					else
						block.BorderSizePixel = 0
					end
					colorFrame:SetAttribute("FirstSelected", nil)
				end
			end)
		end
	end

	return colorBlocks
end

-- Logic puzzle UI (simplified MVP)
local function createLogicPuzzleUI(_: any): TextBox
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 80)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "LOGIC DEDUCTION PUZZLE\n\n(Simplified MVP: Enter 'correct' to solve)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 16
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 300, 0, 50)
	answerBox.Position = UDim2.new(0.5, -150, 0, 120)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter 'correct'..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = 20
	answerBox.Font = Enum.Font.Gotham
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, 8)
	answerCorner.Parent = answerBox

	return answerBox
end

-- Abstract puzzle UI (simplified MVP)
local function createAbstractPuzzleUI(_: any): TextBox
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 80)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "NODE CONNECTION PUZZLE\n\n(Simplified MVP: Enter 'circuit' to solve)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 16
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 300, 0, 50)
	answerBox.Position = UDim2.new(0.5, -150, 0, 120)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter 'circuit'..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = 20
	answerBox.Font = Enum.Font.Gotham
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, 8)
	answerCorner.Parent = answerBox

	return answerBox
end

-- Open puzzle UI
local function openPuzzle(componentName: string, puzzle: any)
	currentPuzzle = puzzle
	currentComponentName = componentName
	puzzleStartTime = tick()

	titleLabel.Text = puzzle.name or "Puzzle"
	descLabel.Text = puzzle.description or "Solve the puzzle"
	timerLabel.Text = string.format("Time: %ds", puzzle.timeLimit or 60)

	if puzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL then
		createMathPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
		createPatternPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
		createColorPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.LOGIC then
		createLogicPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		createAbstractPuzzleUI(puzzle.data)
	else
		clearContent()
	end

	puzzleFrame.Visible = true
	ModalManager.push("PuzzleUI", closePuzzle, ModalManager.Priority.MODAL)

	if timerConnection then
		timerConnection:Disconnect()
	end
	timerConnection = RunService.Heartbeat:Connect(updateTimer)
end

-- Submit answer
connections.submitButton = submitButton.MouseButton1Click:Connect(function()
	if not ModalManager.isTopModal("PuzzleUI") then
		return
	end

	if not currentPuzzle or not currentComponentName then
		return
	end

	local answer: any = nil

	if currentPuzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL or currentPuzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
		local answerBox = contentFrame:FindFirstChild("AnswerBox")
		if answerBox and answerBox:IsA("TextBox") then
			answer = tonumber(answerBox.Text) or answerBox.Text
		end
	elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
		local colorFrame = contentFrame:FindFirstChild("ColorFrame")
		if colorFrame then
			answer = {}
			local blocks: { TextButton } = {}
			for _, child in ipairs(colorFrame:GetChildren()) do
				if child:IsA("TextButton") then
					table.insert(blocks, child)
				end
			end
			table.sort(blocks, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			for _, block in ipairs(blocks) do
				table.insert(answer, block.BackgroundColor3)
			end
		end
	elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.LOGIC or currentPuzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		local answerBox = contentFrame:FindFirstChild("AnswerBox")
		if answerBox and answerBox:IsA("TextBox") then
			answer = answerBox.Text
		end
	end

	if SubmitPuzzleAnswer then
		SubmitPuzzleAnswer:FireServer(currentComponentName, answer)
	else
		warn("[PuzzleUI] Missing remote: SubmitPuzzleAnswer")
	end

	closePuzzle()
end)

-- Remote event handlers (RemoteRegistry only)
if OpenPuzzleUI then
	connections.openPuzzle = (OpenPuzzleUI :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		if data and data.puzzle and data.componentName then
			openPuzzle(data.componentName, data.puzzle)
		end
	end)
else
	warn("[PuzzleUI] Missing remote: OpenPuzzleUI")
end

if PuzzleCompleted then
	connections.puzzleCompleted = (PuzzleCompleted :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local notification = Instance.new("TextLabel")
		notification.Size = UDim2.new(0, 400, 0, 80)
		notification.Position = UDim2.new(0.5, -200, 0.2, 0)
		notification.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		notification.Text = string.format("Puzzle Solved!\n+%d Currency", (data and data.reward) or 0)
		notification.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification.TextSize = 24
		notification.Font = Enum.Font.GothamBold
		notification.Parent = screenGui

		local notifCorner = Instance.new("UICorner")
		notifCorner.CornerRadius = UDim.new(0, 12)
		notifCorner.Parent = notification

		task.wait(3)
		if notification.Parent then
			notification:Destroy()
		end
	end)
else
	warn("[PuzzleUI] Missing remote: PuzzleCompleted")
end

if PuzzleFailed then
	connections.puzzleFailed = (PuzzleFailed :: RemoteEvent).OnClientEvent:Connect(function(message: any)
		local notification = Instance.new("TextLabel")
		notification.Size = UDim2.new(0, 400, 0, 80)
		notification.Position = UDim2.new(0.5, -200, 0.2, 0)
		notification.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		notification.Text = "Puzzle Failed!\n" .. tostring(message or "Try again")
		notification.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification.TextSize = 20
		notification.Font = Enum.Font.GothamBold
		notification.Parent = screenGui

		local notifCorner = Instance.new("UICorner")
		notifCorner.CornerRadius = UDim.new(0, 12)
		notifCorner.Parent = notification

		task.wait(3)
		if notification.Parent then
			notification:Destroy()
		end
	end)
else
	warn("[PuzzleUI] Missing remote: PuzzleFailed")
end

-- Register input actions with InputActionRegistry
InputActionRegistry.register("PuzzleSubmit", "PuzzleUI", {}, InputActionRegistry.Priority.MODAL_UI) -- Submit via button only

-- Cleanup function
local function cleanup()
	for _, conn in pairs(connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		elseif type(conn) == "table" and type(conn.Disconnect) == "function" then
			conn.Disconnect()
		end
	end
	connections = {}

	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end

	if puzzleFrame.Visible then
		ModalManager.remove("PuzzleUI")
	end
end

connections.characterRemoving = player.CharacterRemoving:Connect(cleanup)

print("PuzzleUI initialized")

local PuzzleUIModule = {}
PuzzleUIModule.cleanup = cleanup
return PuzzleUIModule
