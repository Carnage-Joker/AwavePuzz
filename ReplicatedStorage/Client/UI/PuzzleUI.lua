-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- PuzzleUI.lua
-- Client-side puzzle interface for cure synthesis
-- Displays puzzle mini-games when player has collected 5 of a component type
-- Updated for UI modules living in ReplicatedStorage.Client.UI (ModuleScripts)
-- Safe to require multiple times; initialize() is idempotent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local PuzzleConfig = require(SharedFolder:WaitForChild("PuzzleConfig"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))

local PuzzleUI = {}
PuzzleUI._initialized = false
PuzzleUI._connections = {}

-- State
local player = nil
local playerGui = nil

local screenGui = nil
local puzzleFrame = nil
local titleBar = nil
local titleLabel = nil
local closeButton = nil
local descLabel = nil
local timerLabel = nil
local contentFrame = nil
local submitButton = nil

local puzzleCorner = nil
local titleBarCorner = nil
local closeCorner = nil
local timerCorner = nil
local contentCorner = nil
local submitCorner = nil

local MIN_TOUCH_TARGET = (UIScaleConfig.MinSizes.touchTarget and UIScaleConfig.MinSizes.touchTarget.width) or 44

local currentPuzzle = nil
local currentComponentName = nil
local puzzleStartTime = 0
local timerConnection = nil

-- Helpers
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

local function disconnectAll()
	for _, conn in ipairs(PuzzleUI._connections) do
		pcall(function() conn:Disconnect() end)
	end
	PuzzleUI._connections = {}
end

local function clearContent()
	if not contentFrame then return end
	for _, child in ipairs(contentFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end
end

local function closePuzzle()
	if puzzleFrame then
		puzzleFrame.Visible = false
	end
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
	clearContent()
	currentPuzzle = nil
	currentComponentName = nil
end

local function updateTimer()
	if not currentPuzzle or not currentPuzzle.timeLimit or not timerLabel then
		return
	end

	local elapsed = tick() - puzzleStartTime
	local remaining = math.max(0, currentPuzzle.timeLimit - elapsed)

	timerLabel.Text = string.format("Time: %ds", math.ceil(remaining))

	if remaining <= 10 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	elseif remaining <= 30 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	end

	if remaining <= 0 then
		closePuzzle()
	end
end

-- UI scaling update
local function updateUIScaling()
	if not puzzleFrame then return end

	puzzleFrame.Size = UIScaleManager.scaleSize(600, 500, "menuElements", "menuDialog")
	if puzzleCorner then puzzleCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding")) end

	if titleBar then
		titleBar.Size = UDim2.new(1, 0, 0, getScaledValue(50, "padding"))
	end
	if titleBarCorner then
		titleBarCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
	end
	if titleLabel then
		titleLabel.TextSize = getScaledTextSize(24)
		titleLabel.Size = UDim2.new(1, -getScaledValue(60, "padding"), 1, 0)
		titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, 0)
	end

	local newCloseSize = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
	if closeButton then
		closeButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
		closeButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
		closeButton.TextSize = getScaledTextSize(24)
	end
	if closeCorner then
		closeCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	end

	if descLabel then
		descLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(40, "padding"))
		descLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(60, "padding"))
		descLabel.TextSize = getScaledTextSize(16)
	end

	if timerLabel then
		timerLabel.Size = UDim2.new(0, getScaledValue(150, "padding"), 0, getScaledValue(30, "padding"))
		timerLabel.Position = UDim2.new(1, -getScaledValue(160, "padding"), 0, getScaledValue(105, "padding"))
		timerLabel.TextSize = getScaledTextSize(18)
	end
	if timerCorner then
		timerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	end

	if contentFrame then
		contentFrame.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(200, "padding"))
		contentFrame.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(140, "padding"))
	end
	if contentCorner then
		contentCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	end

	local newSubmitHeight = math.max(getScaledValue(45, "menuElements"), MIN_TOUCH_TARGET)
	if submitButton then
		submitButton.Size = UDim2.new(0, getScaledValue(200, "menuElements"), 0, newSubmitHeight)
		submitButton.Position = UDim2.new(0.5, 0, 1, -getScaledValue(60, "padding"))
		submitButton.TextSize = getScaledTextSize(20)
	end
	if submitCorner then
		submitCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
	end
end

