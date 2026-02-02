-- PuzzleUI.client.lua
-- Client-side puzzle interface for cure synthesis
-- Displays puzzle mini-games when player has collected 5 of a component type
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

-- Initialize scale manager
UIScaleManager.initialize()

-- Connection tracking for cleanup
local connections = {}

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
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

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

-- State
local currentPuzzle = nil
local currentComponentName = nil
local puzzleStartTime = 0
local timerConnection = nil

-- Helper function to clear content
local function clearContent()
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
	
	-- Disconnect dynamic color block connections
	for key, connection in pairs(connections) do
		if type(key) == "string" and key:match("^colorBlock_") then
			if connection and connection.Connected then
				connection:Disconnect()
			end
			connections[key] = nil
		end
	end
	
	clearContent()
	currentPuzzle = nil
	currentComponentName = nil
end

connections.closeButton = closeButton.MouseButton1Click:Connect(closePuzzle)

-- ESC/Backspace handled globally by ModalManager

-- Update timer
local function updateTimer()
	if not currentPuzzle or not currentPuzzle.timeLimit then
		return
	end

	local elapsed = tick() - puzzleStartTime
	local remaining = math.max(0, currentPuzzle.timeLimit - elapsed)

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
		-- Notify server of timeout (server also tracks this)
	end
end

-- Mathematical puzzle UI
local function createMathPuzzleUI(puzzleData)
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
				sequenceText = sequenceText .. puzzleData.sequence[i]
			else
				sequenceText = sequenceText .. "?"
			end
			if i < #puzzleData.sequence + 1 then
				sequenceText = sequenceText .. ", "
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
local function createPatternPuzzleUI(puzzleData)
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
local function createColorPuzzleUI(puzzleData)
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 40)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Arrange the colors in the correct order (drag to reorder)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 18
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	-- Create draggable color blocks
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

	local colorBlocks = {}

	if puzzleData.shuffled then
		for i, color in ipairs(puzzleData.shuffled) do
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
			colorBlocks[i] = {frame = block, color = color}

			-- Simple swap on click (click two blocks to swap)
			-- Store connection for cleanup
			local connectionKey = "colorBlock_" .. i
			connections[connectionKey] = block.MouseButton1Click:Connect(function()
				local currentIndex = block:GetAttribute("ColorIndex")
				if not currentIndex then return end

				-- Implement simple selection and swap logic
				if not colorFrame:GetAttribute("FirstSelected") then
					colorFrame:SetAttribute("FirstSelected", currentIndex)
					block.BorderSizePixel = 3
					block.BorderColor3 = Color3.fromRGB(255, 255, 0)
				else
					local firstIndex = colorFrame:GetAttribute("FirstSelected")
					if firstIndex ~= currentIndex then
						-- Swap layout orders
						local firstBlock = colorBlocks[firstIndex].frame
						local secondBlock = block
						local tempOrder = firstBlock.LayoutOrder
						firstBlock.LayoutOrder = secondBlock.LayoutOrder
						secondBlock.LayoutOrder = tempOrder

						-- Update indices
						firstBlock:SetAttribute("ColorIndex", currentIndex)
						block:SetAttribute("ColorIndex", firstIndex)

						-- Swap in table
						colorBlocks[firstIndex], colorBlocks[currentIndex] = colorBlocks[currentIndex], colorBlocks[firstIndex]

						firstBlock.BorderSizePixel = 0
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

-- Logic puzzle UI (simplified MVP with enhanced instructions)
local function createLogicPuzzleUI(puzzleData)
	clearContent()

	-- Full implementation would include:
	--   1. Grid layout (3x3 or 4x4) showing element/person/location combinations
	--   2. Clue display panel showing logical constraints
	--   3. Interactive selection (click cells to mark possibilities)
	--   4. Cross-referencing markers (X for impossible, ✓ for confirmed)
	--   5. Visual feedback for conflicts
	--   6. Submit button validates final arrangement against clues
	-- Example grid: Scientists (rows) x Elements (cols) x Labs (depth)
	-- For MVP, using simplified text input approach with enhanced UI
	
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 80)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "📋 LOGIC DEDUCTION PUZZLE\n\nUse logical reasoning to deduce the correct arrangement.\n(Simplified MVP: Enter 'correct' to solve)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 16
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame
	
	-- Visual grid placeholder for future implementation
	local gridFrame = Instance.new("Frame")
	gridFrame.Size = UDim2.new(0, 320, 0, 200)
	gridFrame.Position = UDim2.new(0.5, -160, 0, 100)
	gridFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	gridFrame.BorderSizePixel = 0
	gridFrame.Parent = contentFrame
	
	local gridCorner = Instance.new("UICorner")
	gridCorner.CornerRadius = UDim.new(0, 8)
	gridCorner.Parent = gridFrame
	
	local gridLabel = Instance.new("TextLabel")
	gridLabel.Size = UDim2.new(1, 0, 1, 0)
	gridLabel.BackgroundTransparency = 1
	gridLabel.Text = "🔲 Grid UI\n\n(To be implemented:\nInteractive 3x3 grid\nwith clue checking)"
	gridLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	gridLabel.TextSize = 14
	gridLabel.Font = Enum.Font.Gotham
	gridLabel.Parent = gridFrame

	-- Answer input
	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 300, 0, 50)
	answerBox.Position = UDim2.new(0.5, -150, 0, 320)
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

