-- EpilogueUI.client.lua
-- Displays the game's epilogue/intro cinematic
-- Multi-page story narrative that can be skipped or advanced

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(SharedFolder:WaitForChild("StoryConfig"))
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))
local UIConnectionMaid = require(SharedFolder:WaitForChild("UI"):WaitForChild("UIConnectionMaid"))

-- Get MusicController for audio muting
local MusicController = require(script.Parent.Parent:WaitForChild("MusicController"))

local EpilogueUI = {}
EpilogueUI.__index = EpilogueUI

-- no module-level maid; each instance owns its cleanup

function EpilogueUI.new()
	local self = setmetatable({}, EpilogueUI)
	
	self.isActive = false
	self.currentPage = 1
	self.isTransitioning = false
	self.autoAdvanceTimer = nil
	self.remotes = nil -- Will be set via bindRemotes()
	self.tweenConnections = {} -- Track tween completion connections
	self.maid = UIConnectionMaid.new()
	
	self.screenGui = nil
	self.frame = nil
	
	self:createUI()
	
	return self
end

-- Bind remotes from RemoteRegistry (called by ClientMain)
function EpilogueUI:bindRemotes(remotes)
	if not remotes then
		warn("[EpilogueUI] bindRemotes: No remotes provided")
		return
	end
	
	self.remotes = remotes
	
	-- ✅ PRIMARY: Listen for GameStateUpdate (state-driven UI)
	if self.remotes.GameStateUpdate then
		self.maid:Give(self.remotes.GameStateUpdate.OnClientEvent:Connect(function(stateData)
			if stateData and stateData.state then
				local state = stateData.state
				-- Show epilogue for any state containing "Epilogue"
				local isEpilogueState = typeof(state) == "string" and string.find(state, "Epilogue", 1, true) ~= nil
				
				if isEpilogueState then
					print("[EpilogueUI] Received GameStateUpdate with state=" .. state)
					self:show()
				elseif self.isActive then
					-- Hide if state changes away from epilogue
					print("[EpilogueUI] Received GameStateUpdate with state=" .. state .. ", hiding")
					self:hide()
				end
			end
		end), "gameStateUpdate")
	end
	
	-- ✅ COMPATIBILITY: Listen for server commands (legacy support)
	if self.remotes.ShowEpilogue then
		self.maid:Give(self.remotes.ShowEpilogue.OnClientEvent:Connect(function()
			print("[EpilogueUI] Received ShowEpilogue event (legacy)")
			self:show()
		end), "showEpilogue")
	end
	
	if self.remotes.HideEpilogue then
		self.maid:Give(self.remotes.HideEpilogue.OnClientEvent:Connect(function()
			print("[EpilogueUI] Received HideEpilogue event (legacy)")
			self:hide()
		end), "hideEpilogue")
	end
	
	print("[EpilogueUI] Remotes bound and ready (state-driven + legacy)")
end

