-- FunFactUI.lua
-- Client-side fun fact display
-- Shows facts during downtime with fade-in/fade-out effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local FunFactUI = {}
FunFactUI.__index = FunFactUI

local _connections = {}

-- Display settings
local FADE_IN_TIME = 0.5
local DISPLAY_TIME = 5
local FADE_OUT_TIME = 0.5

function FunFactUI.new()
	local self = setmetatable({}, FunFactUI)
	
	self.isDisplaying = false
	self.currentTween = nil
	self.queuedFact = nil
	
	self.screenGui = nil
	self.factFrame = nil
	self.factLabel = nil
	
	self:createUI()
	self:setupRemoteEvents()
	
	return self
end

function FunFactUI:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"ShowFunFact",
		"RequestFunFact"
	})
	
	-- Listen for facts from server
	if self.remoteEvents.ShowFunFact then
		table.insert(_connections, self.remoteEvents.ShowFunFact.OnClientEvent:Connect(function(factData)
			self:displayFact(factData)
		end))
	end
	
	print("[FunFactUI] Initialized")
end

function FunFactUI:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("FunFactUI")
	if existing then
		UIDebugConfig.warnDuplicate("FunFactUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("FunFactUI", "Creating ScreenGui", "FunFactUI.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "FunFactUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 50 -- Mid-level priority
	self.screenGui.Enabled = true
	self.screenGui.Parent = PlayerGui
	
	-- Container frame (centered at bottom third of screen)
	self.factFrame = Instance.new("Frame")
	self.factFrame.Name = "FactFrame"
	self.factFrame.Size = UDim2.new(0.8, 0, 0.15, 0)
	self.factFrame.Position = UDim2.new(0.5, 0, 0.75, 0)
	self.factFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.factFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.factFrame.BackgroundTransparency = 0.3
	self.factFrame.BorderSizePixel = 0
	self.factFrame.Visible = false
	self.factFrame.Parent = self.screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.factFrame
	
	-- Text label
	self.factLabel = Instance.new("TextLabel")
	self.factLabel.Name = "FactLabel"
	self.factLabel.Size = UDim2.new(0.95, 0, 0.8, 0)
	self.factLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.factLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	self.factLabel.BackgroundTransparency = 1
	self.factLabel.Font = Enum.Font.GothamMedium
	self.factLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	self.factLabel.TextScaled = true
	self.factLabel.TextWrapped = true
	self.factLabel.TextSize = 24
	self.factLabel.Text = ""
	self.factLabel.TextXAlignment = Enum.TextXAlignment.Center
	self.factLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.factLabel.Parent = self.factFrame
	
	-- Text size constraint for readability
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 28
	textSizeConstraint.MinTextSize = 16
	textSizeConstraint.Parent = self.factLabel
end

function FunFactUI:displayFact(factData)
	-- If already displaying, queue the next fact
	if self.isDisplaying then
		self.queuedFact = factData
		return
	end
	
	self.isDisplaying = true
	
	-- Set text
	self.factLabel.Text = factData.text
	
	-- Set color based on category
	local categoryColors = {
		Lore = Color3.fromRGB(150, 180, 220),
		Mechanics = Color3.fromRGB(180, 220, 180),
		Statistics = Color3.fromRGB(220, 200, 150),
		DarkHumor = Color3.fromRGB(200, 150, 150),
		Psychology = Color3.fromRGB(220, 180, 220)
	}
	
	self.factLabel.TextColor3 = categoryColors[factData.category] or Color3.fromRGB(200, 200, 200)
	
	-- Show frame
	self.factFrame.Visible = true
	self.factFrame.BackgroundTransparency = 1
	self.factLabel.TextTransparency = 1
	
	-- Fade in
	local fadeInTween = TweenService:Create(
		self.factFrame,
		TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.3}
	)
	
	local textFadeInTween = TweenService:Create(
		self.factLabel,
		TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	
	fadeInTween:Play()
	textFadeInTween:Play()
	
	-- Wait for display time
	task.wait(FADE_IN_TIME + DISPLAY_TIME)
	
	-- Fade out
	local fadeOutTween = TweenService:Create(
		self.factFrame,
		TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)
	
	local textFadeOutTween = TweenService:Create(
		self.factLabel,
		TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)
	
	fadeOutTween:Play()
	textFadeOutTween:Play()
	
	table.insert(_connections, fadeOutTween.Completed:Connect(function()
		self.factFrame.Visible = false
		self.isDisplaying = false
		
		-- Display queued fact if any
		if self.queuedFact then
			local queued = self.queuedFact
			self.queuedFact = nil
			self:displayFact(queued)
		end
	end))
end

-- Request a fact from the server
function FunFactUI:requestFact()
	if self.remoteEvents.RequestFunFact then
		self.remoteEvents.RequestFunFact:FireServer()
	end
end

-- Hide any currently displaying fact immediately
function FunFactUI:hideImmediately()
	if self.currentTween then
		self.currentTween:Cancel()
	end
	
	self.factFrame.Visible = false
	self.isDisplaying = false
	self.queuedFact = nil
end

function FunFactUI:cleanup()
	for _, conn in ipairs(_connections) do
		if conn then
			conn:Disconnect()
		end
	end
	_connections = {}
	
	if self.currentTween then
		self.currentTween:Cancel()
		self.currentTween = nil
	end
	
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return FunFactUI
