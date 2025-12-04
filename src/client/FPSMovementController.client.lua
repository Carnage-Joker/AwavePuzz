-- FPSMovementController.client.lua
-- First-person movement controller with crouch, sprint, and air control
-- Integrates with FirstPersonCamera for smooth movement-camera transitions

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

-- Wait for camera module (will be available after initialization)
local FirstPersonCamera = nil
task.spawn(function()
	-- Try to get the camera module from _G or wait for it
	task.wait(0.5)
	local success, cam = pcall(function()
		return require(player.PlayerScripts:WaitForChild("FirstPersonCamera.client", 5))
	end)
	if not success then
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

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
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
	local canSprint = wantsToSprint and 
	                  isGrounded and 
	                  isMoving and 
	                  not isCrouching and 
	                  currentStamina > 0 and
	                  keysHeld.forward -- Only sprint when moving forward
	
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
	
	-- Apply air control penalty when not grounded
	if not isGrounded then
		-- Air control is handled by character physics, but we can reduce input response
		-- This is more of a feel adjustment
	end
	
	humanoid.WalkSpeed = moveSpeed
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	-- Sprint key
	if input.KeyCode == Enum.KeyCode[FPSConfig.Movement.SprintKey] then
		wantsToSprint = true
	end
	
	-- Crouch key (toggle)
	if input.KeyCode == Enum.KeyCode[FPSConfig.Movement.CrouchKey] then
		wantsToCrouch = not wantsToCrouch
	end
	
	-- Movement keys
	if input.KeyCode == FPSConfig.Controls.MoveForward then
		keysHeld.forward = true
	elseif input.KeyCode == FPSConfig.Controls.MoveBackward then
		keysHeld.backward = true
	elseif input.KeyCode == FPSConfig.Controls.MoveLeft then
		keysHeld.left = true
	elseif input.KeyCode == FPSConfig.Controls.MoveRight then
		keysHeld.right = true
	end
end

local function onInputEnded(input, gameProcessedEvent)
	-- Sprint key
	if input.KeyCode == Enum.KeyCode[FPSConfig.Movement.SprintKey] then
		wantsToSprint = false
	end
	
	-- Movement keys
	if input.KeyCode == FPSConfig.Controls.MoveForward then
		keysHeld.forward = false
	elseif input.KeyCode == FPSConfig.Controls.MoveBackward then
		keysHeld.backward = false
	elseif input.KeyCode == FPSConfig.Controls.MoveLeft then
		keysHeld.left = false
	elseif input.KeyCode == FPSConfig.Controls.MoveRight then
		keysHeld.right = false
	end
end

--------------------------------------------------------------------------------
-- STAMINA SYNC (from server)
--------------------------------------------------------------------------------

local staminaUpdateEvent = remoteEventsFolder:FindFirstChild("StaminaUpdate")
if staminaUpdateEvent then
	staminaUpdateEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			currentStamina = data.current or currentStamina
			maxStamina = data.max or maxStamina
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
	-- Connect input events
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
	
	-- Create bindable event for other scripts to listen to sprint state
	local playerGui = player:WaitForChild("PlayerGui")
	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end
	
	local sprintStateEvent = bindableFolder:FindFirstChild("SprintStateChanged")
	if not sprintStateEvent then
		sprintStateEvent = Instance.new("BindableEvent")
		sprintStateEvent.Name = "SprintStateChanged"
		sprintStateEvent.Parent = bindableFolder
	end
	
	print("[FPSMovementController] Initialized")
end

-- Initialize
initialize()

return FPSMovementController
