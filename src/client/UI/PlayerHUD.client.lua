-- PlayerHUD.client.lua
-- Shows player health bar and a compass that points toward nearest zombie and resource.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Remote event
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local healthEvent = remoteEventsFolder:WaitForChild("PlayerHealthUpdate") :: RemoteEvent

-- Wait for camera
local function getCamera()
	while not workspace.CurrentCamera do
		RunService.RenderStepped:Wait()
	end
	return workspace.CurrentCamera
end

local camera = getCamera()

-- ========== UI CREATION ==========

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Health bar container (bottom left-ish)
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UDim2.new(0, 250, 0, 24)
healthFrame.Position = UDim2.new(0, 20, 1, -80)
healthFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
healthFrame.BorderSizePixel = 0
healthFrame.Parent = screenGui

local healthOutline = Instance.new("UIStroke")
healthOutline.Thickness = 1
healthOutline.Color = Color3.fromRGB(80, 80, 80)
healthOutline.Parent = healthFrame

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 6)
healthCorner.Parent = healthFrame

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.new(1, -4, 1, -4)
healthFill.Position = UDim2.new(0, 2, 0, 2)
healthFill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
healthFill.BorderSizePixel = 0
healthFill.AnchorPoint = Vector2.new(0, 0.5)
healthFill.Position = UDim2.new(0, 2, 0.5, 0)
healthFill.Parent = healthFrame

local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, 4)
healthFillCorner.Parent = healthFill

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthLabel"
healthLabel.Size = UDim2.new(1, -8, 1, 0)
healthLabel.Position = UDim2.new(0, 4, 0, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.TextColor3 = Color3.new(1, 1, 1)
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextSize = 16
healthLabel.Text = "HP: 100 / 100"
healthLabel.Parent = healthFrame

-- Compass bar (top centre)
local compassFrame = Instance.new("Frame")
compassFrame.Name = "CompassFrame"
compassFrame.Size = UDim2.new(0, 300, 0, 30)
compassFrame.Position = UDim2.new(0.5, -150, 0, 20)
compassFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
compassFrame.BorderSizePixel = 0
compassFrame.Parent = screenGui

local compassCorner = Instance.new("UICorner")
compassCorner.CornerRadius = UDim.new(0, 8)
compassCorner.Parent = compassFrame

local compassOutline = Instance.new("UIStroke")
compassOutline.Thickness = 1
compassOutline.Color = Color3.fromRGB(90, 90, 120)
compassOutline.Parent = compassFrame

local compassLabel = Instance.new("TextLabel")
compassLabel.BackgroundTransparency = 1
compassLabel.Size = UDim2.new(1, 0, 1, 0)
compassLabel.Text = "N   E   S   W"
compassLabel.Font = Enum.Font.Gotham
compassLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
compassLabel.TextScaled = true
compassLabel.Parent = compassFrame

-- Marker for nearest zombie
local zombieMarker = Instance.new("Frame")
zombieMarker.Name = "ZombieMarker"
zombieMarker.Size = UDim2.new(0, 6, 0, 20)
zombieMarker.AnchorPoint = Vector2.new(0.5, 1)
zombieMarker.Position = UDim2.new(0.5, 0, 1, 0)
zombieMarker.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
zombieMarker.BorderSizePixel = 0
zombieMarker.Parent = compassFrame

local zombieMarkerCorner = Instance.new("UICorner")
zombieMarkerCorner.CornerRadius = UDim.new(0, 3)
zombieMarkerCorner.Parent = zombieMarker

-- Marker for nearest resource
local resourceMarker = Instance.new("Frame")
resourceMarker.Name = "ResourceMarker"
resourceMarker.Size = UDim2.new(0, 6, 0, 14)
resourceMarker.AnchorPoint = Vector2.new(0.5, 0)
resourceMarker.Position = UDim2.new(0.5, 0, 0, 0)
resourceMarker.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
resourceMarker.BorderSizePixel = 0
resourceMarker.Parent = compassFrame

local resourceMarkerCorner = Instance.new("UICorner")
resourceMarkerCorner.CornerRadius = UDim.new(0, 3)
resourceMarkerCorner.Parent = resourceMarker

-- Stamina bar container (below health bar)
local staminaFrame = Instance.new("Frame")
staminaFrame.Name = "StaminaFrame"
staminaFrame.Size = UDim2.new(0, 250, 0, 16)
staminaFrame.Position = UDim2.new(0, 20, 1, -52)
staminaFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
staminaFrame.BorderSizePixel = 0
staminaFrame.Parent = screenGui

local staminaOutline = Instance.new("UIStroke")
staminaOutline.Thickness = 1
staminaOutline.Color = Color3.fromRGB(80, 80, 80)
staminaOutline.Parent = staminaFrame

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, 4)
staminaCorner.Parent = staminaFrame

