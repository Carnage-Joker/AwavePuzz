-- ScoreboardUI.client.lua
-- Client script for displaying player scoreboard with stats
-- Press TAB to toggle scoreboard visibility
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Constants
local REMOTE_EVENT_WAIT_TIMEOUT = 10 -- Seconds to wait for RemoteEvent to exist

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State variables for scoreboard visibility
local tabHeld = false
local isEndOfRoundDisplay = false

-- Load UI scaling utilities
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScoreboardUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- Hidden by default
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main scoreboard frame - centered with scaled dimensions
local scoreboardFrame = Instance.new("Frame")
scoreboardFrame.Name = "ScoreboardFrame"
scoreboardFrame.Size = UIScaleManager.scaleSize(500, 400, "menuElements", "menuDialog")
scoreboardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
scoreboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
scoreboardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scoreboardFrame.BackgroundTransparency = 0.1
scoreboardFrame.BorderSizePixel = 3
scoreboardFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
scoreboardFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))
frameCorner.Parent = scoreboardFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(40, "padding"))
titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SCOREBOARD"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize = getScaledTextSize(28)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = scoreboardFrame

-- Header row
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(35, "padding"))
headerFrame.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(55, "padding"))
headerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = scoreboardFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
headerCorner.Parent = headerFrame

-- Header columns
local columnWidths = {0.30, 0.13, 0.13, 0.13, 0.16, 0.15} -- Player, Kills, Deaths, Wins, Parts, Puzzles
local columnHeaders = {"Player", "Kills", "Deaths", "Wins", "Parts", "Puzzles"}

for i, header in ipairs(columnHeaders) do
	local startX = 0
	for j = 1, i - 1 do
		startX = startX + columnWidths[j]
	end

	local headerCol = Instance.new("TextLabel")
	headerCol.Name = "Header" .. i
	headerCol.Size = UDim2.new(columnWidths[i], 0, 1, 0)
	headerCol.Position = UDim2.new(startX, 0, 0, 0)
	headerCol.BackgroundTransparency = 1
	headerCol.Text = header
	headerCol.TextColor3 = Color3.fromRGB(200, 200, 200)
	headerCol.TextSize = getScaledTextSize(14)
	headerCol.Font = Enum.Font.GothamBold
	headerCol.Parent = headerFrame
end

-- Player list (ScrollingFrame)
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(110, "padding"))
playerList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(95, "padding"))
playerList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
playerList.BackgroundTransparency = 0.5
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = getScaledValue(6, "padding")
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.Parent = scoreboardFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
listCorner.Parent = playerList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, getScaledValue(5, "padding"))
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

-- Update canvas size when content changes
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + getScaledValue(10, "padding"))
end)

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	scoreboardFrame.Size = UIScaleManager.scaleSize(500, 400, "menuElements", "menuDialog")
	frameCorner.CornerRadius = UDim.new(0, getScaledValue(12, "padding"))

	titleLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(40, "padding"))
	titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
	titleLabel.TextSize = getScaledTextSize(28)

	headerFrame.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(35, "padding"))
	headerFrame.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(55, "padding"))
	headerCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))

	-- Update header column text sizes
	for i = 1, 6 do
		local col = headerFrame:FindFirstChild("Header" .. i)
		if col then
			col.TextSize = getScaledTextSize(14)
		end
	end

	playerList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(110, "padding"))
	playerList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(95, "padding"))
	playerList.ScrollBarThickness = getScaledValue(6, "padding")
	listCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
	listLayout.Padding = UDim.new(0, getScaledValue(5, "padding"))
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

