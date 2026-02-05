-- TitleScreenUI.client.lua
-- Displays the game title screen before the epilogue
-- Shows game title and prompt to continue

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(SharedFolder:WaitForChild("StoryConfig"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local TitleScreenUI = {}
TitleScreenUI.__index = TitleScreenUI

function TitleScreenUI.new()
	local self = setmetatable({}, TitleScreenUI)
	
	self.isActive = false
	self.screenGui = nil
	self.frame = nil
	self.hasInteracted = false
	self.pulseTweens = {} -- Store pulse tweens for cleanup
	self.pulseThread = nil -- Store pulse thread for cleanup
	self.remotes = nil -- Will be set via bindRemotes()
	
	self:createUI()
	
	return self
end

-- Bind remotes from RemoteRegistry (called by ClientMain)
function TitleScreenUI:bindRemotes(remotes)
	if not remotes then
		warn("[TitleScreenUI] bindRemotes: No remotes provided")
		return
	end
	
	self.remotes = remotes
	
	-- ✅ PRIMARY: Listen for GameStateUpdate (state-driven UI)
	if self.remotes.GameStateUpdate then
		self.remotes.GameStateUpdate.OnClientEvent:Connect(function(stateData)
			-- ✅ NEW: Track current state for defensive guards
			if stateData and stateData.state then
				self._currentState = stateData.state
			end
			
			if stateData and stateData.state == "TitleScreen" then
				print("[TitleScreenUI] Received GameStateUpdate with state=TitleScreen")
				self:show()
			elseif stateData and stateData.state ~= "TitleScreen" then
				-- Hide if state is not TitleScreen (allows state-driven hiding)
				if self.isActive then
					print("[TitleScreenUI] Received GameStateUpdate with state=" .. tostring(stateData.state) .. ", hiding")
					self:hide()
				end
			end
		end)
	end
	
	-- ✅ COMPATIBILITY: Listen for server commands (legacy support)
	if self.remotes.ShowTitleScreen then
		self.remotes.ShowTitleScreen.OnClientEvent:Connect(function()
			print("[TitleScreenUI] Received ShowTitleScreen event (legacy)")
			self:show()
		end)
	end
	
	if self.remotes.HideTitleScreen then
		self.remotes.HideTitleScreen.OnClientEvent:Connect(function()
			print("[TitleScreenUI] Received HideTitleScreen event (legacy)")
			self:hide()
		end)
	end
	
	print("[TitleScreenUI] Remotes bound and ready (state-driven + legacy)")
end

function TitleScreenUI:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("TitleScreenUI")
	if existing then
		UIDebugConfig.warnDuplicate("TitleScreenUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("TitleScreenUI", "Creating ScreenGui", "TitleScreenUI.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "TitleScreenUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 100 -- High priority to be on top
	self.screenGui.Enabled = false
	self.screenGui.Parent = PlayerGui
	
	-- Main background frame
	self.frame = Instance.new("Frame")
	self.frame.Name = "TitleFrame"
	self.frame.Size = UDim2.new(1, 0, 1, 0)
	self.frame.Position = UDim2.new(0, 0, 0, 0)
	self.frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15) -- Very dark blue-black
	self.frame.BorderSizePixel = 0
	self.frame.Parent = self.screenGui
	
	-- Vignette effect for atmosphere
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.Position = UDim2.new(0, 0, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxasset://textures/ui/VignetteOverlay.png"
	vignette.ImageTransparency = 0.3
	vignette.Parent = self.frame
	
	-- Title container (centered)
	local titleContainer = Instance.new("Frame")
	titleContainer.Name = "TitleContainer"
	titleContainer.Size = UDim2.new(0.8, 0, 0.4, 0)
	titleContainer.Position = UDim2.new(0.5, 0, 0.35, 0)
	titleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	titleContainer.BackgroundTransparency = 1
	titleContainer.Parent = self.frame
	
	-- Main title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = StoryConfig.GameTitle
	titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Aether blue
	titleLabel.TextScaled = true
	titleLabel.TextSize = 80
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Parent = titleContainer
	
	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
	subtitleLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
	subtitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Text = StoryConfig.GameSubtitle
	subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	subtitleLabel.TextScaled = true
	subtitleLabel.TextSize = 36
	subtitleLabel.TextTransparency = 0.3
	subtitleLabel.Parent = titleContainer
	
	-- Prompt (bottom center)
	local promptLabel = Instance.new("TextLabel")
	promptLabel.Name = "PromptLabel"
	promptLabel.Size = UDim2.new(0.6, 0, 0.08, 0)
	promptLabel.Position = UDim2.new(0.5, 0, 0.85, 0)
	promptLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Font = Enum.Font.Gotham
	promptLabel.Text = StoryConfig.UIText.TitlePrompt
	promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptLabel.TextScaled = true
	promptLabel.TextSize = 24
	promptLabel.TextTransparency = 0
	promptLabel.Parent = self.frame
	
	self.promptLabel = promptLabel
	
	-- Clickable button overlay for mobile/touch support
	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickToContinue"
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.Position = UDim2.new(0, 0, 0, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = self.frame
	
	-- Handle click to continue
	clickButton.MouseButton1Click:Connect(function()
		self:onContinue()
	end)
	
	-- Store reference for animations
	self.titleLabel = titleLabel
	self.subtitleLabel = subtitleLabel
end

function TitleScreenUI:show()
	if self.isActive then return end
	
	-- ✅ NEW: Defensive guard - prevent title screen from showing during active match states
	-- This prevents the "state snap-back" bug where TitleScreen appears mid-match
	if self._currentState then
		local blockStates = {
			Countdown = true,
			WaveActive = true,
			Victory = true,
			Defeat = true,
			Epilogue = true
		}
		
		if blockStates[self._currentState] then
			warn(string.format("[TitleScreenUI] Blocked show() while in %s state (prevents snap-back)", self._currentState))
			return
		end
	end
	
	print("[TitleScreenUI] Showing title screen")
	self.isActive = true
	self.hasInteracted = false
	self.screenGui.Enabled = true
	
	-- Fade in animation
	self:fadeIn()
	
	-- Start prompt pulse animation
	self:startPromptPulse()
	
	-- Listen for any key press
	self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if self.hasInteracted then return end
		
		-- Any key continues
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self:onContinue()
		end
	end)
end

function TitleScreenUI:hide()
	if not self.isActive then return end
	
	self.isActive = false
	
	-- Disconnect input listener
	if self.inputConnection then
		self.inputConnection:Disconnect()
		self.inputConnection = nil
	end
	
	-- Cancel pulse thread
	if self.pulseThread then
		task.cancel(self.pulseThread)
		self.pulseThread = nil
	end
	
	-- Cancel pulse tweens
	for _, tween in ipairs(self.pulseTweens) do
		if tween then
			tween:Cancel()
		end
	end
	self.pulseTweens = {}
	
	-- ✅ NEW: Re-enable CoreGui when title screen is hidden
	local StarterGui = game:GetService("StarterGui")
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)
	
	-- Fade out animation
	self:fadeOut()
end

function TitleScreenUI:onContinue()
	if self.hasInteracted then return end
	self.hasInteracted = true
	
	print("[TitleScreenUI] Player clicked continue, notifying server")
	
	-- Notify server that player wants to continue
	if self.remotes and self.remotes.TitleScreenContinue then
		self.remotes.TitleScreenContinue:FireServer()
	end
	
	-- Hide immediately
	self:hide()
end

function TitleScreenUI:fadeIn()
	-- Fade in the background
	local bgTween = TweenService:Create(
		self.frame,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{ BackgroundTransparency = 0 }
	)
	bgTween:Play()
	
	-- Fade in title
	self.titleLabel.TextTransparency = 1
	local titleTween = TweenService:Create(
		self.titleLabel,
		TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	)
	titleTween:Play()
	
	-- Fade in subtitle
	self.subtitleLabel.TextTransparency = 1
	local subtitleTween = TweenService:Create(
		self.subtitleLabel,
		TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.3),
		{ TextTransparency = 0.3 }
	)
	subtitleTween:Play()
	
	-- Fade in prompt
	self.promptLabel.TextTransparency = 1
	local promptTween = TweenService:Create(
		self.promptLabel,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.5),
		{ TextTransparency = 0 }
	)
	promptTween:Play()