-- Puzzle builders
local function createMathPuzzleUI(puzzleData)
	clearContent()

	local mathLabel = Instance.new("TextLabel")
	mathLabel.Size = UDim2.new(1, -40, 0, 80)
	mathLabel.Position = UDim2.new(0, 20, 0, 20)
	mathLabel.BackgroundTransparency = 1
	mathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	mathLabel.TextSize = getScaledTextSize(32)
	mathLabel.Font = Enum.Font.GothamBold
	mathLabel.Parent = contentFrame

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

	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 200, 0, math.max(getScaledValue(50, "menuElements"), MIN_TOUCH_TARGET))
	answerBox.Position = UDim2.new(0.5, -100, 0, 120)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter answer..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = getScaledTextSize(24)
	answerBox.Font = Enum.Font.Gotham
	answerBox.ClearTextOnFocus = false
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	answerCorner.Parent = answerBox

	return answerBox
end

local function createPatternPuzzleUI(puzzleData)
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 40)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "What comes next in the sequence?"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = getScaledTextSize(20)
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.Parent = contentFrame

	local sequenceFrame = Instance.new("Frame")
	sequenceFrame.Size = UDim2.new(1, -40, 0, 80)
	sequenceFrame.Position = UDim2.new(0, 20, 0, 60)
	sequenceFrame.BackgroundTransparency = 1
	sequenceFrame.Parent = contentFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, getScaledValue(10, "padding"))
	listLayout.Parent = sequenceFrame

	if puzzleData.sequence then
		for i = 1, #puzzleData.sequence + 1 do
			local item = Instance.new("Frame")
			item.Size = UDim2.new(0, getScaledValue(60, "menuElements"), 0, getScaledValue(60, "menuElements"))
			item.BackgroundColor3 = puzzleData.sequence[i] and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(100, 100, 100)
			item.Parent = sequenceFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
			itemCorner.Parent = item

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Size = UDim2.new(1, 0, 1, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text = puzzleData.sequence[i] and tostring(puzzleData.sequence[i]) or "?"
			itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemLabel.TextSize = getScaledTextSize(18)
			itemLabel.Font = Enum.Font.GothamBold
			itemLabel.Parent = item
		end
	end

	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 200, 0, math.max(getScaledValue(50, "menuElements"), MIN_TOUCH_TARGET))
	answerBox.Position = UDim2.new(0.5, -100, 0, 160)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter answer..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = getScaledTextSize(24)
	answerBox.Font = Enum.Font.Gotham
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	answerCorner.Parent = answerBox

	return answerBox
end

local function createColorPuzzleUI(puzzleData)
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 40)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Arrange the colors in the correct order (click two blocks to swap)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = getScaledTextSize(18)
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	-- IMPORTANT: ColorFrame must be a child of contentFrame (submit logic expects it there)
	local colorFrame = Instance.new("Frame")
	colorFrame.Name = "ColorFrame"
	colorFrame.Size = UDim2.new(1, -40, 1, -80)
	colorFrame.Position = UDim2.new(0, 20, 0, 60)
	colorFrame.BackgroundTransparency = 1
	colorFrame.Parent = contentFrame

	local colorLayout = Instance.new("UIGridLayout")
	colorLayout.CellSize = UDim2.new(0, getScaledValue(70, "menuElements"), 0, getScaledValue(70, "menuElements"))
	colorLayout.CellPadding = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
	colorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	colorLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	colorLayout.Parent = colorFrame

	local colorBlocks = {}

	if puzzleData.shuffled then
		for i, color in ipairs(puzzleData.shuffled) do
			local block = Instance.new("TextButton")
			block.Name = "ColorBlock" .. i
			block.Size = UDim2.new(0, getScaledValue(70, "menuElements"), 0, getScaledValue(70, "menuElements"))
			block.BackgroundColor3 = color
			block.Text = tostring(i)
			block.TextColor3 = Color3.fromRGB(255, 255, 255)
			block.TextSize = getScaledTextSize(24)
			block.Font = Enum.Font.GothamBold
			block.LayoutOrder = i
			block.Parent = colorFrame

			local blockCorner = Instance.new("UICorner")
			blockCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
			blockCorner.Parent = block

			block:SetAttribute("ColorIndex", i)
			colorBlocks[i] = { frame = block, color = color }

			block.MouseButton1Click:Connect(function()
				local currentIndex = block:GetAttribute("ColorIndex")
				if not currentIndex then return end

				if not colorFrame:GetAttribute("FirstSelected") then
					colorFrame:SetAttribute("FirstSelected", currentIndex)
					block.BorderSizePixel = 3
					block.BorderColor3 = Color3.fromRGB(255, 255, 0)
				else
					local firstIndex = colorFrame:GetAttribute("FirstSelected")
					colorFrame:SetAttribute("FirstSelected", nil)

					if firstIndex == currentIndex then
						block.BorderSizePixel = 0
						return
					end

					local firstBlock = colorBlocks[firstIndex] and colorBlocks[firstIndex].frame
					if not firstBlock then
						block.BorderSizePixel = 0
						return
					end

					-- swap layout order
					local tempOrder = firstBlock.LayoutOrder
					firstBlock.LayoutOrder = block.LayoutOrder
					block.LayoutOrder = tempOrder

					-- clear border
					firstBlock.BorderSizePixel = 0
					block.BorderSizePixel = 0

					-- swap indices
					firstBlock:SetAttribute("ColorIndex", currentIndex)
					block:SetAttribute("ColorIndex", firstIndex)

					-- swap in table
					colorBlocks[firstIndex], colorBlocks[currentIndex] = colorBlocks[currentIndex], colorBlocks[firstIndex]
				end
			end)
		end
	end

	return colorBlocks
