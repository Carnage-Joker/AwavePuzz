-- @ScriptType: Script
-- FirstPersonCamera.lua (ModuleScript)
-- First-person camera controller
--
-- Features:
-- - First-person camera with mouse lock, FOV transitions, and look smoothing
-- - Character transparency management (hides body in first-person)
-- - Configurable sensitivity, FOV, and mouse smoothing
-- - Recoil application support
-- - Sprint and ADS FOV transitions

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local VRService = game:GetService("VRService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local MathUtil = require(SharedFolder:WaitForChild("MathUtil"))
local InputManager = require(SharedFolder:WaitForChild("InputManager"))

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local FirstPersonCamera = {}
FirstPersonCamera.__index = FirstPersonCamera

-- Camera state
local currentFOV = FPSConfig.Camera.DefaultFOV
local targetFOV = FPSConfig.Camera.DefaultFOV
local sensitivity = FPSConfig.Camera.DefaultSensitivity
local invertY = FPSConfig.Camera.InvertY

-- Look state
local lookAngles = Vector2.new(0, 0) -- X = yaw, Y = pitch
local smoothedLookDelta = Vector2.new(0, 0)

-- Character state
local isSprinting = false
local isADS = false
local isCrouching = false
local isGrounded = true

-- Input state
local mouseLocked = true
local isMenuOpen = false

-- Device state
local deviceType = "KeyboardMouse"
local isVRMode = false
local gamepadLookVector = Vector2.new(0, 0)

-- Character parts to hide
local hiddenParts = {}
local originalTransparency = {}

-- Initialization state
local initialized = false
local renderStepConnection = nil

--------------------------------------------------------------------------------
-- USER SETTINGS (can be modified at runtime)
--------------------------------------------------------------------------------

local userSettings = {
	sensitivity = FPSConfig.Camera.DefaultSensitivity,
	invertY = FPSConfig.Camera.InvertY,
	fov = FPSConfig.Camera.DefaultFOV,
	mouseSmoothing = FPSConfig.Camera.MouseSmoothing,
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

-- Use shared utility functions
local clamp = MathUtil.clamp
local lerp = MathUtil.lerp

--------------------------------------------------------------------------------
-- CHARACTER TRANSPARENCY
--------------------------------------------------------------------------------

local function hideCharacterParts(character)
	if not character then return end
	
	-- Store original transparency and hide parts
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Don't hide the HumanoidRootPart (needed for physics)
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
	for _, part in ipairs(hiddenParts) do
		if part and part.Parent then
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = originalTransparency[part] or 0
			elseif part:IsA("Decal") or part:IsA("Texture") then
				part.Transparency = originalTransparency[part] or 0
			end
		end
	end
	hiddenParts = {}
	originalTransparency = {}
end

--------------------------------------------------------------------------------
-- MOUSE LOCK
--------------------------------------------------------------------------------

local function lockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	mouseLocked = true
end

local function unlockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	mouseLocked = false
end

--------------------------------------------------------------------------------
-- CAMERA SETUP
--------------------------------------------------------------------------------

local function setupCamera()
	if not camera then
		camera = workspace.CurrentCamera
	end
	
	camera.CameraType = Enum.CameraType.Scriptable
	currentFOV = userSettings.fov
	targetFOV = userSettings.fov
	camera.FieldOfView = currentFOV
	
	lockMouse()
end

local function resetCamera()
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
	end
	
	unlockMouse()
	showCharacterParts()
end

--------------------------------------------------------------------------------
-- FOV MANAGEMENT
--------------------------------------------------------------------------------

local function setTargetFOV(fov)
	targetFOV = clamp(fov, FPSConfig.Camera.MinFOV, FPSConfig.Camera.MaxFOV)
end

local function updateFOV(deltaTime)
	-- Determine target FOV based on state
	local desiredFOV = userSettings.fov
	
	if isADS then
		desiredFOV = FPSConfig.Camera.ADSFOV
	elseif isSprinting then
		desiredFOV = FPSConfig.Camera.SprintFOV
	end
	
	targetFOV = desiredFOV
	
	-- Smooth FOV transition
	local speed = FPSConfig.Camera.FOVTransitionSpeed * deltaTime
	currentFOV = lerp(currentFOV, targetFOV, speed)
	camera.FieldOfView = currentFOV
end

--------------------------------------------------------------------------------
-- LOOK INPUT
--------------------------------------------------------------------------------

local function processLookInput(deltaTime)
	if not mouseLocked or isMenuOpen then
		return Vector2.new(0, 0)
	end
	
	local delta = Vector2.new(0, 0)
	
	-- VR mode: Use head tracking
	if isVRMode and UserInputService.VREnabled then
		local headCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
		local headRotation = headCFrame.Rotation
		
		-- Extract yaw and pitch from VR headset rotation
		local _, yaw, _ = headRotation:ToEulerAnglesYXZ()
		local pitch, _, _ = headRotation:ToEulerAnglesXYZ()
		
		-- Update look angles directly from VR headset
		lookAngles = Vector2.new(math.deg(yaw), math.deg(pitch))
		
		-- Don't apply sensitivity or smoothing in VR - use direct head tracking
		return Vector2.new(0, 0)
	end
	
	-- Gamepad mode: Use right stick
	if deviceType == "Gamepad" or deviceType == "VR" then
		-- Gamepad look is updated via InputManager callback
		local gamepadSens = FPSConfig.getSensitivityForDevice("Gamepad")
		delta = gamepadLookVector * gamepadSens * 50 * deltaTime
		
		-- Apply deadzone
		if delta.Magnitude < 0.1 then
			delta = Vector2.new(0, 0)
		end
	else
		-- Keyboard/Mouse mode: Use mouse delta
		delta = UserInputService:GetMouseDelta()
		
		-- Apply sensitivity
		local sens = userSettings.sensitivity * 0.5
		delta = delta * sens
	end
	
	-- Apply invert Y
	if userSettings.invertY then
		delta = Vector2.new(delta.X, -delta.Y)
	end
	
	-- Apply mouse smoothing if enabled (not for gamepad/VR)
	if userSettings.mouseSmoothing and deviceType == "KeyboardMouse" then
		local smoothFactor = FPSConfig.Camera.SmoothingFactor
		smoothedLookDelta = smoothedLookDelta:Lerp(delta, 1 - smoothFactor)
		delta = smoothedLookDelta
	end
	
	return delta
end

local function updateLookAngles(delta)
	-- Update yaw (horizontal rotation) - no clamping needed
	lookAngles = Vector2.new(
		lookAngles.X - delta.X,
		clamp(lookAngles.Y - delta.Y, -89, 89) -- Clamp pitch to prevent flipping
	)
end

--------------------------------------------------------------------------------
-- CAMERA UPDATE
--------------------------------------------------------------------------------

local function updateCamera(deltaTime)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	local head = character:FindFirstChild("Head")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not head or not rootPart then return end
	
	-- Process mouse input
	local lookDelta = processLookInput(deltaTime)
	updateLookAngles(lookDelta)
	
	-- Calculate camera CFrame
	local cameraOffset = FPSConfig.Camera.FirstPersonOffset
	local cameraPosition = head.Position + cameraOffset
	
	-- Create rotation from look angles
	local rotation = CFrame.Angles(0, math.rad(lookAngles.X), 0) * 
	                 CFrame.Angles(math.rad(lookAngles.Y), 0, 0)
	
	-- Set camera CFrame
	camera.CFrame = CFrame.new(cameraPosition) * rotation
	
	-- Update character rotation to match yaw
	rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(lookAngles.X), 0)
	
	-- Update FOV
	updateFOV(deltaTime)
end

--------------------------------------------------------------------------------
-- STATE UPDATES (called from other systems)
--------------------------------------------------------------------------------

function FirstPersonCamera.setADS(ads)
	isADS = ads
end

function FirstPersonCamera.setSprinting(sprinting)
	isSprinting = sprinting
end

function FirstPersonCamera.setCrouching(crouching)
	isCrouching = crouching
end

function FirstPersonCamera.setGrounded(grounded)
	isGrounded = grounded
end

function FirstPersonCamera.setMenuOpen(open)
	isMenuOpen = open
	if open then
		unlockMouse()
	else
		lockMouse()
	end
end

--------------------------------------------------------------------------------
-- SETTINGS
--------------------------------------------------------------------------------

function FirstPersonCamera.setSensitivity(sens)
	userSettings.sensitivity = clamp(sens, FPSConfig.Camera.MinSensitivity, FPSConfig.Camera.MaxSensitivity)
end

function FirstPersonCamera.setInvertY(invert)
	userSettings.invertY = invert
end

function FirstPersonCamera.setFOV(fov)
	userSettings.fov = clamp(fov, FPSConfig.Camera.MinFOV, FPSConfig.Camera.MaxFOV)
end

function FirstPersonCamera.setMouseSmoothing(enabled)
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
-- RECOIL APPLICATION (called from weapon system)
--------------------------------------------------------------------------------

function FirstPersonCamera.applyRecoil(verticalDegrees, horizontalDegrees)
	-- Apply recoil to look angles
	lookAngles = Vector2.new(
		lookAngles.X + horizontalDegrees,
		clamp(lookAngles.Y + verticalDegrees, -89, 89)
	)
end

--------------------------------------------------------------------------------
-- GET LOOK DIRECTION (for aiming/shooting)
--------------------------------------------------------------------------------

function FirstPersonCamera.getLookDirection()
	return camera.CFrame.LookVector
end

function FirstPersonCamera.getLookCFrame()
	return camera.CFrame
end

function FirstPersonCamera.getLookAngles()
	return lookAngles
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

function FirstPersonCamera.onCharacterAdded(character)
	-- Wait for character to load
	character:WaitForChild("Head")
	character:WaitForChild("HumanoidRootPart")
	
	-- Reset look angles
	lookAngles = Vector2.new(0, 0)
	
	-- Hide character parts for first person view
	hideCharacterParts(character)
	
	-- Setup camera
	setupCamera()
	
	-- Connect humanoid events
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			showCharacterParts()
		end)
	end
	
	-- Re-hide parts when new accessories/tools are added
	character.DescendantAdded:Connect(function(descendant)
		task.wait() -- Wait for properties to be set
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			originalTransparency[descendant] = descendant.LocalTransparencyModifier
			descendant.LocalTransparencyModifier = 1
			table.insert(hiddenParts, descendant)
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			originalTransparency[descendant] = descendant.Transparency
			descendant.Transparency = 1
			table.insert(hiddenParts, descendant)
		end
	end)
