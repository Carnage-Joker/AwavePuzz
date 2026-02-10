-- @ScriptType: ModuleScript
-- FPSWeaponController.client.lua
-- ADVANCED weapon controller for full FPS mechanics
--
-- NOTE: This is the ADVANCED/FULL FPS weapon controller.
-- For a simpler version, see WeaponController.client.lua
--
-- Features:
-- - Recoil system with camera kick and recovery
-- - Dynamic spread based on movement/firing
-- - ADS (Aim Down Sights) with left alt key
-- - Fire modes: Semi-auto, Burst, Full-auto
-- - Magazine + reserve ammo system
-- - Manual reload with R key
-- - Spread recovery and crosshair updates
--
-- See CODE_ARCHITECTURE.md for details on the dual weapon controller setup.

-- Debug flag - set to true to enable detailed logging
local DEBUG_AMMO = false  -- Set to true to debug ammo UI issues

-- Constants
local DEFAULT_MAGAZINE_SIZE = 30  -- Fallback magazine size when weapon config is unavailable

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local WeaponConfig = require(SharedFolder:WaitForChild("WeaponConfig"))
local InputManager = require(SharedFolder:WaitForChild("InputManager"))
local ModalManager = require(SharedFolder:WaitForChild("ModalManager"))
local InputActionRegistry = require(SharedFolder:WaitForChild("InputActionRegistry"))

--------------------------------------------------------------------------------
-- STATE MANAGEMENT
--------------------------------------------------------------------------------

local currentWeapon = nil
local weaponStats = nil
local isAiming = false
local isReloading = false
local lastFireTime = 0
local consecutiveShots = 0
local lastShotTime = 0
local currentSpread = 0
local targetSpread = 0
local _enabled = true -- Weapon controller enabled/disabled state

-- BUG-009 FIX: Request-response pattern for reload with timeout
local pendingReloadRequest = nil -- Track pending reload request for timeout handling
local RELOAD_CONFIRM_TIMEOUT = 2.0 -- Seconds to wait for server confirmation

-- Helper: Check if gameplay input should be blocked by modal state
local function shouldBlockGameplay()
	-- Block gameplay when MODAL or FULLSCREEN priority modals are active
	-- PANEL priority (like Scoreboard) allows gameplay to continue
	-- Also block if weapon controller is explicitly disabled via setEnabled()
	return not _enabled or ModalManager.shouldBlockGameplay()
end

-- Remote events
-- Note: Using :WaitForChild() is safe here as RemoteEvents folder is created by server at startup
-- All required events are guaranteed to exist before clients load
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local weaponFireEvent = remoteEvents:WaitForChild("WeaponFire")
local weaponEquipEvent = remoteEvents:WaitForChild("WeaponEquip")
local weaponReloadEvent = remoteEvents:WaitForChild("WeaponReload")
local ammoUpdateEvent = remoteEvents:WaitForChild("AmmoUpdate")
local hitConfirmEvent = remoteEvents:WaitForChild("WeaponHitConfirm")
local weaponLoadoutUpdateEvent = remoteEvents:WaitForChild("WeaponLoadoutUpdate")  -- FIX: Added for server sync
local reloadConfirmEvent = remoteEvents:WaitForChild("ReloadConfirm")  -- BUG-009 FIX: Server confirmation for reload

-- Connection storage for cleanup
local inputBeganConn = nil
local inputEndedConn = nil
local fireConnection = nil
local heartbeatConnection = nil  -- BUG-014: Store heartbeat connection for cleanup

-- Bindable events for UI and animation communication
local bindableFolder = playerGui:WaitForChild("BindableEvents", 10)
if not bindableFolder then
	bindableFolder = Instance.new("Folder")
	bindableFolder.Name = "BindableEvents"
	bindableFolder.Parent = playerGui
end

-- Helper function to get or create bindable events
local function getOrCreateBindable(name)
	local bindable = bindableFolder:FindFirstChild(name)
	if not bindable then
		bindable = Instance.new("BindableEvent")
		bindable.Name = name
		bindable.Parent = bindableFolder
	end
	return bindable