-- Abstract puzzle UI (simplified MVP with enhanced instructions)
local function createAbstractPuzzleUI(puzzleData)
	clearContent()

	-- Full implementation would include:
	--   1. Node visualization (circles/points positioned on canvas)
	--   2. Drag-and-drop mechanics to create connections between nodes
	--   3. Visual lines showing current connections
	--   4. Collision detection to prevent crossing lines (if required)
	--   5. Visual feedback for valid/invalid connections
	--   6. Undo/clear buttons for connection management
	--   7. Highlight completed circuits or valid paths
	-- Example: Display 6-8 nodes, player drags from one to another to connect
	-- Validate that all nodes connected and forms desired pattern (circuit, tree, etc.)
	-- For MVP, using simplified text input approach with enhanced UI
	
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 80)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "🔗 NODE CONNECTION PUZZLE\n\nConnect all nodes to form a complete circuit.\n(Simplified MVP: Enter 'circuit' to solve)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = 16
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame
	
	-- Visual node canvas placeholder for future implementation
	local canvasFrame = Instance.new("Frame")
	canvasFrame.Size = UDim2.new(0, 320, 0, 200)
	canvasFrame.Position = UDim2.new(0.5, -160, 0, 100)
	canvasFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	canvasFrame.BorderSizePixel = 0
	canvasFrame.Parent = contentFrame
	
	local canvasCorner = Instance.new("UICorner")
	canvasCorner.CornerRadius = UDim.new(0, 8)
	canvasCorner.Parent = canvasFrame
	
	local canvasLabel = Instance.new("TextLabel")
	canvasLabel.Size = UDim2.new(1, 0, 1, 0)
	canvasLabel.BackgroundTransparency = 1
	canvasLabel.Text = "⭕ Node Canvas\n\n(To be implemented:\nDrag-and-drop nodes\nwith connection lines)"
	canvasLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	canvasLabel.TextSize = 14
	canvasLabel.Font = Enum.Font.Gotham
	canvasLabel.Parent = canvasFrame

	-- Answer input
	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 300, 0, 50)
	answerBox.Position = UDim2.new(0.5, -150, 0, 320)
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
local function openPuzzle(componentName, puzzle)
	currentPuzzle = puzzle
	currentComponentName = componentName
	puzzleStartTime = tick()

	-- Update UI elements
	titleLabel.Text = puzzle.name or "Puzzle"
	descLabel.Text = puzzle.description or "Solve the puzzle"
	timerLabel.Text = string.format("Time: %ds", puzzle.timeLimit or 60)

	-- Create puzzle-specific UI
	local answerElement = nil

	if puzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL then
		answerElement = createMathPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
		answerElement = createPatternPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
		answerElement = createColorPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.LOGIC then
		answerElement = createLogicPuzzleUI(puzzle.data)
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		answerElement = createAbstractPuzzleUI(puzzle.data)
	end

	-- Show frame
	puzzleFrame.Visible = true
	
	-- Register with ModalManager
	ModalManager.push("PuzzleUI", closePuzzle, ModalManager.Priority.MODAL)

	-- Start timer updates
	if timerConnection then
		timerConnection:Disconnect()
	end
	timerConnection = game:GetService("RunService").Heartbeat:Connect(updateTimer)