end

function FirstPersonCamera.onCharacterRemoving()
	showCharacterParts()
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function FirstPersonCamera.initialize()
	if initialized then
		warn("[FirstPersonCamera] Already initialized")
		return
	end
	
	-- Initialize InputManager
	InputManager.initialize()
	
	-- Detect device type
	deviceType = InputManager.getActiveDevice()
	isVRMode = InputManager.isVR()
	
	-- Set appropriate sensitivity for device
	local deviceSens = FPSConfig.getSensitivityForDevice(deviceType)
	userSettings.sensitivity = deviceSens
	
	-- Setup InputManager callbacks for gamepad/VR look
	InputManager.bindAxis("Look", function(lookVector)
		gamepadLookVector = lookVector
	end)
	
	-- VR-specific setup
	if isVRMode then
		print("[FirstPersonCamera] VR mode enabled")
		local vrSettings = FPSConfig.Device.VR
		
		-- Apply VR-specific camera settings
		if vrSettings.VRCameraSmoothing then
			userSettings.mouseSmoothing = true
			FPSConfig.Camera.SmoothingFactor = vrSettings.VRCameraSmoothing
		end
		
		-- Set VR UI distance if needed
		-- (VR UI positioning would be handled by UI scripts)
	end
	
	-- Setup camera when character exists
	if player.Character then
		FirstPersonCamera.onCharacterAdded(player.Character)
	end
	
	-- Main update loop
	renderStepConnection = RunService:BindToRenderStep("FirstPersonCamera", Enum.RenderPriority.Camera.Value, function(deltaTime)
		updateCamera(deltaTime)
	end)
	
	-- Handle window focus (only for desktop)
	if deviceType == "KeyboardMouse" then
		UserInputService.WindowFocused:Connect(function()
			if not isMenuOpen then
				lockMouse()
			end
		end)
		
		UserInputService.WindowFocusReleased:Connect(function()
			-- Don't unlock on focus loss to prevent camera issues
		end)
	end
	
	initialized = true
	print("[FirstPersonCamera] Initialized - Device:", deviceType)
end

-- Cleanup function
function FirstPersonCamera.cleanup()
	if renderStepConnection then
		RunService:UnbindFromRenderStep("FirstPersonCamera")
		renderStepConnection = nil
	end
	resetCamera()
	initialized = false
end

return FirstPersonCamera
