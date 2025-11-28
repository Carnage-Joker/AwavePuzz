-- WaveUI.client.lua
-- Client script for displaying wave information
-- Place in StarterGui as a LocalScript
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load UI scaling utilities
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "hudElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Frame (positioned top-center left of compass, accounting for safe area)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UIScaleManager.scaleSize(250, 120, "hudElements", "waveInfo")
-- Position top-left to avoid overlapping with compass at top-center
mainFrame.Position = UIScaleManager.getPositionWithSafeArea("topLeft", 10, 0)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
mainFrame.Parent = screenGui

-- Add corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
corner.Parent = mainFrame

-- Wave Number Label
local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveLabel"
waveLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
waveLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
waveLabel.BackgroundTransparency = 1
waveLabel.Text = "Wave: 0"
waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waveLabel.TextSize = getScaledTextSize(24)
waveLabel.Font = Enum.Font.GothamBold
waveLabel.TextXAlignment = Enum.TextXAlignment.Left
waveLabel.Parent = mainFrame

-- Time Remaining Label
local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "TimeLabel"
timeLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
timeLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(45, "padding"))
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Time: 0:00"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.TextSize = getScaledTextSize(18)
timeLabel.Font = Enum.Font.Gotham
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.Parent = mainFrame

-- Zombies Remaining Label
local zombieLabel = Instance.new("TextLabel")
zombieLabel.Name = "ZombieLabel"
zombieLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
zombieLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(75, "padding"))
zombieLabel.BackgroundTransparency = 1
zombieLabel.Text = "Zombies: 0"
zombieLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
zombieLabel.TextSize = getScaledTextSize(18)
zombieLabel.Font = Enum.Font.Gotham
zombieLabel.TextXAlignment = Enum.TextXAlignment.Left
zombieLabel.Parent = mainFrame

-- Wave Announcement Frame (for big announcements - centered, scaled)
local announcementFrame = Instance.new("Frame")
announcementFrame.Name = "AnnouncementFrame"
announcementFrame.Size = UIScaleManager.scaleSize(400, 80, "menuElements")
announcementFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
announcementFrame.AnchorPoint = Vector2.new(0.5, 0.5)
announcementFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
announcementFrame.BackgroundTransparency = 0.2
announcementFrame.BorderSizePixel = 3
announcementFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
announcementFrame.Visible = false
announcementFrame.Parent = screenGui

local announcementCorner = Instance.new("UICorner")
announcementCorner.CornerRadius = UDim.new(0, getScaledValue(15, "padding"))
announcementCorner.Parent = announcementFrame

local announcementLabel = Instance.new("TextLabel")
announcementLabel.Name = "AnnouncementLabel"
announcementLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(20, "padding"))
announcementLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
announcementLabel.BackgroundTransparency = 1
announcementLabel.Text = "WAVE 1 STARTING!"
announcementLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
announcementLabel.TextSize = getScaledTextSize(36)
announcementLabel.Font = Enum.Font.GothamBold
announcementLabel.TextScaled = true
announcementLabel.Parent = announcementFrame

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	mainFrame.Size = UIScaleManager.scaleSize(250, 120, "hudElements", "waveInfo")
	mainFrame.Position = UIScaleManager.getPositionWithSafeArea("topLeft", 10, 0)
	mainFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
	corner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
	
	waveLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
	waveLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
	waveLabel.TextSize = getScaledTextSize(24)
	
	timeLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
	timeLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(45, "padding"))
	timeLabel.TextSize = getScaledTextSize(18)
	
	zombieLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(25, "padding"))
	zombieLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(75, "padding"))
	zombieLabel.TextSize = getScaledTextSize(18)
	
	announcementFrame.Size = UIScaleManager.scaleSize(400, 80, "menuElements")
	announcementCorner.CornerRadius = UDim.new(0, getScaledValue(15, "padding"))
	announcementLabel.TextSize = getScaledTextSize(36)
end

-- Register for scale changes
UIScaleManager.onScaleChanged(updateUIScaling)

-- Helpers
local currentAnnouncementId = 0

local function formatTime(seconds)
	seconds = tonumber(seconds) or 0
	if seconds < 0 then
		seconds = 0
	end

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", minutes, secs)
end

local function showAnnouncement(text, duration)
	currentAnnouncementId += 1
	local thisId = currentAnnouncementId

	announcementLabel.Text = text
	announcementFrame.Visible = true

	announcementFrame.Size = UDim2.new(0, 0, 0, 0)
	announcementFrame:TweenSize(
		UDim2.new(0, 400, 0, 80),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5,
		true
	)

	task.delay(duration or 3, function()
		if thisId ~= currentAnnouncementId then
			return
		end

		announcementFrame:TweenSize(
			UDim2.new(0, 0, 0, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.3,
			true,
			function()
				if thisId == currentAnnouncementId then
					announcementFrame.Visible = false
				end
			end
		)
	end)
end

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Wave Announce
local waveAnnounceEvent = remoteEvents:WaitForChild("WaveAnnounce")
waveAnnounceEvent.OnClientEvent:Connect(function(waveData)
	if typeof(waveData) ~= "table" then
		return
	end

	local waveNumber = waveData.waveNumber or 0
	local timeLimit = waveData.timeLimit or 0

	waveLabel.Text = "Wave: " .. tostring(waveNumber)
	timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeLabel.Text = "Time: " .. formatTime(timeLimit)

	showAnnouncement("WAVE " .. tostring(waveNumber) .. " STARTING!", 3)
end)

-- Wave Update
local waveUpdateEvent = remoteEvents:WaitForChild("WaveUpdate")
waveUpdateEvent.OnClientEvent:Connect(function(updateData)
	if typeof(updateData) ~= "table" then
		return
	end

	if updateData.timeRemaining ~= nil then
		local remaining = tonumber(updateData.timeRemaining) or 0
		if remaining < 0 then remaining = 0 end

		timeLabel.Text = "Time: " .. formatTime(remaining)

		if remaining <= 30 and remaining > 0 then
			timeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		else
			timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	if updateData.zombiesAlive ~= nil then
		zombieLabel.Text = "Zombies: " .. tostring(updateData.zombiesAlive)
	end
end)

-- Game State Update
local gameStateEvent = remoteEvents:WaitForChild("GameStateUpdate")
gameStateEvent.OnClientEvent:Connect(function(stateData)
	if typeof(stateData) ~= "table" then
		return
	end

	local state = stateData.state

	if state == "Victory" then
		showAnnouncement("VICTORY! CURE COMPLETED!", 5)
		waveLabel.Text = "Wave: Complete"
		timeLabel.Text = ""
		zombieLabel.Text = ""

	elseif state == "Defeat" then
		showAnnouncement("DEFEAT! GAME OVER", 5)
		waveLabel.Text = "Wave: Failed"
		timeLabel.Text = ""
		zombieLabel.Text = ""

	elseif state == "Waiting" then
		currentAnnouncementId += 1
		announcementFrame.Visible = false
		waveLabel.Text = "Waiting for players..."
		timeLabel.Text = ""
		zombieLabel.Text = ""

	elseif state == "Intermission" then
		showAnnouncement("Wave Complete! Next wave soon...", 3)
	end
end)

print("WaveUI initialized")
