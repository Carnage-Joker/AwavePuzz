-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
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
		-- Buttons (axis handled separately)
		[InputManager.Action.SPRINT] = {Enum.KeyCode.ButtonL3},
		[InputManager.Action.CROUCH] = {Enum.KeyCode.ButtonB},
		[InputManager.Action.JUMP] = {Enum.KeyCode.ButtonA},

		[InputManager.Action.FIRE] = {Enum.KeyCode.ButtonR2},
		[InputManager.Action.AIM] = {Enum.KeyCode.ButtonL2},
		[InputManager.Action.RELOAD] = {Enum.KeyCode.ButtonX},
		[InputManager.Action.SWITCH_WEAPON] = {Enum.KeyCode.ButtonY},
		[InputManager.Action.NEXT_WEAPON] = {Enum.KeyCode.ButtonR1},
		[InputManager.Action.PREV_WEAPON] = {Enum.KeyCode.ButtonL1},

		[InputManager.Action.INTERACT] = {Enum.KeyCode.ButtonX},
		[InputManager.Action.USE] = {Enum.KeyCode.ButtonA},

		[InputManager.Action.MENU] = {Enum.KeyCode.ButtonStart},
		[InputManager.Action.PAUSE] = {Enum.KeyCode.ButtonStart},
		[InputManager.Action.SCOREBOARD] = {Enum.KeyCode.ButtonSelect},
		[InputManager.Action.INVENTORY] = {Enum.KeyCode.DPadUp},
		[InputManager.Action.MAP] = {Enum.KeyCode.DPadDown},
	},

	[InputManager.DeviceType.TOUCH] = {
		-- Virtual mappings (your touch UI should drive these)
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
local actionStates = {}
local actionCallbacks = {}
local axisCallbacks = {}
local connections = {}
local initialized = false

local gamepadConnected = false
local touchEnabled = false
local vrEnabled = false

local GAMEPAD_ENUM = Enum.UserInputType.Gamepad1
local DEADZONE = 0.15

local function getConnectedGamepads()
	-- Returns array of Enum.UserInputType.Gamepad1..Gamepad8
	return UserInputService:GetConnectedGamepads()
end

--------------------------------------------------------------------------------
-- DEVICE DETECTION
--------------------------------------------------------------------------------

function InputManager.detectDevice()
	-- VR first
	if UserInputService.VREnabled then
		activeDevice = InputManager.DeviceType.VR
		vrEnabled = true
		return activeDevice
	end

	-- Touch (mobile/tablet)
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		activeDevice = InputManager.DeviceType.TOUCH
		touchEnabled = true
		return activeDevice
	end

	-- Gamepad
	local pads = getConnectedGamepads()
	if #pads > 0 or gamepadConnected then
		activeDevice = InputManager.DeviceType.GAMEPAD
		gamepadConnected = true
		return activeDevice
	end

	-- Default
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

--------------------------------------------------------------------------------
-- BINDING MANAGEMENT
--------------------------------------------------------------------------------

function InputManager.getBinding(action)
	if bindings[action] then
		return bindings[action]
	end

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

local function getBindingsForDevice(deviceType)
	-- Custom bindings override defaults
	local defaults = DEFAULT_BINDINGS[deviceType] or {}
	return defaults
end

local function processKeyboardMouseInput(input, isPressed)
	for action, inputs in pairs(getBindingsForDevice(InputManager.DeviceType.KEYBOARD_MOUSE)) do
		for _, boundInput in ipairs(inputs) do
			if (input.KeyCode and input.KeyCode == boundInput) or (input.UserInputType and input.UserInputType == boundInput) then
				InputManager.setActionState(action, isPressed)
			end
		end
	end
end

local function processGamepadButtonInput(input, isPressed)
	for action, inputs in pairs(getBindingsForDevice(InputManager.DeviceType.GAMEPAD)) do
		for _, boundInput in ipairs(inputs) do
			if input.KeyCode == boundInput then
				InputManager.setActionState(action, isPressed)
			end
		end
	end
end

local function applyDeadzone(x, y)
	local mag = math.sqrt(x * x + y * y)
	if mag < DEADZONE then
		return 0, 0
	end
	return x, y
end

local function processGamepadAxis()
	-- Only read axis when gamepad is active-ish
	if not gamepadConnected and #getConnectedGamepads() == 0 then
		return
	end

	local state = UserInputService:GetGamepadState(GAMEPAD_ENUM)
	local moveX, moveY = 0, 0
	local lookX, lookY = 0, 0
	local hasMove, hasLook = false, false

	for _, gp in ipairs(state) do
		if gp.KeyCode == Enum.KeyCode.Thumbstick1 then
			moveX, moveY = applyDeadzone(gp.Position.X, -gp.Position.Y)
			hasMove = true
		elseif gp.KeyCode == Enum.KeyCode.Thumbstick2 then
			lookX, lookY = applyDeadzone(gp.Position.X, gp.Position.Y)
			hasLook = true
		end
	end

	if hasMove and axisCallbacks["Movement"] then
		axisCallbacks["Movement"](Vector2.new(moveX, moveY))
	end
	if hasLook and axisCallbacks["Look"] then
		axisCallbacks["Look"](Vector2.new(lookX, lookY))
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function InputManager.initialize()
	if initialized then return end
	initialized = true

	InputManager.detectDevice()

	connections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		-- Device auto-switch (simple + robust)
		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			gamepadConnected = true
			if not vrEnabled then
				activeDevice = InputManager.DeviceType.GAMEPAD
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				touchEnabled = true
				activeDevice = InputManager.DeviceType.TOUCH
			end
		elseif input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.Keyboard then
			if not vrEnabled and not touchEnabled then
				activeDevice = InputManager.DeviceType.KEYBOARD_MOUSE
			end
		end

		if activeDevice == InputManager.DeviceType.KEYBOARD_MOUSE then
			processKeyboardMouseInput(input, true)
		elseif activeDevice == InputManager.DeviceType.GAMEPAD or activeDevice == InputManager.DeviceType.VR then
			processGamepadButtonInput(input, true)
		end
	end)

	connections.inputEnded = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end

		if activeDevice == InputManager.DeviceType.KEYBOARD_MOUSE then
			processKeyboardMouseInput(input, false)
		elseif activeDevice == InputManager.DeviceType.GAMEPAD or activeDevice == InputManager.DeviceType.VR then
			processGamepadButtonInput(input, false)
		end
	end)

	connections.gamepadConnected = UserInputService.GamepadConnected:Connect(function()
		gamepadConnected = true
		if not vrEnabled then
			activeDevice = InputManager.DeviceType.GAMEPAD
		end
	end)

	connections.gamepadDisconnected = UserInputService.GamepadDisconnected:Connect(function()
		local pads = getConnectedGamepads()
		gamepadConnected = (#pads > 0)

		if not gamepadConnected then
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				touchEnabled = true
				activeDevice = InputManager.DeviceType.TOUCH
			else
				activeDevice = InputManager.DeviceType.KEYBOARD_MOUSE
			end
		end
	end)

	connections.renderStepped = RunService.RenderStepped:Connect(function()
		if activeDevice == InputManager.DeviceType.GAMEPAD or activeDevice == InputManager.DeviceType.VR then
			processGamepadAxis()
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

function InputManager.getMovementVector()
	-- For gamepad/VR, movement should come via axis callback into your controller.
	if activeDevice == InputManager.DeviceType.GAMEPAD or activeDevice == InputManager.DeviceType.VR then
		return Vector2.new(0, 0)
	end

	local x, y = 0, 0
	if InputManager.isActionActive(InputManager.Action.MOVE_FORWARD) then y = y + 1 end
	if InputManager.isActionActive(InputManager.Action.MOVE_BACKWARD) then y = y - 1 end
	if InputManager.isActionActive(InputManager.Action.MOVE_LEFT) then x = x - 1 end
	if InputManager.isActionActive(InputManager.Action.MOVE_RIGHT) then x = x + 1 end

	return Vector2.new(x, y)
end

function InputManager.getActionDisplayName(action)
	local binding = InputManager.getBinding(action)
	if not binding or #binding == 0 then return "Unbound" end

	local firstInput = binding[1]
	if typeof(firstInput) == "EnumItem" then
		local name = tostring(firstInput):match("%.(.+)$") or tostring(firstInput)
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

function InputManager.shouldUseGuiInset()
	return activeDevice == InputManager.DeviceType.TOUCH
end

return InputManager
