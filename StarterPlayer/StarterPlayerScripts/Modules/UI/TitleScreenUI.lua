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
	-- Singleton pattern: prevent duplicate instances
	-- If an instance already exists globally, return it instead of creating a new one
	if _G.__AwavePuzzTitleScreenSingleton then
		warn("[TitleScreenUI] Singleton already exists, returning existing instance (prevents duplication)")
		return _G.__AwavePuzzTitleScreenSingleton
	end
	
	local self = setmetatable({}, TitleScreenUI)
	
	self.isActive = false
	self.screenGui = nil
	self.frame = nil
	self.hasInteracted = false
	self.pulseTweens = {} -- Store pulse tweens for cleanup
	self.pulseThread = nil -- Store pulse thread for cleanup
	self.remotes = nil -- Will be set via bindRemotes()
	self.loadingComplete = false -- Track loading completion
	self.currentLoadingProgress = 0 -- Current loading progress (0-100)
	self._connections = {} -- Track all event connections for cleanup
	
	self:createUI()
	
	-- Store as singleton
	_G.__AwavePuzzTitleScreenSingleton = self
	print("[TitleScreenUI] Singleton instance created and registered")
	
	return self
end

-- Bind remotes from RemoteRegistry (called by ClientMain)
function TitleScreenUI:bindRemotes(remotes)
	if not remotes then
		warn("[TitleScreenUI] bindRemotes: No remotes provided")
		return
	end
	
	self.remotes = remotes
	
	print("[TitleScreenUI] Remotes bound - setting up input handlers")
	
	-- If title screen is already showing (from early boot), reconnect input with proper remote support
	if self.isActive and not self.inputConnection then
		local UserInputService = game:GetService("UserInputService")
		self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if self.hasInteracted then return end
			
			-- Any key continues
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:onContinue()
			end
		end)
		print("[TitleScreenUI] Input handler connected after remotes bound")
	elseif self.isActive and self.inputConnection then
		-- Clean up old connection before creating new one to prevent leak
		self.inputConnection:Disconnect()
		self.inputConnection = nil
		
		local UserInputService = game:GetService("UserInputService")
		self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if self.hasInteracted then return end
			
			-- Any key continues
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:onContinue()
			end
		end)
		print("[TitleScreenUI] Input handler reconnected after remotes bound")
	end
	
	-- ✅ PRIMARY: Listen for GameStateUpdate (state-driven UI)
	if self.remotes.GameStateUpdate then
		local conn = self.remotes.GameStateUpdate.OnClientEvent:Connect(function(stateData)
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
		table.insert(self._connections, conn)
	end
	
	-- ✅ COMPATIBILITY: Listen for server commands (legacy support)
	-- NOTE: These are kept for backward compatibility but should not create duplicates
	-- The state-driven system (GameStateUpdate) is the primary mechanism
	if self.remotes.ShowTitleScreen then
		local conn = self.remotes.ShowTitleScreen.OnClientEvent:Connect(function()
			-- ✅ GUARD: Prevent duplicate showing if already active from state system
			if self.isActive then
				print("[TitleScreenUI] Received ShowTitleScreen event but already active, ignoring (prevents duplication)")
				return
			end
			print("[TitleScreenUI] Received ShowTitleScreen event (legacy)")
			self:show()
		end)
		table.insert(self._connections, conn)
	end
	
	if self.remotes.HideTitleScreen then
		local conn = self.remotes.HideTitleScreen.OnClientEvent:Connect(function()
			print("[TitleScreenUI] Received HideTitleScreen event (legacy)")
			self:hide()
		end)
		table.insert(self._connections, conn)
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
	self.screenGui.DisplayOrder = 200 -- HIGHEST priority - must be first visible UI
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
	
	-- Loading bar container (bottom center, above prompt)
	local loadingContainer = Instance.new("Frame")
	loadingContainer.Name = "LoadingContainer"
	loadingContainer.Size = UDim2.new(0.5, 0, 0.06, 0)
	loadingContainer.Position = UDim2.new(0.5, 0, 0.78, 0)
	loadingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingContainer.BackgroundTransparency = 1
	loadingContainer.Visible = true
	loadingContainer.Parent = self.frame
	
	-- Loading bar background
	local loadingBarBg = Instance.new("Frame")
	loadingBarBg.Name = "LoadingBarBackground"
	loadingBarBg.Size = UDim2.new(1, 0, 0.4, 0)
	loadingBarBg.Position = UDim2.new(0.5, 0, 0.5, 0)
	loadingBarBg.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	loadingBarBg.BorderSizePixel = 0
	loadingBarBg.Parent = loadingContainer
	
	-- Loading bar fill
	local loadingBarFill = Instance.new("Frame")
	loadingBarFill.Name = "LoadingBarFill"
	loadingBarFill.Size = UDim2.new(0, 0, 1, 0)
	loadingBarFill.Position = UDim2.new(0, 0, 0, 0)
	loadingBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255) -- Aether blue
	loadingBarFill.BorderSizePixel = 0
	loadingBarFill.Parent = loadingBarBg
	
	-- Loading percentage text
	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.Size = UDim2.new(1, 0, 0.5, 0)
	loadingText.Position = UDim2.new(0.5, 0, 0, 0)
	loadingText.AnchorPoint = Vector2.new(0.5, 0)
	loadingText.BackgroundTransparency = 1
	loadingText.Font = Enum.Font.Gotham
	loadingText.Text = "Loading... 0%"
	loadingText.TextColor3 = Color3.fromRGB(180, 180, 200)
	loadingText.TextScaled = false
	loadingText.TextSize = 18
	loadingText.TextTransparency = 1
	loadingText.Parent = loadingContainer
	
	-- Prompt (bottom center) - initially hidden
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
	promptLabel.TextTransparency = 1 -- Start hidden
	promptLabel.Visible = false -- Hide initially
	promptLabel.Parent = self.frame
	
	self.promptLabel = promptLabel
	self.loadingContainer = loadingContainer
	self.loadingBarFill = loadingBarFill
	self.loadingText = loadingText
	
	-- Clickable button overlay for mobile/touch support
	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickToContinue"
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.Position = UDim2.new(0, 0, 0, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = self.frame
	
	-- Handle click to continue
	local clickConn = clickButton.MouseButton1Click:Connect(function()
		self:onContinue()
	end)
	table.insert(self._connections, clickConn)
	
	-- Store reference for animations
	self.titleLabel = titleLabel
	self.subtitleLabel = subtitleLabel
end

function TitleScreenUI:show()
	if self.isActive then 
		print("[TitleScreenUI] show() called but already active, ignoring duplicate")
		return 
	end
	
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
	
	-- Don't start prompt pulse animation here - it will start after loading completes
	
	-- Listen for any key press (only if UserInputService is available)
	-- Note: This might be called early before remotes are bound, so we skip input setup
	-- Input will be bound later via bindRemotes() or after user interaction is possible
	local UserInputService = game:GetService("UserInputService")
	if UserInputService then
		self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if self.hasInteracted then return end
			
			-- Any key continues (only works if remotes are bound AND loading is complete)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if not self.loadingComplete then
					print("[TitleScreenUI] Key pressed but loading not complete yet")
					return
				end
				
				if self.remotes and self.remotes.TitleScreenContinue then
					self:onContinue()
				else
					print("[TitleScreenUI] Key pressed but remotes not yet bound, waiting...")
				end
			end
		end)
	end
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
	
	-- Don't allow continue if loading is not complete
	if not self.loadingComplete then
		print("[TitleScreenUI] Cannot continue - loading not complete yet")
		return
	end
	
	self.hasInteracted = true
	
	print("[TitleScreenUI] Player clicked continue, notifying server")
	
	-- Notify server that player wants to continue
	if self.remotes and self.remotes.TitleScreenContinue then
		self.remotes.TitleScreenContinue:FireServer()
	else
		warn("[TitleScreenUI] Cannot continue - remotes not yet bound!")
		-- Reset hasInteracted so user can try again
		self.hasInteracted = false
		return
	end
	
	-- Hide immediately
	self:hide()
