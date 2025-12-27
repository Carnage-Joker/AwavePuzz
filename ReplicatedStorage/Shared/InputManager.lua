-- InputManager.lua
-- Cross-platform input abstraction for keyboard, mouse, gamepad, touch, and VR
-- Provides unified interface for all input devices with device detection

local InputManager = {}
InputManager.__index = InputManager

-- Services
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

-- Device types
InputManager.DeviceType = {
	KEYBOARD_MOUSE = "KeyboardMouse",
	GAMEPAD = "Gamepad",
	TOUCH = "Touch",
	VR = "VR",
}

-- Input actions (abstract actions that map to different inputs per device)
InputManager.Action = {
	-- Movement
	MOVE_FORWARD = "MoveForward",
	MOVE_BACKWARD = "MoveBackward",
	MOVE_LEFT = "MoveLeft",
	MOVE_RIGHT = "MoveRight",
	SPRINT = "Sprint",
	CROUCH = "Crouch",
	JUMP = "Jump",
	
	-- Combat
	FIRE = "Fire",
	AIM = "Aim",
	RELOAD = "Reload",
	SWITCH_WEAPON = "SwitchWeapon",
	NEXT_WEAPON = "NextWeapon",
	PREV_WEAPON = "PrevWeapon",
	
	-- Interaction
	INTERACT = "Interact",
	USE = "Use",
	
	-- UI
	MENU = "Menu",
	PAUSE = "Pause",
	SCOREBOARD = "Scoreboard",
	INVENTORY = "Inventory",
	MAP = "Map",
	
	-- Camera
	LOOK = "Look",
	LOOK_UP = "LookUp",
	LOOK_DOWN = "LookDown",
	LOOK_LEFT = "LookLeft",
	LOOK_RIGHT = "LookRight",
}

