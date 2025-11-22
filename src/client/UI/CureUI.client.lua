-- CureUI.client.lua
-- Client script for displaying cure progress and puzzle interface
-- Place in StarterGui as a LocalScript
-- TODO When 5 like components (for example 5 chemical A's) are collected before they are able to bec used in synthesising the cure a puzzle must be solved by the user at a cure station
-- TODO when all 5 cure component puzzles have been solved a final puzzle must be solved in order to synthesise the cure

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get config
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CureUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.Parent = playerGui

-- Progress Frame (always visible)
local progressFrame = Instance.new("Frame")
progressFrame.Name = "ProgressFrame"
progressFrame.Size = UDim2.new(0, 300, 0, 100)
progressFrame.Position = UDim2.new(1, -310, 0, 10)
progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
progressFrame.BackgroundTransparency = 0.3
progressFrame.BorderSizePixel = 2
progressFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
progressFrame.Active = true
progressFrame.Parent = screenGui

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 10)
progressCorner.Parent = progressFrame

-- Title
local progressTitle = Instance.new("TextLabel")
progressTitle.Name = "Title"
progressTitle.Size = UDim2.new(1, -20, 0, 25)
progressTitle.Position = UDim2.new(0, 10, 0, 5)
progressTitle.BackgroundTransparency = 1
progressTitle.Text = "Cure Progress"
progressTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
progressTitle.TextSize = 18
progressTitle.Font = Enum.Font.GothamBold
progressTitle.TextXAlignment = Enum.TextXAlignment.Left
progressTitle.Parent = progressFrame

-- Progress Bar Background
local progressBarBg = Instance.new("Frame")
progressBarBg.Name = "ProgressBarBg"
progressBarBg.Size = UDim2.new(1, -20, 0, 30)
progressBarBg.Position = UDim2.new(0, 10, 0, 35)
progressBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressBarBg.BorderSizePixel = 0
progressBarBg.Parent = progressFrame

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, 5)
progressBarCorner.Parent = progressBarBg

-- Progress Bar Fill
local progressBarFill = Instance.new("Frame")
progressBarFill.Name = "ProgressBarFill"
progressBarFill.Size = UDim2.new(0, 0, 1, 0)
progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
progressBarFill.BorderSizePixel = 0
progressBarFill.Parent = progressBarBg

local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 5)
progressFillCorner.Parent = progressBarFill

-- Progress Text
local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "0%"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextSize = 16
progressText.Font = Enum.Font.GothamBold
progressText.ZIndex = 2
progressText.Parent = progressBarBg

-- Components Info
local componentsLabel = Instance.new("TextLabel")
componentsLabel.Name = "ComponentsLabel"
componentsLabel.Size = UDim2.new(1, -20, 0, 25)
componentsLabel.Position = UDim2.new(0, 10, 0, 70)
componentsLabel.BackgroundTransparency = 1
componentsLabel.Text = "0 / 0 Components"
componentsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
componentsLabel.TextSize = 14
componentsLabel.Font = Enum.Font.Gotham
componentsLabel.TextXAlignment = Enum.TextXAlignment.Left
componentsLabel.Parent = progressFrame

-- Detailed Components Frame (shows on click or interaction)
local detailFrame = Instance.new("Frame")
detailFrame.Name = "DetailFrame"
detailFrame.Size = UDim2.new(0, 350, 0, 250)
detailFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
detailFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
detailFrame.BackgroundTransparency = 0.1
detailFrame.BorderSizePixel = 3
detailFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
detailFrame.Visible = false
detailFrame.ZIndex = 10
detailFrame.Active = true
detailFrame.Parent = screenGui

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 10)
detailCorner.Parent = detailFrame

-- Detail Title
local detailTitle = Instance.new("TextLabel")
detailTitle.Name = "Title"
detailTitle.Size = UDim2.new(1, -20, 0, 30)
detailTitle.Position = UDim2.new(0, 10, 0, 10)
detailTitle.BackgroundTransparency = 1
detailTitle.Text = "Cure Components"
detailTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
detailTitle.TextSize = 20
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Parent = detailFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = detailFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	detailFrame.Visible = false
end)

-- Components List (ScrollingFrame)
local componentsList = Instance.new("ScrollingFrame")
componentsList.Name = "ComponentsList"
componentsList.Size = UDim2.new(1, -20, 1, -60)
componentsList.Position = UDim2.new(0, 10, 0, 50)
componentsList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
componentsList.BackgroundTransparency = 0.5
componentsList.BorderSizePixel = 0
componentsList.ScrollBarThickness = 6
componentsList.CanvasSize = UDim2.new(0, 0, 0, 0)
componentsList.Parent = detailFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = componentsList

