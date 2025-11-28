-- SprintController.client.lua
-- Handles sprint input (Left Shift hotkey) and stamina management

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for shared config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))

-- Configuration from GameConfig
local SPRINT_SPEED_MULTIPLIER = GameConfig.SPRINT_SPEED_MULTIPLIER or 1.5
local STAMINA_MAX = GameConfig.STAMINA_MAX or 100
local STAMINA_DEPLETION_RATE = GameConfig.STAMINA_DEPLETION_RATE or 20
local STAMINA_REGEN_RATE = GameConfig.STAMINA_REGEN_RATE or 15
local STAMINA_REGEN_DELAY = GameConfig.STAMINA_REGEN_DELAY or 1.0
local SPRINT_HOTKEY = GameConfig.SPRINT_HOTKEY or "LeftShift"

-- State
local currentStamina = STAMINA_MAX
local isSprinting = false
local isSprintKeyHeld = false
local timeSinceSprintStopped = 0
local baseWalkSpeed = 16 -- Default Roblox walk speed
local DEFAULT_WALK_SPEED = 16 -- Roblox default walk speed constant

-- Create or get the stamina update event (client-side bindable for UI communication)
local staminaEvent = nil
local function getOrCreateStaminaEvent()
	local bindableFolder = player:WaitForChild("PlayerGui"):FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = player:WaitForChild("PlayerGui")
	end
	
	staminaEvent = bindableFolder:FindFirstChild("StaminaUpdate")
	if not staminaEvent then
		staminaEvent = Instance.new("BindableEvent")
		staminaEvent.Name = "StaminaUpdate"
		staminaEvent.Parent = bindableFolder
	end
	
	return staminaEvent
end

-- Get the player's humanoid
local function getHumanoid()
	local character = player.Character
	if character then
		return character:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

-- Check if player is moving
local function isPlayerMoving()
	local humanoid = getHumanoid()
	if humanoid then
		return humanoid.MoveDirection.Magnitude > 0.1
	end
	return false
end

-- Update sprint state
local function updateSprint()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	
	-- Store base walk speed if not stored
	if baseWalkSpeed == DEFAULT_WALK_SPEED and humanoid.WalkSpeed ~= DEFAULT_WALK_SPEED * SPRINT_SPEED_MULTIPLIER then
		baseWalkSpeed = humanoid.WalkSpeed
	end
	
	-- Determine if we should be sprinting
	local canSprint = isSprintKeyHeld and currentStamina > 0 and isPlayerMoving()
	
	if canSprint and not isSprinting then
		-- Start sprinting
		isSprinting = true
		humanoid.WalkSpeed = baseWalkSpeed * SPRINT_SPEED_MULTIPLIER
	elseif not canSprint and isSprinting then
		-- Stop sprinting
		isSprinting = false
		humanoid.WalkSpeed = baseWalkSpeed
		timeSinceSprintStopped = 0
	end
end

-- Update stamina
local function updateStamina(deltaTime)
	if isSprinting then
		-- Deplete stamina while sprinting
		currentStamina = math.max(0, currentStamina - STAMINA_DEPLETION_RATE * deltaTime)
		timeSinceSprintStopped = 0
		
		-- Stop sprinting if stamina runs out
		if currentStamina <= 0 then
			updateSprint()
		end
	else
		-- Regenerate stamina after delay
		timeSinceSprintStopped = timeSinceSprintStopped + deltaTime
		
		if timeSinceSprintStopped >= STAMINA_REGEN_DELAY then
			currentStamina = math.min(STAMINA_MAX, currentStamina + STAMINA_REGEN_RATE * deltaTime)
		end
	end
	
	-- Fire stamina update event for UI
	if staminaEvent then
		staminaEvent:Fire({
			current = currentStamina,
			max = STAMINA_MAX,
			isSprinting = isSprinting
		})
	end
end

-- Input handling
local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	
	if input.KeyCode == Enum.KeyCode[SPRINT_HOTKEY] then
		isSprintKeyHeld = true
		updateSprint()
	end
end

local function onInputEnded(input)
	if input.KeyCode == Enum.KeyCode[SPRINT_HOTKEY] then
		isSprintKeyHeld = false
		updateSprint()
	end
end

-- Character added handler
local function onCharacterAdded(character)
	-- Reset sprint state on character spawn
	isSprinting = false
	isSprintKeyHeld = UserInputService:IsKeyDown(Enum.KeyCode[SPRINT_HOTKEY])
	currentStamina = STAMINA_MAX
	timeSinceSprintStopped = 0
	
	-- Wait for humanoid and set base walk speed
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		baseWalkSpeed = humanoid.WalkSpeed
	end
end

-- Initialize
local function initialize()
	-- Setup events
	getOrCreateStaminaEvent()
	
	-- Connect input events
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	
	-- Connect character events
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	-- Main update loop
	RunService.RenderStepped:Connect(function(deltaTime)
		updateSprint()
		updateStamina(deltaTime)
	end)
end

-- Start the controller
initialize()