function EpilogueUI:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("EpilogueUI")
	if existing then
		UIDebugConfig.warnDuplicate("EpilogueUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("EpilogueUI", "Creating ScreenGui", "EpilogueUI.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "EpilogueUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 99 -- Just below title screen
	self.screenGui.Enabled = false
	self.screenGui.Parent = PlayerGui
	
	-- Main background frame
	self.frame = Instance.new("Frame")
	self.frame.Name = "EpilogueFrame"
	self.frame.Size = UDim2.new(1, 0, 1, 0)
	self.frame.Position = UDim2.new(0, 0, 0, 0)
	self.frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.frame.BorderSizePixel = 0
	self.frame.Parent = self.screenGui
	
	-- Content container (centered)
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(0.8, 0, 0.7, 0)
	contentContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	contentContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = self.frame
	
	-- Title label - styled as system log header
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Code
	titleLabel.Text = "THE OUTBREAK"
	titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	titleLabel.TextScaled = true
	titleLabel.TextSize = 48
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.Parent = contentContainer
	
	-- Story text container with ScrollingFrame for long text
	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, 0, 0.7, 0)
	textContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	textContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	textContainer.BackgroundTransparency = 1
	textContainer.Parent = contentContainer
	
	-- Story text label - styled as monospace system log
	local storyText = Instance.new("TextLabel")
	storyText.Name = "StoryText"
	storyText.Size = UDim2.new(1, 0, 1, 0)
	storyText.Position = UDim2.new(0.5, 0, 0.5, 0)
	storyText.AnchorPoint = Vector2.new(0.5, 0.5)
	storyText.BackgroundTransparency = 1
	storyText.Font = Enum.Font.Code
	storyText.Text = ""
	storyText.TextColor3 = Color3.fromRGB(200, 220, 240)
	storyText.TextSize = 22
	storyText.TextWrapped = true
	storyText.TextXAlignment = Enum.TextXAlignment.Left
	storyText.TextYAlignment = Enum.TextYAlignment.Top
	storyText.Parent = textContainer
	
	-- Progress indicator
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "ProgressLabel"
	progressLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
	progressLabel.Position = UDim2.new(0.5, 0, 0.95, 0)
	progressLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.Text = "1 / " .. StoryConfig.TotalEpiloguePages
	progressLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	progressLabel.TextSize = 18
	progressLabel.Parent = contentContainer
	
	-- Skip button (top right)
	if StoryConfig.EpilogueSkippable then
		local skipButton = Instance.new("TextButton")
		skipButton.Name = "SkipButton"
		skipButton.Size = UDim2.new(0.25, 0, 0.06, 0)
		skipButton.Position = UDim2.new(0.98, 0, 0.05, 0)
		skipButton.AnchorPoint = Vector2.new(1, 0)
		skipButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		skipButton.BackgroundTransparency = 0.3
		skipButton.BorderSizePixel = 0
		skipButton.Font = Enum.Font.Code
		skipButton.Text = StoryConfig.SkipButtonText
		skipButton.TextColor3 = Color3.fromRGB(255, 100, 100)
		skipButton.TextSize = 16
		skipButton.Parent = self.frame
		
		self.maid:Give(skipButton.MouseButton1Click:Connect(function()
			self:skip()
		end), "skipButton")
		
		self.skipButton = skipButton
	end
	
	-- Mute button (top right, below skip)
	local muteButton = Instance.new("TextButton")
	muteButton.Name = "MuteButton"
	muteButton.Size = UDim2.new(0.25, 0, 0.06, 0)
	muteButton.Position = UDim2.new(0.98, 0, 0.12, 0)
	muteButton.AnchorPoint = Vector2.new(1, 0)
	muteButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	muteButton.BackgroundTransparency = 0.3
	muteButton.BorderSizePixel = 0
	muteButton.Font = Enum.Font.Code
	muteButton.Text = StoryConfig.MuteButtonText
	muteButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	muteButton.TextSize = 16
	muteButton.Parent = self.frame
	
	self.audioMuted = false
	self.maid:Give(muteButton.MouseButton1Click:Connect(function()
		self.audioMuted = not self.audioMuted
		if self.audioMuted then
			muteButton.Text = "[M] Unmute Audio"
			muteButton.TextColor3 = Color3.fromRGB(255, 100, 100)
			-- Mute all music tracks
			MusicController.muteAll()
		else
			muteButton.Text = StoryConfig.MuteButtonText
			muteButton.TextColor3 = Color3.fromRGB(200, 200, 200)
			-- Unmute all music tracks
			MusicController.unmuteAll()
		end
	end), "muteButton")
	
	self.muteButton = muteButton
	
	-- Continue button (bottom center) - styled as system prompt
	local continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0.3, 0, 0.08, 0)
	continueButton.Position = UDim2.new(0.5, 0, 0.92, 0)
	continueButton.AnchorPoint = Vector2.new(0.5, 0.5)
	continueButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	continueButton.BackgroundTransparency = 0.2
	continueButton.BorderSizePixel = 2
	continueButton.BorderColor3 = Color3.fromRGB(80, 150, 200)
	continueButton.Font = Enum.Font.Code
	continueButton.Text = StoryConfig.ContinueButtonText
	continueButton.TextColor3 = Color3.fromRGB(180, 220, 255)
	continueButton.TextSize = 20
	continueButton.Parent = self.frame
	
	self.maid:Give(continueButton.MouseButton1Click:Connect(function()
		self:nextPage()
	end), "continueButton")
	
	-- Store references
	self.titleLabel = titleLabel
	self.storyText = storyText
	self.progressLabel = progressLabel
	self.continueButton = continueButton
	self.contentContainer = contentContainer
