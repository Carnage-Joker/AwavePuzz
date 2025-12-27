-- FPSMovementController.client.lua
-- First-person movement controller with crouch, sprint, and air control
-- Integrates with FirstPersonCamera for smooth movement-camera transitions
-- Updated with cross-platform InputManager support

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local MathUtil = require(SharedFolder:WaitForChild("MathUtil"))
local InputManager = require(SharedFolder:WaitForChild("InputManager"))

-- Wait for camera module (will be available after initialization)
local FirstPersonCamera = nil
task.spawn(function()
	-- Try to get the camera module from _G or wait for it
	task.wait(0.5)
	local success, cam = pcall(function()
		return require(player.PlayerScripts:WaitForChild("FirstPersonCamera.client", 5))
	end)
	if success then
		FirstPersonCamera = cam
	else
		-- Camera module runs as a separate script, communicate via events
		FirstPersonCamera = nil
	end
end)

--------------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------------

local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Create crouch event if it doesn't exist
local crouchEvent = remoteEventsFolder:FindFirstChild("CrouchUpdate")
if not crouchEvent then
	crouchEvent = Instance.new("RemoteEvent")
	crouchEvent.Name = "CrouchUpdate"
	crouchEvent.Parent = remoteEventsFolder
end

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local FPSMovementController = {}

-- internal bindable reference for stamina → HUD
FPSMovementController._staminaBindable = nil

-- Movement state
local isSprinting = false
local isCrouching = false
local isGrounded = true
local isMoving = false
local wantsToSprint = false
local wantsToCrouch = false

-- Stamina (synced with server but also tracked locally for responsiveness)
local currentStamina = FPSConfig.Movement.StaminaMax
local maxStamina = FPSConfig.Movement.StaminaMax

-- Movement keys held
local keysHeld = {
	forward = false,
	backward = false,
	left = false,
	right = false,
}

-- Gamepad/Touch movement vector (for analog input)
local movementVector = Vector2.new(0, 0)

-- Crouch animation state
local currentCrouchHeight = FPSConfig.Movement.StandHeight
local targetCrouchHeight = FPSConfig.Movement.StandHeight

-- Original humanoid values
local originalWalkSpeed = nil
local originalJumpPower = nil
local originalHipHeight = nil

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

-- Use shared utility functions
local lerp = MathUtil.lerp
local clamp = MathUtil.clamp

--------------------------------------------------------------------------------
-- GROUND CHECK
--------------------------------------------------------------------------------

local function checkGrounded(character)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoidRootPart or not humanoid then
		return true
	end

	-- Use humanoid floor material as primary check
	local floorMaterial = humanoid.FloorMaterial
	isGrounded = floorMaterial ~= Enum.Material.Air

	return isGrounded
end

--------------------------------------------------------------------------------
-- MOVEMENT SPEED CALCULATION
--------------------------------------------------------------------------------

local function calculateMoveSpeed(humanoid)
	local baseSpeed = FPSConfig.Movement.WalkSpeed

	-- Priority: Crouch > ADS > Sprint > Walk
	if isCrouching then
		return FPSConfig.Movement.CrouchSpeed
	end

	-- Note: ADS speed is handled by weapon controller

	if isSprinting and currentStamina > 0 then
		return FPSConfig.Movement.SprintSpeed
	end

	return baseSpeed
end

--------------------------------------------------------------------------------
-- SPRINT HANDLING
--------------------------------------------------------------------------------

