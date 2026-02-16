--!strict
-- @ScriptType: ModuleScript
-- FirstPersonCamera.lua (ModuleScript)
-- Production-solid first-person camera controller
--
-- Key fixes vs your version:
-- - Proper lifecycle: Init / Bind / Unbind / Disconnect all connections
-- - No reliance on BindToRenderStep return value (it returns nothing)
-- - Robust respawn handling (character connections cleaned up)
-- - VR yaw/pitch extracted consistently
-- - Head-relative camera offset
-- - Framerate-independent smoothing
-- - Safe mouse lock toggling + state guards

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VRService = game:GetService("VRService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local MathUtil = require(SharedFolder:WaitForChild("MathUtil"))
local InputManager = require(SharedFolder:WaitForChild("InputManager"))
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))

local clamp = MathUtil.clamp
local lerp = MathUtil.lerp

type Conn = RBXScriptConnection

local FirstPersonCamera = {}
FirstPersonCamera.__index = FirstPersonCamera

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local initialized = false
local bound = false

-- user settings (runtime adjustable)
local userSettings = {
	sensitivity = FPSConfig.Camera.DefaultSensitivity,
	invertY = FPSConfig.Camera.InvertY,
	fov = FPSConfig.Camera.DefaultFOV,
	mouseSmoothing = FPSConfig.Camera.MouseSmoothing,
}

-- camera state
local currentFOV = userSettings.fov
local targetFOV = userSettings.fov

-- look state (degrees)
local lookAngles = Vector2.new(0, 0) -- X=yaw, Y=pitch
local smoothedLookDelta = Vector2.new(0, 0)

-- gameplay state
local isSprinting = false
local isADS = false
local isCrouching = false
local isGrounded = true
local isMenuOpen = false

-- device state
local deviceType = "KeyboardMouse"
local isVRMode = false
local gamepadLookVector = Vector2.new(0, 0)

-- transparency state
local hiddenParts: {Instance} = {}
local originalTransparency: {[Instance]: number} = {}

-- connection management
local globalConnections: {Conn} = {}
local characterConnections: {Conn} = {}

-- renderstep name
local RENDERSTEP_NAME = "FirstPersonCamera"

--------------------------------------------------------------------------------
-- INTERNAL: CONNECTION UTILS
--------------------------------------------------------------------------------

local function disconnectAll(list: {Conn})
	for _, c in ipairs(list) do
		if c.Connected then
			c:Disconnect()
		end
	end
	table.clear(list)
end

local function bindConn(list: {Conn}, c: Conn)
	table.insert(list, c)
end

--------------------------------------------------------------------------------
-- CHARACTER TRANSPARENCY
--------------------------------------------------------------------------------

local function hideCharacterParts(character: Model)
	-- Clear any previous cached parts first (in case of mis-order)
	for _, inst in ipairs(hiddenParts) do
		if inst and inst.Parent then
			if inst:IsA("BasePart") then
				inst.LocalTransparencyModifier = originalTransparency[inst] or 0
			elseif inst:IsA("Decal") or inst:IsA("Texture") then
				inst.Transparency = originalTransparency[inst] or 0
			end
		end
	end
	table.clear(hiddenParts)
	table.clear(originalTransparency)

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name ~= "HumanoidRootPart" then
				originalTransparency[descendant] = descendant.LocalTransparencyModifier
				descendant.LocalTransparencyModifier = 1
				table.insert(hiddenParts, descendant)
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			originalTransparency[descendant] = descendant.Transparency
			descendant.Transparency = 1
			table.insert(hiddenParts, descendant)
		end
	end
end

local function showCharacterParts()
	for _, inst in ipairs(hiddenParts) do
		if inst and inst.Parent then
			if inst:IsA("BasePart") then
				inst.LocalTransparencyModifier = originalTransparency[inst] or 0
			elseif inst:IsA("Decal") or inst:IsA("Texture") then
				inst.Transparency = originalTransparency[inst] or 0
			end
		end
	end
	table.clear(hiddenParts)
	table.clear(originalTransparency)
end

--------------------------------------------------------------------------------
-- MOUSE LOCK
--------------------------------------------------------------------------------

local function lockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function unlockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function applyMouseLockForState()
	if isMenuOpen then
		unlockMouse()
	else
		lockMouse()
	end
end

--------------------------------------------------------------------------------
-- CAMERA SETUP / RESET
--------------------------------------------------------------------------------

local function ensureCamera()
	if not camera then
		camera = workspace.CurrentCamera
	end
end

local function setupCamera()
	ensureCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	currentFOV = userSettings.fov
	targetFOV = userSettings.fov
	camera.FieldOfView = currentFOV
	applyMouseLockForState()
end

local function resetCamera()
	ensureCamera()
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	unlockMouse()
	showCharacterParts()
end

--------------------------------------------------------------------------------
-- FOV MANAGEMENT
--------------------------------------------------------------------------------