end

function EpilogueUI:show()
	if self.isActive then return end
	
	print("[EpilogueUI] Showing epilogue")
	self.isActive = true
	self.currentPage = 1
	self.screenGui.Enabled = true
	
	-- Display first page
	self:displayPage(1)
	
	-- Register with ModalManager at FULLSCREEN priority
	ModalManager.push("EpilogueUI", function()
		-- Allow skipping via ESC if enabled
		if StoryConfig.EpilogueSkippable then
			self:skip()
		end
	end, ModalManager.Priority.FULLSCREEN)
	
	-- Listen for input (only if top modal)
	self.maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Only process if this is the top modal
		if not ModalManager.isTopModal("EpilogueUI") then
			return
		end
		
		-- ESC handled by ModalManager global handler
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
			self:nextPage()
		elseif input.KeyCode == Enum.KeyCode.M then
			-- Toggle mute
			if self.muteButton then
				self.audioMuted = not self.audioMuted
				if self.audioMuted then
					self.muteButton.Text = "[M] Unmute Audio"
					self.muteButton.TextColor3 = Color3.fromRGB(255, 100, 100)
					-- Mute all music tracks
					MusicController.muteAll()
				else
					self.muteButton.Text = StoryConfig.MuteButtonText
					self.muteButton.TextColor3 = Color3.fromRGB(200, 200, 200)
					-- Unmute all music tracks
					MusicController.unmuteAll()
				end
			end
		end
	end), "inputConnection")
	
	-- Fade in
	self:fadeIn()
end

function EpilogueUI:hide()
	if not self.isActive then return end
	
	print("[EpilogueUI] ✓ Hide() called - hiding UI")
	self.isActive = false
	
	-- Cancel any auto-advance timer
	if self.autoAdvanceTimer then
		task.cancel(self.autoAdvanceTimer)
		self.autoAdvanceTimer = nil
	end
	
	-- Remove from ModalManager
	ModalManager.remove("EpilogueUI")
	
	-- Fade out
	self:fadeOut()
end

function EpilogueUI:displayPage(pageNumber)
	if pageNumber < 1 or pageNumber > StoryConfig.TotalEpiloguePages then
		return
	end
	
	local pageData = StoryConfig.EpiloguePages[pageNumber]
	if not pageData then return end
	
	-- Fade out current content
	self:fadeOutContent()
	
	-- Wait for fade out using spawn instead of blocking
	task.spawn(function()
		task.wait(0.3)
		
		-- BUGFIX (MEDIUM): Check if UI is still active before updating
		if not self or not self.isActive then return end
		
		-- Update content
		self.titleLabel.Text = pageData.Title
		self.storyText.Text = pageData.Text
		self.progressLabel.Text = pageNumber .. " / " .. StoryConfig.TotalEpiloguePages
		
		-- Update continue button text
		if pageNumber == StoryConfig.TotalEpiloguePages then
			self.continueButton.Text = "Begin"
		else
			self.continueButton.Text = StoryConfig.ContinueButtonText
		end
		
		-- Fade in new content
		self:fadeInContent()
		
		-- Start auto-advance timer if configured
		if pageData.DisplayTime and pageData.DisplayTime > 0 then
			if self.autoAdvanceTimer then
				task.cancel(self.autoAdvanceTimer)
			end
			
			self.autoAdvanceTimer = task.delay(pageData.DisplayTime, function()
				if self.isActive and self.currentPage == pageNumber then
					self:nextPage()
				end
			end)
		end
	end)
end

function EpilogueUI:nextPage()
	-- Cancel any pending auto-advance timer to avoid double-trigger
	if self.autoAdvanceTimer then
		task.cancel(self.autoAdvanceTimer)
		self.autoAdvanceTimer = nil
	end
	
	self.currentPage = self.currentPage + 1
	
	if self.currentPage > StoryConfig.TotalEpiloguePages then
		-- Epilogue complete - bypass transition gating on final page
		self:complete()
	else
		-- Only block navigation if transitioning between pages
		if self.isTransitioning then return end
		-- Display next page
		self:displayPage(self.currentPage)
	end
end

function EpilogueUI:skip()
	if not StoryConfig.EpilogueSkippable then return end
	self:complete()
end