-- Default keybindings for each device type
local DEFAULT_BINDINGS = {
	[InputManager.DeviceType.KEYBOARD_MOUSE] = {
		[InputManager.Action.MOVE_FORWARD] = {Enum.KeyCode.W},
		[InputManager.Action.MOVE_BACKWARD] = {Enum.KeyCode.S},
		[InputManager.Action.MOVE_LEFT] = {Enum.KeyCode.A},
		[InputManager.Action.MOVE_RIGHT] = {Enum.KeyCode.D},
		[InputManager.Action.SPRINT] = {Enum.KeyCode.LeftShift},
		[InputManager.Action.CROUCH] = {Enum.KeyCode.LeftControl, Enum.KeyCode.C},
		[InputManager.Action.JUMP] = {Enum.KeyCode.Space},
		[InputManager.Action.FIRE] = {Enum.UserInputType.MouseButton1},
		[InputManager.Action.AIM] = {Enum.UserInputType.MouseButton2},
		[InputManager.Action.RELOAD] = {Enum.KeyCode.R},
		[InputManager.Action.SWITCH_WEAPON] = {Enum.KeyCode.Q},
		[InputManager.Action.NEXT_WEAPON] = {Enum.KeyCode.E},
		[InputManager.Action.PREV_WEAPON] = {Enum.KeyCode.Tab},
		[InputManager.Action.INTERACT] = {Enum.KeyCode.F},
		[InputManager.Action.USE] = {Enum.KeyCode.E},
		[InputManager.Action.MENU] = {Enum.KeyCode.Escape},
		[InputManager.Action.PAUSE] = {Enum.KeyCode.P},
		[InputManager.Action.SCOREBOARD] = {Enum.KeyCode.Tab},
		[InputManager.Action.INVENTORY] = {Enum.KeyCode.I},
		[InputManager.Action.MAP] = {Enum.KeyCode.M},
	},
	
	[InputManager.DeviceType.GAMEPAD] = {
		[InputManager.Action.MOVE_FORWARD] = {Enum.KeyCode.Thumbstick1}, -- Left stick (axis-based, handled separately)
		[InputManager.Action.MOVE_BACKWARD] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.MOVE_LEFT] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.MOVE_RIGHT] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.SPRINT] = {Enum.KeyCode.ButtonL3}, -- Left stick click
		[InputManager.Action.CROUCH] = {Enum.KeyCode.ButtonB}, -- B/Circle
		[InputManager.Action.JUMP] = {Enum.KeyCode.ButtonA}, -- A/X
		[InputManager.Action.FIRE] = {Enum.KeyCode.ButtonR2}, -- Right trigger
		[InputManager.Action.AIM] = {Enum.KeyCode.ButtonL2}, -- Left trigger
		[InputManager.Action.RELOAD] = {Enum.KeyCode.ButtonX}, -- X/Square
		[InputManager.Action.SWITCH_WEAPON] = {Enum.KeyCode.ButtonY}, -- Y/Triangle
		[InputManager.Action.NEXT_WEAPON] = {Enum.KeyCode.ButtonR1}, -- Right bumper
		[InputManager.Action.PREV_WEAPON] = {Enum.KeyCode.ButtonL1}, -- Left bumper
		[InputManager.Action.INTERACT] = {Enum.KeyCode.ButtonX},
		[InputManager.Action.USE] = {Enum.KeyCode.ButtonA},
		[InputManager.Action.MENU] = {Enum.KeyCode.ButtonStart},
		[InputManager.Action.PAUSE] = {Enum.KeyCode.ButtonStart},
		[InputManager.Action.SCOREBOARD] = {Enum.KeyCode.ButtonSelect},
		[InputManager.Action.INVENTORY] = {Enum.KeyCode.DPadUp},
		[InputManager.Action.MAP] = {Enum.KeyCode.DPadDown},
		[InputManager.Action.LOOK] = {Enum.KeyCode.Thumbstick2}, -- Right stick (axis-based)
	},
	
	[InputManager.DeviceType.TOUCH] = {
		-- Touch controls are handled via on-screen UI buttons
		-- These are virtual mappings
		[InputManager.Action.MOVE_FORWARD] = {"VirtualJoystick"},
		[InputManager.Action.MOVE_BACKWARD] = {"VirtualJoystick"},
		[InputManager.Action.MOVE_LEFT] = {"VirtualJoystick"},
		[InputManager.Action.MOVE_RIGHT] = {"VirtualJoystick"},
		[InputManager.Action.SPRINT] = {"VirtualButton_Sprint"},
		[InputManager.Action.CROUCH] = {"VirtualButton_Crouch"},
		[InputManager.Action.JUMP] = {"VirtualButton_Jump"},
		[InputManager.Action.FIRE] = {"VirtualButton_Fire"},
		[InputManager.Action.AIM] = {"VirtualButton_Aim"},
		[InputManager.Action.RELOAD] = {"VirtualButton_Reload"},
		[InputManager.Action.INTERACT] = {"VirtualButton_Interact"},
		[InputManager.Action.MENU] = {"VirtualButton_Menu"},
	},
	
	[InputManager.DeviceType.VR] = {
		[InputManager.Action.MOVE_FORWARD] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.MOVE_BACKWARD] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.MOVE_LEFT] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.MOVE_RIGHT] = {Enum.KeyCode.Thumbstick1},
		[InputManager.Action.SPRINT] = {Enum.KeyCode.ButtonL3},
		[InputManager.Action.JUMP] = {Enum.KeyCode.ButtonA},
		[InputManager.Action.FIRE] = {Enum.KeyCode.ButtonR2},
		[InputManager.Action.AIM] = {Enum.KeyCode.ButtonL2},
		[InputManager.Action.RELOAD] = {Enum.KeyCode.ButtonX},
		[InputManager.Action.INTERACT] = {Enum.KeyCode.ButtonA},
		[InputManager.Action.MENU] = {Enum.KeyCode.ButtonStart},
	},
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local activeDevice = InputManager.DeviceType.KEYBOARD_MOUSE
local bindings = {}
local actionStates = {} -- Tracks if actions are currently active
local actionCallbacks = {} -- Callbacks for action state changes
local axisCallbacks = {} -- Callbacks for axis-based inputs (movement, look)
local connections = {}
local initialized = false

-- Gamepad state
local gamepadConnected = false
local lastGamepadInput = 0
local activeGamepad = nil

-- Touch state
local touchEnabled = false

-- VR state
local vrEnabled = false

--------------------------------------------------------------------------------
-- DEVICE DETECTION
--------------------------------------------------------------------------------

function InputManager.detectDevice()
	-- Check for VR first
	if UserInputService.VREnabled then
		activeDevice = InputManager.DeviceType.VR
		vrEnabled = true
		return activeDevice
	end
	
	-- Check for touch without keyboard (mobile/tablet)
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		activeDevice = InputManager.DeviceType.TOUCH
		touchEnabled = true
		return activeDevice
	end
	
	-- Check for gamepad
	local gamepads = UserInputService:GetGamepadConnected()
	if #gamepads > 0 or gamepadConnected then
		activeDevice = InputManager.DeviceType.GAMEPAD
		gamepadConnected = true
		if #gamepads > 0 then
			activeGamepad = gamepads[1]
		end
		return activeDevice
	end
	
	-- Default to keyboard/mouse
	activeDevice = InputManager.DeviceType.KEYBOARD_MOUSE
	return activeDevice