end

-- Submit answer
connections.submitButton = submitButton.MouseButton1Click:Connect(function()
	-- Only process if this is the top modal
	if not ModalManager.isTopModal("PuzzleUI") then
		return
	end
	
	if not currentPuzzle or not currentComponentName then
		return
	end

	local answer = nil

	-- Get answer based on puzzle type
	if currentPuzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL or 
		currentPuzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
		local answerBox = contentFrame:FindFirstChild("AnswerBox")
		if answerBox and answerBox:IsA("TextBox") then
			answer = tonumber(answerBox.Text) or answerBox.Text
		end
	elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
		-- Get current color order
		local colorFrame = contentFrame:FindFirstChild("ColorFrame")
		if colorFrame then
			answer = {}
			local blocks = {}
			-- Filter to only TextButtons first
			for _, child in ipairs(colorFrame:GetChildren()) do
				if child:IsA("TextButton") then
					table.insert(blocks, child)
				end
			end
			-- Now sort TextButtons by LayoutOrder
			table.sort(blocks, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			for _, block in ipairs(blocks) do
				table.insert(answer, block.BackgroundColor3)
			end
		end
	elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.LOGIC or 
		currentPuzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		local answerBox = contentFrame:FindFirstChild("AnswerBox")
		if answerBox and answerBox:IsA("TextBox") then
			answer = answerBox.Text
		end
	end

	-- Send to server
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents and remoteEvents:FindFirstChild("SubmitPuzzleAnswer") then
		remoteEvents.SubmitPuzzleAnswer:FireServer(currentComponentName, answer)
	end

	-- Close UI (server will notify if correct/incorrect)
	closePuzzle()
end)

-- Remote event handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Open puzzle UI
local openPuzzleEvent = remoteEvents:WaitForChild("OpenPuzzleUI")
openPuzzleEvent.OnClientEvent:Connect(function(data)
	if data and data.puzzle and data.componentName then
		openPuzzle(data.componentName, data.puzzle)
	end
end)

-- Puzzle completed
local puzzleCompletedEvent = remoteEvents:WaitForChild("PuzzleCompleted")
puzzleCompletedEvent.OnClientEvent:Connect(function(data)
	-- Show success notification
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, 400, 0, 80)
	notification.Position = UDim2.new(0.5, -200, 0.2, 0)
	notification.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	notification.Text = string.format("Puzzle Solved!\n+%d Currency", data.reward or 0)
	notification.TextColor3 = Color3.fromRGB(255, 255, 255)
	notification.TextSize = 24
	notification.Font = Enum.Font.GothamBold
	notification.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 12)
	notifCorner.Parent = notification

	-- Fade out and remove
	task.wait(3)
	notification:Destroy()
end)

-- Puzzle failed
local puzzleFailedEvent = remoteEvents:WaitForChild("PuzzleFailed")
puzzleFailedEvent.OnClientEvent:Connect(function(message)
	-- Show error notification
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, 400, 0, 80)
	notification.Position = UDim2.new(0.5, -200, 0.2, 0)
	notification.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	notification.Text = "Puzzle Failed!\n" .. (message or "Try again")
	notification.TextColor3 = Color3.fromRGB(255, 255, 255)
	notification.TextSize = 20
	notification.Font = Enum.Font.GothamBold
	notification.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 12)
	notifCorner.Parent = notification

	-- Fade out and remove
	task.wait(3)
	notification:Destroy()
end)

-- Register input actions with InputActionRegistry
InputActionRegistry.register("PuzzleSubmit", "PuzzleUI", {}, InputActionRegistry.Priority.MODAL_UI) -- Submit via button only

-- Cleanup function
local function cleanup()
	for name, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}
	
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
	
	-- Remove from ModalManager if still open
	if puzzleFrame.Visible then
		ModalManager.remove("PuzzleUI")
	end
end

-- Handle respawn - cleanup connections
connections.characterRemoving = player.CharacterRemoving:Connect(cleanup)

print("PuzzleUI initialized")

-- Return module table
local PuzzleUIModule = {}
PuzzleUIModule.cleanup = cleanup
return PuzzleUIModule