end

local function createLogicPuzzleUI(_puzzleData)
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 80)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "📋 LOGIC DEDUCTION PUZZLE\n\n(Simplified MVP: Enter 'correct' to solve)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = getScaledTextSize(16)
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 300, 0, math.max(getScaledValue(50, "menuElements"), MIN_TOUCH_TARGET))
	answerBox.Position = UDim2.new(0.5, -150, 0, 120)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter 'correct'..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = getScaledTextSize(20)
	answerBox.Font = Enum.Font.Gotham
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	answerCorner.Parent = answerBox

	return answerBox
end

local function createAbstractPuzzleUI(_puzzleData)
	clearContent()

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, -40, 0, 80)
	instructionLabel.Position = UDim2.new(0, 20, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "🔗 NODE CONNECTION PUZZLE\n\n(Simplified MVP: Enter 'circuit' to solve)"
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionLabel.TextSize = getScaledTextSize(16)
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextWrapped = true
	instructionLabel.Parent = contentFrame

	local answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0, 300, 0, math.max(getScaledValue(50, "menuElements"), MIN_TOUCH_TARGET))
	answerBox.Position = UDim2.new(0.5, -150, 0, 120)
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	answerBox.Text = ""
	answerBox.PlaceholderText = "Enter 'circuit'..."
	answerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	answerBox.TextSize = getScaledTextSize(20)
	answerBox.Font = Enum.Font.Gotham
	answerBox.Parent = contentFrame

	local answerCorner = Instance.new("UICorner")
	answerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	answerCorner.Parent = answerBox

	return answerBox
end

local function openPuzzle(componentName, puzzle)
	if not puzzleFrame then return end

	currentPuzzle = puzzle
	currentComponentName = componentName
	puzzleStartTime = tick()

	titleLabel.Text = puzzle.name or "Puzzle"
	descLabel.Text = puzzle.description or "Solve the puzzle"
	timerLabel.Text = string.format("Time: %ds", puzzle.timeLimit or 60)
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)

	-- Build puzzle UI
	if puzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL then
		createMathPuzzleUI(puzzle.data or {})
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
		createPatternPuzzleUI(puzzle.data or {})
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
		createColorPuzzleUI(puzzle.data or {})
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.LOGIC then
		createLogicPuzzleUI(puzzle.data or {})
	elseif puzzle.type == PuzzleConfig.PuzzleTypes.ABSTRACT then
		createAbstractPuzzleUI(puzzle.data or {})
	else
		clearContent()
	end

	puzzleFrame.Visible = true

	if timerConnection then
		timerConnection:Disconnect()
	end
	timerConnection = RunService.Heartbeat:Connect(updateTimer)
end

local function showNotification(bgColor, text, textSize, seconds)
	if not screenGui then return end

	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, getScaledValue(400, "menuDialog"), 0, getScaledValue(80, "menuDialog"))
	notification.Position = UDim2.new(0.5, -notification.Size.X.Offset/2, 0.2, 0)
	notification.BackgroundColor3 = bgColor
	notification.Text = text
	notification.TextColor3 = Color3.fromRGB(255, 255, 255)
	notification.TextSize = getScaledTextSize(textSize)
	notification.Font = Enum.Font.GothamBold
	notification.TextWrapped = true
	notification.ZIndex = 200
	notification.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
	notifCorner.Parent = notification

	task.delay(seconds or 3, function()
		if notification and notification.Parent then
			notification:Destroy()
		end
	end)
