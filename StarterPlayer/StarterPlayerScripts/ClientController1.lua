-- @ScriptType: LocalScript
-- @ScriptType: LocalScript
-- ClientController.client.lua
-- SINGLE CLIENT ENTRYPOINT
--
-- Fixes:
-- 1) Waits for PlayerScripts.Modules instead of failing instantly
-- 2) Self-heals by cloning Modules from StarterPlayerScripts or ReplicatedStorage fallback
-- 3) Initializes ReplicatedStorage.Client.UI modules (NOT StarterGui LocalScripts)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer

print("=== AwavePuzz Client Controller Starting ===")
print("[ClientController] Script:", script:GetFullName())

--------------------------------------------------------------------------------
-- READY FLAGS (optional)
--------------------------------------------------------------------------------

player:SetAttribute("ClientReady", true)

local function ensureClientReadyFlag(value: boolean)
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("[ClientController] PlayerGui not found; cannot set ClientReady flag")
		return nil
	end

	local flag = playerGui:FindFirstChild("ClientReady")
	if not flag then
		flag = Instance.new("BoolValue")
		flag.Name = "ClientReady"
		flag.Parent = playerGui
	end

	flag.Value = (value == true)
	return flag
end

ensureClientReadyFlag(true)

--------------------------------------------------------------------------------
-- SHARED CONFIG
--------------------------------------------------------------------------------

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[ClientController] Failed to load ReplicatedStorage.Shared")
end

local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
print("[ClientController] Configuration loaded")

--------------------------------------------------------------------------------
-- DEBUG HELPERS
--------------------------------------------------------------------------------

local function listChildren(inst: Instance?): string
	if not inst then return "(nil)" end
	local t = {}
	for _, c in ipairs(inst:GetChildren()) do
		table.insert(t, string.format("%s(%s)", c.Name, c.ClassName))
	end
	return table.concat(t, ", ")
end

local function waitForChildOfClass(parent: Instance, name: string, className: string, timeout: number): Instance?
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		local child = parent:FindFirstChild(name)
		if child and child.ClassName == className then
			return child
		end
		task.wait(0.1)
	end
	return nil
end

--------------------------------------------------------------------------------
-- MODULE LOCATION RESOLUTION (WAIT + SELF-HEAL)
--------------------------------------------------------------------------------

local function tryCloneModulesIntoPlayerScripts(playerScripts: Instance): Folder?
	-- 1) StarterPlayerScripts.Modules
	local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	if sps then
		local m = sps:FindFirstChild("Modules")
		if m and m:IsA("Folder") then
			warn("[ClientController] Modules missing in PlayerScripts. Cloning from StarterPlayerScripts.Modules...")
			local clone = m:Clone()
			clone.Parent = playerScripts
			return clone
		end
	end

	-- 2) ReplicatedStorage.Client.Modules (optional fallback if you add it)
	local clientFolder = ReplicatedStorage:FindFirstChild("Client")
	if clientFolder then
		local m = clientFolder:FindFirstChild("Modules")
		if m and m:IsA("Folder") then
			warn("[ClientController] Modules missing in PlayerScripts. Cloning from ReplicatedStorage.Client.Modules...")
			local clone = m:Clone()
			clone.Parent = playerScripts
			return clone
		end
	end

	return nil
end

local function resolveClientModules(): Folder?
	local playerScripts = player:WaitForChild("PlayerScripts", 10)
	if not playerScripts then
		warn("[ClientController] PlayerScripts not found under player")
		return nil
	end

	print("[ClientController] PlayerScripts children (initial):", listChildren(playerScripts))

	-- Wait for Modules to appear (in case PlayerScriptsLoader creates/moves it)
	local modules = waitForChildOfClass(playerScripts, "Modules", "Folder", 15)
	if modules then
		return modules :: Folder
	end

	-- Still missing: attempt to self-heal
	modules = tryCloneModulesIntoPlayerScripts(playerScripts)
	if modules then
		return modules
	end

	-- Final wait in case something creates it late
	modules = waitForChildOfClass(playerScripts, "Modules", "Folder", 10)
	if modules then
		return modules :: Folder
	end

	-- Debug dump before giving up
	warn("[ClientController] PlayerScripts children (final):", listChildren(playerScripts))
	return nil
end

local clientModules = resolveClientModules()
if not clientModules then
	error(string.format(
		"[ClientController] CRITICAL: Modules folder not found.\nExpected: Players.%s.PlayerScripts.Modules\nScript: %s",
		player.Name,
		script:GetFullName()
		))
end

print("[ClientController] Modules resolved to:", clientModules:GetFullName())

--------------------------------------------------------------------------------
-- SAFE REQUIRE
--------------------------------------------------------------------------------

local function safeRequire(moduleScript: Instance?, label: string)
	if not moduleScript then
		warn(string.format("[ClientController] ✗ %s missing", label))
		return nil
	end
	if not moduleScript:IsA("ModuleScript") then
		warn(string.format("[ClientController] ✗ %s is not a ModuleScript (%s)", label, moduleScript.ClassName))
		return nil
	end

	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn(string.format("[ClientController] ✗ %s failed to load: %s", label, tostring(result)))
		return nil
	end

	return result
end

--------------------------------------------------------------------------------
-- MODULE REFERENCES
--------------------------------------------------------------------------------

