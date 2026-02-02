-- NotificationUI.lua
-- Simple notification system for displaying server messages to players
-- Handles notifications from various server services (CureSynthesisService, etc.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))
local UIDebugConfig = require(SharedFolder:WaitForChild("UIDebugConfig"))

local NotificationUI = {}
NotificationUI.__index = NotificationUI

-- Color schemes for different message types
local MESSAGE_COLORS = {
	info = Color3.fromRGB(100, 180, 255),     -- Blue
	success = Color3.fromRGB(100, 255, 150),  -- Green
	warning = Color3.fromRGB(255, 200, 100),  -- Orange
	error = Color3.fromRGB(255, 100, 100)     -- Red
}

function NotificationUI.new()
	local self = setmetatable({}, NotificationUI)
	
	self.screenGui = nil
	self.notificationQueue = {}
	self.isShowingNotification = false
	self.isProcessingQueue = false
	
	self:createUI()
	self:setupRemoteEvents()
	
	return self
end

function NotificationUI:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"ShowNotification"
	})
	
	if self.remoteEvents.ShowNotification then
		self.remoteEvents.ShowNotification.OnClientEvent:Connect(function(notificationData)
			if notificationData and notificationData.message then
				self:showNotification(
					notificationData.message, 
					notificationData.messageType or "info",
					notificationData.duration or 3
				)
			end
		end)
	end
	
	print("[NotificationUI] Initialized and ready")
end

function NotificationUI:createUI()
	-- Prevent duplicate UI instances
	local existing = PlayerGui:FindFirstChild("NotificationUI")
	if existing then
		UIDebugConfig.warnDuplicate("NotificationUI")
		existing:Destroy()
	end
	
	UIDebugConfig.logUICreation("NotificationUI", "Creating ScreenGui", "NotificationUI.lua")
	
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "NotificationUI"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.DisplayOrder = 100  -- High priority to show above most UI
	self.screenGui.Parent = PlayerGui
	
	-- Container for notification (top-center)
	self.notificationContainer = Instance.new("Frame")
	self.notificationContainer.Name = "NotificationContainer"
	self.notificationContainer.Size = UDim2.new(0.4, 0, 0.08, 0)
	self.notificationContainer.Position = UDim2.new(0.5, 0, -0.15, 0) -- Start above screen
	self.notificationContainer.AnchorPoint = Vector2.new(0.5, 0)
	self.notificationContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	self.notificationContainer.BackgroundTransparency = 0.15
	self.notificationContainer.BorderSizePixel = 2
	self.notificationContainer.BorderColor3 = Color3.fromRGB(100, 180, 255)
	self.notificationContainer.Parent = self.screenGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.notificationContainer
	
	-- Icon (left side)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.15, 0, 0.8, 0)
	icon.Position = UDim2.new(0.05, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "ℹ️"
	icon.TextSize = 28
	icon.Parent = self.notificationContainer
	
	-- Message text
	local messageText = Instance.new("TextLabel")
	messageText.Name = "MessageText"
	messageText.Size = UDim2.new(0.75, 0, 0.8, 0)
	messageText.Position = UDim2.new(0.22, 0, 0.1, 0)
	messageText.BackgroundTransparency = 1
	messageText.Font = Enum.Font.Gotham
	messageText.Text = "Notification message"
	messageText.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageText.TextSize = 18
	messageText.TextScaled = true
	messageText.TextXAlignment = Enum.TextXAlignment.Left
	messageText.TextWrapped = true
	messageText.Parent = self.notificationContainer
	
	-- Store references
	self.icon = icon
	self.messageText = messageText
end

function NotificationUI:showNotification(message, messageType, duration)
	messageType = messageType or "info"
	duration = duration or 3
	
	-- Queue the notification
	table.insert(self.notificationQueue, {
		message = message,
		messageType = messageType,
		duration = duration
	})
	
	-- Start showing if not already showing
	if not self.isShowingNotification then
		self:processQueue()
	end
end

function NotificationUI:processQueue()
	-- Prevent multiple concurrent processors
	if self.isProcessingQueue then
		return
	end
	
	self.isProcessingQueue = true
	
	task.spawn(function()
		while true do
			if #self.notificationQueue == 0 then
				self.isShowingNotification = false
				self.isProcessingQueue = false
				break
			end
			
			self.isShowingNotification = true
			local notification = table.remove(self.notificationQueue, 1)
			
			-- Update content
			self.messageText.Text = notification.message
			
			-- Update icon based on type
			local iconMap = {
				info = "ℹ️",
				success = "✅",
				warning = "⚠️",
				error = "❌"
			}
			self.icon.Text = iconMap[notification.messageType] or iconMap.info
			
			-- Update border color based on type
			local borderColor = MESSAGE_COLORS[notification.messageType] or MESSAGE_COLORS.info
			self.notificationContainer.BorderColor3 = borderColor
			
			-- Slide in from top
			local slideInTween = TweenService:Create(
				self.notificationContainer,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0.05, 0)}
			)
			slideInTween:Play()
			slideInTween.Completed:Wait()
			
			-- Wait for duration
			task.wait(notification.duration)
			
			-- Slide out to top
			local slideOutTween = TweenService:Create(
				self.notificationContainer,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, -0.15, 0)}
			)
			slideOutTween:Play()
			slideOutTween.Completed:Wait()
			
			-- Small delay before next notification
			task.wait(0.2)
		end
	end)
end

return NotificationUI

-- Initialize the UI immediately
local notificationUI = NotificationUI.new()