end

local ammoUpdateBindable = getOrCreateBindable("AmmoUpdate")
local hitmarkerBindable = getOrCreateBindable("Hitmarker")
local crosshairBindable = getOrCreateBindable("CrosshairUpdate")
local weaponInfoBindable = getOrCreateBindable("WeaponInfoUpdate")

-- Animation events
local weaponFiredBindable = getOrCreateBindable("WeaponFired")
local reloadStartedBindable = getOrCreateBindable("ReloadStarted")
local reloadCanceledBindable = getOrCreateBindable("ReloadCanceled")
local weaponEquippedBindable = getOrCreateBindable("WeaponEquipped")
local adsStateBindable = getOrCreateBindable("ADSStateChanged")

--------------------------------------------------------------------------------
-- WEAPON FUNCTIONS
--------------------------------------------------------------------------------

local function getWeaponStats(weaponId)
	return FPSConfig.getWeaponStats(weaponId)
end

local function updateWeaponInfo(weaponId)
	local stats = getWeaponStats(weaponId)
	if not stats then return end

	local weaponConfig = WeaponConfig.getWeapon(weaponId)
	local weaponName = weaponConfig and weaponConfig.Name or weaponId
	local fireMode = stats.Automatic and "AUTO" or "SEMI"

	weaponInfoBindable:Fire({
		weaponId = weaponId,
		weaponName = weaponName,
		fireMode = fireMode
	})
end

local function refreshWeaponDisplay(weaponId)
	-- Refresh weapon info display (name, fire mode)
	-- Actual ammo numbers are updated via bindable events from server
	if weaponId then
		updateWeaponInfo(weaponId)
	end
end

local function canFire()
	-- Check if gameplay should be blocked by modals
	if shouldBlockGameplay() then
		return false
	end
	
	if not currentWeapon or not weaponStats then
		return false
	end

	if isReloading then
		return false
	end

	local now = tick()
	if now - lastFireTime < weaponStats.FireRate then
		return false
	end

	return true
end

local function fireWeapon()
	if not canFire() then return end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	-- Calculate fire origin and direction
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	-- Apply spread
	local spread = FPSConfig.calculateSpread(currentWeapon, isAiming, false, consecutiveShots)
	if spread > 0 then
		local randomAngle = math.random() * math.pi * 2
		local randomRadius = math.random() * spread
		local spreadX = math.cos(randomAngle) * randomRadius
		local spreadY = math.sin(randomAngle) * randomRadius

		local spreadCFrame = CFrame.Angles(math.rad(spreadY), math.rad(spreadX), 0)
		direction = spreadCFrame:VectorToWorldSpace(direction)
	end

	-- Send fire event to server
	weaponFireEvent:FireServer({
		weaponId = currentWeapon,
		origin = origin,
		direction = direction
	})

	-- Fire animation event
	weaponFiredBindable:Fire({
		weaponId = currentWeapon
	})

	-- Update state
	lastFireTime = tick()
	consecutiveShots = consecutiveShots + 1
	lastShotTime = tick()

	-- Update spread
	targetSpread = math.min(targetSpread + weaponStats.SpreadIncreasePerShot, weaponStats.MaxSpread)

	-- Update crosshair
	crosshairBindable:Fire({
		spread = targetSpread,
		isADS = isAiming
	})
end

local function startReload()
	-- Check if gameplay should be blocked by modals
	if shouldBlockGameplay() then
		return
	end
	
	if not currentWeapon or isReloading then return end
	
	-- BUG-009 FIX: Don't set isReloading immediately - wait for server confirmation
	-- This prevents client-side state manipulation exploits
	
	-- Prevent duplicate reload requests while one is pending
	if pendingReloadRequest then
		return
	end
	
	-- Send reload request to server
	weaponReloadEvent:FireServer({
		weaponId = currentWeapon
	})
	
	-- Track pending request for timeout handling
	local requestTime = tick()
	local requestWeapon = currentWeapon
	pendingReloadRequest = {
		weaponId = requestWeapon,
		requestTime = requestTime
	}
	
	-- Set up timeout to cancel request if server doesn't respond
	task.delay(RELOAD_CONFIRM_TIMEOUT, function()
		if pendingReloadRequest and pendingReloadRequest.requestTime == requestTime then
			-- Server didn't respond within timeout - clear pending request
			warn("[FPSWeaponController] Reload request timed out for weapon: " .. tostring(requestWeapon))
			pendingReloadRequest = nil
		end
	end)
