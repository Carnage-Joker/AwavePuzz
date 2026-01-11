-- MapVotingUI.client.lua
-- Client script for displaying map voting interface in the lobby
-- Place in StarterGui as a LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Constants
local REMOTE_EVENT_WAIT_TIMEOUT = 10

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MapVotingUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- Hidden by default
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main voting frame
local votingFrame = Instance.new("Frame")
votingFrame.Name = "VotingFrame"
votingFrame.Size = UDim2.new(0, 600, 0, 450)
votingFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
votingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
votingFrame.BackgroundTransparency = 0.05
votingFrame.BorderSizePixel = 0
votingFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = votingFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 3
frameStroke.Color = Color3.fromRGB(255, 165, 0)
frameStroke.Parent = votingFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 50)
titleLabel.Position = UDim2.new(0, 20, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VOTE FOR NEXT MAP"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize = 32
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = votingFrame

-- Timer label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.new(0, 100, 0, 30)
timerLabel.Position = UDim2.new(1, -120, 0, 20)
timerLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
timerLabel.BackgroundTransparency = 0.5
timerLabel.Text = "20s"
timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
timerLabel.TextSize = 20
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = votingFrame

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 8)
timerCorner.Parent = timerLabel

-- Maps container
local mapsContainer = Instance.new("Frame")
mapsContainer.Name = "MapsContainer"
mapsContainer.Size = UDim2.new(1, -40, 0, 320)
mapsContainer.Position = UDim2.new(0, 20, 0, 80)
mapsContainer.BackgroundTransparency = 1
mapsContainer.Parent = votingFrame

local mapsLayout = Instance.new("UIGridLayout")
mapsLayout.CellSize = UDim2.new(0.5, -10, 0.5, -10)
mapsLayout.CellPadding = UDim2.new(0, 20, 0, 20)
mapsLayout.SortOrder = Enum.SortOrder.LayoutOrder
mapsLayout.Parent = mapsContainer

-- Current vote tracking
local currentVote = nil
local mapButtons = {}

-- Function to create a map card
local function createMapCard(mapData, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = mapData.id
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = mapsContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 2
	cardStroke.Color = Color3.fromRGB(80, 80, 100)
	cardStroke.Parent = card

	-- Map name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "MapName"
	nameLabel.Size = UDim2.new(1, -20, 0, 35)
	nameLabel.Position = UDim2.new(0, 10, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = mapData.name or mapData.id
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 22
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -20, 0, 40)
	descLabel.Position = UDim2.new(0, 10, 0, 45)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = mapData.description or ""
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.Parent = card

	-- Vote count
	local voteCount = Instance.new("TextLabel")
	voteCount.Name = "VoteCount"
	voteCount.Size = UDim2.new(0, 60, 0, 35)
	voteCount.Position = UDim2.new(1, -70, 1, -45)
	voteCount.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	voteCount.Text = "0"
	voteCount.TextColor3 = Color3.fromRGB(255, 215, 0)
	voteCount.TextSize = 24
	voteCount.Font = Enum.Font.GothamBold
	voteCount.Parent = card

	local voteCorner = Instance.new("UICorner")
	voteCorner.CornerRadius = UDim.new(0, 8)
	voteCorner.Parent = voteCount

	-- Vote button
	local voteButton = Instance.new("TextButton")
	voteButton.Name = "VoteButton"
	voteButton.Size = UDim2.new(0, 100, 0, 35)
	voteButton.Position = UDim2.new(0, 10, 1, -45)
	voteButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	voteButton.Text = "VOTE"
	voteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	voteButton.TextSize = 16
	voteButton.Font = Enum.Font.GothamBold
	voteButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = voteButton

	-- Hover effect
	voteButton.MouseEnter:Connect(function()
		TweenService:Create(voteButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 180, 70)
		}):Play()
	end)

	voteButton.MouseLeave:Connect(function()
		if currentVote == mapData.id then
			TweenService:Create(voteButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(255, 165, 0)
			}):Play()
		else
			TweenService:Create(voteButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			}):Play()
		end
	end)

	-- Store reference
	mapButtons[mapData.id] = {
		card = card,
		button = voteButton,
		voteCount = voteCount,
		stroke = cardStroke,
		connection = nil  -- Will store the click connection
	}

	return card
end