end

-- Update loading progress (0-100)
function TitleScreenUI:updateLoadingProgress(progress, phaseName)
	if not self.loadingBarFill or not self.loadingText then
		return
	end
	
	self.currentLoadingProgress = math.clamp(progress, 0, 100)
	
	-- Update progress bar fill with smooth tween
	local targetSize = UDim2.new(self.currentLoadingProgress / 100, 0, 1, 0)
	local fillTween = TweenService:Create(
		self.loadingBarFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = targetSize }
	)
	fillTween:Play()
	
	-- Update loading text
	local displayText = string.format("Loading... %d%%", self.currentLoadingProgress)
	if phaseName then
		displayText = string.format("Loading %s... %d%%", phaseName, self.currentLoadingProgress)
	end
	self.loadingText.Text = displayText
	
	-- Check if loading is complete
	if self.currentLoadingProgress >= 100 then
		self:onLoadingComplete()
	end
end

-- Called when loading is complete
function TitleScreenUI:onLoadingComplete()
	if self.loadingComplete then
		return
	end
	
	self.loadingComplete = true
	print("[TitleScreenUI] Loading complete - showing continue prompt")
	
	-- Hide loading bar
	if self.loadingContainer then
		local hideTween = TweenService:Create(
			self.loadingContainer,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 1.2, 0) }
		)
		hideTween:Play()
		
		-- One-shot connection: disconnect after firing to avoid keeping closures around
		local hideConnection
		hideConnection = hideTween.Completed:Connect(function()
			self.loadingContainer.Visible = false
			if hideConnection then
				hideConnection:Disconnect()
				hideConnection = nil
			end
		end)
	end
	
	-- Show and fade in the prompt
	if self.promptLabel then
		self.promptLabel.Visible = true
		local promptTween = TweenService:Create(
			self.promptLabel,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ TextTransparency = 0 }
		)
		promptTween:Play()
		
		-- One-shot connection: disconnect after firing to avoid keeping closures around
		local promptConnection
		promptConnection = promptTween.Completed:Connect(function()
			self:startPromptPulse()
			if promptConnection then
				promptConnection:Disconnect()
				promptConnection = nil
			end
		end)
	end
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
	
	-- Fade in loading bar
	if self.loadingContainer then
		self.loadingContainer.Position = UDim2.new(0.5, 0, 0.78, 0)
		local loadingTween = TweenService:Create(
			self.loadingText,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.5),
			{ TextTransparency = 0 }
		)
		loadingTween:Play()
	end
	
	-- Don't fade in prompt here - it will be shown after loading completes
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

-- Cleanup all connections and resources
function TitleScreenUI:cleanup()
	print("[TitleScreenUI] Cleaning up all connections and resources")
	
	-- Disconnect input connection
	if self.inputConnection then
		self.inputConnection:Disconnect()
		self.inputConnection = nil
	end
	
	-- Disconnect all tracked RemoteEvent connections
	for _, conn in ipairs(self._connections) do
		if conn then
			conn:Disconnect()
		end
	end
	self._connections = {}
	
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
	
	-- Destroy ScreenGui
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
	
	self.isActive = false
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