local function updateSprint(deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if we can sprint
	-- For gamepad/touch: Check movement vector magnitude
	local isMovingForward = keysHeld.forward or (movementVector.Y > 0.2)
	
	local canSprint = wantsToSprint
		and isGrounded
		and isMoving
		and not isCrouching
		and currentStamina > 0
		and isMovingForward -- Only sprint when moving forward

	local wasSprinting = isSprinting
	isSprinting = canSprint

	-- Update camera FOV if sprint state changed
	if wasSprinting ~= isSprinting then
		-- Broadcast sprint state change via bindable if needed
		local sprintBindable = player.PlayerGui:FindFirstChild("BindableEvents")
		if sprintBindable then
			local sprintEvent = sprintBindable:FindFirstChild("SprintStateChanged")
			if sprintEvent then
				sprintEvent:Fire(isSprinting)
			end
		end
	end

	-- Local stamina prediction (server is authoritative)
	if isSprinting then
		currentStamina = math.max(0, currentStamina - FPSConfig.Movement.SprintStaminaDrain * deltaTime)
	end
end

--------------------------------------------------------------------------------
-- CROUCH HANDLING
--------------------------------------------------------------------------------

local function updateCrouch(deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Toggle crouch
	local wasCrouching = isCrouching
	isCrouching = wantsToCrouch

	-- Set target height
	targetCrouchHeight = isCrouching and FPSConfig.Movement.CrouchHeight or FPSConfig.Movement.StandHeight

	-- Smooth crouch transition
	local transitionSpeed = FPSConfig.Movement.CrouchTransitionSpeed * deltaTime
	currentCrouchHeight = lerp(currentCrouchHeight, targetCrouchHeight, transitionSpeed)

	-- Apply crouch height to humanoid
	humanoid.HipHeight = currentCrouchHeight

	-- Stop sprinting if crouching
	if isCrouching and isSprinting then
		isSprinting = false
	end

	-- Notify server of crouch state change
	if wasCrouching ~= isCrouching then
		crouchEvent:FireServer(isCrouching)
	end
end

--------------------------------------------------------------------------------
-- MOVEMENT UPDATE
--------------------------------------------------------------------------------

local function updateMovement(deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if player is moving
	isMoving = keysHeld.forward or keysHeld.backward or keysHeld.left or keysHeld.right

	-- Check grounded state
	checkGrounded(character)

	-- Update sprint and crouch
	updateSprint(deltaTime)
	updateCrouch(deltaTime)

	-- Calculate and apply move speed
	local moveSpeed = calculateMoveSpeed(humanoid)

	-- Air control could be tweaked here if needed

	humanoid.WalkSpeed = moveSpeed
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

-- Setup InputManager callbacks
local function setupInputCallbacks()
	-- Initialize InputManager
	InputManager.initialize()
	
	-- Sprint action
	InputManager.bindAction(InputManager.Action.SPRINT, function(active)
		wantsToSprint = active
	end)
	
	-- Crouch action (toggle)
	InputManager.bindAction(InputManager.Action.CROUCH, function(active)
		if active then
			wantsToCrouch = not wantsToCrouch
		end
	end)
	
	-- Jump action
	InputManager.bindAction(InputManager.Action.JUMP, function(active)
		if active then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and isGrounded then
					humanoid.Jump = true
				end
			end
		end
	end)
	
	-- Movement axis (for gamepad/touch)
	InputManager.bindAxis("Movement", function(vector)
		movementVector = vector
		
		-- Update key states based on analog input
		-- This allows the rest of the code to work with both digital and analog input
		keysHeld.forward = vector.Y > 0.2
		keysHeld.backward = vector.Y < -0.2
		keysHeld.left = vector.X < -0.2
		keysHeld.right = vector.X > 0.2
	end)
end

-- Legacy keyboard input handler (kept for compatibility)
local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	-- Movement keys (only for keyboard, gamepad uses axis)
	if input.KeyCode == FPSConfig.Controls.MoveForward or input.KeyCode == Enum.KeyCode.W then
		keysHeld.forward = true
	elseif input.KeyCode == FPSConfig.Controls.MoveBackward or input.KeyCode == Enum.KeyCode.S then
		keysHeld.backward = true
	elseif input.KeyCode == FPSConfig.Controls.MoveLeft or input.KeyCode == Enum.KeyCode.A then
		keysHeld.left = true
	elseif input.KeyCode == FPSConfig.Controls.MoveRight or input.KeyCode == Enum.KeyCode.D then
		keysHeld.right = true
	end
end

local function onInputEnded(input, gameProcessedEvent)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	-- Movement keys
	if input.KeyCode == FPSConfig.Controls.MoveForward or input.KeyCode == Enum.KeyCode.W then
		keysHeld.forward = false
	elseif input.KeyCode == FPSConfig.Controls.MoveBackward or input.KeyCode == Enum.KeyCode.S then
		keysHeld.backward = false
	elseif input.KeyCode == FPSConfig.Controls.MoveLeft or input.KeyCode == Enum.KeyCode.A then
		keysHeld.left = false
	elseif input.KeyCode == FPSConfig.Controls.MoveRight or input.KeyCode == Enum.KeyCode.D then
		keysHeld.right = false
	end
end

--------------------------------------------------------------------------------
-- STAMINA SYNC (from server) → Bindable for HUD
--------------------------------------------------------------------------------

local staminaUpdateEvent = remoteEventsFolder:FindFirstChild("StaminaUpdate")
if staminaUpdateEvent then
	staminaUpdateEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			currentStamina = data.current or currentStamina
			maxStamina = data.max or maxStamina

			-- Tell the HUD via bindable (forward all data including isSprinting)
			local staminaBindable = FPSMovementController._staminaBindable
			if staminaBindable then
				staminaBindable:Fire({
					current = currentStamina,
					max = maxStamina,
					isSprinting = data.isSprinting,
				})
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

local function onCharacterAdded(character)
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid")

	-- Store original values
	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower = humanoid.JumpPower
	originalHipHeight = humanoid.HipHeight

	-- Set initial values
	humanoid.WalkSpeed = FPSConfig.Movement.WalkSpeed
	humanoid.JumpPower = FPSConfig.Movement.JumpPower

	-- Reset state
	isSprinting = false
	isCrouching = false
	wantsToCrouch = false
	currentCrouchHeight = FPSConfig.Movement.StandHeight

	-- Reset stamina to max on spawn
	currentStamina = maxStamina
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function FPSMovementController.isSprinting()
	return isSprinting
end

function FPSMovementController.isCrouching()
	return isCrouching
end

function FPSMovementController.isGrounded()
	return isGrounded
end

function FPSMovementController.isMoving()
	return isMoving
end

function FPSMovementController.getStamina()
	return currentStamina, maxStamina
end

function FPSMovementController.setADSActive(active)
	-- Called by weapon controller to reduce speed during ADS
	-- Speed adjustment happens in calculateMoveSpeed
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	-- Setup InputManager callbacks
	setupInputCallbacks()
	
	-- Connect legacy input events (for keyboard fallback)
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	-- Connect character events
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	-- Main update loop
	RunService.Heartbeat:Connect(function(deltaTime)
		updateMovement(deltaTime)
	end)

	-- Create bindable events folder
	local playerGui = player:WaitForChild("PlayerGui")
	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end

	-- Sprint state event (already there)
	local sprintStateEvent = bindableFolder:FindFirstChild("SprintStateChanged")
	if not sprintStateEvent then
		sprintStateEvent = Instance.new("BindableEvent")
		sprintStateEvent.Name = "SprintStateChanged"
		sprintStateEvent.Parent = bindableFolder
	end

	-- Stamina event for PlayerHUD.client
	local staminaBindable = bindableFolder:FindFirstChild("StaminaUpdate")
	if not staminaBindable then
		staminaBindable = Instance.new("BindableEvent")
		staminaBindable.Name = "StaminaUpdate"
		staminaBindable.Parent = bindableFolder
	end

	-- Store for remote → HUD bridge
	FPSMovementController._staminaBindable = staminaBindable

	-- Optionally push an initial value so HUD draws immediately
	staminaBindable:Fire({
		current = currentStamina,
		max = maxStamina,
	})

	print("[FPSMovementController] Initialized")
end

--------------------------------------------------------------------------------
-- PUBLIC INITIALIZE FUNCTION (called from ClientController)
--------------------------------------------------------------------------------

function FPSMovementController.initialize()
	initialize()
end

function FPSMovementController.onCharacterAdded(character)
	onCharacterAdded(character)
end

function FPSMovementController.onCharacterRemoving()
	-- Cleanup if needed
end

return FPSMovementController
