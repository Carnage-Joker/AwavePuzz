-- PortalQueueUI.lua
-- Client-side UI for portal matchmaking queue status
-- Shows queue count, countdown timer, and status messages

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PortalQueueUI = {}

-- Constants
local REMOTE_EVENT_WAIT_TIMEOUT = 10

-- UI State
local currentPortalId = nil
local isInQueue = false

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PortalQueueUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main queue status frame
local queueFrame = Instance.new("Frame")
queueFrame.Name = "QueueFrame"
queueFrame.Size = UDim2.new(0, 400, 0, 160)
queueFrame.Position = UDim2.new(0.5, -200, 0.85, -80)
queueFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
queueFrame.BackgroundTransparency = 0.1
queueFrame.BorderSizePixel = 0
queueFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = queueFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(100, 200, 255)
frameStroke.Parent = queueFrame

-- Portal name label
local portalNameLabel = Instance.new("TextLabel")
portalNameLabel.Name = "PortalName"
portalNameLabel.Size = UDim2.new(1, -20, 0, 30)
portalNameLabel.Position = UDim2.new(0, 10, 0, 10)
portalNameLabel.BackgroundTransparency = 1
portalNameLabel.Text = "PORTAL QUEUE"
portalNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
portalNameLabel.TextSize = 24
portalNameLabel.Font = Enum.Font.GothamBold
portalNameLabel.TextXAlignment = Enum.TextXAlignment.Left
portalNameLabel.Parent = queueFrame

-- Queue count label
local queueCountLabel = Instance.new("TextLabel")
queueCountLabel.Name = "QueueCount"
queueCountLabel.Size = UDim2.new(1, -20, 0, 35)
queueCountLabel.Position = UDim2.new(0, 10, 0, 45)
queueCountLabel.BackgroundTransparency = 1
queueCountLabel.Text = "Players: 0 / 8"
queueCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
queueCountLabel.TextSize = 20
queueCountLabel.Font = Enum.Font.GothamBold
queueCountLabel.TextXAlignment = Enum.TextXAlignment.Left
queueCountLabel.Parent = queueFrame

-- Countdown label
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "Countdown"
countdownLabel.Size = UDim2.new(1, -20, 0, 30)
countdownLabel.Position = UDim2.new(0, 10, 0, 85)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "Waiting for players..."
countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
countdownLabel.TextSize = 18
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.TextXAlignment = Enum.TextXAlignment.Left
countdownLabel.Parent = queueFrame

-- Leave queue button
local leaveButton = Instance.new("TextButton")
leaveButton.Name = "LeaveButton"
leaveButton.Size = UDim2.new(0, 150, 0, 35)
leaveButton.Position = UDim2.new(1, -160, 1, -45)
leaveButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
leaveButton.Text = "LEAVE QUEUE"
leaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveButton.TextSize = 16
leaveButton.Font = Enum.Font.GothamBold
leaveButton.Parent = queueFrame

local leaveCorner = Instance.new("UICorner")
leaveCorner.CornerRadius = UDim.new(0, 8)
leaveCorner.Parent = leaveButton

-- Get remote events
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", REMOTE_EVENT_WAIT_TIMEOUT)
if not remoteEvents then
	warn("[PortalQueueUI] Failed to find RemoteEvents folder")
	return PortalQueueUI
end

local portalQueueStatus = remoteEvents:WaitForChild("PortalQueueStatus", REMOTE_EVENT_WAIT_TIMEOUT)
local portalLeaveQueue = remoteEvents:WaitForChild("PortalLeaveQueue", REMOTE_EVENT_WAIT_TIMEOUT)
local portalQueueJoined = remoteEvents:WaitForChild("PortalQueueJoined", REMOTE_EVENT_WAIT_TIMEOUT)
local portalQueueLeft = remoteEvents:WaitForChild("PortalQueueLeft", REMOTE_EVENT_WAIT_TIMEOUT)