function EpilogueUI:complete()
	print("[EpilogueUI] ✓ Complete() called - closing epilogue UI")
	-- Notify server that epilogue is complete
	if self.remotes and self.remotes.EpilogueComplete then
		self.remotes.EpilogueComplete:FireServer()
	end
	
	self:hide()
end

function EpilogueUI:fadeIn()
	self.frame.BackgroundTransparency = 1
	
	local tween = TweenService:Create(
		self.frame,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{ BackgroundTransparency = 0 }
	)
	tween:Play()
	
	self:fadeInContent()
end

function EpilogueUI:fadeOut()
	local fadeTime = 0.8
	
	local bgTween = TweenService:Create(
		self.frame,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	bgTween:Play()
	
	self:fadeOutContent()
	
	-- Use :Once() to avoid accumulating connections
	bgTween.Completed:Once(function()
		self.screenGui.Enabled = false
	end)
end

function EpilogueUI:fadeInContent()
	self.isTransitioning = true
	
	-- Fade in title
	self.titleLabel.TextTransparency = 1
	local titleTween = TweenService:Create(
		self.titleLabel,
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	)
	titleTween:Play()
	
	-- Fade in story text
	self.storyText.TextTransparency = 1
	local textTween = TweenService:Create(
		self.storyText,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.2),
		{ TextTransparency = 0 }
	)
	textTween:Play()
	
	-- Fade in progress
	self.progressLabel.TextTransparency = 1
	local progressTween = TweenService:Create(
		self.progressLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.3),
		{ TextTransparency = 0 }
	)
	progressTween:Play()
	
	-- Fade in continue button
	self.continueButton.BackgroundTransparency = 1
	self.continueButton.TextTransparency = 1
	local btnBgTween = TweenService:Create(
		self.continueButton,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.4),
		{ BackgroundTransparency = 0.2 }
	)
	local btnTextTween = TweenService:Create(
		self.continueButton,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.4),
		{ TextTransparency = 0 }
	)
	btnBgTween:Play()
	btnTextTween:Play()
	
	-- Use :Once() to avoid accumulating connections, reset isTransitioning when fade completes
	textTween.Completed:Once(function()
		self.isTransitioning = false
	end)
end

function EpilogueUI:fadeOutContent()
	self.isTransitioning = true
	
	local fadeTime = 0.3
	
	local titleTween = TweenService:Create(
		self.titleLabel,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	titleTween:Play()
	
	local textTween = TweenService:Create(
		self.storyText,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	textTween:Play()
	
	local progressTween = TweenService:Create(
		self.progressLabel,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	progressTween:Play()
	
	local btnTween = TweenService:Create(
		self.continueButton,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1, TextTransparency = 1 }
	)
	btnTween:Play()
	
	-- Use :Once() to avoid accumulating connections, reset isTransitioning when fade completes
	btnTween.Completed:Once(function()
		self.isTransitioning = false
	end)
end

-- Register input actions with InputActionRegistry
InputActionRegistry.register("EpilogueContinue", "EpilogueUI", {Enum.KeyCode.Space, Enum.KeyCode.Return}, InputActionRegistry.Priority.FULLSCREEN_STATE)
InputActionRegistry.register("EpilogueMute", "EpilogueUI", {Enum.KeyCode.M}, InputActionRegistry.Priority.FULLSCREEN_STATE)

-- Cleanup function
function EpilogueUI:cleanup()
	-- Unregister input actions
	InputActionRegistry.unregister("EpilogueContinue")
	InputActionRegistry.unregister("EpilogueMute")
	
	-- Clean up all connections via maid
	self.maid:Cleanup()
	
	-- Cancel timers
	if self.autoAdvanceTimer then
		task.cancel(self.autoAdvanceTimer)
		self.autoAdvanceTimer = nil
	end
	
	-- Cancel any ongoing tweens
	if self.pulseTweens then
		for _, tween in pairs(self.pulseTweens) do
			if tween then
				tween:Cancel()
			end
		end
		table.clear(self.pulseTweens)
	end
	
	if self.pulseThread then
		task.cancel(self.pulseThread)
		self.pulseThread = nil
	end
	
	-- Remove from ModalManager if still active
	if self.isActive then
		ModalManager.remove("EpilogueUI")
	end
	
	-- Destroy ScreenGui to prevent UI pollution
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return EpilogueUI