end

function TitleScreenUI:fadeOut()
	local fadeTime = 0.5
	
	-- Fade out all elements
	local bgTween = TweenService:Create(
		self.frame,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	
	local titleTween = TweenService:Create(
		self.titleLabel,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	
	local subtitleTween = TweenService:Create(
		self.subtitleLabel,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	
	local promptTween = TweenService:Create(
		self.promptLabel,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	
	bgTween:Play()
	titleTween:Play()
	subtitleTween:Play()
	promptTween:Play()
	
	-- Disable after fade completes
	bgTween.Completed:Connect(function()
		self.screenGui.Enabled = false
	end)
end

function TitleScreenUI:startPromptPulse()
	-- Continuous pulse animation for the prompt using repeating tweens
	self.pulseThread = task.spawn(function()
		while self.isActive and self.promptLabel do
			-- Clear old tweens to prevent memory accumulation
			self.pulseTweens = {}
			
			-- Fade to semi-transparent
			local tween1 = TweenService:Create(
				self.promptLabel,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ TextTransparency = 0.5 }
			)
			table.insert(self.pulseTweens, tween1)
			tween1:Play()
			
			-- Wait for completion or cancellation
			local success = pcall(function()
				tween1.Completed:Wait()
			end)
			
			if not self.isActive or not success then 
				self.pulseTweens = {}
				break 
			end
			
			-- Fade back to opaque
			local tween2 = TweenService:Create(
				self.promptLabel,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ TextTransparency = 0 }
			)
			table.insert(self.pulseTweens, tween2)
			tween2:Play()
			
			-- Wait for completion or cancellation
			success = pcall(function()
				tween2.Completed:Wait()
			end)
			
			if not self.isActive or not success then 
				self.pulseTweens = {}
				break 
			end
		end
		
		-- Final cleanup
		self.pulseTweens = {}
	end)
end

-- Module interface
TitleScreenUI.initialize = function()
	-- Initialization handled by ClientMain via bindRemotes()
end

-- Create a default singleton instance for backward compatibility.
-- This allows older code that expects `require(TitleScreenUI)` to return
-- an instance to keep working, while still exposing `.new` for newer code.
local defaultTitleScreen = TitleScreenUI.new()

-- Expose the constructor on the singleton so callers that do
-- `local TitleScreenUI = require(...); local ui = TitleScreenUI.new()`
-- continue to work even though the module returns an instance.
defaultTitleScreen.new = TitleScreenUI.new

return defaultTitleScreen
