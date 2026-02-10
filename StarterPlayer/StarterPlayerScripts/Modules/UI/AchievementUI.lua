-- AchievementUI.client.lua
-- Displays achievement notifications as they are unlocked

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(SharedFolder:WaitForChild("StoryConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local AchievementUI = {}
AchievementUI.__index = AchievementUI

local _connections = {}

function AchievementUI.new()
	local self = setmetatable({}, AchievementUI)
	
	self.screenGui = nil
	self.notificationQueue = {}
	self.isShowingNotification = false
	
	self:createUI()
	self:setupRemoteEvents()
	
	return self
end

function AchievementUI:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"AchievementUnlocked"
	})
	
	if self.remoteEvents.AchievementUnlocked then
		table.insert(_connections, self.remoteEvents.AchievementUnlocked.OnClientEvent:Connect(function(achievementId)
			print("[AchievementUI] Achievement unlocked:", achievementId)
			self:showAchievement(achievementId)
		end))
	end
	
	print("[AchievementUI] Initialized and ready")
end

function AchievementUI:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("AchievementUI")
	if existing then
		UIDebugConfig.warnDuplicate("AchievementUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("AchievementUI", "Creating ScreenGui", "AchievementUI.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "AchievementUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 50
	self.screenGui.Parent = PlayerGui
	
	-- Container for notification (top-right)
	self.notificationContainer = Instance.new("Frame")
	self.notificationContainer.Name = "NotificationContainer"
	self.notificationContainer.Size = UDim2.new(0.35, 0, 0.15, 0)
	self.notificationContainer.Position = UDim2.new(1.1, 0, 0.1, 0) -- Start off-screen
	self.notificationContainer.AnchorPoint = Vector2.new(1, 0)
	self.notificationContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	self.notificationContainer.BackgroundTransparency = 0.1
	self.notificationContainer.BorderSizePixel = 2
	self.notificationContainer.BorderColor3 = Color3.fromRGB(100, 200, 255)
	self.notificationContainer.Parent = self.screenGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.notificationContainer
	
	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1, 20, 1, 20)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxasset://textures/ui/VignetteOverlay.png"
	glow.ImageColor3 = Color3.fromRGB(100, 200, 255)
	glow.ImageTransparency = 0.5
	glow.ZIndex = 0
	glow.Parent = self.notificationContainer
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(0.9, 0, 0.3, 0)
	header.Position = UDim2.new(0.5, 0, 0.1, 0)
	header.AnchorPoint = Vector2.new(0.5, 0)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.Text = "ACHIEVEMENT UNLOCKED"
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	header.TextSize = 18
	header.TextScaled = true
	header.Parent = self.notificationContainer
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.2, 0, 0.4, 0)
	icon.Position = UDim2.new(0.1, 0, 0.45, 0)
	icon.AnchorPoint = Vector2.new(0, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "🏆"
	icon.TextSize = 32
	icon.Parent = self.notificationContainer
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.65, 0, 0.25, 0)
	title.Position = UDim2.new(0.33, 0, 0.45, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Achievement Name"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = self.notificationContainer
	
	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(0.65, 0, 0.2, 0)
	description.Position = UDim2.new(0.33, 0, 0.72, 0)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.Text = "Achievement description"
	description.TextColor3 = Color3.fromRGB(200, 200, 200)
	description.TextSize = 14
	description.TextScaled = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.Parent = self.notificationContainer
	
	-- Store references
	self.header = header
	self.icon = icon
	self.title = title
	self.description = description
end

function AchievementUI:showAchievement(achievementId)
	-- Find achievement data
	local achievement = nil
	for _, ach in ipairs(StoryConfig.Achievements) do
		if ach.Id == achievementId then
			achievement = ach
			break
		end
	end
	
	if not achievement then
		warn("[AchievementUI] Achievement not found:", achievementId)
		return
	end
	
	-- Queue the notification
	table.insert(self.notificationQueue, achievement)
	
	-- Start showing if not already showing
	if not self.isShowingNotification then
		self:processQueue()
	end
end

function AchievementUI:processQueue()
	-- Prevent multiple concurrent processors; only one queue loop should run at a time
	if self.isProcessingQueue then
		return
	end
	
	self.isProcessingQueue = true
	
	-- Run the queue processing in a separate thread so callers don't block on waits
	task.spawn(function()
		while true do
			if #self.notificationQueue == 0 then
				-- Nothing left to show; stop processing
				self.isShowingNotification = false
				self.isProcessingQueue = false
				break
			end
			
			self.isShowingNotification = true
			local achievement = table.remove(self.notificationQueue, 1)
			
			-- Update content
			self.icon.Text = achievement.Icon or "🏆"
			self.title.Text = achievement.Name
			self.description.Text = achievement.Description
			
			-- Update border color based on rarity
			local rarityColors = {
				Common = Color3.fromRGB(150, 150, 150),
				Uncommon = Color3.fromRGB(100, 200, 100),
				Rare = Color3.fromRGB(100, 150, 255),
				Epic = Color3.fromRGB(150, 100, 255),
				Legendary = Color3.fromRGB(255, 200, 50)
			}
			self.notificationContainer.BorderColor3 = rarityColors[achievement.Rarity] or Color3.fromRGB(100, 200, 255)
			
			-- Slide in
			local slideInTween = TweenService:Create(
				self.notificationContainer,
				TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0.98, 0, 0.1, 0) }
			)
			slideInTween:Play()
			
			-- Pulse effect (runs independently of the main queue timing)
			task.spawn(function()
				task.wait(0.5)
				for i = 1, 2 do
					TweenService:Create(
						self.notificationContainer,
						TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{ Size = UDim2.new(0.37, 0, 0.16, 0) }
					):Play()
					task.wait(0.3)
					TweenService:Create(
						self.notificationContainer,
						TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{ Size = UDim2.new(0.35, 0, 0.15, 0) }
					):Play()
					task.wait(0.3)
				end
			end)
			
			-- Hold for 4 seconds (4.5 includes slide-in time)
			task.wait(4.5)
			
			-- Slide out
			local slideOutTween = TweenService:Create(
				self.notificationContainer,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(1.1, 0, 0.1, 0) }
			)
			slideOutTween:Play()
			slideOutTween.Completed:Wait()
			
			-- Small delay before showing the next notification
			task.wait(0.5)
		end
	end)
end

-- Cleanup method
function AchievementUI.cleanup()
	for _, connection in ipairs(_connections) do
		connection:Disconnect()
	end
	_connections = {}
end

-- Initialize
local achievementUI = AchievementUI.new()

return achievementUI
