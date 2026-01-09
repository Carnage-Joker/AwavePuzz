-- @ScriptType: LocalScript
-- ClientController.client.lua
-- SINGLE CLIENT ENTRYPOINT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
print("=== AwavePuzz Client Controller Starting ===")
print("[ClientController] Player:", player.Name)

-- Make EVERY possible "ready" mechanism true
player:SetAttribute("ClientReady", true)

local function ensureClientReadyFlag(value)
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("[ClientController] PlayerGui not found; cannot set ClientReady")
		return nil
	end

	local flag = playerGui:FindFirstChild("ClientReady")
	if not flag then
		flag = Instance.new("BoolValue")
		flag.Name = "ClientReady"
		flag.Parent = playerGui
	end
	flag.Value = value and true or false
	return flag
end

ensureClientReadyFlag(true)

-- Wait for Shared
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[ClientController] Failed to load ReplicatedStorage.Shared")
end

local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
print("[ClientController] Configuration loaded")

--------------------------------------------------------------------------------
-- MODULE LOCATION RESOLUTION
--------------------------------------------------------------------------------

local function resolveClientModules()
	local parent = script.Parent -- PlayerScripts at runtime

	local modules = parent:FindFirstChild("Modules")
	if modules and modules:IsA("Folder") then
		return modules
	end

	modules = parent:WaitForChild("Modules", 10)
	if modules and modules:IsA("Folder") then
		return modules
	end

	local clientFolder = ReplicatedStorage:FindFirstChild("Client")
	if clientFolder then
		local rsModules = clientFolder:FindFirstChild("Modules")
		if rsModules and rsModules:IsA("Folder") then
			return rsModules
		end
	end

	return nil
end

local clientModules = resolveClientModules()
if not clientModules then
	error(string.format(
		"[ClientController] CRITICAL: Modules folder not found.\nScript: %s",
		script:GetFullName()
		))
end

print("[ClientController] Modules resolved to:", clientModules:GetFullName())

--------------------------------------------------------------------------------
-- MODULE REFERENCES
--------------------------------------------------------------------------------

local Camera, Movement, WeaponController, AnimationController, AudioController, MenuController, MusicController
local FPSHUD, PlayerHUD, LobbyUI

--------------------------------------------------------------------------------
-- SYSTEM INITIALIZATION
--------------------------------------------------------------------------------

local ClientController = {}
ClientController.initialized = false

local function safeRequire(moduleScript, label)
	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn(string.format("[ClientController] ✗ %s failed to load: %s", label, tostring(result)))
		return nil
	end
	return result
end

function ClientController.initializeCamera()
	print("[ClientController] Initializing Camera...")
	local m = clientModules:FindFirstChild("FirstPersonCamera")
	if not m then return warn("[ClientController] ✗ Camera module not found") end
	Camera = safeRequire(m, "Camera")
	if Camera and Camera.initialize then pcall(Camera.initialize) end
	print("[ClientController] ✓ Camera initialized")
end

function ClientController.initializeMovement()
	print("[ClientController] Initializing Movement...")
	local m = clientModules:FindFirstChild("FPSMovement")
	if not m then return warn("[ClientController] ✗ Movement module not found") end
	Movement = safeRequire(m, "Movement")
	if Movement and Movement.initialize then pcall(Movement.initialize) end
	print("[ClientController] ✓ Movement initialized")
end

function ClientController.initializeWeapon()
	print("[ClientController] Initializing Weapon System...")
	local m = clientModules:FindFirstChild("FPSWeaponController")
	if not m then return warn("[ClientController] ✗ Weapon module not found") end
	WeaponController = safeRequire(m, "WeaponController")
	if WeaponController and WeaponController.initialize then pcall(WeaponController.initialize) end
	print("[ClientController] ✓ Weapon system initialized")
end

function ClientController.initializeAnimation()
	print("[ClientController] Initializing Animations...")
	local m = clientModules:FindFirstChild("FPSAnimationController")
	if not m then return warn("[ClientController] ✗ Animation module not found") end
	AnimationController = safeRequire(m, "AnimationController")
	if AnimationController and AnimationController.initialize then pcall(AnimationController.initialize) end
	print("[ClientController] ✓ Animations initialized")
end

function ClientController.initializeAudio()
	print("[ClientController] Initializing Audio...")
	local m = clientModules:FindFirstChild("FPSAudioController")
	if not m then return warn("[ClientController] ✗ Audio module not found") end
	AudioController = safeRequire(m, "AudioController")
	if AudioController and AudioController.initialize then pcall(AudioController.initialize) end
	print("[ClientController] ✓ Audio initialized")
end

function ClientController.initializeMusic()
	print("[ClientController] Initializing Music...")
	local m = clientModules:FindFirstChild("MusicController")
	if not m then return warn("[ClientController] ✗ Music module not found") end
	MusicController = safeRequire(m, "MusicController")
	if MusicController and MusicController.initialize then pcall(MusicController.initialize) end
	print("[ClientController] ✓ Music initialized")
end

function ClientController.initializeMenu()
	print("[ClientController] Initializing Menu...")
	local m = clientModules:FindFirstChild("FPSMenuController")
	if not m then return warn("[ClientController] ✗ Menu module not found") end
	MenuController = safeRequire(m, "MenuController")
	if MenuController and MenuController.initialize then pcall(MenuController.initialize) end
	print("[ClientController] ✓ Menu initialized")
end

function ClientController.initializeUI()
	print("[ClientController] Initializing UI modules...")

	-- These may be ModuleScripts in Modules, or LocalScripts elsewhere.
	-- If they are ModuleScripts, we initialise them here.
	local fpsHudModule = clientModules:FindFirstChild("FPSHUD")
	if fpsHudModule then
		FPSHUD = safeRequire(fpsHudModule, "FPSHUD")
		if FPSHUD and FPSHUD.initialize then pcall(FPSHUD.initialize) end
	end

	local playerHudModule = clientModules:FindFirstChild("PlayerHUD")
	if playerHudModule then
		PlayerHUD = safeRequire(playerHudModule, "PlayerHUD")
		if PlayerHUD and PlayerHUD.initialize then pcall(PlayerHUD.initialize) end
	end

	local lobbyUIModule = clientModules:FindFirstChild("LobbyUI")
	if lobbyUIModule then
		LobbyUI = safeRequire(lobbyUIModule, "LobbyUI")
		-- LobbyUI typically auto-hooks remotes on require
	end

	print("[ClientController] ✓ UI initialised")
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

function ClientController.onCharacterAdded(character)
	print("[ClientController] Character added:", character.Name)
	ensureClientReadyFlag(true)

	if Camera and Camera.onCharacterAdded then Camera.onCharacterAdded(character) end
	if Movement and Movement.onCharacterAdded then Movement.onCharacterAdded(character) end
	if WeaponController and WeaponController.onCharacterAdded then WeaponController.onCharacterAdded(character) end
	if AnimationController and AnimationController.onCharacterAdded then AnimationController.onCharacterAdded(character) end
end

function ClientController.onCharacterRemoving()
	print("[ClientController] Character removing")
	if Camera and Camera.onCharacterRemoving then Camera.onCharacterRemoving() end
	if Movement and Movement.onCharacterRemoving then Movement.onCharacterRemoving() end
	if WeaponController and WeaponController.onCharacterRemoving then WeaponController.onCharacterRemoving() end
	if AnimationController and AnimationController.onCharacterRemoving then AnimationController.onCharacterRemoving() end
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
