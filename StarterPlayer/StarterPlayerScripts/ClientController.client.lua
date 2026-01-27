-- ClientController.client.lua
-- SINGLE CLIENT ENTRYPOINT - Initializes all client subsystems
-- This is the ONLY LocalScript that should run on the client
-- All other client logic is in ModuleScripts initialized from here

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

print("=== AwavePuzz Client Controller Starting ===")
print("[ClientController] Player:", player.Name)

-- Wait for essential services
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[ClientController] Failed to load Shared folder")
end

-- Load configuration
local FPSConfig = SharedFolder:WaitForChild("FPSConfig", 5)
if not FPSConfig then
	error("[ClientController] Failed to load FPSConfig")
end
FPSConfig = require(FPSConfig)

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[ClientController] Failed to load GameConfig")
end
GameConfig = require(GameConfig)

-- Load input management systems
local ModalManager = SharedFolder:WaitForChild("ModalManager", 5)
if not ModalManager then
	error("[ClientController] Failed to load ModalManager")
end
ModalManager = require(ModalManager)

local InputActionRegistry = SharedFolder:WaitForChild("InputActionRegistry", 5)
if not InputActionRegistry then
	error("[ClientController] Failed to load InputActionRegistry")
end
InputActionRegistry = require(InputActionRegistry)

print("[ClientController] Configuration loaded")

--------------------------------------------------------------------------------
-- MODULE REFERENCES
--------------------------------------------------------------------------------

-- Wait longer for Modules folder and ensure it's properly located
local clientModules = script.Parent:WaitForChild("Modules", 10)
if not clientModules then
	error("[ClientController] CRITICAL: Modules folder not found in " .. script.Parent:GetFullName())
end

-- Core systems (will be loaded from Modules folder)
local Camera = nil
local Movement = nil
local WeaponController = nil
local AnimationController = nil
local AudioController = nil
local MenuController = nil
local MusicController = nil

-- UI systems
local UI = {}

--------------------------------------------------------------------------------
-- SYSTEM INITIALIZATION
--------------------------------------------------------------------------------

local ClientController = {}
ClientController.initialized = false

-- System names constant to prevent typos
local SYSTEM_NAMES = {
	CAMERA = "camera",
	MOVEMENT = "movement",
	WEAPON = "weapon",
	ANIMATION = "animation",
	AUDIO = "audio",
	MUSIC = "music",
	MENU = "menu",
	UI = "ui"
}

-- Track which systems have been initialized to prevent duplicates
local systemsInitialized = {
	[SYSTEM_NAMES.CAMERA] = false,
	[SYSTEM_NAMES.MOVEMENT] = false,
	[SYSTEM_NAMES.WEAPON] = false,
	[SYSTEM_NAMES.ANIMATION] = false,
	[SYSTEM_NAMES.AUDIO] = false,
	[SYSTEM_NAMES.MUSIC] = false,
	[SYSTEM_NAMES.MENU] = false,
	[SYSTEM_NAMES.UI] = false
}

-- Initialize Camera System
function ClientController.initializeCamera()
	if systemsInitialized[SYSTEM_NAMES.CAMERA] then
		warn("[ClientController] Camera already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Camera...")
	
	local cameraModule = clientModules:FindFirstChild("FirstPersonCamera")
	if cameraModule then
		local success, result = pcall(function()
			return require(cameraModule)
		end)
		
		if success then
			Camera = result
			if Camera.initialize then
				Camera.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.CAMERA] = true
			print("[ClientController] ✓ Camera initialized")
		else
			warn("[ClientController] ✗ Camera failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Camera module not found")
	end
end

-- Initialize Movement System
function ClientController.initializeMovement()
	if systemsInitialized[SYSTEM_NAMES.MOVEMENT] then
		warn("[ClientController] Movement already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Movement...")
	
	local movementModule = clientModules:FindFirstChild("FPSMovement")
	if movementModule then
		local success, result = pcall(function()
			return require(movementModule)
		end)
		
		if success then
			Movement = result
			if Movement.initialize then
				Movement.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.MOVEMENT] = true
			print("[ClientController] ✓ Movement initialized")
		else
			warn("[ClientController] ✗ Movement failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Movement module not found")
	end
end

