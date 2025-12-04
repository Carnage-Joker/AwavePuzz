-- FPSWeaponController.client.lua
-- Enhanced first-person weapon controller with recoil, spread, ADS, reload, and fire modes
-- Replaces the basic WeaponController with full FPS mechanics

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local WeaponConfig = require(SharedFolder:WaitForChild("WeaponConfig"))

-- Remote events
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local fireEvent = remoteFolder:WaitForChild("WeaponFire")
local equipEvent = remoteFolder:WaitForChild("WeaponEquip")
local loadoutEvent = remoteFolder:WaitForChild("WeaponLoadoutUpdate")
local hitEvent = remoteFolder:WaitForChild("WeaponHitConfirm")

-- Create new remote events if needed
local reloadEvent = remoteFolder:FindFirstChild("WeaponReload")
if not reloadEvent then
	reloadEvent = Instance.new("RemoteEvent")
	reloadEvent.Name = "WeaponReload"
	reloadEvent.Parent = remoteFolder
end

local ammoUpdateEvent = remoteFolder:FindFirstChild("AmmoUpdate")
if not ammoUpdateEvent then
	ammoUpdateEvent = Instance.new("RemoteEvent")
	ammoUpdateEvent.Name = "AmmoUpdate"
	ammoUpdateEvent.Parent = remoteFolder
end

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local FPSWeaponController = {}
FPSWeaponController.__index = FPSWeaponController

-- Weapon state
local currentWeapon = nil
local weapons = {}
local weaponStats = {}

-- Ammo state
local currentAmmo = 0
local reserveAmmo = 0
local maxAmmo = 0

-- Firing state
local isFiring = false
local canFire = true
local lastFireTime = 0
local consecutiveShots = 0
local fireMode = "Semi"
local burstShotsRemaining = 0

-- ADS state
local isADS = false
local adsTransition = 0 -- 0 = hip, 1 = full ADS

-- Reload state
local isReloading = false
local reloadStartTime = 0
local reloadDuration = 0

-- Recoil state
local currentRecoil = Vector2.new(0, 0) -- accumulated recoil
local recoilRecoverySpeed = 5

-- Spread state
local currentSpread = 0
local baseSpread = 0

-- Movement state (from movement controller)
local isMoving = false
local isSprinting = false

--------------------------------------------------------------------------------
-- UI BINDABLE EVENTS
--------------------------------------------------------------------------------

local function getOrCreateBindableEvent(name)
	local playerGui = player:WaitForChild("PlayerGui")
	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = "BindableEvents"
		bindableFolder.Parent = playerGui
	end
	
	local event = bindableFolder:FindFirstChild(name)
	if not event then
		event = Instance.new("BindableEvent")
		event.Name = name
		event.Parent = bindableFolder
	end
	
	return event
end

local ammoUIEvent = nil
local hitmarkerUIEvent = nil
local crosshairUIEvent = nil
local weaponInfoUIEvent = nil

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function getWeaponFPSStats(weaponId)
	-- First try FPS config, fall back to basic WeaponConfig
	local fpsStats = FPSConfig.getWeaponStats(weaponId)
	if fpsStats then
		return fpsStats
	end
	
	local basicStats = WeaponConfig.getWeapon(weaponId)
	if basicStats then
		-- Create FPS-compatible stats from basic stats
		return {
			Damage = basicStats.Damage,
			FireRate = basicStats.FireRate,
			Range = basicStats.Range,
			Automatic = basicStats.Automatic or false,
			FireMode = basicStats.Automatic and "Auto" or "Semi",
			MagSize = 30,
			ReserveAmmo = 120,
			ReloadTime = 2.0,
			RecoilVertical = 1.0,
			RecoilHorizontal = 0.5,
			RecoilRecovery = 5,
			HipSpread = 3.0,
			ADSSpread = 1.0,
			MoveSpreadMultiplier = 1.5,
			SpreadIncreasePerShot = 0.2,
			SpreadRecovery = 8,
			MaxSpread = 8,
			ADSZoom = 1.2,
			ADSSpeed = 0.15,
		}
	end
	
	return nil
end

