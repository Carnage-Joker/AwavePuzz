-- LobbyUI.lua
-- Enhanced lobby UI showing waiting status, ready button, and server switch
-- Provides better matchmaking experience

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load UI debug config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local LobbyUI = {}
local _connections = {}

-- Constants
local REMOTE_EVENT_WAIT_TIMEOUT = 10

-- UI State
local isReady = false
local isWaiting = false

-- Prevent duplicate UI instances
local existing = playerGui:FindFirstChild("LobbyUI")
if existing then
	UIDebugConfig.warnDuplicate("LobbyUI")
	existing:Destroy()
end

UIDebugConfig.logUICreation("LobbyUI", "Creating ScreenGui", "LobbyUI.lua")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- Hidden by default
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main lobby frame - positioned at bottom center below voting UI
local lobbyFrame = Instance.new("Frame")
lobbyFrame.Name = "LobbyFrame"
lobbyFrame.Size = UDim2.new(0, 500, 0, 180)
lobbyFrame.Position = UDim2.new(0.5, -250, 1, -200)
lobbyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
lobbyFrame.BackgroundTransparency = 0.1
lobbyFrame.BorderSizePixel = 0
lobbyFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = lobbyFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(100, 150, 255)
frameStroke.Parent = lobbyFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "LOBBY"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = lobbyFrame

-- Player count label
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Name = "PlayerCount"
playerCountLabel.Size = UDim2.new(1, -20, 0, 25)
playerCountLabel.Position = UDim2.new(0, 10, 0, 55)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.Text = "Players: 0 (0 ready, 0 waiting)"
playerCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
playerCountLabel.TextSize = 16
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCountLabel.Parent = lobbyFrame

-- Status message
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusMessage"
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 80)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Waiting for more players..."
statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = lobbyFrame

-- Ready button
local readyButton = Instance.new("TextButton")
readyButton.Name = "ReadyButton"
readyButton.Size = UDim2.new(0.48, -10, 0, 40)
readyButton.Position = UDim2.new(0, 10, 0, 110)
readyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
readyButton.Text = "I'M READY"
readyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
readyButton.TextSize = 18
readyButton.Font = Enum.Font.GothamBold
readyButton.Parent = lobbyFrame

local readyCorner = Instance.new("UICorner")
readyCorner.CornerRadius = UDim.new(0, 8)
readyCorner.Parent = readyButton

-- Waiting button
local waitingButton = Instance.new("TextButton")
waitingButton.Name = "WaitingButton"
waitingButton.Size = UDim2.new(0.48, -10, 0, 40)
waitingButton.Position = UDim2.new(0.52, 0, 0, 110)
waitingButton.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
waitingButton.Text = "WAITING FOR FRIENDS"
waitingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
waitingButton.TextSize = 14
waitingButton.Font = Enum.Font.GothamBold
waitingButton.Parent = lobbyFrame

local waitingCorner = Instance.new("UICorner")
waitingCorner.CornerRadius = UDim.new(0, 8)
waitingCorner.Parent = waitingButton

-- Switch server button
local switchButton = Instance.new("TextButton")
switchButton.Name = "SwitchButton"
switchButton.Size = UDim2.new(1, -20, 0, 30)
switchButton.Position = UDim2.new(0, 10, 1, -40)
switchButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
switchButton.Text = "SWITCH SERVER"
switchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
switchButton.TextSize = 14
switchButton.Font = Enum.Font.Gotham
switchButton.Parent = lobbyFrame

local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(0, 8)
switchCorner.Parent = switchButton

-- Function to update button states
local function updateButtonStates()
	if isReady then
		readyButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		readyButton.Text = "✓ READY"
		waitingButton.BackgroundColor3 = Color3.fromRGB(100, 70, 40)
		waitingButton.Text = "WAITING FOR FRIENDS"
	elseif isWaiting then
		readyButton.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
		readyButton.Text = "I'M READY"
		waitingButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		waitingButton.Text = "⏱ WAITING FOR FRIENDS"
	else
		readyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		readyButton.Text = "I'M READY"
		waitingButton.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
		waitingButton.Text = "WAITING FOR FRIENDS"
	end
end

