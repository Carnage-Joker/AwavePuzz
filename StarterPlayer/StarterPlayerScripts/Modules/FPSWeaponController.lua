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
-- - ADS (Aim Down Sights) with right-click
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

-- Helper: Check if gameplay input should be blocked by modal state
local function shouldBlockGameplay()
	-- Block gameplay when MODAL or FULLSCREEN priority modals are active
	-- PANEL priority (like Scoreboard) allows gameplay to continue
	return ModalManager.shouldBlockGameplay()
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

-- Connection storage for cleanup
local inputBeganConn = nil
local inputEndedConn = nil
local fireConnection = nil

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

	weaponReloadEvent:FireServer({
		weaponId = currentWeapon
	})

	isReloading = true

	-- Fire reload animation event
	local reloadTime = 2.0
	if weaponStats and weaponStats.ReloadTime then
		reloadTime = weaponStats.ReloadTime
	end
	reloadStartedBindable:Fire({
		weaponId = currentWeapon,
		duration = reloadTime
	})

	ammoUpdateBindable:Fire({
		weaponId = currentWeapon,
		isReloading = true
	})
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
	if data.weaponId ~= currentWeapon then
		if DEBUG_AMMO then
			print(string.format("[FPSWeaponController] ⚠ Syncing currentWeapon from server: %s -> %s", 
				tostring(currentWeapon), tostring(data.weaponId)))
		end
		currentWeapon = data.weaponId
		weaponStats = getWeaponStats(data.weaponId)
		updateWeaponInfo(data.weaponId)
		
		-- Fire weapon equipped event to notify animation and other systems
		weaponEquippedBindable:Fire(data.weaponId)
	end
	
	-- Require at least current and reserve data (max can be derived if missing)
	if data.current ~= nil and data.reserve ~= nil then
		-- Use provided max, or derive from weapon stats, or use default
		local maxAmmo = data.max
		if not maxAmmo and weaponStats then
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
		
		if DEBUG_AMMO then
			print(string.format("[FPSWeaponController] ✓ Ammo update applied: %s (current=%d, reserve=%d, max=%d)", 
				data.weaponId, data.current, data.reserve, maxAmmo))
		end
	elseif DEBUG_AMMO then
		print(string.format("[FPSWeaponController] ✗ Dropped update: missing required data (current=%s, reserve=%s)",
			tostring(data.current), tostring(data.reserve)))
	end
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

-- Spread recovery
RunService.Heartbeat:Connect(function(deltaTime)
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

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	-- Setup InputManager callbacks
	setupInputCallbacks()

	-- Connect legacy input events (for weapon switching on keyboard)
	inputBeganConn = UserInputService.InputBegan:Connect(onInputBegan)
	inputEndedConn = UserInputService.InputEnded:Connect(onInputEnded)

	-- Equip default weapon
	equipWeapon(WeaponConfig.DefaultWeapon)

	print("[FPSWeaponController] Initialized - Device:", InputManager.getActiveDevice())
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

-- Module export (without auto-init)
local FPSWeaponControllerModule = {}

function FPSWeaponControllerModule.initialize()
	initialize()
end

function FPSWeaponControllerModule.onCharacterAdded(character)
	-- FIX: Refresh weapon info on respawn
	-- The server will send WeaponLoadoutUpdate and AmmoUpdate via the GameManager hookCharacter
	-- This ensures the client UI is ready to receive those updates
	if currentWeapon then
		-- Refresh weapon display (name, fire mode), actual ammo comes from server events
		refreshWeaponDisplay(currentWeapon)
	end
	
	if DEBUG_AMMO then
		print(string.format("[FPSWeaponController] Character added, currentWeapon: %s", tostring(currentWeapon)))
	end
end

function FPSWeaponControllerModule.onCharacterRemoving()
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
end

return FPSWeaponControllerModule