end

local function cancelReload()
	if not isReloading then return end
	
	-- Cancel any active firing when reload is cancelled
	if fireConnection then
		fireConnection:Disconnect()
		fireConnection = nil
	end
	
	isReloading = false

	-- Fire reload canceled event
	reloadCanceledBindable:Fire()

	ammoUpdateBindable:Fire({
		weaponId = currentWeapon,
		isReloading = false
	})
end

local function equipWeapon(weaponId)
	-- Check if gameplay should be blocked by modals
	if shouldBlockGameplay() then
		return
	end
	
	if currentWeapon == weaponId then return end

	-- Cleanup any active fire connections on weapon switch
	if fireConnection then
		fireConnection:Disconnect()
		fireConnection = nil
	end
	
	-- Clear pending reload request when switching weapons
	pendingReloadRequest = nil

	currentWeapon = weaponId
	weaponStats = getWeaponStats(weaponId)
	isReloading = false
	consecutiveShots = 0
	targetSpread = 0

	updateWeaponInfo(weaponId)
	refreshWeaponDisplay(weaponId)

	-- Request weapon equip on server
	weaponEquipEvent:FireServer(weaponId)

	-- Fire weapon equipped event for animations
	weaponEquippedBindable:Fire(weaponId)
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

local weaponSwitchConnections = {}

-- Setup InputManager callbacks
local function setupInputCallbacks()
	-- Initialize InputManager
	InputManager.initialize()

	-- Fire action (can be held for automatic weapons)
	local isFiring = false
	InputManager.bindAction(InputManager.Action.FIRE, function(active)
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			if isFiring then
				isFiring = false
				if fireConnection then
					fireConnection:Disconnect()
					fireConnection = nil
				end
			end
			return
		end
		
		if active then
			if not isFiring then
				isFiring = true
				if weaponStats and weaponStats.Automatic then
					fireConnection = RunService.Heartbeat:Connect(fireWeapon)
				else
					fireWeapon()
				end
			end
		else
			isFiring = false
			if fireConnection then
				fireConnection:Disconnect()
				fireConnection = nil
			end
		end
	end)

	-- ADS action
	InputManager.bindAction(InputManager.Action.AIM, function(active)
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			isAiming = false
			adsStateBindable:Fire(false)
			return
		end
		
		isAiming = active
		adsStateBindable:Fire(active)
		crosshairBindable:Fire({
			spread = targetSpread,
			isADS = active
		})
	end)

	-- Reload action
	InputManager.bindAction(InputManager.Action.RELOAD, function(active)
		-- Check if gameplay should be blocked
		if shouldBlockGameplay() then
			return
		end
		
		if active then
			startReload()
		end
	end)

	-- Weapon switching (not all devices support these)
	-- Weapons can also be switched via UI on touch devices

	-- Note: For VR, weapon switching would typically be done via radial menu or gestures
	-- For touch, weapon switching is done via on-screen UI buttons
end

-- Legacy input handler (kept for compatibility)
local function onInputBegan(input, gameProcessed)
	-- ALWAYS check gameProcessedEvent first
	if gameProcessed then return end
	
	-- Check if gameplay should be blocked
	if shouldBlockGameplay() then return end

	-- Weapon switching with number keys (keyboard only)
	if input.KeyCode == FPSConfig.Controls.WeaponSlot1 or input.KeyCode == Enum.KeyCode.One then
		equipWeapon("Pistol")
	elseif input.KeyCode == FPSConfig.Controls.WeaponSlot2 or input.KeyCode == Enum.KeyCode.Two then
		equipWeapon("SMG")
	elseif input.KeyCode == FPSConfig.Controls.WeaponSlot3 or input.KeyCode == Enum.KeyCode.Three then
		equipWeapon("Shotgun")
	elseif input.KeyCode == FPSConfig.Controls.WeaponSlot4 or input.KeyCode == Enum.KeyCode.Four then
		equipWeapon("Rifle")
	end