-- Function to update player status display
local function updatePlayerStatus(data)
	if not data then return end
	
	local totalPlayers = data.totalPlayers or 0
	local readyPlayers = data.readyPlayers or 0
	local waitingPlayers = data.waitingPlayers or 0
	
	playerCountLabel.Text = string.format("Players: %d (%d ready, %d waiting)", 
		totalPlayers, readyPlayers, waitingPlayers)
	
	-- Update status message
	if totalPlayers < 2 then
		statusLabel.Text = "Waiting for more players to join..."
		statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif waitingPlayers > 0 then
		statusLabel.Text = string.format("%d player(s) waiting for friends", waitingPlayers)
		statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
	elseif readyPlayers >= totalPlayers then
		statusLabel.Text = "All players ready! Game starting soon..."
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		statusLabel.Text = "Vote for a map to begin!"
		statusLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	end
end

-- Show lobby UI
function LobbyUI.show()
	screenGui.Enabled = true
	
	-- Animate in from bottom
	lobbyFrame.Position = UDim2.new(0.5, -250, 1.2, 0)
	TweenService:Create(lobbyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -250, 1, -200)
	}):Play()
end

-- Hide lobby UI
function LobbyUI.hide()
	TweenService:Create(lobbyFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -250, 1.2, 0)
	}):Play()
	
	task.wait(0.4)
	screenGui.Enabled = false
end

-- Remote event setup
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", REMOTE_EVENT_WAIT_TIMEOUT)
if not remoteEvents then
	warn("[LobbyUI] RemoteEvents folder not found")
	return LobbyUI
end

-- Handle lobby players update
local lobbyPlayersUpdate = remoteEvents:WaitForChild("LobbyPlayersUpdate", REMOTE_EVENT_WAIT_TIMEOUT)
if lobbyPlayersUpdate then
	table.insert(_connections, lobbyPlayersUpdate.OnClientEvent:Connect(function(data)
		updatePlayerStatus(data)
	end))
end

-- Handle map vote start (show lobby UI)
local mapVoteStart = remoteEvents:WaitForChild("MapVoteStart", REMOTE_EVENT_WAIT_TIMEOUT)
if mapVoteStart then
	table.insert(_connections, mapVoteStart.OnClientEvent:Connect(function(data)
		LobbyUI.show()
	end))
end

-- Handle map vote end (hide lobby UI after delay)
local mapVoteEnd = remoteEvents:WaitForChild("MapVoteEnd", REMOTE_EVENT_WAIT_TIMEOUT)
if mapVoteEnd then
	table.insert(_connections, mapVoteEnd.OnClientEvent:Connect(function(data)
		task.wait(3) -- Wait a bit before hiding
		LobbyUI.hide()
		
		-- Reset states
		isReady = false
		isWaiting = false
		updateButtonStates()
	end))
end

-- Ready button click handler
table.insert(_connections, readyButton.MouseButton1Click:Connect(function()
	isReady = not isReady
	if isReady then
		isWaiting = false
	end
	
	updateButtonStates()
	
	local playerReadyEvent = remoteEvents:FindFirstChild("PlayerReady")
	if playerReadyEvent then
		playerReadyEvent:FireServer(isReady)
	end
end))

-- Waiting button click handler
table.insert(_connections, waitingButton.MouseButton1Click:Connect(function()
	isWaiting = not isWaiting
	if isWaiting then
		isReady = false
	end
	
	updateButtonStates()
	
	local playerWaitingEvent = remoteEvents:FindFirstChild("PlayerWaiting")
	if playerWaitingEvent then
		playerWaitingEvent:FireServer(isWaiting)
	end
end))

-- Switch server button click handler
table.insert(_connections, switchButton.MouseButton1Click:Connect(function()
	local switchServerEvent = remoteEvents:FindFirstChild("SwitchServer")
	if switchServerEvent then
		switchServerEvent:FireServer()
	end
end))

-- Button hover effects
table.insert(_connections, readyButton.MouseEnter:Connect(function()
	if not isReady then
		TweenService:Create(readyButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 180, 70)
		}):Play()
	end
end))

table.insert(_connections, readyButton.MouseLeave:Connect(function()
	updateButtonStates()
end))

table.insert(_connections, waitingButton.MouseEnter:Connect(function()
	if not isWaiting then
		TweenService:Create(waitingButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(180, 120, 60)
		}):Play()
	end
end))

table.insert(_connections, waitingButton.MouseLeave:Connect(function()
	updateButtonStates()
end))

table.insert(_connections, switchButton.MouseEnter:Connect(function()
	TweenService:Create(switchButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(120, 120, 150)
	}):Play()
end))

table.insert(_connections, switchButton.MouseLeave:Connect(function()
	TweenService:Create(switchButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	}):Play()
end))

-- Cleanup method
function LobbyUI.cleanup()
	for _, connection in ipairs(_connections) do
		connection:Disconnect()
	end
	_connections = {}
end

print("[LobbyUI] Initialized")

return LobbyUI
