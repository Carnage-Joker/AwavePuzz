-- SynthesisUI.lua
-- Client-side cure synthesis progress UI
-- Displays high-tension synthesis status with time limit and puzzle progress

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local RemoteRegistry = require(RemotesFolder:WaitForChild("RemoteRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local SynthesisUI = {}
SynthesisUI.__index = SynthesisUI

function SynthesisUI.new()
	local self = setmetatable({}, SynthesisUI)
	
	self.isActive = false
	self.screenGui = nil
	self.mainFrame = nil
	self._connections = {}
	
	self:createUI()
	self:setupRemoteEvents()
	
	return self
end

function SynthesisUI:setupRemoteEvents()
	local remotes = RemoteRegistry.GetClientRemotes()
	self.remoteEvents = {
		SynthesisStateUpdate = remotes.SynthesisStateUpdate,
		SynthesisComplete = remotes.SynthesisComplete,
		SynthesisFailed = remotes.SynthesisFailed,
	}
	
	-- Listen for synthesis state updates
	if self.remoteEvents.SynthesisStateUpdate then
		self._connections.stateUpdate = self.remoteEvents.SynthesisStateUpdate.OnClientEvent:Connect(function(stateData)
			self:updateSynthesisState(stateData)
		end)
	end
	
	-- Listen for synthesis completion
	if self.remoteEvents.SynthesisComplete then
		self._connections.complete = self.remoteEvents.SynthesisComplete.OnClientEvent:Connect(function(data)
			self:onSynthesisComplete(data)
		end)
	end
	
	-- Listen for synthesis failure
	if self.remoteEvents.SynthesisFailed then
		self._connections.failed = self.remoteEvents.SynthesisFailed.OnClientEvent:Connect(function(data)
			self:onSynthesisFailed(data)
		end)
	end
	
	print("[SynthesisUI] Initialized")
end

function SynthesisUI:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("SynthesisUI")
	if existing then
		UIDebugConfig.warnDuplicate("SynthesisUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("SynthesisUI", "Creating ScreenGui", "SynthesisUI.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "SynthesisUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 75 -- High priority
	self.screenGui.Enabled = false
	self.screenGui.Parent = PlayerGui
	
	-- Main container (centered, top of screen)
	self.mainFrame = Instance.new("Frame")
	self.mainFrame.Name = "SynthesisFrame"
	self.mainFrame.Size = UDim2.new(0.6, 0, 0.25, 0)
	self.mainFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	self.mainFrame.BackgroundTransparency = 0.1
	self.mainFrame.BorderSizePixel = 3
	self.mainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
	self.mainFrame.Parent = self.screenGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = self.mainFrame
	
	-- Warning glow effect (pulsing border)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(255, 50, 50)
	uiStroke.Thickness = 3
	uiStroke.Transparency = 0.3
	uiStroke.Parent = self.mainFrame
	self.warningStroke = uiStroke
	
	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0.12, 0)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Code
	titleLabel.Text = "⚠ CURE SYNTHESIS IN PROGRESS ⚠"
	titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	titleLabel.TextScaled = true
	titleLabel.TextStrokeTransparency = 0.3
	titleLabel.Parent = self.mainFrame
	self.titleLabel = titleLabel
	
	-- Time remaining label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
	timeLabel.Position = UDim2.new(0.5, 0, 0.35, 0)
	timeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.Code
	timeLabel.Text = "TIME REMAINING: 120s"
	timeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	timeLabel.TextScaled = true
	timeLabel.TextSize = 32
	timeLabel.Parent = self.mainFrame
	self.timeLabel = timeLabel
	
	-- Puzzle progress bar
	local progressBarBG = Instance.new("Frame")
	progressBarBG.Name = "ProgressBarBG"
	progressBarBG.Size = UDim2.new(0.85, 0, 0.12, 0)
	progressBarBG.Position = UDim2.new(0.5, 0, 0.58, 0)
	progressBarBG.AnchorPoint = Vector2.new(0.5, 0.5)
	progressBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	progressBarBG.BorderSizePixel = 2
	progressBarBG.BorderColor3 = Color3.fromRGB(100, 100, 110)
	progressBarBG.Parent = self.mainFrame
	
	local progressBarFill = Instance.new("Frame")
	progressBarFill.Name = "ProgressBarFill"
	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	progressBarFill.Position = UDim2.new(0, 0, 0, 0)
	progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	progressBarFill.BorderSizePixel = 0
	progressBarFill.Parent = progressBarBG
	self.progressBarFill = progressBarFill
	
	-- Progress label
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "ProgressLabel"
	progressLabel.Size = UDim2.new(0.9, 0, 0.18, 0)
	progressLabel.Position = UDim2.new(0.5, 0, 0.78, 0)
	progressLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Font = Enum.Font.Code
	progressLabel.Text = "PUZZLES COMPLETED: 0/5"
	progressLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
	progressLabel.TextScaled = true
	progressLabel.TextSize = 24
	progressLabel.Parent = self.mainFrame
	self.progressLabel = progressLabel
	
	-- Warning message
	local warningLabel = Instance.new("TextLabel")
	warningLabel.Name = "WarningLabel"
	warningLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	warningLabel.Position = UDim2.new(0.5, 0, 0.93, 0)
	warningLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	warningLabel.BackgroundTransparency = 1
	warningLabel.Font = Enum.Font.Code
	warningLabel.Text = "HOSTILE ACTIVITY INTENSIFIED"
	warningLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
	warningLabel.TextScaled = true
	warningLabel.TextSize = 18
	warningLabel.TextStrokeTransparency = 0.5
	warningLabel.Parent = self.mainFrame
	self.warningLabel = warningLabel
end

function SynthesisUI:show()
	if self.isActive then return end
	
	self.isActive = true
	self.screenGui.Enabled = true
	
	-- Fade in animation
	self.mainFrame.BackgroundTransparency = 1
	local tween = TweenService:Create(
		self.mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.1}
	)
	tween:Play()
	
	-- Start pulsing warning effect
	self:startWarningPulse()
end

function SynthesisUI:hide()
	if not self.isActive then return end
	
	self.isActive = false
	
	-- Stop warning pulse
	self:stopWarningPulse()
	
	-- Fade out animation
	local tween = TweenService:Create(
		self.mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)
	tween:Play()
	
	tween.Completed:Connect(function()
		self.screenGui.Enabled = false
	end)
end

function SynthesisUI:updateSynthesisState(stateData)
	if stateData.state == "Active" then
		self:show()
		
		-- Update time remaining
		if stateData.timeRemaining then
			local seconds = math.floor(stateData.timeRemaining)
			self.timeLabel.Text = string.format("TIME REMAINING: %ds", seconds)
			
			-- Change color based on urgency
			if seconds <= 30 then
				self.timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			elseif seconds <= 60 then
				self.timeLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
			else
				self.timeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			end
		end
		
		-- Update puzzle progress
		if stateData.puzzlesCompleted and stateData.puzzlesTotal then
			local progress = stateData.puzzlesCompleted / stateData.puzzlesTotal
			self.progressLabel.Text = string.format("PUZZLES COMPLETED: %d/%d", 
				stateData.puzzlesCompleted, stateData.puzzlesTotal)
			
			-- Animate progress bar
			TweenService:Create(
				self.progressBarFill,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.new(progress, 0, 1, 0)}
			):Play()
		end
	else
		self:hide()
	end