end

local function onInputEnded(input, gameProcessed)
	-- Legacy handler - most input is now handled by InputManager
	-- Cancel reload on movement (handled by checking movement state)
end

--------------------------------------------------------------------------------
-- EVENT CONNECTIONS
--------------------------------------------------------------------------------

-- Ammo updates from server
ammoUpdateEvent.OnClientEvent:Connect(function(data)
	-- Debug logging for all ammo updates
	if DEBUG_AMMO then
		print(string.format("[FPSWeaponController] AmmoUpdate received - weaponId=%s, current=%s, reserve=%s, max=%s, currentWeapon=%s", 
			tostring(data and data.weaponId), 
			tostring(data and data.current), 
			tostring(data and data.reserve), 
			tostring(data and data.max),
			tostring(currentWeapon)))
	end
	
	-- Validate data structure to prevent crashes (check for nil, not truthy, to allow 0 ammo)
	if typeof(data) ~= "table" or not data.weaponId then
		if DEBUG_AMMO then
			print("[FPSWeaponController] ✗ Dropped update: invalid data structure")
		end
		return
	end
	
	-- FIX: Accept ammo updates even if currentWeapon is nil or mismatched
	-- This handles cases where:
	-- 1. Player just spawned and currentWeapon isn't set yet
	-- 2. Server equipped a weapon before client received the equip event
	-- 3. State transitions caused temporary desync
	
	-- If weaponId doesn't match currentWeapon, sync it from the server
	-- NOTE: The server is the authority for weapon state, so syncing from server
	-- is always correct even if updates arrive out of order. The latest update
	-- represents the current server state.
	-- SECURITY: RemoteEvents.OnClientEvent can ONLY be fired by the server.
	-- Clients cannot spoof these events, so this sync is always safe.
	if data.weaponId ~= currentWeapon then
		if DEBUG_AMMO then
			print(string.format("[FPSWeaponController] ⚠ Syncing currentWeapon from server: %s -> %s", 
				tostring(currentWeapon), tostring(data.weaponId)))
		end
		currentWeapon = data.weaponId
		weaponStats = getWeaponStats(data.weaponId)
		
		-- Validate weaponStats after fetching
		if not weaponStats then
			warn(string.format("[FPSWeaponController] Failed to get weapon stats for weaponId '%s' during ammo update sync", tostring(data.weaponId)))
			-- Reset to nil to avoid stale data
			currentWeapon = nil
			return
		end
		
		updateWeaponInfo(data.weaponId)
		-- NOTE: Do not fire weaponEquippedBindable here.
		-- Weapon equips (animations, state transitions) are handled by the
		-- WeaponLoadoutUpdate handler to avoid duplicate equip events when
		-- AmmoUpdate and WeaponLoadoutUpdate arrive out of order.
	end
	
	-- Require at least current and reserve data (max can be derived if missing)
	if data.current ~= nil and data.reserve ~= nil then
		-- Use provided max, or derive from weapon stats, or use default
		local maxAmmo = data.max
		if not maxAmmo and weaponStats and weaponStats.MagSize then
			maxAmmo = weaponStats.MagSize
		end
		if not maxAmmo then
			-- Fallback to default magazine size
			maxAmmo = DEFAULT_MAGAZINE_SIZE
			if DEBUG_AMMO then
				print(string.format("[FPSWeaponController] ⚠ Using default max (%d) for weapon %s", 
					DEFAULT_MAGAZINE_SIZE, tostring(data.weaponId)))
			end
		end
		
		ammoUpdateBindable:Fire({
			current = data.current,
			reserve = data.reserve,
			max = maxAmmo,
			isReloading = false
		})

		-- Update reload state
		isReloading = false
		
		-- BUGFIX (MEDIUM): Reset consecutive shots on reload completion
		consecutiveShots = 0
		
		if DEBUG_AMMO then
			print(string.format("[FPSWeaponController] ✓ Ammo update applied: %s (current=%d, reserve=%d, max=%d)", 
				data.weaponId, data.current, data.reserve, maxAmmo))
		end
	elseif DEBUG_AMMO then
		print(string.format("[FPSWeaponController] ✗ Dropped update: missing required data (current=%s, reserve=%s)",
			tostring(data.current), tostring(data.reserve)))
	end
end)

