-- @ScriptType: LocalScript
-- MapVotingClient.lua (LocalScript)
-- Place under StarterGui/MapVotingGui
-- Builds a basic voting UI and talks to LobbyManager remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent

local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local MapVotingState = remotesFolder:WaitForChild("MapVotingState")
local MapVotingUpdate = remotesFolder:WaitForChild("MapVotingUpdate")
local MapVoteCast = remotesFolder:WaitForChild("MapVoteCast")

-- ----------------------------
-- UI build (simple + robust)
-- ----------------------------
local function ensure(name, className, parent)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local root = ensure("Root", "Frame", gui)
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(520, 360)
root.BackgroundTransparency = 0.15
root.Visible = false

local title = ensure("Title", "TextLabel", root)
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.fromOffset(10, 10)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Map Vote"
title.TextScaled = true

local timerLabel = ensure("Timer", "TextLabel", root)
timerLabel.Size = UDim2.new(0, 160, 0, 28)
timerLabel.Position = UDim2.fromOffset(10, 50)
timerLabel.BackgroundTransparency = 1
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Text = "Time: --"
timerLabel.TextScaled = true

local statusLabel = ensure("Status", "TextLabel", root)
statusLabel.Size = UDim2.new(1, -180, 0, 28)
statusLabel.Position = UDim2.fromOffset(170, 50)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = ""
statusLabel.TextScaled = true

local listFrame = ensure("List", "ScrollingFrame", root)
listFrame.Position = UDim2.fromOffset(10, 90)
listFrame.Size = UDim2.new(1, -20, 1, -140)
listFrame.BackgroundTransparency = 0.2
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.fromOffset(0, 0)

local layout = ensure("Layout", "UIListLayout", listFrame)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local bottom = ensure("Bottom", "Frame", root)
bottom.Position = UDim2.new(0, 10, 1, -40)
bottom.Size = UDim2.new(1, -20, 0, 30)
bottom.BackgroundTransparency = 1

local selectedLabel = ensure("Selected", "TextLabel", bottom)
selectedLabel.Size = UDim2.new(1, 0, 1, 0)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Text = "Your vote: --"
selectedLabel.TextScaled = true

-- ----------------------------
-- State
-- ----------------------------
local mapsById = {}       -- mapId -> mapData
local buttonsById = {}    -- mapId -> button frame
local currentCounts = {}  -- mapId -> count
local myVote = nil
local votingActive = false
local timeRemaining = 0

local function clearList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "MapRow" then
			child:Destroy()
		end
	end
	mapsById = {}
	buttonsById = {}
	currentCounts = {}
	myVote = nil
end

local function resizeCanvas()
	task.defer(function()
		local total = layout.AbsoluteContentSize.Y
		listFrame.CanvasSize = UDim2.fromOffset(0, total + 12)
	end)
end

local function setRowHighlight(mapId)
	for id, row in pairs(buttonsById) do
		local bg = row:FindFirstChild("BG")
		if bg then
			bg.BackgroundTransparency = (id == mapId) and 0.05 or 0.25
		end
	end
end

local function formatRowText(mapId)
	local mapData = mapsById[mapId]
	if not mapData then return "" end
	local count = currentCounts[mapId] or 0
	return string.format("%s  (%d)", tostring(mapData.name or mapId), count)
end

local function updateRowTexts()
	for mapId, row in pairs(buttonsById) do
		local label = row:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = formatRowText(mapId)
		end
	end
end

local function setTimer(t)
	timeRemaining = t or 0
	timerLabel.Text = "Time: " .. tostring(math.max(0, timeRemaining))
end

local function buildRow(mapData)
	local mapId = mapData.id
	mapsById[mapId] = mapData
	currentCounts[mapId] = currentCounts[mapId] or 0

	local row = Instance.new("Frame")
	row.Name = "MapRow"
	row.Size = UDim2.new(1, -10, 0, 48)
	row.BackgroundTransparency = 1
	row.Parent = listFrame

	local bg = Instance.new("TextButton")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundTransparency = 0.25
	bg.Text = ""
	bg.AutoButtonColor = true
	bg.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 6)
	label.Size = UDim2.new(1, -24, 1, -12)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.Text = formatRowText(mapId)
	label.Parent = row

	bg.MouseButton1Click:Connect(function()
		if not votingActive then return end
		myVote = mapId
		selectedLabel.Text = "Your vote: " .. tostring(mapsById[mapId].name or mapId)
		setRowHighlight(mapId)

		-- server authoritative; this only *requests* the vote
		MapVoteCast:FireServer(mapId)
	end)

	buttonsById[mapId] = row
end

local function applyCounts(votesTable)
	-- votesTable is a dictionary mapId -> count
	currentCounts = votesTable or currentCounts or {}
	updateRowTexts()
end

-- ----------------------------
-- Remote handlers
-- ----------------------------
MapVotingState.OnClientEvent:Connect(function(payload)
	-- payload examples:
	-- { active=true, timeRemaining=20, maps=[{id,name,description}], votes={...} }
	-- { active=false, timeRemaining=0, selectedMapId="X", votes={...} }
	if typeof(payload) ~= "table" then return end

	votingActive = payload.active == true
	root.Visible = votingActive or (payload.active == false and payload.selectedMapId ~= nil)

	if payload.active then
		clearList()

		local maps = payload.maps or {}
		for _, mapData in ipairs(maps) do
			if typeof(mapData) == "table" and typeof(mapData.id) == "string" then
				buildRow(mapData)
			end
		end

		applyCounts(payload.votes or {})
		setTimer(payload.timeRemaining or 0)
		statusLabel.Text = "Voting open"
		selectedLabel.Text = "Your vote: --"
		resizeCanvas()

	else
		-- voting ended
		applyCounts(payload.votes or {})
		setTimer(payload.timeRemaining or 0)

		local selectedId = payload.selectedMapId
		if selectedId then
			statusLabel.Text = "Selected: " .. tostring(mapsById[selectedId] and mapsById[selectedId].name or selectedId)
			setRowHighlight(selectedId)
		else
			statusLabel.Text = "Voting closed"
		end

		-- Optional: auto-hide after a short delay
		task.delay(3, function()
			if not votingActive then
				root.Visible = false
			end
		end)
	end
end)

MapVotingUpdate.OnClientEvent:Connect(function(payload)
	-- payload: { timeRemaining = int, votes = {mapId=count,...} }
	if typeof(payload) ~= "table" then return end
	if payload.timeRemaining ~= nil then
		setTimer(payload.timeRemaining)
	end
	if payload.votes ~= nil then
		applyCounts(payload.votes)
	end
end)

-- Safety: if UI starts visible in Studio, hide it
root.Visible = false