-- Initialize Weapon System
function ClientController.initializeWeapon()
	if systemsInitialized[SYSTEM_NAMES.WEAPON] then
		warn("[ClientController] Weapon already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Weapon System...")
	
	local weaponModule = clientModules:FindFirstChild("FPSWeaponController")
	if weaponModule then
		local success, result = pcall(function()
			return require(weaponModule)
		end)
		
		if success then
			WeaponController = result
			if WeaponController.initialize then
				WeaponController.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.WEAPON] = true
			print("[ClientController] ✓ Weapon system initialized")
		else
			warn("[ClientController] ✗ Weapon system failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Weapon module not found")
	end
end

-- Initialize Animation System
function ClientController.initializeAnimation()
	if systemsInitialized[SYSTEM_NAMES.ANIMATION] then
		warn("[ClientController] Animation already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Animations...")
	
	local animModule = clientModules:FindFirstChild("FPSAnimationController")
	if animModule then
		local success, result = pcall(function()
			return require(animModule)
		end)
		
		if success then
			AnimationController = result
			if AnimationController.initialize then
				AnimationController.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.ANIMATION] = true
			print("[ClientController] ✓ Animations initialized")
		else
			warn("[ClientController] ✗ Animations failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Animation module not found")
	end
end

-- Initialize Audio System
function ClientController.initializeAudio()
	if systemsInitialized[SYSTEM_NAMES.AUDIO] then
		warn("[ClientController] Audio already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Audio...")
	
	local audioModule = clientModules:FindFirstChild("FPSAudioController")
	if audioModule then
		local success, result = pcall(function()
			return require(audioModule)
		end)
		
		if success then
			AudioController = result
			if AudioController.initialize then
				AudioController.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.AUDIO] = true
			print("[ClientController] ✓ Audio initialized")
		else
			warn("[ClientController] ✗ Audio failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Audio module not found")
	end
end

-- Initialize Music System
function ClientController.initializeMusic()
	if systemsInitialized[SYSTEM_NAMES.MUSIC] then
		warn("[ClientController] Music already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Music...")
	
	local musicModule = clientModules:FindFirstChild("MusicController")
	if musicModule then
		local success, result = pcall(function()
			return require(musicModule)
		end)
		
		if success then
			MusicController = result
			if MusicController.initialize then
				MusicController.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.MUSIC] = true
			print("[ClientController] ✓ Music initialized")
		else
			warn("[ClientController] ✗ Music failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Music module not found")
	end
end

-- Initialize Menu System
function ClientController.initializeMenu()
	if systemsInitialized[SYSTEM_NAMES.MENU] then
		warn("[ClientController] Menu already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing Menu...")
	
	local menuModule = clientModules:FindFirstChild("FPSMenuController")
	if menuModule then
		local success, result = pcall(function()
			return require(menuModule)
		end)
		
		if success then
			MenuController = result
			if MenuController.initialize then
				MenuController.initialize()
			end
			systemsInitialized[SYSTEM_NAMES.MENU] = true
			print("[ClientController] ✓ Menu initialized")
		else
			warn("[ClientController] ✗ Menu failed to load:", result)
		end
	else
		warn("[ClientController] ✗ Menu module not found")
	end
end

