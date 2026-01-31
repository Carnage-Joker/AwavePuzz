-- @ScriptType: ModuleScript
-- FPSMenuController.client.lua
-- Controller-friendly menu system with keyboard navigation
-- No mouse cursor during gameplay - all navigation via keyboard/controller

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))

--------------------------------------------------------------------------------
-- UTILS
--------------------------------------------------------------------------------

local function clamp(x, minv, maxv)
	if x < minv then return minv end
	if x > maxv then return maxv end
	return x
end

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local FPSMenuController = {}

local isMenuOpen = false
local isPaused = false
local currentMenuType = nil -- "pause", "settings", "controls"
local selectedIndex = 1
local menuItems = {}
local settingsValues = {}

-- Debounce for input
local lastInputTime = 0
local inputCooldown = 0.15

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

-- Menu container
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 400, 0, 500)
menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Thickness = 2
menuStroke.Color = Color3.fromRGB(100, 100, 120)
menuStroke.Parent = menuFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 60)
titleLabel.Position = UDim2.new(0, 20, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 32
titleLabel.Text = "PAUSE"
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = menuFrame

-- Menu items container
local itemsContainer = Instance.new("Frame")
itemsContainer.Name = "ItemsContainer"
itemsContainer.Size = UDim2.new(1, -40, 1, -140)
itemsContainer.Position = UDim2.new(0, 20, 0, 90)
itemsContainer.BackgroundTransparency = 1
itemsContainer.Parent = menuFrame

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsLayout.Padding = UDim.new(0, 8)
itemsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
itemsLayout.Parent = itemsContainer

-- Navigation hint
local navHint = Instance.new("TextLabel")
navHint.Name = "NavHint"
navHint.Size = UDim2.new(1, -40, 0, 30)
navHint.Position = UDim2.new(0, 20, 1, -50)
navHint.BackgroundTransparency = 1
navHint.TextColor3 = Color3.fromRGB(150, 150, 150)
navHint.Font = Enum.Font.Gotham
navHint.TextSize = 12
navHint.Text = "W/S or ↑/↓ to navigate  •  Enter to select  •  Escape to close"
navHint.Parent = menuFrame

--------------------------------------------------------------------------------
-- MENU ITEM CREATION
--------------------------------------------------------------------------------

local menuItemFrames = {}

local function createMenuItem(text, itemType, callback, options)
	local item = Instance.new("Frame")
	item.Name = "MenuItem_" .. text
	item.Size = UDim2.new(1, 0, 0, 50)
	item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	item.BackgroundTransparency = 0.3
	item.BorderSizePixel = 0
	item.Parent = itemsContainer

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = item

	local itemStroke = Instance.new("UIStroke")
	itemStroke.Name = "SelectionStroke"
	itemStroke.Thickness = 0
	itemStroke.Color = Color3.fromRGB(100, 200, 255)
	itemStroke.Parent = item

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.6, -20, 1, 0)
	label.Position = UDim2.new(0, 20, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = item

	local valueLabel = nil
	options = options or {}

	if itemType == "slider" or itemType == "toggle" or itemType == "choice" then
		valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(0.4, -20, 1, 0)
		valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextSize = 16
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = item

		if itemType == "toggle" then
			local on = options.default and true or false
			valueLabel.Text = on and "ON" or "OFF"
			valueLabel.TextColor3 = on and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		elseif itemType == "slider" then
			valueLabel.Text = tostring(options.default or 50)
		elseif itemType == "choice" then
			valueLabel.Text = options.choices[(options.defaultIndex or 1)]
			options.currentIndex = options.defaultIndex or 1
		end
	end

	table.insert(menuItemFrames, item)

	return {
		frame = item,
		label = label,
		valueLabel = valueLabel,
		itemType = itemType,
		callback = callback,
		options = options,
	}
end

local function clearMenuItems()
	for _, frame in ipairs(menuItemFrames) do
		if frame and frame.Parent then
			frame:Destroy()
		end
	end
	menuItemFrames = {}
	menuItems = {}
end

local function updateSelection()
	for i, item in ipairs(menuItems) do
		local frame = item.frame
		local stroke = frame:FindFirstChild("SelectionStroke")
		local label = item.label

		if i == selectedIndex then
			if stroke then stroke.Thickness = 2 end
			frame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			label.TextColor3 = Color3.fromRGB(100, 200, 255)

			TweenService:Create(frame, TweenInfo.new(0.1), {
				Size = UDim2.new(1, 0, 0, 55)
			}):Play()
		else
			if stroke then stroke.Thickness = 0 end
			frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			label.TextColor3 = Color3.new(1, 1, 1)

			TweenService:Create(frame, TweenInfo.new(0.1), {
				Size = UDim2.new(1, 0, 0, 50)
			}):Play()
		end
	end
end

--------------------------------------------------------------------------------
-- MENU DEFINITIONS (forward declarations)
--------------------------------------------------------------------------------

local buildPauseMenu, buildSettingsMenu, buildControlsMenu

buildPauseMenu = function()
	clearMenuItems()
	currentMenuType = "pause"
	titleLabel.Text = "PAUSED"

	table.insert(menuItems, createMenuItem("Resume", "button", function()
		FPSMenuController.closeMenu()
	end))

	table.insert(menuItems, createMenuItem("Settings", "button", function()
		buildSettingsMenu()
		selectedIndex = 1
		updateSelection()
	end))

	table.insert(menuItems, createMenuItem("Controls", "button", function()
		buildControlsMenu()
		selectedIndex = 1
		updateSelection()
	end))

	table.insert(menuItems, createMenuItem("Leave Match", "button", function()
		player:Kick("Left match")
	end))
end

buildSettingsMenu = function()
	clearMenuItems()
	currentMenuType = "settings"
	titleLabel.Text = "SETTINGS"

	table.insert(menuItems, createMenuItem("Mouse Sensitivity", "slider", function(value)
		settingsValues.sensitivity = value / 100
		local bindable = playerGui:FindFirstChild("BindableEvents")
		local event = bindable and bindable:FindFirstChild("SettingsChanged")
		if event then event:Fire({ sensitivity = settingsValues.sensitivity }) end
	end, {
		min = 10, max = 200,
		default = math.floor((settingsValues.sensitivity or 0.5) * 100),
		step = 5,
	}))

	table.insert(menuItems, createMenuItem("Field of View", "slider", function(value)
		settingsValues.fov = value
		local bindable = playerGui:FindFirstChild("BindableEvents")
		local event = bindable and bindable:FindFirstChild("SettingsChanged")
		if event then event:Fire({ fov = settingsValues.fov }) end
	end, {
		min = 50, max = 120,
		default = settingsValues.fov or 70,
		step = 5,
	}))

	table.insert(menuItems, createMenuItem("Invert Y-Axis", "toggle", function(value)
		settingsValues.invertY = value
		local bindable = playerGui:FindFirstChild("BindableEvents")
		local event = bindable and bindable:FindFirstChild("SettingsChanged")
		if event then event:Fire({ invertY = settingsValues.invertY }) end
	end, {
		default = settingsValues.invertY or false,
	}))

	table.insert(menuItems, createMenuItem("Master Volume", "slider", function(value)
		settingsValues.masterVolume = value / 100
	end, {
		min = 0, max = 100,
		default = math.floor((settingsValues.masterVolume or 1) * 100),
		step = 5,
	}))

	table.insert(menuItems, createMenuItem("SFX Volume", "slider", function(value)
		settingsValues.sfxVolume = value / 100
	end, {
		min = 0, max = 100,
		default = math.floor((settingsValues.sfxVolume or 0.8) * 100),
		step = 5,
	}))

	table.insert(menuItems, createMenuItem("Back", "button", function()
		buildPauseMenu()
		selectedIndex = 1
		updateSelection()
	end))
end

buildControlsMenu = function()
	clearMenuItems()
	currentMenuType = "controls"
	titleLabel.Text = "CONTROLS"

	local controls = {
		{ "Move", "W/A/S/D" },
		{ "Look", "Mouse" },
		{ "Fire", "Left Click" },
		{ "Aim (ADS)", "Right Click" },
		{ "Reload", "R" },
		{ "Sprint", "Left Shift" },
		{ "Crouch", "Left Ctrl" },
		{ "Jump", "Space" },
		{ "Weapon 1-4", "1/2/3/4" },
	}

	for _, control in ipairs(controls) do
		local item = createMenuItem(control[1], "display", nil, {})

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "Key"
		keyLabel.Size = UDim2.new(0.4, -20, 1, 0)
		keyLabel.Position = UDim2.new(0.6, 0, 0, 0)
		keyLabel.BackgroundTransparency = 1
		keyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		keyLabel.Font = Enum.Font.Gotham
		keyLabel.TextSize = 14
		keyLabel.Text = control[2]
		keyLabel.TextXAlignment = Enum.TextXAlignment.Right
		keyLabel.Parent = item.frame
	end

	table.insert(menuItems, createMenuItem("Back", "button", function()
		buildPauseMenu()
		selectedIndex = 1
		updateSelection()
	end))
end

--------------------------------------------------------------------------------
-- MENU NAVIGATION
--------------------------------------------------------------------------------

local function navigateUp()
	if #menuItems == 0 then return end
	selectedIndex -= 1
	if selectedIndex < 1 then selectedIndex = #menuItems end
	updateSelection()
end

local function navigateDown()
	if #menuItems == 0 then return end
	selectedIndex += 1
	if selectedIndex > #menuItems then selectedIndex = 1 end
	updateSelection()
end

local function adjustValue(direction)
	local item = menuItems[selectedIndex]
	if not item then return end

	if item.itemType == "slider" then
		local options = item.options
		local currentValue = tonumber(item.valueLabel.Text) or options.default
		local step = options.step or 1
		local newValue = clamp(currentValue + (direction * step), options.min, options.max)
		item.valueLabel.Text = tostring(newValue)
		if item.callback then item.callback(newValue) end

	elseif item.itemType == "toggle" then
		local current = item.valueLabel.Text == "ON"
		local newValue = not current
		item.valueLabel.Text = newValue and "ON" or "OFF"
		item.valueLabel.TextColor3 = newValue and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		if item.callback then item.callback(newValue) end

	elseif item.itemType == "choice" then
		local options = item.options
		local choices = options.choices
		local currentIndex = options.currentIndex or 1
		local newIndex = currentIndex + direction
		if newIndex < 1 then newIndex = #choices end
		if newIndex > #choices then newIndex = 1 end
		options.currentIndex = newIndex
		item.valueLabel.Text = choices[newIndex]
		if item.callback then item.callback(choices[newIndex], newIndex) end
	end
end

local function selectItem()
	local item = menuItems[selectedIndex]
	if not item then return end
	if item.itemType == "button" then
		if item.callback then item.callback() end
	elseif item.itemType == "toggle" then
		adjustValue(1)
	end
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

local function handleInput(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if not isMenuOpen then
		if input.KeyCode == FPSConfig.Controls.PauseKey then
			FPSMenuController.openMenu("pause")
		end
		return
	end

	-- Debounce
	local now = tick()
	if now - lastInputTime < inputCooldown then return end
	lastInputTime = now

	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		navigateUp()
	elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		navigateDown()
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		adjustValue(-1)
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		adjustValue(1)
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
		selectItem()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		if currentMenuType == "settings" or currentMenuType == "controls" then
			buildPauseMenu()
			selectedIndex = 1
			updateSelection()
		else
			FPSMenuController.closeMenu()
		end
	end
end

UserInputService.InputBegan:Connect(handleInput)

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function FPSMenuController.openMenu(menuType)
	menuType = menuType or "pause"

	if menuType == "pause" then
		buildPauseMenu()
	elseif menuType == "settings" then
		buildSettingsMenu()
	elseif menuType == "controls" then
		buildControlsMenu()
	end

	selectedIndex = 1
	updateSelection()

	screenGui.Enabled = true
	isMenuOpen = true
	isPaused = true

	-- Keyboard/controller-only menu: keep cursor hidden
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = false

	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	local menuEvent = bindableFolder and bindableFolder:FindFirstChild("MenuStateChanged")
	if menuEvent then
		menuEvent:Fire({ isOpen = true, menuType = currentMenuType })
	end

	print("[FPSMenuController] Menu opened:", currentMenuType)
end

function FPSMenuController.closeMenu()
	screenGui.Enabled = false
	isMenuOpen = false
	isPaused = false
	currentMenuType = nil

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	local menuEvent = bindableFolder and bindableFolder:FindFirstChild("MenuStateChanged")
	if menuEvent then
		menuEvent:Fire({ isOpen = false })
	end

	print("[FPSMenuController] Menu closed")
end

function FPSMenuController.isOpen()
	return isMenuOpen
end

function FPSMenuController.getSettings()
	return settingsValues
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	settingsValues = {
		sensitivity = FPSConfig.Camera.DefaultSensitivity,
		fov = FPSConfig.Camera.DefaultFOV,
		invertY = FPSConfig.Camera.InvertY,
		masterVolume = 1.0,
		sfxVolume = 0.8,
		musicVolume = 0.5,
	}

	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end

	local settingsEvent = bindableFolder:FindFirstChild("SettingsChanged")
	if not settingsEvent then
		settingsEvent = Instance.new("BindableEvent")
		settingsEvent.Name = "SettingsChanged"
		settingsEvent.Parent = bindableFolder
	end

	local menuEvent = bindableFolder:FindFirstChild("MenuStateChanged")
	if not menuEvent then
		menuEvent = Instance.new("BindableEvent")
		menuEvent.Name = "MenuStateChanged"
		menuEvent.Parent = bindableFolder
	end

	print("[FPSMenuController] Initialized")
end

--------------------------------------------------------------------------------
-- MODULE EXPORT
--------------------------------------------------------------------------------

function FPSMenuController.initialize()
	initialize()
end

function FPSMenuController.onCharacterAdded(character) end
function FPSMenuController.onCharacterRemoving() end

return FPSMenuController