local staminaFill = Instance.new("Frame")
staminaFill.Name = "StaminaFill"
staminaFill.Size = UDim2.new(1, -4, 1, -4)
staminaFill.Position = UDim2.new(0, 2, 0, 2)
staminaFill.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
staminaFill.BorderSizePixel = 0
staminaFill.AnchorPoint = Vector2.new(0, 0.5)
staminaFill.Position = UDim2.new(0, 2, 0.5, 0)
staminaFill.Parent = staminaFrame

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(0, 3)
staminaFillCorner.Parent = staminaFill

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "StaminaLabel"
staminaLabel.Size = UDim2.new(1, -8, 1, 0)
staminaLabel.Position = UDim2.new(0, 4, 0, 0)
staminaLabel.BackgroundTransparency = 1
staminaLabel.TextColor3 = Color3.new(1, 1, 1)
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.Font = Enum.Font.GothamBold
staminaLabel.TextSize = 12
staminaLabel.Text = "STAMINA"
staminaLabel.Parent = staminaFrame

-- Sprint indicator (shows when sprinting)
local sprintIndicator = Instance.new("TextLabel")
sprintIndicator.Name = "SprintIndicator"
sprintIndicator.Size = UDim2.new(0, 60, 0, 16)
sprintIndicator.Position = UDim2.new(0, 280, 1, -52)
sprintIndicator.BackgroundColor3 = Color3.fromRGB(60, 140, 180)
sprintIndicator.BorderSizePixel = 0
sprintIndicator.TextColor3 = Color3.new(1, 1, 1)
sprintIndicator.Font = Enum.Font.GothamBold
sprintIndicator.TextSize = 10
sprintIndicator.Text = "SPRINT"
sprintIndicator.Visible = false
sprintIndicator.Parent = screenGui

local sprintIndicatorCorner = Instance.new("UICorner")
sprintIndicatorCorner.CornerRadius = UDim.new(0, 4)
sprintIndicatorCorner.Parent = sprintIndicator

-- ========== HEALTH HANDLING ==========

local currentHealth = 100
local maxHealth = 100

local function updateHealthUI()
	local ratio = 0
	if maxHealth > 0 then
		ratio = math.clamp(currentHealth / maxHealth, 0, 1)
	end

	healthFill.Size = UDim2.new(ratio, -4, 1, -4)
	healthLabel.Text = string.format("HP: %d / %d", math.floor(currentHealth + 0.5), maxHealth)

	-- nice visual feedback: more yellow when low HP
	if ratio > 0.6 then
		healthFill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
	elseif ratio > 0.3 then
		healthFill.BackgroundColor3 = Color3.fromRGB(220, 180, 60)
	else
		healthFill.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
	end
end

healthEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end

	currentHealth = data.current or currentHealth
	maxHealth = data.max or maxHealth
	updateHealthUI()
end)

updateHealthUI()

-- ========== STAMINA HANDLING ==========

local currentStamina = 100
local maxStamina = 100

local function updateStaminaUI()
	local ratio = 0
	if maxStamina > 0 then
		ratio = math.clamp(currentStamina / maxStamina, 0, 1)
	end

	staminaFill.Size = UDim2.new(ratio, -4, 1, -4)

	-- Color feedback based on stamina level
	if ratio > 0.5 then
		staminaFill.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
	elseif ratio > 0.25 then
		staminaFill.BackgroundColor3 = Color3.fromRGB(180, 180, 80)
	else
		staminaFill.BackgroundColor3 = Color3.fromRGB(220, 100, 80)
	end
