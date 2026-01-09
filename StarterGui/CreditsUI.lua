-- @ScriptType: LocalScript
-- CreditsUI.client.lua
-- Victory credits screen showing survivors and development team

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(SharedFolder:WaitForChild("StoryConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local CreditsUI = {}
CreditsUI.__index = CreditsUI

function CreditsUI.new()
	local self = setmetatable({}, CreditsUI)

	self.isActive = false
	self.screenGui = nil
	self.scrollFrame = nil
	self.scrollThread = nil

	self:createUI()
	self:setupRemoteEvents()

	return self
end

function CreditsUI:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"ShowCredits",
		"HideCredits"
	})

	if self.remoteEvents.ShowCredits then
		self.remoteEvents.ShowCredits.OnClientEvent:Connect(function(survivorData)
			print("[CreditsUI] Received ShowCredits event")
			self:show(survivorData)
		end)
	end

	if self.remoteEvents.HideCredits then
		self.remoteEvents.HideCredits.OnClientEvent:Connect(function()
			print("[CreditsUI] Received HideCredits event")
			self:hide()
		end)
	end

	print("[CreditsUI] Initialized and ready")
end

function CreditsUI:createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "CreditsUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 101 -- Above title screen
	self.screenGui.Enabled = false
	self.screenGui.Parent = PlayerGui

	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BorderSizePixel = 0
	background.Parent = self.screenGui

	-- ScrollingFrame for credits
	self.scrollFrame = Instance.new("ScrollingFrame")
	self.scrollFrame.Name = "CreditsScroll"
	self.scrollFrame.Size = UDim2.new(0.8, 0, 1, 0)
	self.scrollFrame.Position = UDim2.new(0.5, 0, 0, 0)
	self.scrollFrame.AnchorPoint = Vector2.new(0.5, 0)
	self.scrollFrame.BackgroundTransparency = 1
	self.scrollFrame.BorderSizePixel = 0
	self.scrollFrame.ScrollBarThickness = 0
	self.scrollFrame.ScrollingEnabled = false -- We'll auto-scroll
	self.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
	self.scrollFrame.Parent = background

	-- Content container
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0) -- Height will be calculated
	content.BackgroundTransparency = 1
	content.Parent = self.scrollFrame

	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 40)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	self.content = content
	self.layout = layout

	-- Skip button
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0.2, 0, 0.06, 0)
	skipButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	skipButton.AnchorPoint = Vector2.new(1, 1)
	skipButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	skipButton.BackgroundTransparency = 0.3
	skipButton.BorderSizePixel = 0
	skipButton.Font = Enum.Font.Gotham
	skipButton.Text = "Skip Credits"
	skipButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	skipButton.TextSize = 18
	skipButton.Parent = background

	skipButton.MouseButton1Click:Connect(function()
		self:hide()
	end)
end

function CreditsUI:show(survivorData)
	if self.isActive then return end

	print("[CreditsUI] Showing credits")
	self.isActive = true
	self.screenGui.Enabled = true

	-- Clear existing content
	for _, child in ipairs(self.content:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Build credits content
	self:buildCreditsContent(survivorData or {})

	-- Calculate total height
	-- Wait for layout completion by listening for AbsoluteContentSize changes,
	-- with a timeout safeguard to avoid hanging if no change occurs.
	local initialHeight = self.layout.AbsoluteContentSize.Y
	if initialHeight == 0 then
		local layoutComplete = false
		local layoutConnection
		layoutConnection = self.layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			layoutComplete = true
			if layoutConnection then
				layoutConnection:Disconnect()
				layoutConnection = nil
			end
		end)

		local startTime = os.clock()
		local TIMEOUT_SECONDS = 2
		while not layoutComplete and (os.clock() - startTime) < TIMEOUT_SECONDS do
			task.wait()
		end

		if layoutConnection then
			layoutConnection:Disconnect()
			layoutConnection = nil
		end
	end

	local totalHeight = self.layout.AbsoluteContentSize.Y
	self.content.Size = UDim2.new(1, 0, 0, totalHeight)
	self.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 1000) -- Extra space

	-- Start at bottom (credits scroll up from bottom)
	self.scrollFrame.CanvasPosition = Vector2.new(0, totalHeight + 1000)

	-- Fade in
	self:fadeIn()

	-- Start auto-scroll
	self:startAutoScroll(totalHeight)
end