local function updateFOV(dt: number)
	local desiredFOV = userSettings.fov
	if isADS then
		desiredFOV = FPSConfig.Camera.ADSFOV
	elseif isSprinting then
		desiredFOV = FPSConfig.Camera.SprintFOV
	end

	targetFOV = clamp(desiredFOV, FPSConfig.Camera.MinFOV, FPSConfig.Camera.MaxFOV)

	-- smooth transition (lerp speed scales with dt)
	local speed = FPSConfig.Camera.FOVTransitionSpeed * dt
	currentFOV = lerp(currentFOV, targetFOV, speed)
	camera.FieldOfView = currentFOV
end

--------------------------------------------------------------------------------
-- LOOK INPUT
--------------------------------------------------------------------------------

local function getLookDelta(dt: number): Vector2
	-- Block camera input when menus are open or modal is active
	if isMenuOpen or ModalManager.shouldBlockGameplay() then
		return Vector2.zero
	end

	-- VR head tracking (direct angles; no delta)
	if isVRMode and UserInputService.VREnabled then
		local headCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
		local rot = headCFrame.Rotation
		local pitch, yaw, _ = rot:ToEulerAnglesYXZ()
		lookAngles = Vector2.new(math.deg(yaw), math.deg(pitch))
		return Vector2.zero
	end

	-- Gamepad/VR stick look
	if deviceType == "Gamepad" or deviceType == "VR" then
		local gamepadSens = FPSConfig.getSensitivityForDevice("Gamepad")
		local delta = gamepadLookVector * gamepadSens * 50 * dt
		if delta.Magnitude < 0.1 then
			return Vector2.zero
		end
		return delta
	end

	-- Mouse delta
	local delta = UserInputService:GetMouseDelta()
	local sens = userSettings.sensitivity * 0.5
	delta = delta * sens

	if userSettings.invertY then
		delta = Vector2.new(delta.X, -delta.Y)
	end

	-- Framerate-independent smoothing
	if userSettings.mouseSmoothing then
		local strength = FPSConfig.Camera.SmoothingStrength or 18 -- add this to FPSConfig if you want
		local alpha = 1 - math.exp(-strength * dt)
		smoothedLookDelta = smoothedLookDelta:Lerp(delta, alpha)
		return smoothedLookDelta
	end

	return delta
end

local function applyLookDelta(delta: Vector2)
	lookAngles = Vector2.new(
		lookAngles.X - delta.X,
		clamp(lookAngles.Y - delta.Y, -89, 89)
	)
end

--------------------------------------------------------------------------------
-- CAMERA UPDATE
--------------------------------------------------------------------------------

local function updateCamera(dt: number)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head") :: BasePart?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not humanoid or not root then return end
	if not head then
		-- fallback for edge cases
		head = root
	end

	-- input
	local lookDelta = getLookDelta(dt)
	if lookDelta ~= Vector2.zero then
		applyLookDelta(lookDelta)
	end

	-- head-relative camera position
	local offset = FPSConfig.Camera.FirstPersonOffset
	local cameraPos = (head.CFrame * CFrame.new(offset)).Position

	-- rotation: yaw then pitch (your original order kept)
	local rot = CFrame.Angles(0, math.rad(lookAngles.X), 0) * CFrame.Angles(math.rad(lookAngles.Y), 0, 0)

	ensureCamera()
	camera.CFrame = CFrame.new(cameraPos) * rot

	-- rotate character to match yaw (server-auth games may want to gate this)
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(lookAngles.X), 0)

	updateFOV(dt)
end

local function bindRenderStep()
	if bound then return end
	RunService:BindToRenderStep(RENDERSTEP_NAME, Enum.RenderPriority.Camera.Value, updateCamera)
	bound = true
end

local function unbindRenderStep()
	if not bound then return end
	RunService:UnbindFromRenderStep(RENDERSTEP_NAME)
	bound = false
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

local function onCharacterAdded(character: Model)
	disconnectAll(characterConnections)

	-- Reset angles per spawn
	lookAngles = Vector2.zero
	smoothedLookDelta = Vector2.zero

	-- Hide body in first person
	hideCharacterParts(character)
	setupCamera()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		bindConn(characterConnections, humanoid.Died:Connect(function()
			showCharacterParts()
		end))
	end

	-- Keep new accessories/tools hidden
	bindConn(characterConnections, character.DescendantAdded:Connect(function(desc)
		task.defer(function()
			-- only hide while we are controlling first-person
			if not initialized then return end
			if not player.Character or desc.Parent == nil then return end

			if desc:IsA("BasePart") then
				if desc.Name ~= "HumanoidRootPart" then
					originalTransparency[desc] = desc.LocalTransparencyModifier
					desc.LocalTransparencyModifier = 1
					table.insert(hiddenParts, desc)
				end
			elseif desc:IsA("Decal") or desc:IsA("Texture") then
				originalTransparency[desc] = desc.Transparency
				desc.Transparency = 1
				table.insert(hiddenParts, desc)
			end
		end)
	end))
end

local function onCharacterRemoving()
	disconnectAll(characterConnections)
	showCharacterParts()
end

