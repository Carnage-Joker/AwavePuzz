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
local RemoteRegistry = require(SharedFolder:WaitForChild("RemoteRegistry"))
local remotes = RemoteRegistry.GetClientRemotes()
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
-- NOTE: Duplicates should never occur during normal boot; warn loudly without
-- silently destroying so any real bug surfaces immediately.
local existing = playerGui:FindFirstChild("PuzzleUI")
if existing then
	warn("[PuzzleUI] UNEXPECTED: PuzzleUI ScreenGui already exists in PlayerGui — this indicates a boot ordering bug and should be investigated.")
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
	end
}

-- State
local currentPuzzle = nil
local currentComponentName = nil
local puzzleStartTime = 0
local timerConnection = nil

-- Helper function to clear content and disconnect dynamic connections
local function clearContent()
	-- Disconnect any dynamic connections (e.g., colorBlock connections, puzzle-specific connections)
	for key, connection in pairs(connections) do
		if type(key) == "string" and (
			key:match("^colorBlock_") or 
			key:match("^elementButton_") or 
			key:match("^labButton_") or 
			key:match("^node_") or 
			key:match("^clearButton_")
		) then
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
	
	-- clearContent() now handles disconnecting dynamic connections
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

-- Logic puzzle UI with interactive grid
local function createLogicPuzzleUI(puzzleData)
	clearContent()

	-- Interactive grid implementation
	-- Grid shows Scientists (rows) x Elements+Labs (columns)
	-- Player clicks cells to select assignments
	
	local scientists = puzzleData.scientists or {}
	local elements = puzzleData.elements or {}
	local labs = puzzleData.labs or {}
	local clues = puzzleData.clues or {}
	
	-- Show clues at the top
	local cluesLabel = Instance.new("TextLabel")
	cluesLabel.Size = UDim2.new(1, -20, 0, 60)
	cluesLabel.Position = UDim2.new(0, 10, 0, 5)
	cluesLabel.BackgroundTransparency = 1
	cluesLabel.Text = "Clues:"
	cluesLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	cluesLabel.TextSize = 14
	cluesLabel.Font = Enum.Font.GothamBold
	cluesLabel.TextWrapped = true
	cluesLabel.TextXAlignment = Enum.TextXAlignment.Left
	cluesLabel.TextYAlignment = Enum.TextYAlignment.Top
	cluesLabel.Parent = contentFrame
	
	-- Display each clue
	local clueText = "Clues:\n"
	for i, clue in ipairs(clues) do
		clueText = clueText .. i .. ". " .. clue.text .. "\n"
	end
	cluesLabel.Text = clueText
	
	-- Interactive grid for assigning elements and labs to scientists
	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "GridFrame"
	gridFrame.Size = UDim2.new(1, -20, 0, 180)
	gridFrame.Position = UDim2.new(0, 10, 0, 75)
	gridFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	gridFrame.BorderSizePixel = 0
	gridFrame.Parent = contentFrame
	
	local gridCorner = Instance.new("UICorner")
	gridCorner.CornerRadius = UDim.new(0, 6)
	gridCorner.Parent = gridFrame
	
	-- Store player's selections
	local playerGrid = {}
	for _, scientist in ipairs(scientists) do
		playerGrid[scientist] = {element = nil, lab = nil}
	end
	
	-- Create rows for each scientist
	local rowHeight = 50
	local labelWidth = 100
	local cellWidth = 80
	
	for i, scientist in ipairs(scientists) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, rowHeight)
		row.Position = UDim2.new(0, 0, 0, (i - 1) * rowHeight)
		row.BackgroundTransparency = 1
		row.Parent = gridFrame
		
		-- Scientist label
		local scientistLabel = Instance.new("TextLabel")
		scientistLabel.Size = UDim2.new(0, labelWidth, 1, 0)
		scientistLabel.BackgroundTransparency = 1
		scientistLabel.Text = scientist
		scientistLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		scientistLabel.TextSize = 12
		scientistLabel.Font = Enum.Font.Gotham
		scientistLabel.Parent = row
		
		-- Element dropdown button
		local elementButton = Instance.new("TextButton")
		elementButton.Name = "ElementButton"
		elementButton.Size = UDim2.new(0, cellWidth, 0, 35)
		elementButton.Position = UDim2.new(0, labelWidth + 5, 0, 7)
		elementButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		elementButton.Text = "Element?"
		elementButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		elementButton.TextSize = 11
		elementButton.Font = Enum.Font.Gotham
		elementButton.Parent = row
		
		local elementCorner = Instance.new("UICorner")
		elementCorner.CornerRadius = UDim.new(0, 4)
		elementCorner.Parent = elementButton
		
		-- Lab dropdown button
		local labButton = Instance.new("TextButton")
		labButton.Name = "LabButton"
		labButton.Size = UDim2.new(0, cellWidth, 0, 35)
		labButton.Position = UDim2.new(0, labelWidth + cellWidth + 10, 0, 7)
		labButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		labButton.Text = "Lab?"
		labButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		labButton.TextSize = 11
		labButton.Font = Enum.Font.Gotham
		labButton.Parent = row
		
		local labCorner = Instance.new("UICorner")
		labCorner.CornerRadius = UDim.new(0, 4)
		labCorner.Parent = labButton
		
		-- Element selection cycles through options
		local elementIndex = 0
		local connectionKey1 = "elementButton_" .. i
		connections[connectionKey1] = elementButton.MouseButton1Click:Connect(function()
			elementIndex = (elementIndex % #elements) + 1
			local selectedElement = elements[elementIndex]
			elementButton.Text = selectedElement
			playerGrid[scientist].element = selectedElement
			-- Update stored data
			contentFrame:SetAttribute("PlayerGridData", game:GetService("HttpService"):JSONEncode(playerGrid))
		end)
		
		-- Lab selection cycles through options
		local labIndex = 0
		local connectionKey2 = "labButton_" .. i
		connections[connectionKey2] = labButton.MouseButton1Click:Connect(function()
			labIndex = (labIndex % #labs) + 1
			local selectedLab = labs[labIndex]
			labButton.Text = selectedLab
			playerGrid[scientist].lab = selectedLab
			-- Update stored data
			contentFrame:SetAttribute("PlayerGridData", game:GetService("HttpService"):JSONEncode(playerGrid))
		end)
	end
	
	-- Store playerGrid in contentFrame for later access
	contentFrame:SetAttribute("HasPlayerGrid", true)
	contentFrame:SetAttribute("PlayerGridData", game:GetService("HttpService"):JSONEncode(playerGrid))
	
	return playerGrid
end

-- Abstract puzzle UI with node canvas and drag connections
local function createAbstractPuzzleUI(puzzleData)
	clearContent()

	local nodeCount = puzzleData.nodeCount or 6
	
	-- Instructions
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -20, 0, 40)
	instructionLabel.Position = UDim2.new(0, 10, 0, 5)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "🔗 Connect all nodes in a circuit (1→2→3→...→1)\nClick nodes in order to create path"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	instructionLabel.TextSize = 13
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame
	
	-- Node canvas
	local canvasFrame = Instance.new("Frame")
	canvasFrame.Name = "NodeCanvas"
	canvasFrame.Size = UDim2.new(1, -20, 0, 180)
	canvasFrame.Position = UDim2.new(0, 10, 0, 50)
	canvasFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	canvasFrame.BorderSizePixel = 0
	canvasFrame.Parent = contentFrame
	
	local canvasCorner = Instance.new("UICorner")
	canvasCorner.CornerRadius = UDim.new(0, 6)
	canvasCorner.Parent = canvasFrame
	
	-- Store connections
	local nodeConnections = {}
	local connectionPath = {}  -- Order of nodes clicked
	
	-- Create nodes in a circle pattern once the canvas has a valid size
	local function layoutNodes()
		local size = canvasFrame.AbsoluteSize
		if size.X == 0 or size.Y == 0 then
			-- Wait for the first non-zero AbsoluteSize before laying out nodes
			local sizeChangedConn
			sizeChangedConn = canvasFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local newSize = canvasFrame.AbsoluteSize
				if newSize.X > 0 and newSize.Y > 0 then
					sizeChangedConn:Disconnect()
					layoutNodes()
				end
			end)
			return
		end
		
		local centerX = size.X / 2
		local centerY = size.Y / 2
		local radius = math.min(centerX, centerY) - 30
		
		for i = 1, nodeCount do
			local angle = (i - 1) * (2 * math.pi / nodeCount) - math.pi / 2
			local nodeX = centerX + radius * math.cos(angle)
			local nodeY = centerY + radius * math.sin(angle)
			
			local nodeButton = Instance.new("TextButton")
			nodeButton.Name = "Node" .. i
			nodeButton.Size = UDim2.new(0, 40, 0, 40)
			nodeButton.Position = UDim2.new(0, nodeX - 20, 0, nodeY - 20)
			nodeButton.AnchorPoint = Vector2.new(0, 0)
			nodeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
			nodeButton.Text = tostring(i)
			nodeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			nodeButton.TextSize = 18
			nodeButton.Font = Enum.Font.GothamBold
			nodeButton.Parent = canvasFrame
			
			local nodeCorner = Instance.new("UICorner")
			nodeCorner.CornerRadius = UDim.new(1, 0)  -- Circular
			nodeCorner.Parent = nodeButton
			
			-- Click to add to path
			local connectionKey = "node_" .. i
			connections[connectionKey] = nodeButton.MouseButton1Click:Connect(function()
				-- Add node to path
				table.insert(connectionPath, i)
				
				-- Highlight node
				nodeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
				
				-- Update connection display
				local pathText = "Path: "
				for j, node in ipairs(connectionPath) do
					pathText = pathText .. node
					if j < #connectionPath then
						pathText = pathText .. " → "
					end
				end
				instructionLabel.Text = pathText
				
				-- If path is complete (all nodes + return to start), build connections
				if #connectionPath == nodeCount + 1 then
					-- Build connections table
					for j = 1, #connectionPath - 1 do
						nodeConnections[connectionPath[j]] = connectionPath[j + 1]
					end
					-- Update stored data
					contentFrame:SetAttribute("NodeConnectionsData", game:GetService("HttpService"):JSONEncode(nodeConnections))
				end
			end)
		end
	end
	
	layoutNodes()
	
	-- Clear button
	local clearButton = Instance.new("TextButton")
	clearButton.Size = UDim2.new(0, 80, 0, 30)
	clearButton.Position = UDim2.new(0.5, -40, 0, 240)
	clearButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	clearButton.Text = "Clear"
	clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearButton.TextSize = 14
	clearButton.Font = Enum.Font.GothamBold
	clearButton.Parent = contentFrame
	
	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 4)
	clearCorner.Parent = clearButton
	
	local clearConnection = "clearButton_abstract"
	connections[clearConnection] = clearButton.MouseButton1Click:Connect(function()
		-- Reset
		connectionPath = {}
		nodeConnections = {}
		instructionLabel.Text = "🔗 Connect all nodes in a circuit (1→2→3→...→1)\nClick nodes in order to create path"
		
		-- Reset node colors
		for i = 1, nodeCount do
			local node = canvasFrame:FindFirstChild("Node" .. i)
			if node then
				node.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
			end
		end
		
		-- Update stored data
		contentFrame:SetAttribute("NodeConnectionsData", game:GetService("HttpService"):JSONEncode(nodeConnections))
	end)
	
	-- Store connections in contentFrame
	contentFrame:SetAttribute("HasNodeConnections", true)
	contentFrame:SetAttribute("NodeConnectionsData", game:GetService("HttpService"):JSONEncode(nodeConnections))
	
	return nodeConnections
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
	elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.LOGIC then
		-- Get player grid data from interactive UI
		if contentFrame:GetAttribute("HasPlayerGrid") then
			local gridDataJSON = contentFrame:GetAttribute("PlayerGridData")
			if gridDataJSON then
				answer = game:GetService("HttpService"):JSONDecode(gridDataJSON)
			end
		else
			-- Fallback to text input for MVP compatibility
			local answerBox = contentFrame:FindFirstChild("AnswerBox")
			if answerBox and answerBox:IsA("TextBox") then
				answer = answerBox.Text
			end
		end
	elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		-- Get node connections from interactive UI
		if contentFrame:GetAttribute("HasNodeConnections") then
			local connectionsJSON = contentFrame:GetAttribute("NodeConnectionsData")
			if connectionsJSON then
				answer = game:GetService("HttpService"):JSONDecode(connectionsJSON)
			end
		else
			-- Fallback to text input for MVP compatibility
			local answerBox = contentFrame:FindFirstChild("AnswerBox")
			if answerBox and answerBox:IsA("TextBox") then
				answer = answerBox.Text
			end
		end
	end

	-- Send to server
	if remotes.SubmitPuzzleAnswer then
		remotes.SubmitPuzzleAnswer:FireServer(currentComponentName, answer)
	else
		warn("[PuzzleUI] SubmitPuzzleAnswer remote not found — answer not sent to server")
	end

	-- Close UI (server will notify if correct/incorrect)
	closePuzzle()