end

local function hookRemotes()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		warn("[PuzzleUI] RemoteEvents folder not found (yet). Puzzle UI will wait until it exists.")
		-- Try once more shortly; avoids infinite yield if server is misconfigured.
		task.delay(2, function()
			hookRemotes()
		end)
		return
	end

	local openPuzzleEvent = remoteEvents:FindFirstChild("OpenPuzzleUI")
	if openPuzzleEvent and openPuzzleEvent:IsA("RemoteEvent") then
		table.insert(PuzzleUI._connections, openPuzzleEvent.OnClientEvent:Connect(function(data)
			if data and data.puzzle and data.componentName then
				openPuzzle(data.componentName, data.puzzle)
			end
		end))
	else
		warn("[PuzzleUI] Missing RemoteEvent: OpenPuzzleUI")
	end

	local puzzleCompletedEvent = remoteEvents:FindFirstChild("PuzzleCompleted")
	if puzzleCompletedEvent and puzzleCompletedEvent:IsA("RemoteEvent") then
		table.insert(PuzzleUI._connections, puzzleCompletedEvent.OnClientEvent:Connect(function(data)
			local reward = (data and data.reward) or 0
			showNotification(Color3.fromRGB(50, 200, 50), string.format("Puzzle Solved!\n+%d Currency", reward), 24, 3)
		end))
	else
		warn("[PuzzleUI] Missing RemoteEvent: PuzzleCompleted")
	end

	local puzzleFailedEvent = remoteEvents:FindFirstChild("PuzzleFailed")
	if puzzleFailedEvent and puzzleFailedEvent:IsA("RemoteEvent") then
		table.insert(PuzzleUI._connections, puzzleFailedEvent.OnClientEvent:Connect(function(message)
			showNotification(Color3.fromRGB(200, 50, 50), "Puzzle Failed!\n" .. (message or "Try again"), 20, 3)
		end))
	else
		warn("[PuzzleUI] Missing RemoteEvent: PuzzleFailed")
	end
end

local function buildUI()
	-- Re-resolve player if needed (safe during respawns / studio quirks)
	player = Players.LocalPlayer
	playerGui = player:WaitForChild("PlayerGui")

	-- scale manager can be initialized multiple times; make it safe
	pcall(function()
		UIScaleManager.initialize()
	end)

	-- ScreenGui (one instance)
	screenGui = playerGui:FindFirstChild("PuzzleUI")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "PuzzleUI"
		screenGui.ResetOnSpawn = false
		screenGui.Enabled = true
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = playerGui
	end

	-- Main frame
	puzzleFrame = screenGui:FindFirstChild("PuzzleFrame")
	if not puzzleFrame then
		puzzleFrame = Instance.new("Frame")
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

		puzzleCorner = Instance.new("UICorner")
		puzzleCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
		puzzleCorner.Parent = puzzleFrame
	else
		puzzleCorner = puzzleFrame:FindFirstChildOfClass("UICorner")
	end

	-- Title bar
	titleBar = puzzleFrame:FindFirstChild("TitleBar")
	if not titleBar then
		titleBar = Instance.new("Frame")
		titleBar.Name = "TitleBar"
		titleBar.Size = UDim2.new(1, 0, 0, getScaledValue(50, "padding"))
		titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		titleBar.BorderSizePixel = 0
		titleBar.Parent = puzzleFrame

		titleBarCorner = Instance.new("UICorner")
		titleBarCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
		titleBarCorner.Parent = titleBar
	else
		titleBarCorner = titleBar:FindFirstChildOfClass("UICorner")
	end

	-- Title text
	titleLabel = titleBar:FindFirstChild("Title")
	if not titleLabel then
		titleLabel = Instance.new("TextLabel")
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
	end

	-- Close button
	local closeButtonSize = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
	closeButton = titleBar:FindFirstChild("CloseButton")
	if not closeButton then
		closeButton = Instance.new("TextButton")
		closeButton.Name = "CloseButton"
		closeButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
		closeButton.Position = UDim2.new(1, -closeButtonSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
		closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		closeButton.Text = "✕"
		closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeButton.TextSize = getScaledTextSize(24)
		closeButton.Font = Enum.Font.GothamBold
		closeButton.Parent = titleBar

		closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
		closeCorner.Parent = closeButton
	else
		closeCorner = closeButton:FindFirstChildOfClass("UICorner")
	end

	-- Description label
	descLabel = puzzleFrame:FindFirstChild("Description")
	if not descLabel then
		descLabel = Instance.new("TextLabel")
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
	end

	-- Timer label
	timerLabel = puzzleFrame:FindFirstChild("Timer")
	if not timerLabel then
		timerLabel = Instance.new("TextLabel")
		timerLabel.Name = "Timer"
		timerLabel.Size = UDim2.new(0, getScaledValue(150, "padding"), 0, getScaledValue(30, "padding"))
		timerLabel.Position = UDim2.new(1, -getScaledValue(160, "padding"), 0, getScaledValue(105, "padding"))
		timerLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		timerLabel.Text = "Time: 60s"
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		timerLabel.TextSize = getScaledTextSize(18)
		timerLabel.Font = Enum.Font.GothamBold
		timerLabel.Parent = puzzleFrame

		timerCorner = Instance.new("UICorner")
		timerCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
		timerCorner.Parent = timerLabel
	else
		timerCorner = timerLabel:FindFirstChildOfClass("UICorner")
	end

	-- Content frame
	contentFrame = puzzleFrame:FindFirstChild("Content")
	if not contentFrame then
		contentFrame = Instance.new("Frame")
		contentFrame.Name = "Content"
		contentFrame.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(200, "padding"))
		contentFrame.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(140, "padding"))
		contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		contentFrame.BackgroundTransparency = 0.5
		contentFrame.BorderSizePixel = 0
		contentFrame.Parent = puzzleFrame

		contentCorner = Instance.new("UICorner")
		contentCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
		contentCorner.Parent = contentFrame
	else
		contentCorner = contentFrame:FindFirstChildOfClass("UICorner")
	end

	-- Submit button
	local submitButtonHeight = math.max(getScaledValue(45, "menuElements"), MIN_TOUCH_TARGET)
	submitButton = puzzleFrame:FindFirstChild("SubmitButton")
	if not submitButton then
		submitButton = Instance.new("TextButton")
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

		submitCorner = Instance.new("UICorner")
		submitCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
		submitCorner.Parent = submitButton
	else
		submitCorner = submitButton:FindFirstChildOfClass("UICorner")
	end

	-- Initial scale
	updateUIScaling()
