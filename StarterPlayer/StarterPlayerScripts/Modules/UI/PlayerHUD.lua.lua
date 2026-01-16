-- @ScriptType: Script
-- PlayerHUD.client.lua
-- Shows player health bar and a compass that points toward nearest zombie and resource.
-- Updated with dynamic UI scaling for mobile devices and cleaner config integration.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Load shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))

-- Initialize scale manager
UIScaleManager.initialize()

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

-- Get scale factors
local function getScaledValue(baseValue, scaleType)
	return UIScaleManager.scalePixels(baseValue, scaleType or "hudElements")
end

local function getScaledTextSize(baseSize)
	return UIScaleManager.scaleTextSize(baseSize)
end

-- ========== UI CREATION ==========

-- Prevent duplicate HUDs on respawn
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("PlayerHUD")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Health bar container (bottom left with safe area)
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UIScaleManager.scaleSize(250, 24, "hudElements", "healthBar")
healthFrame.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 10, 40)
healthFrame.AnchorPoint = Vector2.new(0, 1)
healthFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
healthFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.3 or 0
healthFrame.BorderSizePixel = 0
healthFrame.Parent = screenGui

local healthOutline = Instance.new("UIStroke")
healthOutline.Thickness = 1
healthOutline.Color = Color3.fromRGB(80, 80, 80)
healthOutline.Parent = healthFrame

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
healthCorner.Parent = healthFrame

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.new(1, -4, 1, -4)
healthFill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
healthFill.BorderSizePixel = 0
healthFill.AnchorPoint = Vector2.new(0, 0.5)
healthFill.Position = UDim2.new(0, 2, 0.5, 0)
healthFill.Parent = healthFrame

local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, getScaledValue(4, "padding"))
healthFillCorner.Parent = healthFill

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthLabel"
healthLabel.Size = UDim2.new(1, -8, 1, 0)
healthLabel.Position = UDim2.new(0, 4, 0, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.TextColor3 = Color3.new(1, 1, 1)
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextSize = getScaledTextSize(16)
healthLabel.Text = "HP: 100 / 100"
healthLabel.Parent = healthFrame

-- Stamina bar container (above health bar)
local staminaFrame = Instance.new("Frame")
staminaFrame.Name = "StaminaFrame"
staminaFrame.Size = UIScaleManager.scaleSize(250, 16, "hudElements", "healthBar")
staminaFrame.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 10, 70)
staminaFrame.AnchorPoint = Vector2.new(0, 1)
staminaFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
staminaFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.3 or 0
staminaFrame.BorderSizePixel = 0
staminaFrame.Parent = screenGui

local staminaOutline = Instance.new("UIStroke")
staminaOutline.Thickness = 1
staminaOutline.Color = Color3.fromRGB(60, 80, 100)
staminaOutline.Parent = staminaFrame

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
staminaCorner.Parent = staminaFrame

local staminaFill = Instance.new("Frame")
staminaFill.Name = "StaminaFill"
staminaFill.Size = UDim2.new(1, -4, 1, -4)
staminaFill.Position = UDim2.new(0, 2, 0.5, 0)
staminaFill.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
staminaFill.BorderSizePixel = 0
staminaFill.AnchorPoint = Vector2.new(0, 0.5)
staminaFill.Parent = staminaFrame

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(0, getScaledValue(4, "padding"))
staminaFillCorner.Parent = staminaFill

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "StaminaLabel"
staminaLabel.Size = UDim2.new(1, -4, 1, 0)
staminaLabel.Position = UDim2.new(0, 2, 0, 0)
staminaLabel.BackgroundTransparency = 1
staminaLabel.TextColor3 = Color3.new(1, 1, 1)
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.Font = Enum.Font.GothamBold
staminaLabel.TextSize = getScaledTextSize(12)
staminaLabel.Text = "STAMINA"
staminaLabel.Parent = staminaFrame