-- Function to create a player row
local function createPlayerRow(playerStats, layoutOrder)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = playerStats.playerName
	rowFrame.Size = UDim2.new(1, -10, 0, 35)
	rowFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	rowFrame.BorderSizePixel = 0
	rowFrame.LayoutOrder = layoutOrder
	rowFrame.Parent = playerList

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = rowFrame

	-- Highlight current player's row
	if playerStats.userId == player.UserId then
		rowFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
	end

	-- Create columns
	local values = {
		playerStats.playerName or "Unknown",
		tostring(playerStats.kills or 0),
		tostring(playerStats.deaths or 0),
		tostring(playerStats.roundWins or 0),
		tostring(playerStats.componentsCollected or 0),
		tostring(playerStats.puzzleSolves or 0)
	}

	for i, value in ipairs(values) do
		local startX = 0
		for j = 1, i - 1 do
			startX = startX + columnWidths[j]
		end

		local colLabel = Instance.new("TextLabel")
		colLabel.Size = UDim2.new(columnWidths[i], 0, 1, 0)
		colLabel.Position = UDim2.new(startX, 0, 0, 0)
		colLabel.BackgroundTransparency = 1
		colLabel.Text = value
		colLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		colLabel.TextSize = 14
		colLabel.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
		colLabel.Parent = rowFrame
	end

	return rowFrame
end

-- Function to update the scoreboard
local function updateScoreboard(data)
	-- Clear existing rows
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create new rows
	for i, playerStats in ipairs(data) do
		createPlayerRow(playerStats, i)
	end
end

-- Toggle scoreboard with TAB key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Tab then
		tabHeld = true
		-- Don't show TAB scoreboard if end of round display is active
		if not isEndOfRoundDisplay then
			screenGui.Enabled = true
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab then
		tabHeld = false
		-- Don't hide if end of round display is active
		if not isEndOfRoundDisplay then
			screenGui.Enabled = false
		end
	end
end)

-- Listen for scoreboard updates from server
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local scoreboardUpdateEvent = remoteEvents:WaitForChild("ScoreboardUpdate", REMOTE_EVENT_WAIT_TIMEOUT)
if not scoreboardUpdateEvent then
	warn("ScoreboardUpdate event not found - scoreboard will not receive updates")
else
	scoreboardUpdateEvent.OnClientEvent:Connect(function(data)
		if type(data) == "table" then
			updateScoreboard(data)
		end
	end)
end

-- Handle end of round scoreboard display
local showScoreboardEvent = remoteEvents:WaitForChild("ShowScoreboard", REMOTE_EVENT_WAIT_TIMEOUT)
if showScoreboardEvent then
	showScoreboardEvent.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end

		isEndOfRoundDisplay = true

		-- Update title for end of round
		titleLabel.Text = "ROUND COMPLETE"
		titleLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Update scores if provided
		if data.scores then
			updateScoreboard(data.scores)
		end

		-- Show the scoreboard
		screenGui.Enabled = true

		-- Animate in from top
		scoreboardFrame.Position = UDim2.new(0.5, -250, -0.5, 0)
		TweenService:Create(scoreboardFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -250, 0.5, -200)
		}):Play()
	end)
end

-- Handle hiding end of round scoreboard
local hideScoreboardEvent = remoteEvents:WaitForChild("HideScoreboard", REMOTE_EVENT_WAIT_TIMEOUT)
if hideScoreboardEvent then
	hideScoreboardEvent.OnClientEvent:Connect(function()
		isEndOfRoundDisplay = false

		-- Reset title
		titleLabel.Text = "SCOREBOARD"
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

		-- Animate out
		TweenService:Create(scoreboardFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -250, 1.5, 0)
		}):Play()

		task.delay(0.3, function()
			-- Only hide if TAB isn't being held
			if not tabHeld then
				screenGui.Enabled = false
			end
			-- Reset position for next time
			scoreboardFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
		end)
	end)
end

-- Show hint
task.delay(3, function()
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(0, 300, 0, 40)
	hint.Position = UDim2.new(0.5, -150, 1, -50)
	hint.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	hint.BackgroundTransparency = 0.3
	hint.Text = "Hold TAB to view Scoreboard"
	hint.TextColor3 = Color3.fromRGB(255, 255, 255)
	hint.TextSize = 14
	hint.Font = Enum.Font.Gotham
	hint.Parent = screenGui

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 8)
	hintCorner.Parent = hint

	task.wait(5)
	hint:Destroy()
end)

print("ScoreboardUI initialized")
