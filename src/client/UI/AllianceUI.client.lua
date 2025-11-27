
-- AllianceUI.client.lua
-- Client script for alliance management UI
-- Place in StarterGui as a LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AllianceUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (player list)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 300)
mainFrame.Position = UDim2.new(1, -260, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
mainFrame.Visible = false -- Hidden by default, toggle with key
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Player Alliances"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Player List (ScrollingFrame)
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, -20, 1, -55)
playerList.Position = UDim2.new(0, 10, 0, 45)
playerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerList.BackgroundTransparency = 0.5
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 6
playerList.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

-- Request Frame (shows when receiving alliance request)
local requestFrame = Instance.new("Frame")
requestFrame.Name = "RequestFrame"
requestFrame.Size = UDim2.new(0, 300, 0, 120)
requestFrame.Position = UDim2.new(0.5, -150, 0.5, -60)
requestFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
requestFrame.BackgroundTransparency = 0.1
requestFrame.BorderSizePixel = 3
requestFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
requestFrame.Visible = false
requestFrame.ZIndex = 20
requestFrame.Parent = screenGui

local requestCorner = Instance.new("UICorner")
requestCorner.CornerRadius = UDim.new(0, 10)
requestCorner.Parent = requestFrame

local requestLabel = Instance.new("TextLabel")
requestLabel.Name = "RequestLabel"
requestLabel.Size = UDim2.new(1, -20, 0, 50)
requestLabel.Position = UDim2.new(0, 10, 0, 10)
requestLabel.BackgroundTransparency = 1
requestLabel.Text = "PlayerName wants to ally with you!"
requestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
requestLabel.TextSize = 16
requestLabel.Font = Enum.Font.Gotham
requestLabel.TextWrapped = true
requestLabel.Parent = requestFrame

local acceptButton = Instance.new("TextButton")
acceptButton.Name = "AcceptButton"
acceptButton.Size = UDim2.new(0, 120, 0, 40)
acceptButton.Position = UDim2.new(0, 15, 0, 70)
acceptButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
acceptButton.Text = "Accept"
acceptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptButton.TextSize = 16
acceptButton.Font = Enum.Font.GothamBold
acceptButton.Parent = requestFrame

local acceptCorner = Instance.new("UICorner")
acceptCorner.CornerRadius = UDim.new(0, 8)
acceptCorner.Parent = acceptButton

local declineButton = Instance.new("TextButton")
declineButton.Name = "DeclineButton"
declineButton.Size = UDim2.new(0, 120, 0, 40)
declineButton.Position = UDim2.new(1, -135, 0, 70)
declineButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
declineButton.Text = "Decline"
declineButton.TextColor3 = Color3.fromRGB(255, 255, 255)
declineButton.TextSize = 16
declineButton.Font = Enum.Font.GothamBold
declineButton.Parent = requestFrame

local declineCorner = Instance.new("UICorner")
declineCorner.CornerRadius = UDim.new(0, 8)
declineCorner.Parent = declineButton

-- Notification Frame (for messages)
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 300, 0, 60)
notificationFrame.Position = UDim2.new(0.5, -150, 0, 150)
notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
notificationFrame.BackgroundTransparency = 0.2
notificationFrame.BorderSizePixel = 2
notificationFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notificationFrame

local notificationLabel = Instance.new("TextLabel")
notificationLabel.Size = UDim2.new(1, -20, 1, -20)
notificationLabel.Position = UDim2.new(0, 10, 0, 10)
notificationLabel.BackgroundTransparency = 1
notificationLabel.Text = "Notification"
notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationLabel.TextSize = 14
notificationLabel.Font = Enum.Font.Gotham
notificationLabel.TextWrapped = true
notificationLabel.Parent = notificationFrame

-- State
local myAlliances = {}
local pendingRequest = nil
local allyHighlights = {} -- Track highlight objects for allies

-- Functions
local function showNotification(message, duration)
	notificationLabel.Text = message
	notificationFrame.Visible = true

	task.delay(duration or 3, function()
		notificationFrame.Visible = false
	end)
end

local function addAllyHighlight(allyPlayer)
	-- Remove any existing highlight for this player
	if allyHighlights[allyPlayer.UserId] then
		allyHighlights[allyPlayer.UserId]:Destroy()
		allyHighlights[allyPlayer.UserId] = nil
	end

	-- Wait for character if it doesn't exist yet
	local character = allyPlayer.Character
	if not character then
		allyPlayer.CharacterAdded:Wait()
		character = allyPlayer.Character
	end

	if character then
		-- Create highlight effect for ally
		local highlight = Instance.new("Highlight")
		highlight.Name = "AllyHighlight"
		highlight.FillColor = Color3.fromRGB(100, 200, 100) -- Green for allies
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
		highlight.OutlineTransparency = 0
		highlight.Parent = character

		allyHighlights[allyPlayer.UserId] = highlight

		-- Re-add highlight if character respawns
		allyPlayer.CharacterAdded:Connect(function(newChar)
			if myAlliances[allyPlayer.UserId] then
				task.wait(0.1) -- Small delay for character to load
				addAllyHighlight(allyPlayer)
			end
		end)
	end