--------------------------------------------------------------------------------
-- PUBLIC API: STATE UPDATES
--------------------------------------------------------------------------------

function FirstPersonCamera.setADS(ads: boolean)
	isADS = ads
end

function FirstPersonCamera.setSprinting(sprinting: boolean)
	isSprinting = sprinting
end

function FirstPersonCamera.setCrouching(crouching: boolean)
	isCrouching = crouching
end

function FirstPersonCamera.setGrounded(grounded: boolean)
	isGrounded = grounded
end

function FirstPersonCamera.setMenuOpen(open: boolean)
	isMenuOpen = open
	applyMouseLockForState()
end

--------------------------------------------------------------------------------
-- PUBLIC API: SETTINGS
--------------------------------------------------------------------------------

function FirstPersonCamera.setSensitivity(sens: number)
	userSettings.sensitivity = clamp(sens, FPSConfig.Camera.MinSensitivity, FPSConfig.Camera.MaxSensitivity)
end

function FirstPersonCamera.setInvertY(invert: boolean)
	userSettings.invertY = invert
end

function FirstPersonCamera.setFOV(fov: number)
	userSettings.fov = clamp(fov, FPSConfig.Camera.MinFOV, FPSConfig.Camera.MaxFOV)
end

function FirstPersonCamera.setMouseSmoothing(enabled: boolean)
	userSettings.mouseSmoothing = enabled
end

function FirstPersonCamera.getSettings()
	return {
		sensitivity = userSettings.sensitivity,
		invertY = userSettings.invertY,
		fov = userSettings.fov,
		mouseSmoothing = userSettings.mouseSmoothing,
	}
end

--------------------------------------------------------------------------------
-- PUBLIC API: RECOIL
--------------------------------------------------------------------------------

function FirstPersonCamera.applyRecoil(verticalDegrees: number, horizontalDegrees: number)
	lookAngles = Vector2.new(
		lookAngles.X + horizontalDegrees,
		clamp(lookAngles.Y + verticalDegrees, -89, 89)
	)
end

--------------------------------------------------------------------------------
-- PUBLIC API: LOOK INFO
--------------------------------------------------------------------------------

function FirstPersonCamera.getLookDirection()
	ensureCamera()
	return camera.CFrame.LookVector
end

function FirstPersonCamera.getLookCFrame()
	ensureCamera()
	return camera.CFrame
end

function FirstPersonCamera.getLookAngles()
	return lookAngles
end

--------------------------------------------------------------------------------
-- INITIALIZATION / CLEANUP
--------------------------------------------------------------------------------

function FirstPersonCamera.initialize()
	if initialized then
		warn("[FirstPersonCamera] Already initialized")
		return
	end
	initialized = true

	-- Input
	InputManager.initialize()
	deviceType = InputManager.getActiveDevice()
	isVRMode = InputManager.isVR()

	userSettings.sensitivity = FPSConfig.getSensitivityForDevice(deviceType)

	InputManager.bindAxis("Look", function(v: Vector2)
		gamepadLookVector = v
	end)

	-- Character lifecycle
	bindConn(globalConnections, player.CharacterAdded:Connect(onCharacterAdded))
	bindConn(globalConnections, player.CharacterRemoving:Connect(onCharacterRemoving))

	-- Window focus handling (desktop)
	if deviceType == "KeyboardMouse" then
		bindConn(globalConnections, UserInputService.WindowFocused:Connect(function()
			if not isMenuOpen then
				lockMouse()
			end
		end))
	end
	
	-- Listen for sprint state changes from movement controller
	-- This synchronizes FOV changes with sprint state
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	task.spawn(function()
		-- Guard: Only subscribe if still initialized
		if not initialized then return end
		
		local bindableFolder = playerGui:WaitForChild("BindableEvents", 5)
		if bindableFolder and initialized then
			local sprintEvent = bindableFolder:WaitForChild("SprintStateChanged", 2)
			if sprintEvent and sprintEvent:IsA("BindableEvent") and initialized then
				bindConn(globalConnections, sprintEvent.Event:Connect(function(sprinting)
					if initialized then
						isSprinting = sprinting
					end
				end))
			end
			
			local crouchEvent = bindableFolder:WaitForChild("CrouchStateChanged", 2)
			if crouchEvent and crouchEvent:IsA("BindableEvent") and initialized then
				bindConn(globalConnections, crouchEvent.Event:Connect(function(crouching)
					if initialized then
						isCrouching = crouching
					end
				end))
			end
		end
	end)

	-- Setup existing character
	if player.Character then
		onCharacterAdded(player.Character)
	end

	bindRenderStep()

	print(("[FirstPersonCamera] Initialized - Device: %s (VR=%s)"):format(deviceType, tostring(isVRMode)))
end

function FirstPersonCamera.cleanup()
	if not initialized then return end

	unbindRenderStep()
	disconnectAll(characterConnections)
	disconnectAll(globalConnections)

	resetCamera()

	initialized = false
	print("[FirstPersonCamera] Cleaned up")
end

return FirstPersonCamera