-- Sprint indicator (shows when sprinting)
local sprintIndicator = Instance.new("TextLabel")
sprintIndicator.Name = "SprintIndicator"
sprintIndicator.Size = UIScaleManager.scaleSize(80, 20, "hudElements", "healthBar")
sprintIndicator.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 270, 40)
sprintIndicator.AnchorPoint = Vector2.new(0, 1)
sprintIndicator.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
sprintIndicator.BackgroundTransparency = 0.2
sprintIndicator.BorderSizePixel = 0
sprintIndicator.TextColor3 = Color3.new(1, 1, 1)
sprintIndicator.Font = Enum.Font.GothamBold
sprintIndicator.TextSize = getScaledTextSize(14)
sprintIndicator.Text = "SPRINT"
sprintIndicator.Visible = false
sprintIndicator.Parent = screenGui

local sprintCorner = Instance.new("UICorner")
sprintCorner.CornerRadius = UDim.new(0, getScaledValue(4, "padding"))
sprintCorner.Parent = sprintIndicator

-- Compass bar (top centre with safe area - positioned to avoid Roblox menu)
local compassFrame = Instance.new("Frame")
compassFrame.Name = "CompassFrame"
compassFrame.Size = UIScaleManager.scaleSize(300, 30, "hudElements", "compass")
compassFrame.Position = UIScaleManager.getPositionWithSafeArea("topCenter", 0, 5)
compassFrame.AnchorPoint = Vector2.new(0.5, 0)
compassFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
compassFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0
compassFrame.BorderSizePixel = 0
compassFrame.Parent = screenGui

local compassCorner = Instance.new("UICorner")
compassCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
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
zombieMarker.Size = UDim2.new(0, getScaledValue(6, "hudElements"), 0, getScaledValue(20, "hudElements"))
zombieMarker.AnchorPoint = Vector2.new(0.5, 1)
zombieMarker.Position = UDim2.new(0.5, 0, 1, 0)
zombieMarker.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
zombieMarker.BorderSizePixel = 0
zombieMarker.Parent = compassFrame

local zombieMarkerCorner = Instance.new("UICorner")
zombieMarkerCorner.CornerRadius = UDim.new(0, getScaledValue(3, "padding"))
zombieMarkerCorner.Parent = zombieMarker

-- Marker for nearest resource
local resourceMarker = Instance.new("Frame")
resourceMarker.Name = "ResourceMarker"
resourceMarker.Size = UDim2.new(0, getScaledValue(6, "hudElements"), 0, getScaledValue(14, "hudElements"))
resourceMarker.AnchorPoint = Vector2.new(0.5, 0)
resourceMarker.Position = UDim2.new(0.5, 0, 0, 0)
resourceMarker.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
resourceMarker.BorderSizePixel = 0
resourceMarker.Parent = compassFrame

local resourceMarkerCorner = Instance.new("UICorner")
resourceMarkerCorner.CornerRadius = UDim.new(0, getScaledValue(3, "padding"))
resourceMarkerCorner.Parent = resourceMarker

-- Function to update UI scaling when screen size changes
local function updateUIScaling()
	-- Update health frame
	healthFrame.Size = UIScaleManager.scaleSize(250, 24, "hudElements", "healthBar")
	healthFrame.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 10, 40)
	healthCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
	healthFillCorner.CornerRadius = UDim.new(0, getScaledValue(4, "padding"))
	healthLabel.TextSize = getScaledTextSize(16)
	healthFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.3 or 0

	-- Update stamina frame
	staminaFrame.Size = UIScaleManager.scaleSize(250, 16, "hudElements", "healthBar")
	staminaFrame.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 10, 70)
	staminaCorner.CornerRadius = UDim.new(0, getScaledValue(6, "padding"))
	staminaFillCorner.CornerRadius = UDim.new(0, getScaledValue(4, "padding"))
	staminaLabel.TextSize = getScaledTextSize(12)
	staminaFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.3 or 0

	-- Update sprint indicator
	sprintIndicator.Size = UIScaleManager.scaleSize(80, 20, "hudElements", "healthBar")
	sprintIndicator.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 270, 40)
	sprintIndicator.TextSize = getScaledTextSize(14)
	sprintCorner.CornerRadius = UDim.new(0, getScaledValue(4, "padding"))

	-- Update compass
	compassFrame.Size = UIScaleManager.scaleSize(300, 30, "hudElements", "compass")
	compassFrame.Position = UIScaleManager.getPositionWithSafeArea("topCenter", 0, 5)
	compassCorner.CornerRadius = UDim.new(0, getScaledValue(8, "padding"))
	compassFrame.BackgroundTransparency = UIScaleManager.isMobile() and 0.4 or 0

	-- Update markers
	zombieMarker.Size = UDim2.new(0, getScaledValue(6, "hudElements"), 0, getScaledValue(20, "hudElements"))
	zombieMarkerCorner.CornerRadius = UDim.new(0, getScaledValue(3, "padding"))
	resourceMarker.Size = UDim2.new(0, getScaledValue(6, "hudElements"), 0, getScaledValue(14, "hudElements"))
	resourceMarkerCorner.CornerRadius = UDim.new(0, getScaledValue(3, "padding"))
