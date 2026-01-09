-- @ScriptType: LocalScript
-- AllianceUI.client.lua
-- Client script for alliance management UI
-- Place in StarterGui as a LocalScript
-- Updated with dynamic UI scaling for mobile devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load UI scaling utilities
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local UIScaleConfig = require(SharedFolder:WaitForChild("UIScaleConfig"))

-- Initialize scale manager
UIScaleManager.initialize()

-- Helper functions
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "menuElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- Minimum touch target from config
local MIN_TOUCH_TARGET = UIScaleConfig.MinSizes.touchTarget.width

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AllianceUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (player list) - positioned right side, centered vertically
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UIScaleManager.scaleSize(250, 300, "menuElements", "menuDialog")
mainFrame.Position = UIScaleManager.getPositionWithSafeArea("topRight", 10, 120)
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
mainFrame.Visible = false -- Hidden by default, toggle with key
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
mainCorner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Player Alliances"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = getScaledTextSize(20)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Close button with minimum touch target
local closeButtonSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
local mainCloseButton = Instance.new("TextButton")
mainCloseButton.Name = "CloseButton"
mainCloseButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
mainCloseButton.Position = UDim2.new(1, -closeButtonSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
mainCloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
mainCloseButton.Text = "X"
mainCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mainCloseButton.TextSize = getScaledTextSize(18)
mainCloseButton.Font = Enum.Font.GothamBold
mainCloseButton.Parent = mainFrame

local mainCloseCorner = Instance.new("UICorner")
mainCloseCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))
mainCloseCorner.Parent = mainCloseButton

mainCloseButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Player List (ScrollingFrame)
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(55, "padding"))
playerList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(45, "padding"))
playerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerList.BackgroundTransparency = 0.5
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = getScaledValue(6, "padding")
playerList.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, getScaledValue(5, "padding"))
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

-- Request Frame (shows when receiving alliance request) - centered
local requestFrame = Instance.new("Frame")
requestFrame.Name = "RequestFrame"
requestFrame.Size = UIScaleManager.scaleSize(300, 120, "menuElements")
requestFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
requestFrame.AnchorPoint = Vector2.new(0.5, 0.5)
requestFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
requestFrame.BackgroundTransparency = 0.1
requestFrame.BorderSizePixel = 3
requestFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
requestFrame.Visible = false
requestFrame.ZIndex = 20
requestFrame.Parent = screenGui

local requestCorner = Instance.new("UICorner")
requestCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
requestCorner.Parent = requestFrame

local requestLabel = Instance.new("TextLabel")
requestLabel.Name = "RequestLabel"
requestLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(50, "padding"))
requestLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
requestLabel.BackgroundTransparency = 1
requestLabel.Text = "PlayerName wants to ally with you!"
requestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
requestLabel.TextSize = getScaledTextSize(16)
requestLabel.Font = Enum.Font.Gotham
requestLabel.TextWrapped = true
requestLabel.Parent = requestFrame

-- Buttons with minimum touch target sizes
local buttonHeight = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
local buttonWidth = getScaledValue(120, "menuElements")

local acceptButton = Instance.new("TextButton")
acceptButton.Name = "AcceptButton"
acceptButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
acceptButton.Position = UDim2.new(0, getScaledValue(15, "padding"), 0, getScaledValue(70, "padding"))
acceptButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
acceptButton.Text = "Accept"
acceptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptButton.TextSize = getScaledTextSize(16)
acceptButton.Font = Enum.Font.GothamBold
acceptButton.Parent = requestFrame

local acceptCorner = Instance.new("UICorner")
acceptCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
acceptCorner.Parent = acceptButton

local declineButton = Instance.new("TextButton")
declineButton.Name = "DeclineButton"
declineButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
declineButton.Position = UDim2.new(1, -buttonWidth - getScaledValue(15, "padding"), 0, getScaledValue(70, "padding"))
declineButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
declineButton.Text = "Decline"
declineButton.TextColor3 = Color3.fromRGB(255, 255, 255)
declineButton.TextSize = getScaledTextSize(16)
declineButton.Font = Enum.Font.GothamBold
declineButton.Parent = requestFrame

local declineCorner = Instance.new("UICorner")
declineCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
declineCorner.Parent = declineButton

