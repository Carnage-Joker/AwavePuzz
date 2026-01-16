-- @ScriptType: Script
-- SprintController.client.lua
-- Client-side input handler for sprint system
-- Sends sprint requests to server, receives authoritative stamina updates

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for shared config
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))

-- Configuration from GameConfig
local SPRINT_HOTKEY = GameConfig.SPRINT_HOTKEY or "LeftShift"

-- Remote events
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local sprintRequestEvent = remoteEventsFolder:WaitForChild("SprintRequest")
local staminaUpdateEvent = remoteEventsFolder:WaitForChild("StaminaUpdate")

-- State
local isSprintKeyHeld = false
local currentStamina = GameConfig.STAMINA_MAX or 100
local maxStamina = GameConfig.STAMINA_MAX or 100
local isSprinting = false

-- Create or get the stamina update event (client-side bindable for UI communication)
local staminaBindableEvent = nil
local function getOrCreateStaminaBindableEvent()
	local bindableFolder = player:WaitForChild("PlayerGui"):FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = player:WaitForChild("PlayerGui")
	end
	
	staminaBindableEvent = bindableFolder:FindFirstChild("StaminaUpdate")
	if not staminaBindableEvent then
		staminaBindableEvent = Instance.new("BindableEvent")
		staminaBindableEvent.Name = "StaminaUpdate"
		staminaBindableEvent.Parent = bindableFolder
	end
	
	return staminaBindableEvent
end

-- Send sprint state to server
local function sendSprintRequest()
	sprintRequestEvent:FireServer(isSprintKeyHeld)
end

-- Input handling
local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	
	if input.KeyCode == Enum.KeyCode[SPRINT_HOTKEY] then
		isSprintKeyHeld = true
		sendSprintRequest()
	end
end

local function onInputEnded(input)
	if input.KeyCode == Enum.KeyCode[SPRINT_HOTKEY] then
		isSprintKeyHeld = false
		sendSprintRequest()
	end
end

-- Handle stamina updates from server
local function onStaminaUpdate(data)
	if typeof(data) ~= "table" then
		return
	end
	
	currentStamina = data.current or currentStamina
	maxStamina = data.max or maxStamina
	isSprinting = data.isSprinting or false
	
	-- Forward to UI via bindable event
	if staminaBindableEvent then
		staminaBindableEvent:Fire({
			current = currentStamina,
			max = maxStamina,
			isSprinting = isSprinting
		})
	end
end

-- Character added handler
local function onCharacterAdded(character)
	-- Re-sync sprint key state with server after respawn
	isSprintKeyHeld = UserInputService:IsKeyDown(Enum.KeyCode[SPRINT_HOTKEY])
	sendSprintRequest()
end

-- Initialize
local function initialize()
	-- Setup bindable event for UI communication
	getOrCreateStaminaBindableEvent()
	
	-- Connect input events
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	
	-- Connect to server stamina updates
	staminaUpdateEvent.OnClientEvent:Connect(onStaminaUpdate)
	
	-- Connect character events
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Start the controller
initialize()