-- Function to update vote display
local function updateVotes(voteCounts, timeRemaining)
	for mapId, buttonData in pairs(mapButtons) do
		local count = voteCounts[mapId] or 0
		buttonData.voteCount.Text = tostring(count)
	end

	if timeRemaining then
		timerLabel.Text = tostring(math.max(0, math.floor(timeRemaining))) .. "s"

		-- Change color based on time
		if timeRemaining <= 5 then
			timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		elseif timeRemaining <= 10 then
			timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		else
			timerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		end
	end
end

-- Function to highlight selected vote
local function highlightVote(mapId)
	for id, buttonData in pairs(mapButtons) do
		if id == mapId then
			buttonData.stroke.Color = Color3.fromRGB(255, 215, 0)
			buttonData.stroke.Thickness = 3
			buttonData.button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
			buttonData.button.Text = "VOTED"
		else
			buttonData.stroke.Color = Color3.fromRGB(80, 80, 100)
			buttonData.stroke.Thickness = 2
			buttonData.button.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			buttonData.button.Text = "VOTE"
		end
	end
end

-- Function to clear map cards
local function clearMapCards()
	for _, buttonData in pairs(mapButtons) do
		-- Disconnect click handler to prevent memory leaks
		if buttonData.connection then
			buttonData.connection:Disconnect()
		end
		buttonData.card:Destroy()
	end
	mapButtons = {}
	currentVote = nil
end

-- Function to cast a vote
local function castVote(mapId)
	currentVote = mapId
	highlightVote(mapId)

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local castVoteEvent = remoteEvents:FindFirstChild("CastMapVote")
		if castVoteEvent then
			castVoteEvent:FireServer(mapId)
		end
	end
end

-- Remote Event Handlers
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", REMOTE_EVENT_WAIT_TIMEOUT)
if not remoteEvents then
	warn("[MapVotingUI] RemoteEvents folder not found")
	return
end

-- Handle voting start
local mapVoteStartEvent = remoteEvents:WaitForChild("MapVoteStart", REMOTE_EVENT_WAIT_TIMEOUT)
if mapVoteStartEvent then
	mapVoteStartEvent.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end

		-- Clear existing cards
		clearMapCards()

		-- Create cards for each map
		local maps = data.maps or {}
		for i, mapData in ipairs(maps) do
			local card = createMapCard(mapData, i)

			-- Connect vote button and store the connection
			local buttonData = mapButtons[mapData.id]
			if buttonData and buttonData.button then
				buttonData.connection = buttonData.button.MouseButton1Click:Connect(function()
					castVote(mapData.id)
				end)
			end
		end

		-- Set initial timer
		timerLabel.Text = tostring(data.duration or 20) .. "s"

		-- Show the UI
		screenGui.Enabled = true

		-- Animate in
		votingFrame.Position = UDim2.new(0.5, -300, -0.5, 0)
		TweenService:Create(votingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -300, 0.5, -225)
		}):Play()
	end)
end

-- Handle vote updates
local mapVoteUpdateEvent = remoteEvents:WaitForChild("MapVoteUpdate", REMOTE_EVENT_WAIT_TIMEOUT)
if mapVoteUpdateEvent then
	mapVoteUpdateEvent.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end

		updateVotes(data.votes or {}, data.timeRemaining)
	end)
end

-- Handle voting end
local mapVoteEndEvent = remoteEvents:WaitForChild("MapVoteEnd", REMOTE_EVENT_WAIT_TIMEOUT)
if mapVoteEndEvent then
	mapVoteEndEvent.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end

		-- Show selected map
		titleLabel.Text = "SELECTED: " .. (data.mapName or "Unknown")
		titleLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Highlight winning map
		if data.selectedMapId then
			highlightVote(data.selectedMapId)
		end

		-- Animate out after a delay
		task.spawn(function()
			task.wait(2) -- Wait before starting exit animation

			local tween = TweenService:Create(votingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -300, 1.5, 0)
			})
			tween:Play()

			task.wait(0.5) -- Wait for animation to complete

			-- Hide the voting UI
			screenGui.Enabled = false
			
			-- Clear map cards to prevent memory leaks
			clearMapCards()
			
			-- Reset UI state for next voting session
			titleLabel.Text = "VOTE FOR NEXT MAP"
			titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			votingFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
			-- Reset timer label color to its initial state
			timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end)
	end)
end

print("MapVotingUI initialized")

-- Return module table (required for ModuleScript compatibility)
local MapVotingUI = {}
return MapVotingUI