end

local function removeAllyHighlight(allyPlayer)
	if allyHighlights[allyPlayer.UserId] then
		allyHighlights[allyPlayer.UserId]:Destroy()
		allyHighlights[allyPlayer.UserId] = nil
	end
end

local function updateAllyVisuals()
	-- Update highlights for all players
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

local function updatePlayerList()
	-- Clear existing items
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get all players
	local allPlayers = Players:GetPlayers()

	for _, otherPlayer in ipairs(allPlayers) do
		if otherPlayer ~= player then
			local isAllied = myAlliances[otherPlayer.UserId] == true

			local itemFrame = Instance.new("Frame")
			itemFrame.Name = otherPlayer.Name
			itemFrame.Size = UDim2.new(1, -10, 0, 50)
			itemFrame.BackgroundColor3 = isAllied and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(50, 50, 50)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = playerList

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 5)
			itemCorner.Parent = itemFrame

			-- Player name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = otherPlayer.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 14
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
			statusLabel.TextSize = 12
			statusLabel.Font = Enum.Font.Gotham
			statusLabel.Parent = itemFrame

			-- Action button
			local actionButton = Instance.new("TextButton")
			actionButton.Size = UDim2.new(0, 60, 0, 35)
			actionButton.Position = UDim2.new(1, -70, 0.5, -17.5)
			actionButton.BackgroundColor3 = isAllied and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(100, 150, 255)
			actionButton.Text = isAllied and "Betray" or "Ally"
			actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionButton.TextSize = 12
			actionButton.Font = Enum.Font.GothamBold
			actionButton.Parent = itemFrame

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 5)
			btnCorner.Parent = actionButton

			-- Button click handler
			actionButton.MouseButton1Click:Connect(function()
				local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
				if not remoteEvents then return end

				if isAllied then
					-- Break alliance
					local breakEvent = remoteEvents:FindFirstChild("BreakAlliance")
					if breakEvent then
						breakEvent:FireServer(otherPlayer)
					end
				else
					-- Request alliance
					local requestEvent = remoteEvents:FindFirstChild("RequestAlliance")
					if requestEvent then
						requestEvent:FireServer(otherPlayer)
						showNotification("Alliance request sent to " .. otherPlayer.Name)
					end
				end
			end)
		end
	end

	-- Update canvas size
	playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Toggle UI with key (default: Tab key)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			updatePlayerList()
		end
	end
end)

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Alliance Update
local allianceUpdateEvent = remoteEvents:WaitForChild("AllianceUpdate")
allianceUpdateEvent.OnClientEvent:Connect(function(data)
	if data.type == "request" then
		-- Show alliance request
		pendingRequest = data.from
		requestLabel.Text = data.fromName .. " wants to ally with you!"
		requestFrame.Visible = true

	elseif data.type == "formed" then
		-- Alliance was formed
		myAlliances[data.with.UserId] = true
		showNotification("Alliance formed with " .. data.withName, 3)
		requestFrame.Visible = false
		updatePlayerList()
		updateAllyVisuals()

	elseif data.type == "broken" then
		-- Alliance was broken
		myAlliances[data.with.UserId] = nil
		if data.betrayer then
			showNotification("You betrayed " .. data.withName, 3)
		else
			showNotification(data.withName .. " betrayed you!", 3)
		end
		updatePlayerList()
		updateAllyVisuals()

	elseif data.type == "rejected" then
		-- Request was rejected
		showNotification(data.byName .. " rejected your alliance request", 3)

	elseif data.type == "cooldown" then
		-- On betrayal cooldown
		showNotification(data.message, 3)
	end
end)

-- Accept button handler
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

-- Decline button handler
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

-- Listen for player changes
Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(0.5)
	if mainFrame.Visible then
		updatePlayerList()
	end
	-- Add highlight if they're an ally
	if myAlliances[newPlayer.UserId] then
		addAllyHighlight(newPlayer)
	end
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
	myAlliances[removedPlayer.UserId] = nil
	removeAllyHighlight(removedPlayer)
	if mainFrame.Visible then
		updatePlayerList()
	end
end)

-- Initial update
updatePlayerList()

-- Show hint
showNotification("Press LeftShift to open Alliance Menu", 5)

print("AllianceUI initialized")