end

-- Listen for stamina updates from SprintController via BindableEvent
local function setupStaminaListener()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Wait for or create the BindableEvents folder
	local bindableFolder = playerGui:WaitForChild("BindableEvents", 5)
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end
	
	-- Wait for or create the StaminaUpdate event
	local staminaEvent = bindableFolder:WaitForChild("StaminaUpdate", 5)
	if not staminaEvent then
		staminaEvent = Instance.new("BindableEvent")
		staminaEvent.Name = "StaminaUpdate"
		staminaEvent.Parent = bindableFolder
	end
	
	staminaEvent.Event:Connect(function(data)
		if typeof(data) ~= "table" then
			return
		end

		currentStamina = data.current or currentStamina
		maxStamina = data.max or maxStamina
		
		-- Show/hide sprint indicator
		sprintIndicator.Visible = data.isSprinting or false
		
		updateStaminaUI()
	end)
end

-- Initialize stamina listener in a coroutine to avoid blocking
task.spawn(setupStaminaListener)

updateStaminaUI()

-- ========== COMPASS / DIRECTION UTILS ==========

local function getCharacterRoot()
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		root = char:WaitForChild("HumanoidRootPart", 5)
	end
	return root
end

local function getNearestChildPosition(folder)
	if not folder or not folder.Parent then
		return nil
	end

	local root = getCharacterRoot()
	if not root then
		return nil
	end

	local nearestPos = nil
	local nearestDistSq = math.huge

	for _, child in ipairs(folder:GetChildren()) do
		local pos
		if child:IsA("Model") then
			local primary = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
			if primary then
				pos = primary.Position
			end
		elseif child:IsA("BasePart") then
			pos = child.Position
		end

		if pos then
			local d = (pos - root.Position).Magnitude
			local dsq = d * d
			if dsq < nearestDistSq then
				nearestDistSq = dsq
				nearestPos = pos
			end
		end
	end

	return nearestPos
end

-- Map world direction to X position in [0, 1] on compass
local function worldDirToCompassX(dir: Vector3): number
	if dir.Magnitude < 1e-3 then
		return 0.5
	end

	dir = dir.Unit

	local cam = workspace.CurrentCamera or camera
	local cf = cam.CFrame

	local forward = cf.LookVector
	local right = cf.RightVector

	-- Project onto camera's horizontal plane
	local dotForward = dir:Dot(forward)
	local dotRight = dir:Dot(right)

	-- angle in range (-pi, pi)
	local angle = math.atan2(dotRight, dotForward)

	-- Map -pi..pi → 0..1 (wrap on compass)
	-- -pi => 0, 0 => 0.5, pi => 1
	local t = (angle / math.pi) * 0.5 + 0.5
	return t
end

-- ========== UPDATE LOOP ==========

RunService.RenderStepped:Connect(function()
	local zombiesFolder = workspace:FindFirstChild("Zombies")
	local resourcesFolder = workspace:FindFirstChild("CureResources")

	-- Zombie compass marker
	if zombiesFolder and #zombiesFolder:GetChildren() > 0 then
		local pos = getNearestChildPosition(zombiesFolder)
		if pos then
			local root = getCharacterRoot()
			if root then
				local dir = pos - root.Position
				local x = worldDirToCompassX(dir)
				zombieMarker.Visible = true
				zombieMarker.Position = UDim2.new(x, 0, 1, 0)
			else
				zombieMarker.Visible = false
			end
		else
			zombieMarker.Visible = false
		end
	else
		zombieMarker.Visible = false
	end

	-- Resource compass marker
	if resourcesFolder and #resourcesFolder:GetChildren() > 0 then
		local pos = getNearestChildPosition(resourcesFolder)
		if pos then
			local root = getCharacterRoot()
			if root then
				local dir = pos - root.Position
				local x = worldDirToCompassX(dir)
				resourceMarker.Visible = true
				resourceMarker.Position = UDim2.new(x, 0, 0, 0)
			else
				resourceMarker.Visible = false
			end
		else
			resourceMarker.Visible = false
		end
	else
		resourceMarker.Visible = false
	end
end)