-- Notification Frame (for messages)
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UIScaleManager.scaleSize(300, 60, "menuElements")
notificationFrame.Position = UIScaleManager.getPositionWithSafeArea("topCenter", 0, 150)
notificationFrame.AnchorPoint = Vector2.new(0.5, 0)
notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
notificationFrame.BackgroundTransparency = 0.2
notificationFrame.BorderSizePixel = 2
notificationFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
notifCorner.Parent = notificationFrame

local notificationLabel = Instance.new("TextLabel")
notificationLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(20, "padding"))
notificationLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
notificationLabel.BackgroundTransparency = 1
notificationLabel.Text = "Notification"
notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationLabel.TextSize = getScaledTextSize(14)
notificationLabel.Font = Enum.Font.Gotham
notificationLabel.TextWrapped = true
notificationLabel.Parent = notificationFrame

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local myAlliances: {[number]: boolean} = {}
local pendingRequest: Player? = nil

local allyHighlights: {[number]: Highlight} = {}
local allyRespawnConns: {[number]: RBXScriptConnection} = {} -- prevent stacking connections

--------------------------------------------------------------------------------
-- FUNCTIONS (forward declarations)
--------------------------------------------------------------------------------

-- Forward declaration fixes Luau typechecker when referenced above definition.
local updatePlayerList: () -> ()

local function showNotification(message: string, duration: number?)
	notificationLabel.Text = message
	notificationFrame.Visible = true

	task.delay(duration or 3, function()
		notificationFrame.Visible = false
	end)
end

local function removeAllyHighlight(allyPlayer: Player)
	local uid = allyPlayer.UserId
	local h = allyHighlights[uid]
	if h then
		h:Destroy()
		allyHighlights[uid] = nil
	end
end

local function addAllyHighlight(allyPlayer: Player)
	local uid = allyPlayer.UserId

	-- Remove any existing highlight for this player
	removeAllyHighlight(allyPlayer)

	-- Ensure we only have ONE respawn connection per ally
	if allyRespawnConns[uid] then
		allyRespawnConns[uid]:Disconnect()
		allyRespawnConns[uid] = nil
	end

	local function attach()
		local character = allyPlayer.Character
		if not character then return end

		local highlight = Instance.new("Highlight")
		highlight.Name = "AllyHighlight"
		highlight.FillColor = Color3.fromRGB(100, 200, 100)
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
		highlight.OutlineTransparency = 0
		highlight.Parent = character

		allyHighlights[uid] = highlight
	end

	-- Attach now if character exists
	if allyPlayer.Character then
		attach()
	end

	-- Re-add highlight if character respawns (only while allied)
	allyRespawnConns[uid] = allyPlayer.CharacterAdded:Connect(function()
		if myAlliances[uid] then
			task.wait(0.1)
			attach()
		end
	end)
end

local function updateAllyVisuals()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			if myAlliances[otherPlayer.UserId] then
				addAllyHighlight(otherPlayer)
			else
				removeAllyHighlight(otherPlayer)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- PLAYER LIST (definition after forward declare)
--------------------------------------------------------------------------------