end)

-- Remote event handlers

-- Open puzzle UI
local openPuzzleEvent = remotes.OpenPuzzleUI
if openPuzzleEvent then
	connections.openPuzzle = openPuzzleEvent.OnClientEvent:Connect(function(data)
		if data and data.puzzle and data.componentName then
			openPuzzle(data.componentName, data.puzzle)
		end
	end)
else
	warn("[PuzzleUI] OpenPuzzleUI remote not found — puzzle UI will not open from server")
end

-- Puzzle completed
local puzzleCompletedEvent = remotes.PuzzleCompleted
if puzzleCompletedEvent then
	connections.puzzleCompleted = puzzleCompletedEvent.OnClientEvent:Connect(function(data)
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
else
	warn("[PuzzleUI] PuzzleCompleted remote not found — puzzle completion notifications will not display")
end

-- Puzzle failed
local puzzleFailedEvent = remotes.PuzzleFailed
if puzzleFailedEvent then
	connections.puzzleFailed = puzzleFailedEvent.OnClientEvent:Connect(function(message)
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
else
	warn("[PuzzleUI] PuzzleFailed remote not found — puzzle failure notifications will not display")
end

-- Boot log: report which puzzle-related remotes are available.
-- Includes remotes consumed locally (OpenPuzzleUI, SubmitPuzzleAnswer, PuzzleCompleted,
-- PuzzleFailed) and the broader puzzle-system remotes defined in the problem spec
-- (PuzzleUpdate, PuzzleSubmit, RequestPuzzle, RequestPuzzleProgress) whose presence
-- is verified here even though they are consumed by PuzzleMenuUI / the server.
do
	-- Gate boot logging behind UIDebugConfig to avoid noisy production logs.
	if UIDebugConfig and UIDebugConfig.DEBUG_UI_CREATION then
		local PUZZLE_REMOTES = {
			"PuzzleUpdate", "PuzzleSubmit", "OpenPuzzleUI",
			"RequestPuzzle", "RequestPuzzleProgress", "SubmitPuzzleAnswer",
			"PuzzleCompleted", "PuzzleFailed",
		}
		local bound = {}
		for _, name in ipairs(PUZZLE_REMOTES) do
			if remotes[name] then
				table.insert(bound, name)
			else
				warn("[PuzzleUI] Missing remote: " .. name)
			end
		end
		print("[PuzzleUI] Bound remotes: " .. table.concat(bound, ", "))
	end
end

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

-- bindRemotes satisfies the standard contract used by ClientMainModule.
-- Remotes are already bound during module initialization via RemoteRegistry.GetClientRemotes(),
-- so this is intentionally a no-op; it just confirms compatibility.
function PuzzleUIModule:bindRemotes(_remotesMap)
	print("[PuzzleUI] bindRemotes called (remotes already bound at module init)")
end

return PuzzleUIModule
