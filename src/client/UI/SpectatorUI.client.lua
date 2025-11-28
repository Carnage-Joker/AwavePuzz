-- SpectatorUI.client.lua
-- Client script for displaying spectator mode interface when player dies
-- Allows cycling through alive players to spectate

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Constants
local REMOTE_EVENT_WAIT_TIMEOUT = 10

-- State
local isSpectating = false
local currentTargetUserId = nil
local spectatorConnection = nil

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpectatorUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main spectator frame (top banner)
local spectatorBanner = Instance.new("Frame")
spectatorBanner.Name = "SpectatorBanner"
spectatorBanner.Size = UDim2.new(0, 400, 0, 60)
spectatorBanner.Position = UDim2.new(0.5, -200, 0, 80)
spectatorBanner.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
spectatorBanner.BackgroundTransparency = 0.2
spectatorBanner.BorderSizePixel = 0
spectatorBanner.Parent = screenGui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = spectatorBanner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Thickness = 2
bannerStroke.Color = Color3.fromRGB(255, 100, 100)
bannerStroke.Parent = spectatorBanner

-- Spectator icon/text
local spectatorIcon = Instance.new("TextLabel")
spectatorIcon.Name = "Icon"
spectatorIcon.Size = UDim2.new(0, 40, 0, 40)
spectatorIcon.Position = UDim2.new(0, 10, 0.5, -20)
spectatorIcon.BackgroundTransparency = 1
spectatorIcon.Text = "👁"
spectatorIcon.TextSize = 28
spectatorIcon.Parent = spectatorBanner

-- "SPECTATING" label
local spectatingLabel = Instance.new("TextLabel")
spectatingLabel.Name = "SpectatingLabel"
spectatingLabel.Size = UDim2.new(0, 120, 0, 20)
spectatingLabel.Position = UDim2.new(0, 55, 0, 8)
spectatingLabel.BackgroundTransparency = 1
spectatingLabel.Text = "SPECTATING"
spectatingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
spectatingLabel.TextSize = 14
spectatingLabel.Font = Enum.Font.GothamBold
spectatingLabel.TextXAlignment = Enum.TextXAlignment.Left
spectatingLabel.Parent = spectatorBanner

-- Target player name
local targetNameLabel = Instance.new("TextLabel")
targetNameLabel.Name = "TargetName"
targetNameLabel.Size = UDim2.new(0, 280, 0, 28)
targetNameLabel.Position = UDim2.new(0, 55, 0, 28)
targetNameLabel.BackgroundTransparency = 1
targetNameLabel.Text = "Player Name"
targetNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetNameLabel.TextSize = 20
targetNameLabel.Font = Enum.Font.GothamBold
targetNameLabel.TextXAlignment = Enum.TextXAlignment.Left
targetNameLabel.Parent = spectatorBanner

-- Navigation buttons container
local navContainer = Instance.new("Frame")
navContainer.Name = "NavContainer"
navContainer.Size = UDim2.new(0, 80, 0, 40)
navContainer.Position = UDim2.new(1, -90, 0.5, -20)
navContainer.BackgroundTransparency = 1
navContainer.Parent = spectatorBanner

-- Previous button
local prevButton = Instance.new("TextButton")
prevButton.Name = "PrevButton"
prevButton.Size = UDim2.new(0, 35, 0, 35)
prevButton.Position = UDim2.new(0, 0, 0, 0)
prevButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
prevButton.Text = "◀"
prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
prevButton.TextSize = 18
prevButton.Font = Enum.Font.GothamBold
prevButton.Parent = navContainer

local prevCorner = Instance.new("UICorner")
prevCorner.CornerRadius = UDim.new(0, 8)
prevCorner.Parent = prevButton

-- Next button
local nextButton = Instance.new("TextButton")
nextButton.Name = "NextButton"
nextButton.Size = UDim2.new(0, 35, 0, 35)
nextButton.Position = UDim2.new(0, 40, 0, 0)
nextButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
nextButton.Text = "▶"
nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nextButton.TextSize = 18
nextButton.Font = Enum.Font.GothamBold
nextButton.Parent = navContainer

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 8)
nextCorner.Parent = nextButton

-- Bottom info banner
local infoBanner = Instance.new("Frame")
infoBanner.Name = "InfoBanner"
infoBanner.Size = UDim2.new(0, 350, 0, 50)
infoBanner.Position = UDim2.new(0.5, -175, 1, -70)
infoBanner.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
infoBanner.BackgroundTransparency = 0.3
infoBanner.BorderSizePixel = 0
infoBanner.Parent = screenGui

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = infoBanner

-- "You died" label
local diedLabel = Instance.new("TextLabel")
diedLabel.Name = "DiedLabel"
diedLabel.Size = UDim2.new(1, -20, 0, 25)
diedLabel.Position = UDim2.new(0, 10, 0, 5)
diedLabel.BackgroundTransparency = 1
diedLabel.Text = "☠ YOU HAVE BEEN ELIMINATED"
diedLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
diedLabel.TextSize = 16
diedLabel.Font = Enum.Font.GothamBold
diedLabel.Parent = infoBanner

-- Alive count label
local aliveCountLabel = Instance.new("TextLabel")
aliveCountLabel.Name = "AliveCount"
aliveCountLabel.Size = UDim2.new(1, -20, 0, 20)
aliveCountLabel.Position = UDim2.new(0, 10, 0, 28)
aliveCountLabel.BackgroundTransparency = 1
aliveCountLabel.Text = "Players alive: 0"
aliveCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
aliveCountLabel.TextSize = 14
aliveCountLabel.Font = Enum.Font.Gotham
aliveCountLabel.Parent = infoBanner