end

function InputManager.getActiveDevice()
	return activeDevice
end

function InputManager.isKeyboardMouse()
	return activeDevice == InputManager.DeviceType.KEYBOARD_MOUSE
end

function InputManager.isGamepad()
	return activeDevice == InputManager.DeviceType.GAMEPAD
end

function InputManager.isTouch()
	return activeDevice == InputManager.DeviceType.TOUCH
end

function InputManager.isVR()
	return activeDevice == InputManager.DeviceType.VR
end

function InputManager.getActiveGamepad()
	return activeGamepad
end

--------------------------------------------------------------------------------
-- BINDING MANAGEMENT
--------------------------------------------------------------------------------

function InputManager.getBinding(action)
	if bindings[action] then
		return bindings[action]
	end
	
	-- Return default binding for current device
	local deviceBindings = DEFAULT_BINDINGS[activeDevice]
	if deviceBindings then
		return deviceBindings[action]
	end
	
	return nil
end

function InputManager.setBinding(action, inputs)
	bindings[action] = inputs
end

function InputManager.resetBindings()
	bindings = {}
end

function InputManager.getDefaultBindings()
	return DEFAULT_BINDINGS[activeDevice]
end

--------------------------------------------------------------------------------
-- ACTION STATE
--------------------------------------------------------------------------------

function InputManager.isActionActive(action)
	return actionStates[action] == true
end

function InputManager.setActionState(action, active)
	local wasActive = actionStates[action]
	actionStates[action] = active
	
	-- Trigger callbacks if state changed
	if wasActive ~= active and actionCallbacks[action] then
		for _, callback in ipairs(actionCallbacks[action]) do
			task.spawn(callback, active)
		end
	end
end

--------------------------------------------------------------------------------
-- CALLBACKS
--------------------------------------------------------------------------------

function InputManager.bindAction(action, callback)
	if not actionCallbacks[action] then
		actionCallbacks[action] = {}
	end
	table.insert(actionCallbacks[action], callback)
end

function InputManager.bindAxis(axisName, callback)
	axisCallbacks[axisName] = callback
end

function InputManager.unbindAction(action, callback)
	if not actionCallbacks[action] then return end
	
	for i, cb in ipairs(actionCallbacks[action]) do
		if cb == callback then
			table.remove(actionCallbacks[action], i)
			break
		end
	end
end

--------------------------------------------------------------------------------
-- INPUT PROCESSING
--------------------------------------------------------------------------------

local function processKeyboardMouseInput(input, isPressed)
	-- Check all actions for matching input
	for action, inputs in pairs(DEFAULT_BINDINGS[InputManager.DeviceType.KEYBOARD_MOUSE]) do
		for _, boundInput in ipairs(inputs) do
			if input.KeyCode == boundInput or input.UserInputType == boundInput then
				InputManager.setActionState(action, isPressed)
			end
		end
	end
end

local function processGamepadInput(input, isPressed)
	-- Check all actions for matching input
	for action, inputs in pairs(DEFAULT_BINDINGS[InputManager.DeviceType.GAMEPAD]) do
		for _, boundInput in ipairs(inputs) do
			if input.KeyCode == boundInput then
				InputManager.setActionState(action, isPressed)
				lastGamepadInput = tick()
			end
		end
	end
end