end

local function hookInputsAndButtons()
	-- Close button
	table.insert(PuzzleUI._connections, closeButton.MouseButton1Click:Connect(closePuzzle))

	-- Backspace closes
	table.insert(PuzzleUI._connections, UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.KeyCode == Enum.KeyCode.Backspace and puzzleFrame and puzzleFrame.Visible then
			closePuzzle()
		end
	end))

	-- Submit
	table.insert(PuzzleUI._connections, submitButton.MouseButton1Click:Connect(function()
		if not currentPuzzle or not currentComponentName then
			return
		end

		local answer = nil

		if currentPuzzle.type == PuzzleConfig.PuzzleTypes.MATHEMATICAL or currentPuzzle.type == PuzzleConfig.PuzzleTypes.PATTERN then
			local answerBox = contentFrame:FindFirstChild("AnswerBox")
			if answerBox and answerBox:IsA("TextBox") then
				answer = tonumber(answerBox.Text) or answerBox.Text
			end
		elseif currentPuzzle.type == PuzzleConfig.PuzzleTypes.COLOR then
			local colorFrame = contentFrame:FindFirstChild("ColorFrame")
			if colorFrame then
				answer = {}
				local blocks = {}
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

		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		local submit = remoteEvents and remoteEvents:FindFirstChild("SubmitPuzzleAnswer")
		if submit and submit:IsA("RemoteEvent") then
			submit:FireServer(currentComponentName, answer)
		else
			warn("[PuzzleUI] Missing RemoteEvent: SubmitPuzzleAnswer")
		end

		closePuzzle()
	end))

	-- Scale change listener
	pcall(function()
		UIScaleManager.onScaleChanged(updateUIScaling)
	end)
end

function PuzzleUI.initialize(_context)
	if PuzzleUI._initialized then
		return
	end
	PuzzleUI._initialized = true

	-- Build UI once
	buildUI()

	-- Hook buttons + inputs + remotes
	hookInputsAndButtons()
	hookRemotes()

	print("PuzzleUI initialized")
end

function PuzzleUI.destroy()
	-- Optional cleanup if you ever want it
	disconnectAll()
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
	PuzzleUI._initialized = false
end

return PuzzleUI