-- Controls hint
local controlsHint = Instance.new("TextLabel")
controlsHint.Name = "ControlsHint"
controlsHint.Size = UDim2.new(0, 300, 0, 30)
controlsHint.Position = UDim2.new(0.5, -150, 0, 150)
controlsHint.BackgroundTransparency = 1
controlsHint.Text = "Press Q/E or click arrows to switch players"
controlsHint.TextColor3 = Color3.fromRGB(150, 150, 150)
controlsHint.TextSize = 14
controlsHint.Font = Enum.Font.Gotham
controlsHint.Parent = screenGui

-- Camera control variables

-- Function to set camera on target
local function updateCamera()
	if not isSpectating or not currentTargetUserId then
		return
	end
	
	local targetPlayer = Players:GetPlayerByUserId(currentTargetUserId)
	if not targetPlayer then
		return
	end
	
	local character = targetPlayer.Character
	if not character then
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	-- Set camera to follow target
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
	end
end

-- Function to cycle spectator target
local function cycleTarget(direction)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local cycleEvent = remoteEvents:FindFirstChild("SpectatorCycleTarget")
		if cycleEvent then
			cycleEvent:FireServer(direction)
		end
	end
end

-- Function to enter spectator mode
local function enterSpectatorMode(data)
	isSpectating = true
	screenGui.Enabled = true
	
	-- Update target info
	if data.targetPlayer then
		targetNameLabel.Text = data.targetPlayer
		currentTargetUserId = data.targetUserId
	else
		targetNameLabel.Text = "No players alive"
		currentTargetUserId = nil
	end
	
	-- Animate in
	spectatorBanner.Position = UDim2.new(0.5, -200, -0.2, 0)
	infoBanner.Position = UDim2.new(0.5, -175, 1.2, 0)
	
	TweenService:Create(spectatorBanner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0, 80)
	}):Play()
	
	TweenService:Create(infoBanner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -175, 1, -70)
	}):Play()
	
	-- Start camera update loop
	if spectatorConnection then
		spectatorConnection:Disconnect()
	end
	spectatorConnection = RunService.RenderStepped:Connect(updateCamera)
	
	-- Initial camera setup
	task.delay(0.1, updateCamera)
end

-- Function to exit spectator mode
local function exitSpectatorMode()
	isSpectating = false
	currentTargetUserId = nil
	
	-- Disconnect camera loop
	if spectatorConnection then
		spectatorConnection:Disconnect()
		spectatorConnection = nil
	end
	
	-- Reset camera
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		if player.Character then
			camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
		else
			-- Wait for character to load, then set camera subject
			local conn
			conn = player.CharacterAdded:Connect(function(char)
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					camera.CameraSubject = humanoid
				end
				if conn then
					conn:Disconnect()
				end
			end)
		end
	
	-- Animate out
	TweenService:Create(spectatorBanner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -200, -0.2, 0)
	}):Play()
	
	TweenService:Create(infoBanner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -175, 1.2, 0)
	}):Play()
	
	task.delay(0.3, function()
		screenGui.Enabled = false
	end)
end

-- Function to update spectator target
local function updateSpectatorTarget(data)
	if not isSpectating then
		return
	end
	
	if data.targetPlayer then
		targetNameLabel.Text = data.targetPlayer
		currentTargetUserId = data.targetUserId
	else
		targetNameLabel.Text = "No players alive"
		currentTargetUserId = nil
	end
	
	updateCamera()
end

-- Function to update alive player list
local function updateAliveList(data)
	local aliveCount = data.aliveCount or 0
	aliveCountLabel.Text = "Players alive: " .. tostring(aliveCount)
end

-- Button hover effects
prevButton.MouseEnter:Connect(function()
	TweenService:Create(prevButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(80, 80, 110)
	}):Play()
end)

prevButton.MouseLeave:Connect(function()
	TweenService:Create(prevButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	}):Play()
end)

nextButton.MouseEnter:Connect(function()
	TweenService:Create(nextButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(80, 80, 110)
	}):Play()
end)

nextButton.MouseLeave:Connect(function()
	TweenService:Create(nextButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	}):Play()
end)

-- Button click handlers
prevButton.MouseButton1Click:Connect(function()
	cycleTarget("prev")
end)

nextButton.MouseButton1Click:Connect(function()
	cycleTarget("next")
end)

-- Keyboard controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isSpectating then return end
	
	if input.KeyCode == Enum.KeyCode.Q then
		cycleTarget("prev")
	elseif input.KeyCode == Enum.KeyCode.E then
		cycleTarget("next")
	end
end)

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", REMOTE_EVENT_WAIT_TIMEOUT)
if not remoteEvents then
	warn("[SpectatorUI] RemoteEvents folder not found")
	return
end

-- Enter spectator mode
local enterEvent = remoteEvents:WaitForChild("EnterSpectatorMode", REMOTE_EVENT_WAIT_TIMEOUT)
if enterEvent then
	enterEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			enterSpectatorMode(data)
		end
	end)
end

-- Exit spectator mode
local exitEvent = remoteEvents:WaitForChild("ExitSpectatorMode", REMOTE_EVENT_WAIT_TIMEOUT)
if exitEvent then
	exitEvent.OnClientEvent:Connect(function()
		exitSpectatorMode()
	end)
end

-- Update spectator target
local targetUpdateEvent = remoteEvents:WaitForChild("SpectatorTargetUpdate", REMOTE_EVENT_WAIT_TIMEOUT)
if targetUpdateEvent then
	targetUpdateEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			updateSpectatorTarget(data)
		end
	end)
end

-- Update alive list
local stateUpdateEvent = remoteEvents:WaitForChild("SpectatorStateUpdate", REMOTE_EVENT_WAIT_TIMEOUT)
if stateUpdateEvent then
	stateUpdateEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			updateAliveList(data)
		end
	end)
end

print("SpectatorUI initialized")