-- BUG-009 FIX: Handle server confirmation for reload requests
-- This implements server-authoritative reload state (prevents rapid fire exploits)
reloadConfirmEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	
	-- Validate confirmation matches our pending request
	local pending = pendingReloadRequest
	if not pending then
		-- No pending reload for this client - ignore
		return
	end

	-- Weapon must match the weapon we most recently requested a reload for
	if pending.weaponId ~= data.weaponId then
		-- Not our weapon - ignore
		return
	end
	
	-- Also verify this matches our currently equipped weapon to prevent stale confirmations
	-- This handles the case where weapon was switched after reload request was sent
	if currentWeapon ~= data.weaponId then
		-- Weapon was switched after reload request - ignore stale confirmation
		pendingReloadRequest = nil
		return
	end
	
	-- Clear pending request
	pendingReloadRequest = nil
	
	-- Only proceed if reload was successful
	if not data.success then
		warn("[FPSWeaponController] Server rejected reload request")
		return
	end
	
	-- Server confirmed reload - now set isReloading state
	isReloading = true
	
	-- Use server-provided reload time (server is authority)
	-- Fall back to weaponStats or default if server didn't provide it
	local reloadTime = data.reloadTime
	if not reloadTime then
		reloadTime = (weaponStats and weaponStats.ReloadTime) or 2.0
	end
	reloadStartedBindable:Fire({
		weaponId = data.weaponId,
		duration = reloadTime
	})
	
	ammoUpdateBindable:Fire({
		weaponId = data.weaponId,
		isReloading = true
	})
end)

-- FIX: Listen for server-authoritative weapon loadout updates
-- This ensures client syncs with server when weapon is equipped (e.g., on spawn or server-forced equip)
weaponLoadoutUpdateEvent.OnClientEvent:Connect(function(data)
	if typeof(data) == "table" and data.equipped then
		-- Only update if the equipped weapon differs from current
		if data.equipped ~= currentWeapon then
			-- Sync to server's equipped weapon without sending another equip request
			currentWeapon = data.equipped
			weaponStats = getWeaponStats(data.equipped)
			isReloading = false
			consecutiveShots = 0
			targetSpread = 0
			
			updateWeaponInfo(data.equipped)
			refreshWeaponDisplay(data.equipped)
			
			-- Fire weapon equipped event for animations
			weaponEquippedBindable:Fire(data.equipped)
			
			if DEBUG then
				print(string.format("[FPSWeaponController] Synced to server weapon: %s", data.equipped))
			end
		end
	end
end)

-- Hit confirmation from server
hitConfirmEvent.OnClientEvent:Connect(function(data)
	if typeof(data) == "table" then
		-- Simple hit detection - could be enhanced
		local isHeadshot = false
		local isKill = false

		hitmarkerBindable:Fire({
			isHeadshot = isHeadshot,
			isKill = isKill
		})
	end
end)

--------------------------------------------------------------------------------
-- UPDATE LOOPS
--------------------------------------------------------------------------------

