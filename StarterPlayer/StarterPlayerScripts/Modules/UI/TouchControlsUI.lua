-- TouchControlsUI.lua
-- On-screen touch controls for mobile devices
-- Provides virtual joystick for movement and buttons for actions

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local InputManager = require(SharedFolder:WaitForChild("InputManager"))
local UIScaleManager = require(SharedFolder:WaitForChild("UIScaleManager"))

-- Initialize managers
InputManager.initialize()
UIScaleManager.initialize()

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

local JOYSTICK_SIZE = 150
local JOYSTICK_INNER_SIZE = 60
local JOYSTICK_MAX_DISTANCE = 50
local BUTTON_SIZE = 70
local BUTTON_SPACING = 10

local JOYSTICK_POSITION = UDim2.new(0, 100, 1, -150) -- Bottom left
local FIRE_BUTTON_POSITION = UDim2.new(1, -100, 1, -150) -- Bottom right
local JUMP_BUTTON_POSITION = UDim2.new(1, -100, 1, -250) -- Above fire button
local CROUCH_BUTTON_POSITION = UDim2.new(1, -190, 1, -150) -- Left of fire button
local AIM_BUTTON_POSITION = UDim2.new(1, -190, 1, -250) -- Above crouch
local RELOAD_BUTTON_POSITION = UDim2.new(1, -280, 1, -150) -- Further left

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local TouchControls = {}
TouchControls.enabled = false
local screenGui = nil
local joystickOuter = nil
local joystickInner = nil
local fireButton = nil
local jumpButton = nil
local crouchButton = nil
local aimButton = nil
local reloadButton = nil
local sprintButton = nil

-- Touch tracking
local joystickTouch = nil
local joystickPosition = Vector2.new(0, 0) -- Normalized -1 to 1
local activeButtons = {}

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createScreenGui()
	-- Remove existing UI
	local existing = playerGui:FindFirstChild("TouchControls")
	if existing then
		existing:Destroy()
	end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TouchControls"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false -- Use safe area
	screenGui.DisplayOrder = 100
	screenGui.Enabled = false -- Will be enabled if touch device detected
	screenGui.Parent = playerGui
	
	return screenGui
end

local function createJoystick()
	-- Outer circle (background)
	joystickOuter = Instance.new("Frame")
	joystickOuter.Name = "JoystickOuter"
	joystickOuter.Size = UIScaleManager.scaleSize(JOYSTICK_SIZE, JOYSTICK_SIZE, "hudElements")
	joystickOuter.Position = UIScaleManager.getPositionWithSafeArea("bottomLeft", 80, -130)
	joystickOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	joystickOuter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	joystickOuter.BackgroundTransparency = 0.7
	joystickOuter.BorderSizePixel = 0
	joystickOuter.Parent = screenGui
	
	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(1, 0)
	outerCorner.Parent = joystickOuter
	
	-- Inner circle (stick)
	joystickInner = Instance.new("Frame")
	joystickInner.Name = "JoystickInner"
	joystickInner.Size = UIScaleManager.scaleSize(JOYSTICK_INNER_SIZE, JOYSTICK_INNER_SIZE, "hudElements")
	joystickInner.Position = UDim2.new(0.5, 0, 0.5, 0)
	joystickInner.AnchorPoint = Vector2.new(0.5, 0.5)
	joystickInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	joystickInner.BackgroundTransparency = 0.3
	joystickInner.BorderSizePixel = 0
	joystickInner.Parent = joystickOuter
	
	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = joystickInner
end

local function createButton(name, text, position, action)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UIScaleManager.scaleSize(BUTTON_SIZE, BUTTON_SIZE, "hudElements")
	button.Position = position
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.7
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = UIScaleManager.scaleTextSize(20)
	button.Font = Enum.Font.GothamBold
	button.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = button
	
	-- Store action for later
	button:SetAttribute("Action", action)
	
	return button
end

local function createAllButtons()
	-- Fire button (bottom right)
	fireButton = createButton(
		"FireButton",
		"FIRE",
		UIScaleManager.getPositionWithSafeArea("bottomRight", -80, -130),
		InputManager.Action.FIRE
	)
	
	-- Jump button (above fire)
	jumpButton = createButton(
		"JumpButton",
		"JUMP",
		UIScaleManager.getPositionWithSafeArea("bottomRight", -80, -220),
		InputManager.Action.JUMP
	)
	
	-- Crouch button (left of fire)
	crouchButton = createButton(
		"CrouchButton",
		"CROUCH",
		UIScaleManager.getPositionWithSafeArea("bottomRight", -170, -130),
		InputManager.Action.CROUCH
	)
	
	-- ADS/Aim button (above crouch)
	aimButton = createButton(
		"AimButton",
		"AIM",
		UIScaleManager.getPositionWithSafeArea("bottomRight", -170, -220),
		InputManager.Action.AIM
	)
	
	-- Reload button (further left)
	reloadButton = createButton(
		"ReloadButton",
		"R",
		UIScaleManager.getPositionWithSafeArea("bottomRight", -260, -130),
		InputManager.Action.RELOAD
	)
	
	-- Sprint button (top right of joystick)
	sprintButton = createButton(
		"SprintButton",
		"SPRINT",
		UIScaleManager.getPositionWithSafeArea("bottomLeft", 80, -240),
		InputManager.Action.SPRINT
	)