-- State
local cureProgress = 0
local componentsCollected = {}

local function getTotalNeeded()
	if type(GameConfig) ~= "table" then
		return 0
	end

	local names = GameConfig.CURE_COMPONENT_NAMES
	local required = GameConfig.CURE_COMPONENTS_REQUIRED

	if type(names) ~= "table" or type(required) ~= "number" then
		return 0
	end

	return #names * required
end

-- Functions
local function updateProgress(progress, components)
	if type(progress) == "number" then
		cureProgress = math.clamp(progress, 0, 100)
	end

	if type(components) == "table" then
		componentsCollected = components
	end

	-- Update progress bar
	local targetSize = UDim2.new(cureProgress / 100, 0, 1, 0)
	pcall(function()
		progressBarFill:TweenSize(
			targetSize,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.5,
			true
		)
	end)

	-- Update text
	progressText.Text = string.format("%d%%", math.floor(cureProgress + 0.5))

	-- Calculate total components
	local totalCollected = 0
	for _, count in pairs(componentsCollected) do
		if type(count) == "number" then
			totalCollected = totalCollected + count
		end
	end

	local totalNeeded = getTotalNeeded()
	if totalNeeded > 0 then
		componentsLabel.Text = totalCollected .. " / " .. totalNeeded .. " Components"
	else
		componentsLabel.Text = totalCollected .. " Components"
	end

	-- Change color based on progress
	if cureProgress >= 100 then
		progressBarFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	elseif cureProgress >= 75 then
		progressBarFill.BackgroundColor3 = Color3.fromRGB(150, 255, 150) -- Light green
	else
		progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green
	end
end

local function updateComponentsList()
	-- Clear existing items (keep the layout)
	for _, child in ipairs(componentsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local names = GameConfig.CURE_COMPONENT_NAMES
	local required = GameConfig.CURE_COMPONENTS_REQUIRED

	if type(names) ~= "table" or type(required) ~= "number" then
		componentsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
		return
	end

	-- Create items for each component
	for _, componentName in ipairs(names) do
		local count = componentsCollected[componentName] or 0

		local itemFrame = Instance.new("Frame")
		itemFrame.Name = tostring(componentName)
		itemFrame.Size = UDim2.new(1, -10, 0, 35)
		itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = componentsList

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 5)
		itemCorner.Parent = itemFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = tostring(componentName)
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(0.4, -10, 1, 0)
		countLabel.Position = UDim2.new(0.6, 0, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = tostring(count) .. " / " .. tostring(required)
		countLabel.TextColor3 = count >= required and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 100)
		countLabel.TextSize = 14
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		countLabel.Parent = itemFrame

		-- Checkmark if complete
		if count >= required then
			local checkmark = Instance.new("TextLabel")
			checkmark.Size = UDim2.new(0, 20, 0, 20)
			checkmark.Position = UDim2.new(1, -30, 0.5, -10)
			checkmark.BackgroundTransparency = 1
			checkmark.Text = "✓"
			checkmark.TextColor3 = Color3.fromRGB(100, 255, 100)
			checkmark.TextSize = 18
			checkmark.Font = Enum.Font.GothamBold
			checkmark.Parent = itemFrame
		end
	end

	componentsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Show detail frame on click/touch
progressFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		detailFrame.Visible = not detailFrame.Visible
		if detailFrame.Visible then
			updateComponentsList()
		end
	end
end)

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Cure Update
local cureUpdateEvent = remoteEvents:WaitForChild("CureUpdate")
cureUpdateEvent.OnClientEvent:Connect(function(data)
	local dataType = typeof(data)

	if dataType == "number" then
		updateProgress(data)
	elseif dataType == "table" then
		if data.type == "progress" then
			updateProgress(data.progress, data.components)

			if data.contributor and data.componentAdded then
				print(tostring(data.contributor) .. " added " .. tostring(data.componentAdded))
			end

		elseif data.type == "complete" then
			updateProgress(100, data.components)

		elseif data.type == "openUI" then
			detailFrame.Visible = true
			if type(data.components) == "table" then
				componentsCollected = data.components
			end
			if type(data.progress) == "number" then
				cureProgress = math.clamp(data.progress, 0, 100)
			end
			updateComponentsList()
		end
	end
end)

-- Initial state
updateProgress(0, {})

print("CureUI initialized")