local function processGamepadAxis()
	if not gamepadConnected or not activeGamepad then return end
	
	-- Left stick (movement)
	local leftStick = UserInputService:GetGamepadState(activeGamepad)
	local moveX = 0
	local moveY = 0
	
	for _, input in ipairs(leftStick) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			moveX = input.Position.X
			moveY = -input.Position.Y -- Invert Y for forward/backward
			
			-- Apply deadzone
			local magnitude = math.sqrt(moveX * moveX + moveY * moveY)
			if magnitude < 0.15 then
				moveX = 0
				moveY = 0
			end
			
			if axisCallbacks["Movement"] then
				axisCallbacks["Movement"](Vector2.new(moveX, moveY))
			end
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			-- Right stick (look)
			local lookX = input.Position.X
			local lookY = input.Position.Y
			
			-- Apply deadzone
			local magnitude = math.sqrt(lookX * lookX + lookY * lookY)
			if magnitude < 0.15 then
				lookX = 0
				lookY = 0
			end
			
			if axisCallbacks["Look"] then
				axisCallbacks["Look"](Vector2.new(lookX, lookY))
			end
		end
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function InputManager.initialize()
	if initialized then return end
	initialized = true
	
	-- Detect initial device
	InputManager.detectDevice()
	
	-- Input began
	connections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		if activeDevice == InputManager.DeviceType.KEYBOARD_MOUSE then
			processKeyboardMouseInput(input, true)
		elseif activeDevice == InputManager.DeviceType.GAMEPAD then
			processGamepadInput(input, true)
		end
	end)
	
	-- Input ended
	connections.inputEnded = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		
		if activeDevice == InputManager.DeviceType.KEYBOARD_MOUSE then
			processKeyboardMouseInput(input, false)
		elseif activeDevice == InputManager.DeviceType.GAMEPAD then
			processGamepadInput(input, false)
		end
	end)
	
	-- Gamepad connected
	connections.gamepadConnected = UserInputService.GamepadConnected:Connect(function(gamepad)
		gamepadConnected = true
		activeGamepad = gamepad
		-- Switch to gamepad if not VR
		if not vrEnabled then
			activeDevice = InputManager.DeviceType.GAMEPAD
		end
	end)
	
	-- Gamepad disconnected
	connections.gamepadDisconnected = UserInputService.GamepadDisconnected:Connect(function(gamepad)
		if gamepad == activeGamepad then
			activeGamepad = nil
		end
		
		local gamepads = UserInputService:GetGamepadConnected()
		if #gamepads == 0 then
			gamepadConnected = false
			-- Switch back to keyboard/mouse or touch
			if touchEnabled then
				activeDevice = InputManager.DeviceType.TOUCH
			else
				activeDevice = InputManager.DeviceType.KEYBOARD_MOUSE
			end
		else
			activeGamepad = gamepads[1]
		end
	end)
	
	-- Process gamepad axis input continuously
	connections.renderStepped = RunService.RenderStepped:Connect(function()
		if activeDevice == InputManager.DeviceType.GAMEPAD or activeDevice == InputManager.DeviceType.VR then
			processGamepadAxis()
		end
	end)
	
	-- Auto-switch device based on last input
	connections.inputChanged = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			if not vrEnabled and activeDevice ~= InputManager.DeviceType.GAMEPAD then
				activeDevice = InputManager.DeviceType.GAMEPAD
				lastGamepadInput = tick()
			end
		end
	end)
	
	print("[InputManager] Initialized - Active device:", activeDevice)
end

function InputManager.cleanup()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	initialized = false
end

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

-- Get movement vector from current input state
function InputManager.getMovementVector()
	if activeDevice == InputManager.DeviceType.GAMEPAD or activeDevice == InputManager.DeviceType.VR then
		-- Movement is handled via axis callbacks for gamepad/VR
		return Vector2.new(0, 0)
	end
	
	local x = 0
	local y = 0
	
	if InputManager.isActionActive(InputManager.Action.MOVE_FORWARD) then
		y = y + 1
	end
	if InputManager.isActionActive(InputManager.Action.MOVE_BACKWARD) then
		y = y - 1
	end
	if InputManager.isActionActive(InputManager.Action.MOVE_LEFT) then
		x = x - 1
	end
	if InputManager.isActionActive(InputManager.Action.MOVE_RIGHT) then
		x = x + 1
	end
	
	return Vector2.new(x, y)
end

-- Get action display name for UI
function InputManager.getActionDisplayName(action)
	local binding = InputManager.getBinding(action)
	if not binding or #binding == 0 then return "Unbound" end
	
	local firstInput = binding[1]
	if typeof(firstInput) == "EnumItem" then
		-- Convert enum to readable string
		local name = tostring(firstInput):match("%.(.+)$") or tostring(firstInput)
		-- Format name (ButtonA -> A, MouseButton1 -> LMB, etc.)
		name = name:gsub("Button", "")
		name = name:gsub("MouseButton1", "LMB")
		name = name:gsub("MouseButton2", "RMB")
		name = name:gsub("LeftShift", "Shift")
		name = name:gsub("LeftControl", "Ctrl")
		return name
	elseif type(firstInput) == "string" then
		return firstInput
	end
	
	return "Unknown"
end

-- Check if GuiInset should be used (for safe area on mobile)
function InputManager.shouldUseGuiInset()
	return activeDevice == InputManager.DeviceType.TOUCH
end

return InputManager
