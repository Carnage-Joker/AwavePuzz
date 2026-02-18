-- @ScriptType: ModuleScript
-- VoiceoverController.lua
-- Client-side voiceover audio playback
-- Plays voiceover audio and displays subtitles
-- Note: Audio assets not yet created - system ready for integration when assets are available

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local RemoteRegistry = require(RemotesFolder:WaitForChild("RemoteRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local VoiceoverController = {}
VoiceoverController.__index = VoiceoverController

-- Display settings
local FADE_IN_TIME = 0.3
local FADE_OUT_TIME = 0.3

function VoiceoverController.new()
	local self = setmetatable({}, VoiceoverController)
	
	self.isPlaying = false
	self.currentSound = nil
	self.currentTween = nil
	self._connections = {}
	
	self.screenGui = nil
	self.subtitleFrame = nil
	self.subtitleLabel = nil
	
	self:createUI()
	self:setupRemoteEvents()
	
	return self
end

function VoiceoverController:setupRemoteEvents()
	local remotes = RemoteRegistry.GetClientRemotes()

	-- Prefer remotes provided by RemoteRegistry, but fall back to direct lookup
	local playVoiceoverRemote = remotes.PlayVoiceover
	if not playVoiceoverRemote then
		playVoiceoverRemote = RemotesFolder:FindFirstChild("PlayVoiceover")
		if not playVoiceoverRemote and UIDebugConfig.EnableDebugMessages then
			warn("[VoiceoverController] PlayVoiceover remote not found in RemoteRegistry or RemotesFolder")
		end
	end

	local stopVoiceoverRemote = remotes.StopVoiceover
	if not stopVoiceoverRemote then
		stopVoiceoverRemote = RemotesFolder:FindFirstChild("StopVoiceover")
		if not stopVoiceoverRemote and UIDebugConfig.EnableDebugMessages then
			warn("[VoiceoverController] StopVoiceover remote not found in RemoteRegistry or RemotesFolder")
		end
	end

	self.remoteEvents = {
		PlayVoiceover = playVoiceoverRemote,
		StopVoiceover = stopVoiceoverRemote,
	}
	
	-- Listen for voiceover playback requests
	if self.remoteEvents.PlayVoiceover then
		table.insert(self._connections, self.remoteEvents.PlayVoiceover.OnClientEvent:Connect(function(voiceoverData)
			self:playVoiceover(voiceoverData)
		end))
	end
	
	-- Listen for voiceover stop requests
	if self.remoteEvents.StopVoiceover then
		table.insert(self._connections, self.remoteEvents.StopVoiceover.OnClientEvent:Connect(function()
			self:stopVoiceover()
		end))
	end
	
	print("[VoiceoverController] Initialized")
end

function VoiceoverController:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("VoiceoverUI")
	if existing then
		UIDebugConfig.warnDuplicate("VoiceoverUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("VoiceoverUI", "Creating ScreenGui", "VoiceoverController.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "VoiceoverUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 100 -- High priority
	self.screenGui.Enabled = true
	self.screenGui.Parent = PlayerGui
	
	-- Subtitle frame (bottom center of screen)
	self.subtitleFrame = Instance.new("Frame")
	self.subtitleFrame.Name = "SubtitleFrame"
	self.subtitleFrame.Size = UDim2.new(0.8, 0, 0.15, 0)
	self.subtitleFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
	self.subtitleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.subtitleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.subtitleFrame.BackgroundTransparency = 0.5
	self.subtitleFrame.BorderSizePixel = 0
	self.subtitleFrame.Visible = false
	self.subtitleFrame.Parent = self.screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.subtitleFrame
	
	-- Subtitle text label
	self.subtitleLabel = Instance.new("TextLabel")
	self.subtitleLabel.Name = "SubtitleLabel"
	self.subtitleLabel.Size = UDim2.new(0.95, 0, 0.9, 0)
	self.subtitleLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.subtitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	self.subtitleLabel.BackgroundTransparency = 1
	self.subtitleLabel.Font = Enum.Font.GothamMedium
	self.subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.subtitleLabel.TextScaled = true
	self.subtitleLabel.TextWrapped = true
	self.subtitleLabel.TextSize = 20
	self.subtitleLabel.Text = ""
	self.subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	self.subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.subtitleLabel.Parent = self.subtitleFrame
	
	-- Text size constraint for readability
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 24
	textSizeConstraint.MinTextSize = 14
	textSizeConstraint.Parent = self.subtitleLabel
end

function VoiceoverController:playVoiceover(voiceoverData)
	-- Stop any currently playing voiceover
	self:stopVoiceover()
	
	if not voiceoverData then
		return
	end
	
	self.isPlaying = true
	
	-- Set text color based on style
	local styleColors = {
		System = Color3.fromRGB(200, 200, 255),
		Warning = Color3.fromRGB(255, 200, 100),
		Alert = Color3.fromRGB(255, 100, 100),
		Narrative = Color3.fromRGB(180, 220, 180)
	}
	
	self.subtitleLabel.TextColor3 = styleColors[voiceoverData.style] or Color3.fromRGB(255, 255, 255)
	self.subtitleLabel.Text = voiceoverData.text or ""
	
	-- Show subtitle frame with fade-in
	self.subtitleFrame.Visible = true
	self.subtitleFrame.BackgroundTransparency = 1
	self.subtitleLabel.TextTransparency = 1
	
	local fadeInTween = TweenService:Create(
		self.subtitleFrame,
		TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.5}
	)
	
	local textFadeInTween = TweenService:Create(
		self.subtitleLabel,
		TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	
	fadeInTween:Play()
	textFadeInTween:Play()
	
	-- Play audio if sound ID is provided (when assets are available)
	if voiceoverData.soundId and voiceoverData.soundId ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = "VoiceoverSound"
		sound.SoundId = voiceoverData.soundId
		sound.Volume = 0.8
		sound.Parent = SoundService
		
		self.currentSound = sound
		sound:Play()
		
		-- Clean up sound when it finishes
		sound.Ended:Connect(function()
			if self.currentSound == sound then
				sound:Destroy()
				self.currentSound = nil
			end
		end)
	end
	
	-- Auto-hide after duration
	local duration = voiceoverData.duration or 5
	task.delay(duration, function()
		if self.isPlaying then
			self:stopVoiceover()
		end
	end)
	
	print("[VoiceoverController] Playing voiceover:", voiceoverData.id)
end

function VoiceoverController:stopVoiceover()
	-- Only return early if there is truly nothing to stop.
	-- We intentionally check actual state (sound/tween/UI) instead of only isPlaying
	-- so that lingering fade-out tweens from a previous voiceover don't interfere
	-- with a newly started one.
	local hasActiveSound = self.currentSound ~= nil
	local hasActiveTween = self.currentTween ~= nil
	local isSubtitleVisible = self.subtitleFrame and self.subtitleFrame.Visible
	
	if not (self.isPlaying or hasActiveSound or hasActiveTween or isSubtitleVisible) then
		return
	end
	
	self.isPlaying = false
	
	-- Stop any playing sound
	if self.currentSound then
		self.currentSound:Stop()
		self.currentSound:Destroy()
		self.currentSound = nil
	end
	
	-- Cancel any active tweens
	if self.currentTween then
		self.currentTween:Cancel()
	end
	
	-- Fade out and hide
	local fadeOutTween = TweenService:Create(
		self.subtitleFrame,
		TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)
	
	local textFadeOutTween = TweenService:Create(
		self.subtitleLabel,
		TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)
	
	fadeOutTween:Play()
	textFadeOutTween:Play()
	
	self.currentTween = fadeOutTween
	
	fadeOutTween.Completed:Connect(function()
		self.subtitleFrame.Visible = false
		self.currentTween = nil
	end)
end

-- Hide immediately (for state changes)
function VoiceoverController:hideImmediately()
	self.isPlaying = false
	
	if self.currentSound then
		self.currentSound:Stop()
		self.currentSound:Destroy()
		self.currentSound = nil
	end
	
	if self.currentTween then
		self.currentTween:Cancel()
		self.currentTween = nil
	end
	
	self.subtitleFrame.Visible = false
end

function VoiceoverController:cleanup()
	self:hideImmediately()
	
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self._connections = {}
	
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return VoiceoverController