--------------------------------------------------------------------------------
-- AMMO MANAGEMENT
--------------------------------------------------------------------------------

local function updateAmmoUI()
	if ammoUIEvent then
		ammoUIEvent:Fire({
			current = currentAmmo,
			reserve = reserveAmmo,
			max = maxAmmo,
			isReloading = isReloading,
		})
	end
end

local function setAmmo(current, reserve, max)
	currentAmmo = current or currentAmmo
	reserveAmmo = reserve or reserveAmmo
	maxAmmo = max or maxAmmo
	updateAmmoUI()
end

local function consumeAmmo()
	if currentAmmo > 0 then
		currentAmmo = currentAmmo - 1
		updateAmmoUI()
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- RECOIL SYSTEM
--------------------------------------------------------------------------------

local function applyRecoil()
	if not currentWeapon then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	-- Calculate recoil based on weapon stats and ADS state
	local verticalRecoil = stats.RecoilVertical
	local horizontalRecoil = stats.RecoilHorizontal
	
	-- Reduce recoil when ADS
	if isADS then
		local adsMultiplier = FPSConfig.Weapons.ADSRecoilMultiplier
		verticalRecoil = verticalRecoil * adsMultiplier
		horizontalRecoil = horizontalRecoil * adsMultiplier
	end
	
	-- Add randomness to horizontal recoil
	local horizontalDirection = (math.random() * 2 - 1)
	horizontalRecoil = horizontalRecoil * horizontalDirection
	
	-- Accumulate recoil
	currentRecoil = Vector2.new(
		currentRecoil.X + horizontalRecoil,
		currentRecoil.Y + verticalRecoil
	)
	
	-- Apply recoil to camera via bindable event
	local recoilEvent = getOrCreateBindableEvent("ApplyRecoil")
	recoilEvent:Fire(verticalRecoil, horizontalRecoil)
end

local function updateRecoilRecovery(deltaTime)
	if not currentWeapon then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	-- Recover recoil over time
	local recoverySpeed = (stats.RecoilRecovery or recoilRecoverySpeed) * deltaTime
	
	-- Apply recovery
	currentRecoil = Vector2.new(
		lerp(currentRecoil.X, 0, recoverySpeed),
		lerp(currentRecoil.Y, 0, recoverySpeed)
	)
	
	-- Apply negative recoil to camera (recovery)
	if math.abs(currentRecoil.Y) > 0.01 or math.abs(currentRecoil.X) > 0.01 then
		local recoilEvent = getOrCreateBindableEvent("ApplyRecoil")
		recoilEvent:Fire(-currentRecoil.Y * deltaTime * recoverySpeed, -currentRecoil.X * deltaTime * recoverySpeed)
	end
end

--------------------------------------------------------------------------------
-- SPREAD SYSTEM
--------------------------------------------------------------------------------

local function calculateCurrentSpread()
	if not currentWeapon then return 3.0 end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return 3.0 end
	
	-- Base spread based on ADS state
	baseSpread = isADS and stats.ADSSpread or stats.HipSpread
	
	-- Apply movement penalty
	local spread = baseSpread
	if isMoving then
		spread = spread * stats.MoveSpreadMultiplier
	end
	
	-- Apply consecutive shot penalty
	local shotPenalty = consecutiveShots * stats.SpreadIncreasePerShot
	spread = spread + shotPenalty
	
	-- Clamp to max spread
	spread = math.min(spread, stats.MaxSpread)
	
	currentSpread = spread
	return spread
end

local function updateSpreadRecovery(deltaTime)
	if not currentWeapon then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	-- Reduce consecutive shots over time (spread recovery)
	if not isFiring and consecutiveShots > 0 then
		local recoveryRate = (stats.SpreadRecovery or 8) * deltaTime
		consecutiveShots = math.max(0, consecutiveShots - recoveryRate)
	end
	
	-- Update crosshair UI with current spread
	if crosshairUIEvent then
		crosshairUIEvent:Fire({
			spread = calculateCurrentSpread(),
			isADS = isADS,
		})
	end
end

--------------------------------------------------------------------------------
-- ADS (AIM DOWN SIGHTS)
--------------------------------------------------------------------------------

