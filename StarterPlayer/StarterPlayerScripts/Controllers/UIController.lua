--[[
	UIController.lua
	Manages UI screens and navigation
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UIController = {}
UIController.__index = UIController

function UIController.new()
	local self = setmetatable({}, UIController)
	self.initialized = false
	self.currentScreen = nil
	self.stats = {}
	self.currencies = {}
	return self
end

function UIController:initialize()
	print("🖥️ UIController initializing...")
	
	-- Create simple UI (in a real implementation, this would be in StarterGui)
	self:createBasicUI()
	
	self.initialized = true
	print("✅ UIController initialized")
	return true
end

-- Create basic UI elements
function UIController:createBasicUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Stats display (top left)
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0, 200, 0, 150)
	statsFrame.Position = UDim2.new(0, 10, 0, 10)
	statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	statsFrame.BackgroundTransparency = 0.3
	statsFrame.Parent = screenGui
	
	local statsTitle = Instance.new("TextLabel")
	statsTitle.Name = "Title"
	statsTitle.Size = UDim2.new(1, 0, 0, 30)
	statsTitle.Position = UDim2.new(0, 0, 0, 0)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Text = "✨ Stats"
	statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	statsTitle.TextSize = 18
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.Parent = statsFrame
	
	local statsText = Instance.new("TextLabel")
	statsText.Name = "StatsText"
	statsText.Size = UDim2.new(1, -10, 1, -35)
	statsText.Position = UDim2.new(0, 5, 0, 30)
	statsText.BackgroundTransparency = 1
	statsText.Text = "Loading..."
	statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
	statsText.TextSize = 14
	statsText.Font = Enum.Font.Gotham
	statsText.TextXAlignment = Enum.TextXAlignment.Left
	statsText.TextYAlignment = Enum.TextYAlignment.Top
	statsText.Parent = statsFrame
	
	-- Currency display (top right)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0, 150, 0, 80)
	currencyFrame.Position = UDim2.new(1, -160, 0, 10)
	currencyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	currencyFrame.BackgroundTransparency = 0.3
	currencyFrame.Parent = screenGui
	
	local currencyText = Instance.new("TextLabel")
	currencyText.Name = "CurrencyText"
	currencyText.Size = UDim2.new(1, -10, 1, -10)
	currencyText.Position = UDim2.new(0, 5, 0, 5)
	currencyText.BackgroundTransparency = 1
	currencyText.Text = "💰 Coins: 0\n💎 Gems: 0"
	currencyText.TextColor3 = Color3.fromRGB(255, 255, 255)
	currencyText.TextSize = 16
	currencyText.Font = Enum.Font.GothamBold
	currencyText.TextXAlignment = Enum.TextXAlignment.Left
	currencyText.TextYAlignment = Enum.TextYAlignment.Top
	currencyText.Parent = currencyFrame
	
	self.screenGui = screenGui
	self.statsText = statsText
	self.currencyText = currencyText
end

-- Update stats display
function UIController:updateStats(stats)
	self.stats = stats
	
	if self.statsText then
		local text = ""
		for statName, value in pairs(stats) do
			text = text .. string.format("%s: %d\n", statName, value)
		end
		self.statsText.Text = text
	end
end

-- Update currencies display
function UIController:updateCurrencies(currencies)
	self.currencies = currencies
	
	if self.currencyText then
		self.currencyText.Text = string.format(
			"💰 Coins: %d\n💎 Gems: %d",
			currencies.Coins or 0,
			currencies.Gems or 0
		)
	end
end

-- Navigate to screen
function UIController:navigateTo(screenName)
	print(string.format("Navigate to: %s", screenName))
	self.currentScreen = screenName
	-- In a full implementation, this would show/hide UI panels
end

return UIController