updatePlayerList = function()
	-- Clear existing items (keep UIListLayout)
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local allPlayers = Players:GetPlayers()

	-- Scaled values for player list items
	local itemHeight = getScaledValue(50, "menuElements")
	local itemPadding = getScaledValue(10, "padding")
	local cornerRadius = getScaledValue(5, "padding")
	local nameTextSize = getScaledTextSize(14)
	local statusTextSize = getScaledTextSize(12)
	local buttonTextSize = getScaledTextSize(12)

	-- Action button dimensions with minimum touch target enforcement
	local buttonW = math.max(getScaledValue(60, "menuElements"), MIN_TOUCH_TARGET)
	local buttonH = math.max(getScaledValue(35, "menuElements"), MIN_TOUCH_TARGET)

	for _, otherPlayer in ipairs(allPlayers) do
		if otherPlayer ~= player then
			local isAllied = myAlliances[otherPlayer.UserId] == true

			local itemFrame = Instance.new("Frame")
			itemFrame.Name = otherPlayer.Name
			itemFrame.Size = UDim2.new(1, -itemPadding, 0, itemHeight)
			itemFrame.BackgroundColor3 = isAllied and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(50, 50, 50)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = playerList

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, cornerRadius)
			itemCorner.Parent = itemFrame

			-- Player name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
			nameLabel.Position = UDim2.new(0, itemPadding, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = otherPlayer.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = nameTextSize
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemFrame

			-- Status indicator
			local statusLabel = Instance.new("TextLabel")
			statusLabel.Size = UDim2.new(0.25, 0, 1, 0)
			statusLabel.Position = UDim2.new(0.5, 0, 0, 0)
			statusLabel.BackgroundTransparency = 1
			statusLabel.Text = isAllied and "Allied" or ""
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			statusLabel.TextSize = statusTextSize
			statusLabel.Font = Enum.Font.Gotham
			statusLabel.Parent = itemFrame

			-- Action button
			local actionButton = Instance.new("TextButton")
			actionButton.Size = UDim2.new(0, buttonW, 0, buttonH)
			actionButton.Position = UDim2.new(1, -(buttonW + itemPadding), 0.5, -buttonH / 2)
			actionButton.BackgroundColor3 = isAllied and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(100, 150, 255)
			actionButton.Text = isAllied and "Betray" or "Ally"
			actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionButton.TextSize = buttonTextSize
			actionButton.Font = Enum.Font.GothamBold
			actionButton.Parent = itemFrame

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, cornerRadius)
			btnCorner.Parent = actionButton

			actionButton.MouseButton1Click:Connect(function()
				local remote = ReplicatedStorage:FindFirstChild("RemoteEvents")
				if not remote then return end

				if isAllied then
					local breakEvent = remote:FindFirstChild("BreakAlliance")
					if breakEvent then
						breakEvent:FireServer(otherPlayer)
					end
				else
					local requestEvent = remote:FindFirstChild("RequestAlliance")
					if requestEvent then
						requestEvent:FireServer(otherPlayer)
						showNotification("Alliance request sent to " .. otherPlayer.Name)
					end
				end
			end)
		end
	end

	playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + getScaledValue(10, "padding"))
end

--------------------------------------------------------------------------------
-- UI SCALING
--------------------------------------------------------------------------------

local function updateUIScaling()
	mainFrame.Size = UIScaleManager.scaleSize(250, 300, "menuElements", "menuDialog")
	mainFrame.Position = UIScaleManager.getPositionWithSafeArea("topRight", 10, 120)
	mainFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0.3
	mainCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))

	titleLabel.Size = UDim2.new(1, -getScaledValue(20, "padding"), 0, getScaledValue(30, "padding"))
	titleLabel.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(10, "padding"))
	titleLabel.TextSize = getScaledTextSize(20)

	local newCloseSize = math.max(getScaledValue(30, "menuElements"), MIN_TOUCH_TARGET)
	mainCloseButton.Size = UDim2.new(0, newCloseSize, 0, newCloseSize)
	mainCloseButton.Position = UDim2.new(1, -newCloseSize - getScaledValue(5, "padding"), 0, getScaledValue(5, "padding"))
	mainCloseButton.TextSize = getScaledTextSize(18)
	mainCloseCorner.CornerRadius = UDim.new(0, getScaledValue(5, "padding"))

	playerList.Size = UDim2.new(1, -getScaledValue(20, "padding"), 1, -getScaledValue(55, "padding"))
	playerList.Position = UDim2.new(0, getScaledValue(10, "padding"), 0, getScaledValue(45, "padding"))
	playerList.ScrollBarThickness = getScaledValue(6, "padding")
	listLayout.Padding = UDim.new(0, getScaledValue(5, "padding"))

	requestFrame.Size = UIScaleManager.scaleSize(300, 120, "menuElements")
	requestCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
	requestLabel.TextSize = getScaledTextSize(16)

	local newButtonH = math.max(getScaledValue(40, "menuElements"), MIN_TOUCH_TARGET)
	local newButtonW = getScaledValue(120, "menuElements")
	acceptButton.Size = UDim2.new(0, newButtonW, 0, newButtonH)
	acceptButton.Position = UDim2.new(0, getScaledValue(15, "padding"), 0, getScaledValue(70, "padding"))
	acceptButton.TextSize = getScaledTextSize(16)
	acceptCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))

	declineButton.Size = UDim2.new(0, newButtonW, 0, newButtonH)
	declineButton.Position = UDim2.new(1, -newButtonW - getScaledValue(15, "padding"), 0, getScaledValue(70, "padding"))
	declineButton.TextSize = getScaledTextSize(16)
	declineCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))

	notificationFrame.Size = UIScaleManager.scaleSize(300, 60, "menuElements")
	notificationFrame.Position = UIScaleManager.getPositionWithSafeArea("topCenter", 0, 150)
	notifCorner.CornerRadius = UDim.new(0, getScaledValue(10, "padding"))
	notificationLabel.TextSize = getScaledTextSize(14)

	if mainFrame.Visible then
		updatePlayerList()
	end