end

-- Register for scale changes and immediately apply once
UIScaleManager.onScaleChanged(updateUIScaling)
updateUIScaling()

-- ========== HEALTH HANDLING ==========

local currentHealth = GameConfig.STARTING_HEALTH or 100
local maxHealth = GameConfig.STARTING_HEALTH or 100

local function updateHealthUI()
	local ratio = 0
	if maxHealth > 0 then
		ratio = math.clamp(currentHealth / maxHealth, 0, 1)
	end

	-- Avoid weird negative width when ratio is 0 by scaling padding with ratio
	local innerPadding = 4
	healthFill.Size = UDim2.new(ratio, -innerPadding * ratio, 1, -innerPadding)

	healthLabel.Text = string.format("HP: %d / %d", math.floor(currentHealth + 0.5), maxHealth)

	-- Visual feedback: green → yellow → red
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

local currentStamina = GameConfig.STAMINA_MAX or (FPSConfig.Movement and FPSConfig.Movement.StaminaMax) or 100
local maxStamina = GameConfig.STAMINA_MAX or (FPSConfig.Movement and FPSConfig.Movement.StaminaMax) or 100

local function updateStaminaUI()
	local ratio = 0
	if maxStamina > 0 then
		ratio = math.clamp(currentStamina / maxStamina, 0, 1)
	end

	local innerPadding = 4
	staminaFill.Size = UDim2.new(ratio, -innerPadding * ratio, 1, -innerPadding)

	-- Color feedback based on stamina level
	if ratio > 0.5 then
		staminaFill.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
	elseif ratio > 0.25 then
		staminaFill.BackgroundColor3 = Color3.fromRGB(180, 180, 80)
	else
		staminaFill.BackgroundColor3 = Color3.fromRGB(220, 100, 80)
	end
end

-- Ensure BindableEvents folder + StaminaUpdate exist and listen for updates
local function setupStaminaListener()
	-- Ensure folder exists
	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end

	-- Ensure event exists
	local staminaEvent = bindableFolder:FindFirstChild("StaminaUpdate")
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

local cachedCharacter = nil
local cachedRoot = nil

local function getCharacterRoot()
	local char = player.Character or cachedCharacter
	if not char then
		char = player.Character or player.CharacterAdded:Wait()
		cachedCharacter = char
	end

	local root = cachedRoot
	if not root or not root.Parent then
		root = char:FindFirstChild("HumanoidRootPart")
		if not root then
			root = char:WaitForChild("HumanoidRootPart", 5)
		end
		cachedRoot = root
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
			-- Prefer PrimaryPart, then HumanoidRootPart, then any BasePart
			local primary = child.PrimaryPart
				or child:FindFirstChild("HumanoidRootPart")
				or child:FindFirstChildWhichIsA("BasePart")

			if primary then
				pos = primary.Position
			end
		elseif child:IsA("BasePart") then
			pos = child.Position
		end

		if pos then
			local offset = pos - root.Position
			-- squared distance
			local distSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z

			if distSq < nearestDistSq then
				nearestDistSq = distSq
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
	local root = getCharacterRoot()
	if not root then
		zombieMarker.Visible = false
		resourceMarker.Visible = false
		return
	end

	local zombiesFolder = workspace:FindFirstChild("Zombies")
	local resourcesFolder = workspace:FindFirstChild("CureResources")

	-- Zombie compass marker
	if zombiesFolder and #zombiesFolder:GetChildren() > 0 then
		local pos = getNearestChildPosition(zombiesFolder)
		if pos then
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

	-- Resource compass marker
	if resourcesFolder and #resourcesFolder:GetChildren() > 0 then
		local pos = getNearestChildPosition(resourcesFolder)
		if pos then
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
end)