-- Validate all remote events loaded
if not portalQueueStatus or not portalLeaveQueue or not portalQueueJoined or not portalQueueLeft then
	warn("[PortalQueueUI] Failed to load one or more RemoteEvents")
	return PortalQueueUI
end

-- Show queue UI
function PortalQueueUI.show(portalId, mapId)
	currentPortalId = portalId
	isInQueue = true
	
	-- Update portal name
	local displayName = portalId
	if mapId and mapId ~= "Random" then
		displayName = mapId .. " Portal"
	elseif mapId == "Random" then
		displayName = "Random Map Portal"
	end
	
	portalNameLabel.Text = string.upper(displayName)
	
	-- Show UI with animation
	screenGui.Enabled = true
	queueFrame.Position = UDim2.new(0.5, -200, 1, 0)
	
	local tween = TweenService:Create(queueFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0.85, -80)
	})
	tween:Play()
end

-- Hide queue UI
function PortalQueueUI.hide()
	isInQueue = false
	currentPortalId = nil
	
	-- Hide with animation
	local tween = TweenService:Create(queueFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -200, 1, 0)
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		screenGui.Enabled = false
	end)
end

-- Update queue status
function PortalQueueUI.updateStatus(status)
	if not status then return end
	
	-- If this is not our portal, ignore
	if isInQueue and status.portalId ~= currentPortalId then
		return
	end
	
	-- Update queue count
	local queueCount = status.queueCount or 0
	local maxPlayers = status.maxPlayers or 8
	queueCountLabel.Text = string.format("Players: %d / %d", queueCount, maxPlayers)
	
	-- Update countdown/status
	if status.status == "locked" then
		countdownLabel.Text = "Portal launching..."
		countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		frameStroke.Color = Color3.fromRGB(255, 100, 100)
	elseif status.status == "countdown" and status.countdown then
		local seconds = math.ceil(status.countdown)
		countdownLabel.Text = string.format("Starting in: %d seconds", seconds)
		countdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		frameStroke.Color = Color3.fromRGB(255, 215, 0)
	elseif status.status == "ready" then
		countdownLabel.Text = "Waiting for players..."
		countdownLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		frameStroke.Color = Color3.fromRGB(100, 200, 255)
	elseif status.status == "full" then
		countdownLabel.Text = status.message or "Portal is full!"
		countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

-- Handle portal queue status updates from server
if portalQueueStatus then
	portalQueueStatus.OnClientEvent:Connect(function(status)
		-- Check if this is a status update for all portals or a specific message for us
		if status.status == "full" or status.status == "locked" then
			-- These are specific to the player trying to join
			if status.message then
				-- Show temporary message (could enhance with a separate notification system)
				print("[PortalQueue]", status.message)
			end
		else
			-- This is a general status update
			-- If we're in queue for this portal, update UI
			if isInQueue and status.portalId == currentPortalId then
				PortalQueueUI.updateStatus(status)
			end
		end
	end)
end

-- Handle leave button click
leaveButton.MouseButton1Click:Connect(function()
	if isInQueue and currentPortalId and portalLeaveQueue then
		portalLeaveQueue:FireServer()
		PortalQueueUI.hide()
	end
end)

-- Handle queue join confirmation
if portalQueueJoined then
	portalQueueJoined.OnClientEvent:Connect(function(data)
		if data and data.portalId then
			PortalQueueUI.show(data.portalId, data.mapId)
		end
	end)
end

-- Handle queue leave notification
if portalQueueLeft then
	portalQueueLeft.OnClientEvent:Connect(function(data)
		if data and data.portalId == currentPortalId then
			PortalQueueUI.hide()
		end
	end)
end

-- Export functions
function PortalQueueUI.initialize()
	print("[PortalQueueUI] Initialized")
end

-- Call initialize
PortalQueueUI.initialize()

return PortalQueueUI