local function updateADS(deltaTime)
	if not currentWeapon then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	local adsSpeed = FPSConfig.Weapons.ADSTransitionSpeed
	
	-- Transition ADS state
	local targetTransition = isADS and 1 or 0
	adsTransition = lerp(adsTransition, targetTransition, adsSpeed * deltaTime)
	
	-- Notify camera of ADS state for FOV
	local adsEvent = getOrCreateBindableEvent("ADSStateChanged")
	adsEvent:Fire({
		isADS = isADS,
		transition = adsTransition,
		zoom = stats.ADSZoom or 1.0,
	})
end

--------------------------------------------------------------------------------
-- RELOAD SYSTEM
--------------------------------------------------------------------------------

local function startReload()
	if isReloading then return end
	if currentAmmo >= maxAmmo then return end
	if reserveAmmo <= 0 then return end
	if not currentWeapon then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	isReloading = true
	reloadStartTime = tick()
	reloadDuration = stats.ReloadTime or 2.0
	
	-- Stop firing during reload
	isFiring = false
	canFire = false
	
	-- Cancel ADS during reload
	isADS = false
	
	-- Notify server
	reloadEvent:FireServer({ weaponId = currentWeapon })
	
	-- Update UI
	updateAmmoUI()
	
	-- Notify for reload animation
	local reloadAnimEvent = getOrCreateBindableEvent("ReloadStarted")
	reloadAnimEvent:Fire({
		duration = reloadDuration,
		weaponId = currentWeapon,
	})
	
	print("[FPSWeaponController] Reload started, duration:", reloadDuration)
end

local function finishReload()
	if not isReloading then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	-- Calculate ammo to reload
	local ammoNeeded = maxAmmo - currentAmmo
	local ammoToAdd = math.min(ammoNeeded, reserveAmmo)
	
	currentAmmo = currentAmmo + ammoToAdd
	reserveAmmo = reserveAmmo - ammoToAdd
	
	isReloading = false
	canFire = true
	
	-- Update UI
	updateAmmoUI()
	
	-- Notify reload complete
	local reloadAnimEvent = getOrCreateBindableEvent("ReloadFinished")
	reloadAnimEvent:Fire()
	
	print("[FPSWeaponController] Reload finished, ammo:", currentAmmo, "/", reserveAmmo)
end

local function cancelReload()
	if not isReloading then return end
	
	-- Check if enough time has passed to cancel
	local elapsed = tick() - reloadStartTime
	if elapsed < FPSConfig.Weapons.ReloadInterruptDelay then
		return -- Can't cancel yet
	end
	
	isReloading = false
	canFire = true
	
	-- Notify reload canceled
	local reloadAnimEvent = getOrCreateBindableEvent("ReloadCanceled")
	reloadAnimEvent:Fire()
	
	print("[FPSWeaponController] Reload canceled")
end

local function updateReload(deltaTime)
	if not isReloading then return end
	
	local elapsed = tick() - reloadStartTime
	
	-- Check if reload is complete
	if elapsed >= reloadDuration then
		finishReload()
	end
end

--------------------------------------------------------------------------------
-- FIRING SYSTEM
--------------------------------------------------------------------------------

local function getFireDirection()
	local camera = workspace.CurrentCamera
	if not camera then return Vector3.new(0, 0, -1) end
	
	-- Get base direction from camera
	local direction = camera.CFrame.LookVector
	
	-- Apply spread
	local spread = calculateCurrentSpread()
	if spread > 0 then
		local spreadRadians = math.rad(spread)
		local randomAngle = math.random() * math.pi * 2
		local randomSpread = math.random() * spreadRadians
		
		-- Create spread rotation
		local spreadRotation = CFrame.Angles(
			math.sin(randomAngle) * randomSpread,
			math.cos(randomAngle) * randomSpread,
			0
		)
		
		direction = (CFrame.new(Vector3.new(), direction) * spreadRotation).LookVector
	end
	
	return direction
end