end

function SynthesisUI:onSynthesisComplete(data)
	self:hide()
	
	-- Show success message
	self.titleLabel.Text = "✓ SYNTHESIS COMPLETE ✓"
	self.titleLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	self.warningLabel.Text = "CURE SYNTHESIZED - VICTORY IMMINENT"
	self.warningLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	
	-- Brief flash before hide
	self:show()
	task.wait(3)
	self:hide()
end

function SynthesisUI:onSynthesisFailed(data)
	-- Show failure message
	self.titleLabel.Text = "✗ SYNTHESIS FAILED ✗"
	self.titleLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	self.warningLabel.Text = data.reason or "UNKNOWN FAILURE"
	self.warningLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	
	-- Brief flash before hide
	task.wait(3)
	self:hide()
end

function SynthesisUI:startWarningPulse()
	-- Create pulsing effect on the warning stroke
	self.pulseLoop = task.spawn(function()
		while self.isActive do
			TweenService:Create(
				self.warningStroke,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0}
			):Play()
			task.wait(0.8)
			
			TweenService:Create(
				self.warningStroke,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.6}
			):Play()
			task.wait(0.8)
		end
	end)
end

function SynthesisUI:stopWarningPulse()
	if self.pulseLoop then
		task.cancel(self.pulseLoop)
		self.pulseLoop = nil
	end
end

function SynthesisUI:cleanup()
	-- Stop warning pulse
	self:stopWarningPulse()
	
	-- Disconnect all connections
	for name, connection in pairs(self._connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self._connections = {}
	
	-- Hide UI
	if self.isActive then
		self:hide()
	end
	
	-- Clean up GUI
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return SynthesisUI
