--[[
	NotificationController.lua
	Displays toast notifications from server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local player = Players.LocalPlayer

local NotificationController = {}
NotificationController.__index = NotificationController

function NotificationController.new()
	local self = setmetatable({}, NotificationController)
	self.initialized = false
	self.toastQueue = {}
	return self
end

function NotificationController:initialize()
	print("🔔 NotificationController initializing...")
	
	-- Create toast UI
	self:createToastUI()
	
	-- Listen for toast events from server
	local pushToastEvent = Remotes.getEvent("PushToast")
	pushToastEvent.OnClientEvent:Connect(function(toastData)
		self:showToast(toastData)
	end)
	
	self.initialized = true
	print("✅ NotificationController initialized")
	return true
end

-- Create toast UI container
function NotificationController:createToastUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ToastUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100  -- Top layer
	screenGui.Parent = playerGui
	
	-- Container for toasts (bottom center)
	local container = Instance.new("Frame")
	container.Name = "ToastContainer"
	container.Size = UDim2.new(0, 400, 0, 200)
	container.Position = UDim2.new(0.5, -200, 1, -220)
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	
	self.toastContainer = container
end

-- Show a toast notification
function NotificationController:showToast(toastData)
	if not self.toastContainer then
		return
	end
	
	local title = toastData.title or "Notification"
	local message = toastData.message or ""
	local duration = toastData.duration or 4
	local toastType = toastData.type or "Info"
	
	-- Create toast frame
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 80)
	toast.Position = UDim2.new(0, 0, 0, 0)
	toast.BackgroundColor3 = self:getToastColor(toastType)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 2
	toast.BorderColor3 = Color3.fromRGB(255, 255, 255)
	toast.Parent = self.toastContainer
	
	-- Add corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	
	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 25)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = toast
	
	-- Message label
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -20, 0, 45)
	messageLabel.Position = UDim2.new(0, 10, 0, 30)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.TextSize = 14
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.Parent = toast
	
	print(string.format("[TOAST] %s: %s", title, message))
	
	-- Animate in
	toast.Position = UDim2.new(0, 0, 0, 100)
	toast.BackgroundTransparency = 1
	toast:TweenPosition(
		UDim2.new(0, 0, 0, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.3,
		true
	)
	
	-- Fade in
	task.spawn(function()
		for i = 1, 0, -0.1 do
			toast.BackgroundTransparency = i * 0.1
			task.wait(0.03)
		end
	end)
	
	-- Remove after duration
	task.delay(duration, function()
		-- Fade out
		for i = 0, 1, 0.1 do
			toast.BackgroundTransparency = 0.1 + (i * 0.9)
			task.wait(0.03)
		end
		toast:Destroy()
	end)
end

-- Get color for toast type
function NotificationController:getToastColor(toastType)
	if toastType == "Success" then
		return Color3.fromRGB(46, 204, 113)  -- Green
	elseif toastType == "Error" then
		return Color3.fromRGB(231, 76, 60)   -- Red
	elseif toastType == "Warning" then
		return Color3.fromRGB(241, 196, 15)  -- Yellow
	elseif toastType == "Affirmation" then
		return Color3.fromRGB(155, 89, 182)  -- Purple
	else  -- Info
		return Color3.fromRGB(52, 152, 219)  -- Blue
	end
end

return NotificationController