end

UIScaleManager.onScaleChanged(updateUIScaling)

--------------------------------------------------------------------------------
-- INPUT (toggle)
--------------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			updatePlayerList()
		end
	end
end)

--------------------------------------------------------------------------------
-- REMOTES
--------------------------------------------------------------------------------

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local allianceUpdateEvent = remoteEvents:WaitForChild("AllianceUpdate")
allianceUpdateEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" or not data.type then return end

	if data.type == "request" then
		pendingRequest = data.from
		requestLabel.Text = tostring(data.fromName) .. " wants to ally with you!"
		requestFrame.Visible = true

	elseif data.type == "formed" then
		if data.with and data.with.UserId then
			myAlliances[data.with.UserId] = true
		end
		showNotification("Alliance formed with " .. tostring(data.withName), 3)
		requestFrame.Visible = false
		updatePlayerList()
		updateAllyVisuals()

	elseif data.type == "broken" then
		if data.with and data.with.UserId then
			myAlliances[data.with.UserId] = nil
		end

		if data.betrayer then
			showNotification("You betrayed " .. tostring(data.withName), 3)
		else
			showNotification(tostring(data.withName) .. " betrayed you!", 3)
		end

		updatePlayerList()
		updateAllyVisuals()

	elseif data.type == "rejected" then
		showNotification(tostring(data.byName) .. " rejected your alliance request", 3)

	elseif data.type == "cooldown" or data.type == "locked" or data.type == "traitor" or data.type == "error" then
		showNotification(tostring(data.message), 3)
	end
end)

local betrayalStartedEvent = remoteEvents:WaitForChild("BetrayalStarted")
betrayalStartedEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" or not data.type then return end

	if data.type == "betrayer" then
		showNotification("Betrayal initiated! Eliminate " .. tostring(data.victim) .. " in " .. tostring(data.duration) .. "s!", 5)
	elseif data.type == "victim" then
		showNotification("You've been betrayed by " .. tostring(data.betrayer) .. "! Survive " .. tostring(data.duration) .. "s!", 5)
	end
end)

local betrayalOutcomeEvent = remoteEvents:WaitForChild("BetrayalOutcome")
betrayalOutcomeEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	showNotification(tostring(data.message or "Betrayal update"), 5)
end)

--------------------------------------------------------------------------------
-- REQUEST BUTTONS
--------------------------------------------------------------------------------

acceptButton.MouseButton1Click:Connect(function()
	if pendingRequest then
		local respondEvent = remoteEvents:FindFirstChild("RespondAlliance")
		if respondEvent then
			respondEvent:FireServer(pendingRequest, true)
		end
		pendingRequest = nil
		requestFrame.Visible = false
	end
end)

declineButton.MouseButton1Click:Connect(function()
	if pendingRequest then
		local respondEvent = remoteEvents:FindFirstChild("RespondAlliance")
		if respondEvent then
			respondEvent:FireServer(pendingRequest, false)
		end
		pendingRequest = nil
		requestFrame.Visible = false
	end
end)

--------------------------------------------------------------------------------
-- PLAYER JOIN/LEAVE
--------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(0.5)
	if mainFrame.Visible then
		updatePlayerList()
	end
	if myAlliances[newPlayer.UserId] then
		addAllyHighlight(newPlayer)
	end
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
	myAlliances[removedPlayer.UserId] = nil
	removeAllyHighlight(removedPlayer)

	local uid = removedPlayer.UserId
	if allyRespawnConns[uid] then
		allyRespawnConns[uid]:Disconnect()
		allyRespawnConns[uid] = nil
	end

	if mainFrame.Visible then
		updatePlayerList()
	end
end)

--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------

updatePlayerList()
showNotification("Press LeftShift to open Alliance Menu", 5)
print("AllianceUI initialized")