local Camera
local Movement
local WeaponController
local AnimationController
local AudioController
local MenuController
local MusicController

-- ReplicatedStorage UI modules
local LobbyUI
local TouchControlsUI

--------------------------------------------------------------------------------
-- CONTROLLER
--------------------------------------------------------------------------------

local ClientController = {}
ClientController.initialized = false

--------------------------------------------------------------------------------
-- INITIALISERS
--------------------------------------------------------------------------------

function ClientController.initializeCamera()
	print("[ClientController] Initializing Camera...")
	local m = clientModules:FindFirstChild("FirstPersonCamera")
	Camera = safeRequire(m, "Camera")
	if Camera and Camera.initialize then pcall(Camera.initialize) end
end

function ClientController.initializeMovement()
	print("[ClientController] Initializing Movement...")
	local m = clientModules:FindFirstChild("FPSMovement")
	Movement = safeRequire(m, "Movement")
	if Movement and Movement.initialize then pcall(Movement.initialize) end
end

function ClientController.initializeWeapon()
	print("[ClientController] Initializing Weapon System...")
	local m = clientModules:FindFirstChild("FPSWeaponController")
	WeaponController = safeRequire(m, "WeaponController")
	if WeaponController and WeaponController.initialize then pcall(WeaponController.initialize) end
end

function ClientController.initializeAnimation()
	print("[ClientController] Initializing Animations...")
	local m = clientModules:FindFirstChild("FPSAnimationController")
	AnimationController = safeRequire(m, "AnimationController")
	if AnimationController and AnimationController.initialize then pcall(AnimationController.initialize) end
end

function ClientController.initializeAudio()
	print("[ClientController] Initializing Audio...")
	local m = clientModules:FindFirstChild("FPSAudioController")
	AudioController = safeRequire(m, "AudioController")
	if AudioController and AudioController.initialize then pcall(AudioController.initialize) end
end

function ClientController.initializeMusic()
	print("[ClientController] Initializing Music...")
	local m = clientModules:FindFirstChild("MusicController")
	MusicController = safeRequire(m, "MusicController")
	if MusicController and MusicController.initialize then pcall(MusicController.initialize) end
end

function ClientController.initializeMenu()
	print("[ClientController] Initializing Menu...")
	local m = clientModules:FindFirstChild("FPSMenuController")
	MenuController = safeRequire(m, "MenuController")
	if MenuController and MenuController.initialize then pcall(MenuController.initialize) end
end

function ClientController.initializeUI()
	print("[ClientController] Initializing UI modules (ReplicatedStorage.Client.UI)...")

	local clientFolder = ReplicatedStorage:FindFirstChild("Client")
	local uiFolder = clientFolder and clientFolder:FindFirstChild("UI")

	if not uiFolder then
		warn("[ClientController] ReplicatedStorage.Client.UI not found; skipping UI modules")
		return
	end

	local lobby = uiFolder:FindFirstChild("LobbyUI")
	if lobby then
		LobbyUI = safeRequire(lobby, "LobbyUI")
	end

	local touch = uiFolder:FindFirstChild("TouchControlsUI")
	if touch then
		TouchControlsUI = safeRequire(touch, "TouchControlsUI")
	end
end

--------------------------------------------------------------------------------
-- CHARACTER HOOKS
--------------------------------------------------------------------------------

function ClientController.onCharacterAdded(character: Model)
	print("[ClientController] Character added:", character.Name)
	ensureClientReadyFlag(true)

	if Camera and Camera.onCharacterAdded then pcall(Camera.onCharacterAdded, character) end
	if Movement and Movement.onCharacterAdded then pcall(Movement.onCharacterAdded, character) end
	if WeaponController and WeaponController.onCharacterAdded then pcall(WeaponController.onCharacterAdded, character) end
	if AnimationController and AnimationController.onCharacterAdded then pcall(AnimationController.onCharacterAdded, character) end
end

function ClientController.onCharacterRemoving(_character: Model?)
	print("[ClientController] Character removing")

	if Camera and Camera.onCharacterRemoving then pcall(Camera.onCharacterRemoving) end
	if Movement and Movement.onCharacterRemoving then pcall(Movement.onCharacterRemoving) end
	if WeaponController and WeaponController.onCharacterRemoving then pcall(WeaponController.onCharacterRemoving) end
	if AnimationController and AnimationController.onCharacterRemoving then pcall(AnimationController.onCharacterRemoving) end
end

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

function ClientController.initialize()
	if ClientController.initialized then
		warn("[ClientController] Already initialized")
		return
	end

	print("[ClientController] Starting initialization sequence...")

	ClientController.initializeCamera()
	ClientController.initializeMovement()
	ClientController.initializeWeapon()
	ClientController.initializeAnimation()
	ClientController.initializeAudio()
	ClientController.initializeMusic()
	ClientController.initializeMenu()
	ClientController.initializeUI()

	player.CharacterAdded:Connect(ClientController.onCharacterAdded)
	player.CharacterRemoving:Connect(ClientController.onCharacterRemoving)

	if player.Character then
		task.defer(function()
			ClientController.onCharacterAdded(player.Character)
		end)
	end

	ClientController.initialized = true
	print("[ClientController] ✓✓✓ Client initialization complete ✓✓✓")
end

ClientController.initialize()
return ClientController