end

--------------------------------------------------------------------------------
-- JOYSTICK LOGIC
--------------------------------------------------------------------------------

local function updateJoystick(touchPosition)
	if not joystickOuter or not joystickInner then return end
	
	-- Get joystick center position in screen space
	local outerPos = joystickOuter.AbsolutePosition
	local outerSize = joystickOuter.AbsoluteSize
	local centerPos = outerPos + (outerSize / 2)
	
	-- Calculate offset from center
	local offset = touchPosition - centerPos
	local distance = offset.Magnitude
	
	-- Clamp to max distance
	local maxDist = JOYSTICK_MAX_DISTANCE * (outerSize.X / JOYSTICK_SIZE)
	if distance > maxDist then
		offset = offset.Unit * maxDist
		distance = maxDist
	end
	
	-- Update inner position
	joystickInner.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
	
	-- Calculate normalized position (-1 to 1)
	if distance > 0 then
		joystickPosition = offset / maxDist
	else
		joystickPosition = Vector2.new(0, 0)
	end
	
	-- Send to InputManager
	if InputManager and InputManager.bindAxis then
		local callback = InputManager.axisCallbacks and InputManager.axisCallbacks["Movement"]
		if callback then
			-- Invert Y for forward/backward
			callback(Vector2.new(joystickPosition.X, -joystickPosition.Y))
		end
	end
end

local function resetJoystick()
	if joystickInner then
		joystickInner.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	joystickPosition = Vector2.new(0, 0)
	joystickTouch = nil
	
	-- Notify InputManager
	if InputManager and InputManager.bindAxis then
		local callback = InputManager.axisCallbacks and InputManager.axisCallbacks["Movement"]
		if callback then
			callback(Vector2.new(0, 0))
		end
	end
end

--------------------------------------------------------------------------------
-- BUTTON LOGIC
--------------------------------------------------------------------------------

local function setupButtonEvents(button)
	if not button then return end
	
	local action = button:GetAttribute("Action")
	if not action then return end
	
	-- Track active state
	activeButtons[button] = false
	
	-- Mouse/touch down
	button.MouseButton1Down:Connect(function()
		activeButtons[button] = true
		button.BackgroundTransparency = 0.3 -- Visual feedback
		InputManager.setActionState(action, true)
	end)
	
	-- Mouse/touch up
	button.MouseButton1Up:Connect(function()
		activeButtons[button] = false
		button.BackgroundTransparency = 0.7
		InputManager.setActionState(action, false)
	end)
	
	-- Mouse leave (in case touch moves off button)
	button.MouseLeave:Connect(function()
		if activeButtons[button] then
			activeButtons[button] = false
			button.BackgroundTransparency = 0.7
			InputManager.setActionState(action, false)
		end
	end)
end

--------------------------------------------------------------------------------
-- TOUCH INPUT HANDLING
--------------------------------------------------------------------------------

local function setupTouchInput()
	-- Handle joystick touches
	UserInputService.TouchStarted:Connect(function(touch, processed)
		-- Don't check processed for joystick - we want to capture all touches in the area
		local touchPos = touch.Position
		
		-- Check if touch is on joystick
		if joystickOuter and not joystickTouch then
			local outerPos = joystickOuter.AbsolutePosition
			local outerSize = joystickOuter.AbsoluteSize
			local relativePos = touchPos - outerPos
			
			-- Expand hitbox slightly for easier control
			local expandedMargin = 20
			if relativePos.X >= -expandedMargin and relativePos.X <= outerSize.X + expandedMargin and
			   relativePos.Y >= -expandedMargin and relativePos.Y <= outerSize.Y + expandedMargin then
				joystickTouch = touch
				updateJoystick(touchPos)
			end
		end
	end)
	
	UserInputService.TouchMoved:Connect(function(touch, processed)
		-- Always process joystick movement regardless of processed state
		if touch == joystickTouch then
			updateJoystick(touch.Position)
		end
	end)
	
	UserInputService.TouchEnded:Connect(function(touch, processed)
		if touch == joystickTouch then
			resetJoystick()
		end
	end)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function TouchControls.initialize()
	-- Only enable on touch devices
	if not InputManager.isTouch() then
		return
	end
	
	print("[TouchControls] Initializing touch controls...")
	
	-- Create UI
	createScreenGui()
	createJoystick()
	createAllButtons()
	
	-- Setup button events
	setupButtonEvents(fireButton)
	setupButtonEvents(jumpButton)
	setupButtonEvents(crouchButton)
	setupButtonEvents(aimButton)
	setupButtonEvents(reloadButton)
	setupButtonEvents(sprintButton)
	
	-- Setup touch input handling
	setupTouchInput()
	
	-- Enable UI
	if screenGui then
		screenGui.Enabled = true
		TouchControls.enabled = true
	end
	
	print("[TouchControls] Touch controls enabled")
end

function TouchControls.setEnabled(enabled)
	if screenGui then
		screenGui.Enabled = enabled
		TouchControls.enabled = enabled
	end
end

function TouchControls.isEnabled()
	return TouchControls.enabled
end

-- Auto-initialize on touch devices
if InputManager.isTouch() then
	task.spawn(function()
		task.wait(0.5) -- Wait for InputManager to fully initialize
		TouchControls.initialize()
	end)
end

return TouchControls