-- BUG-014: Setup heartbeat connection for spread recovery
-- This is called on character spawn to ensure connection is recreated after respawn
local function setupHeartbeatConnection()
	-- Disconnect existing connection to prevent leaks
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	
	-- Create new heartbeat connection for spread recovery
	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if weaponStats and tick() - lastShotTime > 0.1 then
			targetSpread = math.max(0, targetSpread - weaponStats.SpreadRecovery * deltaTime)
		end

		-- Smooth spread animation
		currentSpread = currentSpread + (targetSpread - currentSpread) * 0.1

		-- Update crosshair if needed
		if math.abs(currentSpread - targetSpread) > 0.1 then
			crosshairBindable:Fire({
				spread = currentSpread,
				isADS = isAiming
			})
		end

		-- Reset consecutive shots after delay
		if tick() - lastShotTime > 1.0 then
			consecutiveShots = 0
		end
	end)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	-- Register weapon switching input actions with InputActionRegistry for conflict detection
	-- Phase 3: Actions are registered but weapon switching logic is not yet implemented in this controller
	-- Future work: Add weapon inventory system and switching handlers
	InputActionRegistry.register("WeaponSwitch", "FPSWeaponController", {Enum.KeyCode.Q}, InputActionRegistry.Priority.CORE_GAMEPLAY)
	InputActionRegistry.register("WeaponSwitchGamepad", "FPSWeaponController", {Enum.KeyCode.ButtonY}, InputActionRegistry.Priority.CORE_GAMEPLAY)
	InputActionRegistry.register("NextWeapon", "FPSWeaponController", {Enum.KeyCode.E}, InputActionRegistry.Priority.CORE_GAMEPLAY)
	InputActionRegistry.register("NextWeaponGamepad", "FPSWeaponController", {Enum.KeyCode.ButtonR1}, InputActionRegistry.Priority.CORE_GAMEPLAY)
	InputActionRegistry.register("PrevWeapon", "FPSWeaponController", {Enum.KeyCode.Tab}, InputActionRegistry.Priority.CORE_GAMEPLAY)
	InputActionRegistry.register("PrevWeaponGamepad", "FPSWeaponController", {Enum.KeyCode.ButtonL1}, InputActionRegistry.Priority.CORE_GAMEPLAY)

	-- Setup InputManager callbacks
	setupInputCallbacks()

	-- Connect legacy input events (for weapon switching on keyboard)
	inputBeganConn = UserInputService.InputBegan:Connect(onInputBegan)
	inputEndedConn = UserInputService.InputEnded:Connect(onInputEnded)

	-- BUG-014: Setup heartbeat connection for spread recovery
	setupHeartbeatConnection()

	-- Equip default weapon
	equipWeapon(WeaponConfig.DefaultWeapon)

	print("[FPSWeaponController] Initialized - Device:", InputManager.getActiveDevice())
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

-- Module export (without auto-init)
local FPSWeaponController = {}

function FPSWeaponController.initialize()
	initialize()
end

function FPSWeaponController.onCharacterAdded(character)
	-- FIX: Refresh weapon info on respawn
	-- The server will send WeaponLoadoutUpdate and AmmoUpdate via the GameManager hookCharacter
	-- This ensures the client UI is ready to receive those updates
	if currentWeapon then
		-- Refresh weapon display (name, fire mode), actual ammo comes from server events
		refreshWeaponDisplay(currentWeapon)
	end
	
	-- BUG-014: Recreate heartbeat connection on respawn
	setupHeartbeatConnection()
	
	if DEBUG_AMMO then
		print(string.format("[FPSWeaponController] Character added, currentWeapon: %s", tostring(currentWeapon)))
	end
end

function FPSWeaponController.onCharacterRemoving()
	-- Cleanup connections to prevent memory leaks
	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end
	if inputEndedConn then
		inputEndedConn:Disconnect()
		inputEndedConn = nil
	end
	if fireConnection then
		fireConnection:Disconnect()
		fireConnection = nil
	end
	-- BUG-014: Disconnect heartbeat connection to prevent memory leak
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

-- Enable or disable weapon controller (used by state manager)
function FPSWeaponController.setEnabled(enabled)
	_enabled = enabled
	if not enabled then
		-- Cancel any active firing
		if fireConnection then
			fireConnection:Disconnect()
			fireConnection = nil
		end
		-- Reset weapon state
		isAiming = false
		isReloading = false
		adsStateBindable:Fire(false)
	end
	print(string.format("[FPSWeaponController] Weapons %s", enabled and "enabled" or "disabled"))
end

function FPSWeaponController.isEnabled()
	return _enabled
end

return FPSWeaponController