function CreditsUI:buildCreditsContent(survivorData)
	-- Add spacing at top
	self:addSpacer(200)

	-- Title
	self:addTitle(StoryConfig.Credits.Title)
	self:addSubtitle(StoryConfig.Credits.Subtitle)
	self:addSpacer(100)

	-- Build each section
	for _, section in ipairs(StoryConfig.Credits.Sections) do
		self:addSectionHeader(section.Header)

		if section.Type == "players" then
			-- Add actual survivor data
			if #survivorData > 0 then
				for _, survivor in ipairs(survivorData) do
					self:addCreditLine(survivor.name)
					if survivor.stats then
						self:addStatLine(string.format("Kills: %d  |  Components: %d", 
							survivor.stats.kills or 0, 
							survivor.stats.components or 0))
					end
				end
			else
				self:addCreditLine("No survivors recorded")
			end
		else
			-- Add regular credits
			for _, credit in ipairs(section.Credits) do
				self:addCreditLine(credit)
			end
		end

		self:addSpacer(60)
	end

	-- Closing message
	self:addSpacer(100)
	self:addClosingMessage(StoryConfig.Credits.ClosingMessage)

	-- Add spacing at bottom
	self:addSpacer(400)
end

function CreditsUI:addSpacer(height)
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, height)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = #self.content:GetChildren()
	spacer.Parent = self.content
end

function CreditsUI:addTitle(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 80)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(100, 200, 255)
	label.TextSize = 48
	label.TextScaled = false
	label.LayoutOrder = #self.content:GetChildren()
	label.Parent = self.content
	return label
end

function CreditsUI:addSubtitle(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 40)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(180, 180, 200)
	label.TextSize = 24
	label.TextTransparency = 0.3
	label.LayoutOrder = #self.content:GetChildren()
	label.Parent = self.content
	return label
end

function CreditsUI:addSectionHeader(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 50)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(150, 200, 255)
	label.TextSize = 32
	label.LayoutOrder = #self.content:GetChildren()
	label.Parent = self.content
	return label
end

function CreditsUI:addCreditLine(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 30)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextSize = 22
	label.LayoutOrder = #self.content:GetChildren()
	label.Parent = self.content
	return label
end

function CreditsUI:addStatLine(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(150, 150, 150)
	label.TextSize = 18
	label.TextTransparency = 0.3
	label.LayoutOrder = #self.content:GetChildren()
	label.Parent = self.content
	return label
end

function CreditsUI:addClosingMessage(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 80)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(100, 200, 255)
	label.TextSize = 28
	label.TextWrapped = true
	label.LayoutOrder = #self.content:GetChildren()
	label.Parent = self.content
	return label
end

function CreditsUI:startAutoScroll(totalHeight)
	if self.scrollThread then
		task.cancel(self.scrollThread)
	end

	local scrollTime = StoryConfig.Credits.CreditsDisplayTime or 20
	local startPos = totalHeight + 1000
	local endPos = 0

	self.scrollThread = task.spawn(function()
		local elapsed = 0
		while self.isActive and elapsed < scrollTime do
			elapsed += task.wait()
			local progress = math.min(elapsed / scrollTime, 1)
			local currentPos = startPos + (endPos - startPos) * progress
			self.scrollFrame.CanvasPosition = Vector2.new(0, currentPos)
		end

		-- Auto-hide after credits finish
		if self.isActive then
			task.wait(2)
			self:hide()
		end
	end)
end

function CreditsUI:hide()
	if not self.isActive then return end

	print("[CreditsUI] Hiding credits")
	self.isActive = false

	if self.scrollThread then
		task.cancel(self.scrollThread)
		self.scrollThread = nil
	end

	self:fadeOut()
end

function CreditsUI:fadeIn()
	for _, child in ipairs(self.content:GetChildren()) do
		if child:IsA("TextLabel") then
			child.TextTransparency = 1
			TweenService:Create(
				child,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ TextTransparency = child:GetAttribute("OriginalTransparency") or 0 }
			):Play()
		end
	end
end

function CreditsUI:fadeOut()
	local fadeTime = 0.5

	for _, child in ipairs(self.content:GetChildren()) do
		if child:IsA("TextLabel") then
			TweenService:Create(
				child,
				TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ TextTransparency = 1 }
			):Play()
		end
	end

	task.delay(fadeTime, function()
		self.screenGui.Enabled = false
	end)
end

-- Initialize
local credits = CreditsUI.new()

return credits