local function fireWeapon()
	if not canFire or isReloading then return end
	if not currentWeapon then return end
	if isSprinting then return end -- Can't fire while sprinting
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	-- Check ammo
	if currentAmmo <= 0 then
		-- Play empty click sound
		local emptyEvent = getOrCreateBindableEvent("EmptyClick")
		emptyEvent:Fire()
		
		-- Auto-reload if enabled
		startReload()
		return
	end
	
	-- Check fire rate
	local currentTime = tick()
	if currentTime - lastFireTime < stats.FireRate then
		return
	end
	
	-- Consume ammo
	if not consumeAmmo() then return end
	
	lastFireTime = currentTime
	consecutiveShots = consecutiveShots + 1
	
	-- Get fire origin and direction
	local character = player.Character
	if not character then return end
	
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local direction = getFireDirection()
	
	-- Apply recoil
	applyRecoil()
	
	-- Send fire event to server
	fireEvent:FireServer({
		weaponId = currentWeapon,
		origin = origin,
		direction = direction * stats.Range,
		timestamp = currentTime,
	})
	
	-- Trigger visual effects
	local fireVisualEvent = getOrCreateBindableEvent("WeaponFired")
	fireVisualEvent:Fire({
		weaponId = currentWeapon,
		origin = origin,
		direction = direction,
	})
end

local function updateFiring(deltaTime)
	if not currentWeapon then return end
	
	local stats = getWeaponFPSStats(currentWeapon)
	if not stats then return end
	
	-- Handle automatic fire
	if isFiring and canFire and not isReloading and not isSprinting then
		local isAutomatic = stats.Automatic or stats.FireMode == "Auto"
		
		if isAutomatic then
			fireWeapon()
		elseif stats.FireMode == "Burst" and burstShotsRemaining > 0 then
			fireWeapon()
			burstShotsRemaining = burstShotsRemaining - 1
		end
	end
end

--------------------------------------------------------------------------------
-- WEAPON SWITCHING
--------------------------------------------------------------------------------

local function equipWeapon(weaponId)
	if not weaponId then return end
	if isReloading then
		cancelReload()
	end
	
	currentWeapon = weaponId
	
	local stats = getWeaponFPSStats(weaponId)
	if stats then
		maxAmmo = stats.MagSize or 30
		currentAmmo = maxAmmo
		reserveAmmo = stats.ReserveAmmo or 120
		fireMode = stats.FireMode or "Semi"
	end
	
	-- Reset states
	isADS = false
	adsTransition = 0
	consecutiveShots = 0
	currentRecoil = Vector2.new(0, 0)
	canFire = true
	
	-- Update UI
	updateAmmoUI()
	
	if weaponInfoUIEvent then
		weaponInfoUIEvent:Fire({
			weaponId = weaponId,
			weaponName = stats and stats.Name or weaponId,
			fireMode = fireMode,
		})
	end
	
	-- Send equip event to server
	equipEvent:FireServer(weaponId)
	
	print("[FPSWeaponController] Equipped:", weaponId)
end

local function equipSlot(slot)
	if not weapons or #weapons == 0 then return end
	
	local weaponId = weapons[slot]
	if not weaponId then return end
	
	if currentWeapon == weaponId then return end -- Already equipped
	
	equipWeapon(weaponId)
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

