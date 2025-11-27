-- ScoreboardUI.client.lua
-- Client script for displaying player scoreboard with stats
-- Press TAB to toggle scoreboard visibility

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Constants
local REMOTE_EVENT_WAIT_TIMEOUT = 10 -- Seconds to wait for RemoteEvent to exist

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScoreboardUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- Hidden by default
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main scoreboard frame
local scoreboardFrame = Instance.new("Frame")
scoreboardFrame.Name = "ScoreboardFrame"
scoreboardFrame.Size = UDim2.new(0, 500, 0, 400)
scoreboardFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
scoreboardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scoreboardFrame.BackgroundTransparency = 0.1
scoreboardFrame.BorderSizePixel = 3
scoreboardFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
scoreboardFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = scoreboardFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SCOREBOARD"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = scoreboardFrame

-- Header row
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, -20, 0, 35)
headerFrame.Position = UDim2.new(0, 10, 0, 55)
headerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = scoreboardFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = headerFrame

-- Header columns
local columnWidths = {0.35, 0.15, 0.15, 0.15, 0.20} -- Player, Kills, Deaths, Wins, Components
local columnHeaders = {"Player", "Kills", "Deaths", "Wins", "Parts"}

for i, header in ipairs(columnHeaders) do
	local startX = 0
	for j = 1, i - 1 do
		startX = startX + columnWidths[j]
	end
	
	local headerCol = Instance.new("TextLabel")
	headerCol.Size = UDim2.new(columnWidths[i], 0, 1, 0)
	headerCol.Position = UDim2.new(startX, 0, 0, 0)
	headerCol.BackgroundTransparency = 1
	headerCol.Text = header
	headerCol.TextColor3 = Color3.fromRGB(200, 200, 200)
	headerCol.TextSize = 14
	headerCol.Font = Enum.Font.GothamBold
	headerCol.Parent = headerFrame
end

-- Player list (ScrollingFrame)
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, -20, 1, -110)
playerList.Position = UDim2.new(0, 10, 0, 95)
playerList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
playerList.BackgroundTransparency = 0.5
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 6
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.Parent = scoreboardFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = playerList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

-- Update canvas size when content changes
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- Store scoreboard data
local scoreboardData = {}

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
		tostring(playerStats.componentsCollected or 0)
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
		screenGui.Enabled = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab then
		screenGui.Enabled = false
	end
end)

-- Listen for scoreboard updates from server
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local scoreboardUpdateEvent = remoteEvents:WaitForChild("ScoreboardUpdate", REMOTE_EVENT_TIMEOUT)
if scoreboardUpdateEvent then
	scoreboardUpdateEvent.OnClientEvent:Connect(function(data)
		if type(data) == "table" then
			scoreboardData = data
			updateScoreboard(data)
		end
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
	hint.Parent = playerGui
	
	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 8)
	hintCorner.Parent = hint
	
	task.wait(5)
	hint:Destroy()
end)

print("ScoreboardUI initialized")