-- Initialize UI Systems
function ClientController.initializeUI()
	if systemsInitialized[SYSTEM_NAMES.UI] then
		warn("[ClientController] UI already initialized, skipping")
		return
	end
	
	print("[ClientController] Initializing UI Systems...")
	
	local uiFolder = clientModules:FindFirstChild("UI")
	if not uiFolder then
		warn("[ClientController] ✗ UI folder not found")
		return
	end
	
	local uiModules = {
		"FPSHUD",
		"PlayerHUD",
		"WaveUI",
		"CureUI",
		"BaseHealthUI",
		"InventoryUI",
		"ShopUI",
		"AllianceUI",
		"PuzzleUI",
		"PuzzleMenuUI",
		"ScoreboardUI",
		"MapVotingUI",
		"LobbyUI",
		"SpectatorUI",
		"TitleScreenUI",
		"EpilogueUI",
		"AchievementUI",
		"CreditsUI",
		"FunFactUI",
		"SynthesisUI",
		"ControlsTutorialUI",
		"TouchControlsUI"
	}
	
	-- Only load PortalQueueUI if portal matchmaking is enabled
	if GameConfig and GameConfig.USE_PORTAL_MATCHMAKING then
		table.insert(uiModules, "PortalQueueUI")
	end
	
	for _, moduleName in ipairs(uiModules) do
		local uiModule = uiFolder:FindFirstChild(moduleName)
		if uiModule then
			local success, result = pcall(function()
				return require(uiModule)
			end)
			
			if success then
				-- Verify result is exactly one value
				if result ~= nil then
					UI[moduleName] = result
					-- Call initialize if it exists
					if typeof(result) == "table" and result.initialize then
						local initSuccess, initErr = pcall(result.initialize)
						if not initSuccess then
							warn(string.format("[ClientController] ✗ UI module %s initialize failed: %s", moduleName, tostring(initErr)))
						end
					end
				else
					warn(string.format("[ClientController] ✗ UI module %s returned nil", moduleName))
				end
			else
				warn(string.format("[ClientController] ✗ UI module %s failed to load: %s", moduleName, tostring(result)))
			end
		else
			-- Don't warn for optional UI modules
			-- warn(string.format("[ClientController] ✗ UI module %s not found", moduleName))
		end
	end
	
	systemsInitialized[SYSTEM_NAMES.UI] = true
	print("[ClientController] ✓ UI systems initialized")
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

function ClientController.onCharacterAdded(character)
	print("[ClientController] Character added:", character.Name)
	
	-- Clear any stale GUI selections on respawn
	local GuiService = game:GetService("GuiService")
	pcall(function()
		GuiService.SelectedObject = nil
	end)
	
	-- Notify all systems of character spawn
	if Camera and Camera.onCharacterAdded then
		Camera.onCharacterAdded(character)
	end
	
	if Movement and Movement.onCharacterAdded then
		Movement.onCharacterAdded(character)
	end
	
	if WeaponController and WeaponController.onCharacterAdded then
		WeaponController.onCharacterAdded(character)
	end
	
	if AnimationController and AnimationController.onCharacterAdded then
		AnimationController.onCharacterAdded(character)
	end
end

function ClientController.onCharacterRemoving()
	print("[ClientController] Character removing")
	
	-- Clear GUI selections before character removal
	local GuiService = game:GetService("GuiService")
	pcall(function()
		GuiService.SelectedObject = nil
	end)
	
	-- Notify all systems of character removal
	if Camera and Camera.onCharacterRemoving then
		Camera.onCharacterRemoving()
	end
	
	if Movement and Movement.onCharacterRemoving then
		Movement.onCharacterRemoving()
	end
	
	if WeaponController and WeaponController.onCharacterRemoving then
		WeaponController.onCharacterRemoving()
	end
	
	if AnimationController and AnimationController.onCharacterRemoving then
		AnimationController.onCharacterRemoving()
	end
end

--------------------------------------------------------------------------------
-- MAIN INITIALIZATION
--------------------------------------------------------------------------------

function ClientController.initialize()
	if ClientController.initialized then
		warn("[ClientController] Already initialized")
		return
	end
	
	print("[ClientController] Starting initialization sequence...")
	
	-- Initialize input management systems FIRST
	print("[ClientController] Initializing input management systems...")
	ModalManager.initialize()
	InputActionRegistry.initialize()
	
	-- Initialize systems in order
	ClientController.initializeCamera()
	ClientController.initializeMovement()
	ClientController.initializeWeapon()
	ClientController.initializeAnimation()
	ClientController.initializeAudio()
	ClientController.initializeMusic()
	ClientController.initializeMenu()
	ClientController.initializeUI()
	
	-- Connect character events
	player.CharacterAdded:Connect(ClientController.onCharacterAdded)
	player.CharacterRemoving:Connect(ClientController.onCharacterRemoving)
	
	-- Handle existing character
	if player.Character then
		task.defer(function()
			ClientController.onCharacterAdded(player.Character)
		end)
	end
	
	ClientController.initialized = true
	print("[ClientController] ✓✓✓ Client initialization complete ✓✓✓")
	
	-- Run input action audit after all systems have initialized
	task.spawn(function()
		InputActionRegistry.runStartupAudit()
	end)
end

-- Start the client
ClientController.initialize()

return ClientController
