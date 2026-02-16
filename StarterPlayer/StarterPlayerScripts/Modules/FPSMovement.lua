-- @ScriptType: ModuleScript
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
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))

-- NOTE: Camera module is managed separately by ClientMainModule
-- Camera-movement synchronization happens via bindable events and state setters
-- See: FirstPersonCamera.setSprinting(), FirstPersonCamera.setCrouching(), etc.

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

-- Connection tracking for cleanup
local _connections = {}

-- Movement state
local isSprinting = false
local isCrouching = false
local isGrounded = true
local isMoving = false
local wantsToSprint = false
local wantsToCrouch = false
local _enabled = true -- Movement enabled/disabled state

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

-- Helper: Check if gameplay input should be blocked by modal state
-- NOTE: This function is called frequently (every frame, multiple times per input)
-- but is intentionally kept simple for performance:
-- - _enabled is a local boolean (instant check)
-- - ModalManager.shouldBlockGameplay() iterates a small stack (typically 0-2 items)
-- - No need for caching as the check is already O(1) amortized
local function shouldBlockGameplay()
	-- Block gameplay when MODAL or FULLSCREEN priority modals are active
	-- PANEL priority (like Scoreboard) allows gameplay to continue
	-- Also block if movement is explicitly disabled via setEnabled()
	return not _enabled or ModalManager.shouldBlockGameplay()
end

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
		
		-- Broadcast crouch state change via bindable (for camera sync)
		local bindableFolder = player.PlayerGui:FindFirstChild("BindableEvents")
		if bindableFolder then
			local crouchBindable = bindableFolder:FindFirstChild("CrouchStateChanged")
			if crouchBindable then
				crouchBindable:Fire(isCrouching)
			end
		end
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
	
	-- Block movement if modal is active
	if shouldBlockGameplay() then
		-- Reset movement state when blocked
		keysHeld.forward = false
		keysHeld.backward = false
		keysHeld.left = false
		keysHeld.right = false
		movementVector = Vector2.new(0, 0)
		wantsToSprint = false
		isSprinting = false
		isMoving = false
		humanoid.WalkSpeed = 0
		return
	end

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
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			wantsToSprint = false
			return
		end
		wantsToSprint = active
	end)

	-- Crouch action (toggle)
	InputManager.bindAction(InputManager.Action.CROUCH, function(active)
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			return
		end
		if active then
			wantsToCrouch = not wantsToCrouch
		end
	end)

	-- Jump action
	InputManager.bindAction(InputManager.Action.JUMP, function(active)
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			return
		end
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
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			movementVector = Vector2.new(0, 0)
			keysHeld.forward = false
			keysHeld.backward = false
			keysHeld.left = false
			keysHeld.right = false
			return
		end
		
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
	-- ALWAYS check gameProcessedEvent first
	if gameProcessedEvent then return end
	
	-- Check if gameplay should be blocked
	if shouldBlockGameplay() then return end
	
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
	table.insert(_connections, staminaUpdateEvent.OnClientEvent:Connect(function(data)
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
	end))
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
	-- NOTE: ADS speed adjustment is handled by the weapon controller
	-- which directly modifies Humanoid.WalkSpeed when ADS state changes.
	-- This method is kept for API compatibility but is currently unused.
end

-- Enable or disable movement (used by state manager)
function FPSMovementController.setEnabled(enabled)
	_enabled = enabled
	if not enabled then
		-- Reset movement state when disabled
		isSprinting = false
		wantsToSprint = false
		isMoving = false
		keysHeld.forward = false
		keysHeld.backward = false
		keysHeld.left = false
		keysHeld.right = false
		movementVector = Vector2.new(0, 0)

		-- Ensure Humanoid WalkSpeed is reset to base when movement is disabled
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Use configured base walk speed if available, otherwise fall back to Roblox default
				local baseSpeed = humanoid:GetAttribute("BaseWalkSpeed") or 16
				humanoid.WalkSpeed = baseSpeed
			end
		end
	end
	print(string.format("[FPSMovement] Movement %s", enabled and "enabled" or "disabled"))
end

function FPSMovementController.isEnabled()
	return _enabled
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	-- Setup InputManager callbacks
	setupInputCallbacks()

	-- Connect legacy input events (for keyboard fallback)
	table.insert(_connections, UserInputService.InputBegan:Connect(onInputBegan))
	table.insert(_connections, UserInputService.InputEnded:Connect(onInputEnded))

	-- Connect character events
	if player.Character then
		onCharacterAdded(player.Character)
	end
	table.insert(_connections, player.CharacterAdded:Connect(onCharacterAdded))

	-- Main update loop
	table.insert(_connections, RunService.Heartbeat:Connect(function(deltaTime)
		updateMovement(deltaTime)
	end))

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
	
	-- Crouch state event (for camera sync)
	local crouchStateEvent = bindableFolder:FindFirstChild("CrouchStateChanged")
	if not crouchStateEvent then
		crouchStateEvent = Instance.new("BindableEvent")
		crouchStateEvent.Name = "CrouchStateChanged"
		crouchStateEvent.Parent = bindableFolder
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

-- NOTE: Character lifecycle methods onCharacterAdded/onCharacterRemoving
-- are intentionally NOT implemented here. Character events are handled
-- by ClientMainModule which calls initialize() once at boot.
-- All input connections persist across respawns since they're bound to
-- the LocalPlayer, not the character. This avoids connection leaks and
-- simplifies the lifecycle management.
--
-- If character-specific setup is needed in the future:
-- 1. Implement onCharacterAdded(character) to reset character-specific state
-- 2. Wire it in ClientMainModule's character event handler
-- 3. Do NOT create new input connections - reuse existing ones

function FPSMovementController.cleanup()
	-- Disconnect all tracked connections
	for _, connection in ipairs(_connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	_connections = {}
	
	-- Reset state
	isSprinting = false
	isCrouching = false
	wantsToSprint = false
	wantsToCrouch = false
	isMoving = false
	
	print("[FPSMovementController] Cleaned up")
end

return FPSMovementController