local function onInputBegan(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	-- Fire (left mouse button)
	if input.UserInputType == FPSConfig.Controls.FireKey then
		isFiring = true
		
		local stats = getWeaponFPSStats(currentWeapon)
		if stats then
			-- Handle non-automatic fire modes
			if not stats.Automatic and stats.FireMode ~= "Auto" then
				if stats.FireMode == "Burst" then
					burstShotsRemaining = FPSConfig.Weapons.BurstCount
				end
				fireWeapon()
			end
		end
	end
	
	-- ADS (right mouse button)
	if input.UserInputType == FPSConfig.Controls.ADSKey then
		if FPSConfig.Weapons.ReloadCancelEnabled and isReloading then
			cancelReload()
		end
		isADS = true
	end
	
	-- Reload
	if input.KeyCode == FPSConfig.Controls.ReloadKey then
		startReload()
	end
	
	-- Weapon slots
	if input.KeyCode == FPSConfig.Controls.WeaponSlot1 then
		equipSlot(1)
	elseif input.KeyCode == FPSConfig.Controls.WeaponSlot2 then
		equipSlot(2)
	elseif input.KeyCode == FPSConfig.Controls.WeaponSlot3 then
		equipSlot(3)
	elseif input.KeyCode == FPSConfig.Controls.WeaponSlot4 then
		equipSlot(4)
	end
end

local function onInputEnded(input, gameProcessedEvent)
	-- Fire release
	if input.UserInputType == FPSConfig.Controls.FireKey then
		isFiring = false
		burstShotsRemaining = 0
	end
	
	-- ADS release
	if input.UserInputType == FPSConfig.Controls.ADSKey then
		isADS = false
	end
end

--------------------------------------------------------------------------------
-- SERVER EVENTS
--------------------------------------------------------------------------------

loadoutEvent.OnClientEvent:Connect(function(payload)
	if payload.weapons then
		weapons = payload.weapons
	end
	if payload.equipped then
		equipWeapon(payload.equipped)
	end
	if payload.stats then
		weaponStats = payload.stats
	end
end)

hitEvent.OnClientEvent:Connect(function(payload)
	if payload and payload.position then
		-- Trigger hitmarker
		if hitmarkerUIEvent then
			hitmarkerUIEvent:Fire({
				position = payload.position,
				target = payload.target,
				isHeadshot = payload.isHeadshot,
				isKill = payload.isKill,
			})
		end
	end
end)

ammoUpdateEvent.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" then
		setAmmo(payload.current, payload.reserve, payload.max)
	end
end)

--------------------------------------------------------------------------------
-- MOVEMENT STATE SYNC
--------------------------------------------------------------------------------

local function setupMovementSync()
	local playerGui = player:WaitForChild("PlayerGui")
	local bindableFolder = playerGui:FindFirstChild("BindableEvents")
	if not bindableFolder then return end
	
	local sprintEvent = bindableFolder:FindFirstChild("SprintStateChanged")
	if sprintEvent then
		sprintEvent.Event:Connect(function(sprinting)
			isSprinting = sprinting
			if sprinting and isADS then
				isADS = false
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

local function update(deltaTime)
	updateFiring(deltaTime)
	updateReload(deltaTime)
	updateADS(deltaTime)
	updateRecoilRecovery(deltaTime)
	updateSpreadRecovery(deltaTime)
	
	-- Check if moving (simple check via humanoid)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			isMoving = humanoid.MoveDirection.Magnitude > 0.1
		end
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	-- Setup UI events
	ammoUIEvent = getOrCreateBindableEvent("AmmoUpdate")
	hitmarkerUIEvent = getOrCreateBindableEvent("Hitmarker")
	crosshairUIEvent = getOrCreateBindableEvent("CrosshairUpdate")
	weaponInfoUIEvent = getOrCreateBindableEvent("WeaponInfoUpdate")
	
	-- Connect input
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	
	-- Connect update loop
	RunService.Heartbeat:Connect(update)
	
	-- Setup movement sync
	task.spawn(function()
		task.wait(1) -- Wait for movement controller to initialize
		setupMovementSync()
	end)
	
	-- Character added
	player.CharacterAdded:Connect(function(character)
		-- Reset states on respawn
		isReloading = false
		canFire = true
		consecutiveShots = 0
		currentRecoil = Vector2.new(0, 0)
		
		-- Re-initialize ammo
		if currentWeapon then
			local stats = getWeaponFPSStats(currentWeapon)
			if stats then
				currentAmmo = stats.MagSize or 30
				reserveAmmo = stats.ReserveAmmo or 120
				maxAmmo = stats.MagSize or 30
				updateAmmoUI()
			end
		end
	end)
	
	print("[FPSWeaponController] Initialized")
end

-- Public API
function FPSWeaponController.isADS()
	return isADS
end

function FPSWeaponController.isReloading()
	return isReloading
end

function FPSWeaponController.getCurrentWeapon()
	return currentWeapon
end

function FPSWeaponController.getAmmo()
	return currentAmmo, reserveAmmo, maxAmmo
end

-- Initialize
initialize()

return FPSWeaponController
