-- @ScriptType: ModuleScript

-- FPSWeaponService.lua
-- Server-side extension for FPS weapon mechanics
-- Handles ammo tracking, reload validation, and (optional) hit multipliers

-- Debug flag - set to true to enable detailed logging
local DEBUG_AMMO = false  -- Set to true to debug ammo UI issues

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[FPSWeaponService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local FPSConfig = SharedFolder:WaitForChild("FPSConfig", 5)
if not FPSConfig then
	error("[FPSWeaponService] CRITICAL: Failed to load FPSConfig after 5 seconds")
end
FPSConfig = require(FPSConfig)

local RemoteRegistry = SharedFolder:WaitForChild("RemoteRegistry", 5)
if not RemoteRegistry then
	error("[FPSWeaponService] CRITICAL: Failed to load RemoteRegistry after 5 seconds")
end
RemoteRegistry = require(RemoteRegistry)

local FPSWeaponService = {}
FPSWeaponService.__index = FPSWeaponService

-- Security: Ammo validation constants
local AMMO_SYNC_INTERVAL = 30 -- Check ammo consistency every 30 seconds

function FPSWeaponService.new(playerManager, weaponService)
	local self = setmetatable({}, FPSWeaponService)

	self.playerManager = playerManager
	self.weaponService = weaponService

	self.playerAmmo = {} -- userId -> { weaponId -> { current, reserve, max } }
	self.playerReloadState = {} -- userId -> { isReloading, reloadStartTime, weaponId }
	self.activeReloadTasks = {} -- userId -> task handle (to cancel on disconnect)
	
	-- Security: Track last ammo sync time per player
	self.lastAmmoSync = {} -- userId -> timestamp
	
	-- BUG-001: Flag to control validation loop lifecycle
	self._isRunning = false

	self.remoteEvents = {}
	self:setupRemoteEvents()
	
	-- Security: Start periodic ammo validation
	self:startAmmoValidationLoop()

	-- Cleanup: Ensure per-player state is cleared when players disconnect
	self.playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
		if not player or not player.UserId then
			return
		end

		local userId = player.UserId

		-- Clear all per-player caches to avoid memory leaks
		self.playerAmmo[userId] = nil
		self.playerReloadState[userId] = nil
		self.activeReloadTasks[userId] = nil
		self.lastAmmoSync[userId] = nil
	end)
	return self
end

function FPSWeaponService:setupRemoteEvents()
	-- Use RemoteRegistry to get server remotes
	local remotes = RemoteRegistry.GetServerRemotes()
	self.remoteEvents = {
		WeaponReload = remotes.WeaponReload,
		AmmoUpdate = remotes.AmmoUpdate,
		ReloadConfirm = remotes.ReloadConfirm,
	}

	self.remoteEvents.WeaponReload.OnServerEvent:Connect(function(player, payload)
		-- Validate payload structure to prevent client exploits
		if typeof(payload) ~= "table" then
			return
		end
		
		-- BUG-009: Send explicit failure confirmation for malformed payloads
		if not payload.weaponId then
			self:sendReloadConfirmation(player, nil, false, 0)
			return
		end
		
		self:handleReload(player, payload)
	end)
end

function FPSWeaponService:initializePlayer(player)
	local userId = player.UserId
	self.playerAmmo[userId] = {}

	local defaultWeapon = self.playerManager:getEquippedWeapon(player)
	if defaultWeapon then
		self:initializeWeaponAmmo(player, defaultWeapon)
	end
end

-- Add player to FPS weapon tracking (safe to call multiple times)
-- Does not require character/humanoid at call time
function FPSWeaponService:addPlayer(player)
	-- Validate input
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	
	local userId = player.UserId
	
	-- Ensure player ammo tracking exists (idempotent)
	if not self.playerAmmo[userId] then
		self:initializePlayer(player)
	end
	
	return true
end

function FPSWeaponService:removePlayer(player)
	local userId = player.UserId
	
	-- Cancel any pending reload timers to prevent memory leaks
	if self.activeReloadTasks[userId] then
		task.cancel(self.activeReloadTasks[userId])
		self.activeReloadTasks[userId] = nil
	end
	
	self.playerAmmo[userId] = nil
	self.playerReloadState[userId] = nil
end

function FPSWeaponService:initializeWeaponAmmo(player, weaponId)
	-- Validate player is still connected
	if not player or not player.Parent then
		if DEBUG_AMMO then
			warn("[FPSWeaponService] Cannot initialize ammo: player is disconnected")
		end
		return
	end
	
	local userId = player.UserId
	self.playerAmmo[userId] = self.playerAmmo[userId] or {}

	local stats = FPSConfig.getWeaponStats(weaponId)
	if stats then
		self.playerAmmo[userId][weaponId] = {
			current = stats.MagSize,
			reserve = stats.ReserveAmmo,
			max = stats.MagSize,
		}
	else
		self.playerAmmo[userId][weaponId] = {
			current = 30,
			reserve = 120,
			max = 30,
		}
	end

	self:sendAmmoUpdate(player, weaponId)
end

function FPSWeaponService:getAmmo(player, weaponId)
	local userId = player.UserId
	if not self.playerAmmo[userId] then return nil end

	local equipped = weaponId or self.playerManager:getEquippedWeapon(player)
	return equipped and self.playerAmmo[userId][equipped] or nil
end

function FPSWeaponService:consumeAmmo(player, weaponId, amount)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return false end

	amount = amount or 1
	if ammo.current < amount then
		return false
	end

	ammo.current -= amount
	self:sendAmmoUpdate(player, weaponId)
	return true
end

function FPSWeaponService:addAmmo(player, weaponId, amount, isReserve)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return false end

	if isReserve then
		ammo.reserve += amount
	else
		ammo.current = math.min(ammo.current + amount, ammo.max)
	end

	self:sendAmmoUpdate(player, weaponId)
	return true
end

function FPSWeaponService:handleReload(player, payload)
	if typeof(payload) ~= "table" then return end

	local userId = player.UserId
	local weaponId = payload.weaponId or self.playerManager:getEquippedWeapon(player)
	if not weaponId then
		-- Send failure confirmation
		self:sendReloadConfirmation(player, weaponId, false, 0)
		return
	end

	if not self.playerManager:ownsWeapon(player, weaponId) then
		-- Send failure confirmation
		self:sendReloadConfirmation(player, weaponId, false, 0)
		return
	end

	local equippedWeapon = self.playerManager:getEquippedWeapon(player)
	if equippedWeapon ~= weaponId then
		-- Send failure confirmation
		self:sendReloadConfirmation(player, weaponId, false, 0)
		return
	end

	-- BUGFIX (MEDIUM): Add explicit state guard to prevent reload race condition
	local reloadState = self.playerReloadState[userId]
	if reloadState and reloadState.isReloading then
		-- Reject immediately if already reloading (prevents rapid reload spam)
		-- Send failure confirmation
		self:sendReloadConfirmation(player, weaponId, false, 0)
		return
	end

	local ammo = self:getAmmo(player, weaponId)
	if not ammo then
		self:initializeWeaponAmmo(player, weaponId)
		ammo = self:getAmmo(player, weaponId)
		if not ammo then
			-- Send failure confirmation
			self:sendReloadConfirmation(player, weaponId, false, 0)
			return
		end
	end

	if ammo.current >= ammo.max then
		-- Send failure confirmation
		self:sendReloadConfirmation(player, weaponId, false, 0)
		return
	end
	if ammo.reserve <= 0 then
		-- Send failure confirmation
		self:sendReloadConfirmation(player, weaponId, false, 0)
		return
	end

	local stats = FPSConfig.getWeaponStats(weaponId)
	local reloadTime = stats and stats.ReloadTime or 2.0

	self.playerReloadState[userId] = {
		isReloading = true,
		reloadStartTime = tick(),
		weaponId = weaponId,
	}
	
	-- BUG-009 FIX: Send server confirmation to client that reload has started
	-- This implements server-authoritative reload state (prevents client-side exploits)
	self:sendReloadConfirmation(player, weaponId, true, reloadTime)

	-- Cancel previous reload task if exists
	if self.activeReloadTasks[userId] then
		task.cancel(self.activeReloadTasks[userId])
	end

	-- Store task handle to enable cancellation on player disconnect
	self.activeReloadTasks[userId] = task.delay(reloadTime, function()
		if not player or not player.Parent then
			self.activeReloadTasks[userId] = nil
			return
		end

		local currentReloadState = self.playerReloadState[userId]
		if not currentReloadState or not currentReloadState.isReloading then
			self.activeReloadTasks[userId] = nil
			return
		end
		if currentReloadState.weaponId ~= weaponId then
			self.activeReloadTasks[userId] = nil
			return
		end

		local currentEquipped = self.playerManager:getEquippedWeapon(player)
		if currentEquipped ~= weaponId then
			self.playerReloadState[userId] = nil
			self.activeReloadTasks[userId] = nil
			return
		end

		local currentAmmo = self:getAmmo(player, weaponId)
		if not currentAmmo then
			self.playerReloadState[userId] = nil
			self.activeReloadTasks[userId] = nil
			return
		end

		local ammoNeeded = currentAmmo.max - currentAmmo.current
		local ammoToAdd = math.min(ammoNeeded, currentAmmo.reserve)

		currentAmmo.current += ammoToAdd
		currentAmmo.reserve -= ammoToAdd

		self.playerReloadState[userId] = nil
		self.activeReloadTasks[userId] = nil
		self:sendAmmoUpdate(player, weaponId)
	end)
end

function FPSWeaponService:sendAmmoUpdate(player, weaponId)
	-- Validate player is still connected
	if not player or not player.Parent then
		if DEBUG_AMMO then
			warn("[FPSWeaponService] Cannot send ammo update: player is disconnected")
		end
		return
	end
	
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then 
		if DEBUG_AMMO then
			print(string.format("[FPSWeaponService] ✗ Cannot send ammo update for %s: no ammo data for weapon %s", 
				player.Name, tostring(weaponId)))
		end
		return 
	end

	RemoteRegistry.SafeFireClient(self.remoteEvents.AmmoUpdate, player, {
		weaponId = weaponId,
		current = ammo.current,
		reserve = ammo.reserve,
		max = ammo.max,
	})
	
	if DEBUG_AMMO then
		print(string.format("[FPSWeaponService] ✓ Sent ammo update to %s: %s (current=%d, reserve=%d, max=%d)", 
			player.Name, weaponId, ammo.current, ammo.reserve, ammo.max))
	end
end

function FPSWeaponService:sendReloadConfirmation(player, weaponId, success, reloadTime)
	-- BUG-009 FIX: Validate player is still connected before FireClient
	-- This prevents errors if player disconnects mid-reload
	if not player or not player.Parent then
		if DEBUG_AMMO then
			warn("[FPSWeaponService] Cannot send reload confirmation: player is disconnected")
		end
		return
	end
	
	if self.remoteEvents.ReloadConfirm then
		RemoteRegistry.SafeFireClient(self.remoteEvents.ReloadConfirm, player, {
			weaponId = weaponId,
			reloadTime = reloadTime,
			success = success
		})
	end
end

function FPSWeaponService:cancelReload(player)
	local userId = player.UserId
	self.playerReloadState[userId] = nil
	
	-- BUGFIX (MEDIUM): Cancel active reload task to prevent reload completing after weapon switch
	if self.activeReloadTasks[userId] then
		task.cancel(self.activeReloadTasks[userId])
		self.activeReloadTasks[userId] = nil
	end
end

function FPSWeaponService:isReloading(player)
	local state = self.playerReloadState[player.UserId]
	return state and state.isReloading or false
end

function FPSWeaponService:onWeaponEquipped(player, weaponId)
	self:cancelReload(player)

	local userId = player.UserId
	self.playerAmmo[userId] = self.playerAmmo[userId] or {}

	if not self.playerAmmo[userId][weaponId] then
		self:initializeWeaponAmmo(player, weaponId)
	else
		self:sendAmmoUpdate(player, weaponId)
	end
end

function FPSWeaponService:isHeadshot(hitPart)
	if not hitPart then return false end
	local partName = hitPart.Name:lower()
	return partName == "head" or partName:find("head") ~= nil
end

local BODY_PARTS = {
	head = "head",
	torso = "body",
	uppertorso = "body",
	lowertorso = "body",
	humanoidrootpart = "body",
	leftupperarm = "limb",
	leftlowerarm = "limb",
	lefthand = "limb",
	rightupperarm = "limb",
	rightlowerarm = "limb",
	righthand = "limb",
	["left arm"] = "limb",
	["right arm"] = "limb",
	leftupperleg = "limb",
	leftlowerleg = "limb",
	leftfoot = "limb",
	rightupperleg = "limb",
	rightlowerleg = "limb",
	rightfoot = "limb",
	["left leg"] = "limb",
	["right leg"] = "limb",
}

function FPSWeaponService:getDamageMultiplier(hitPart)
	if not hitPart then return 1.0 end

	local partName = hitPart.Name:lower()
	local partType = BODY_PARTS[partName]

	if not partType and partName:find("head") then
		partType = "head"
	end

	if partType == "head" then
		return FPSConfig.Weapons.HeadshotMultiplier
	elseif partType == "body" then
		return FPSConfig.Weapons.BodyshotMultiplier
	else
		return FPSConfig.Weapons.LimbshotMultiplier
	end
end

function FPSWeaponService:validateShot(player, weaponId)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return false end
	return ammo.current > 0
end

function FPSWeaponService:awardAmmoPickup(player, weaponId, amount)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then
		self:initializeWeaponAmmo(player, weaponId)
		ammo = self:getAmmo(player, weaponId)
	end

	if ammo then
		ammo.reserve += amount
		self:sendAmmoUpdate(player, weaponId)
		return true
	end

	return false
end

-- Security: Periodic ammo validation to detect client-side manipulation
function FPSWeaponService:startAmmoValidationLoop()
	-- BUG-001: Prevent duplicate validation loops
	if self._isRunning then
		warn("[FPSWeaponService] Validation loop already running, skipping duplicate start")
		return
	end
	
	self._isRunning = true
	
	-- BUG-001: Store the spawned task handle for immediate cancellation during cleanup
	self._ammoValidationTask = task.spawn(function()
		while self._isRunning do
			task.wait(AMMO_SYNC_INTERVAL)
			
			-- BUG-001: Check flag again after wait to allow clean shutdown
			if not self._isRunning then
				break
			end
			
			for _, player in ipairs(Players:GetPlayers()) do
				local userId = player.UserId
				local currentTime = tick()
				
				-- Sync ammo for all players
				if self.playerAmmo[userId] then
					local equippedWeapon = self.playerManager:getEquippedWeapon(player)
					if equippedWeapon then
						-- Resend current ammo to client to verify sync
						self:sendAmmoUpdate(player, equippedWeapon)
						self.lastAmmoSync[userId] = currentTime
						
						if DEBUG_AMMO then
							print(string.format("[FPSWeaponService] Periodic ammo sync for %s - Weapon: %s", 
								player.Name, equippedWeapon))
						end
					end
				end
			end
		end
		
		print("[FPSWeaponService] Ammo validation loop stopped")
	end)
	
	print("[FPSWeaponService] Started periodic ammo validation (interval: " .. AMMO_SYNC_INTERVAL .. "s)")
end

-- Compatibility shim: equipWeapon(player, weaponId) for test API
-- Forwards to the existing onWeaponEquipped implementation
function FPSWeaponService:equipWeapon(player, weaponId)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	
	-- Forward to the existing implementation
	self:onWeaponEquipped(player, weaponId)
	return true
end

-- Compatibility shim: reloadWeapon(player, weaponId) for test API
-- Forwards to the existing handleReload implementation
function FPSWeaponService:reloadWeapon(player, weaponId)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	
	-- Create payload format expected by handleReload
	local payload = { weaponId = weaponId }
	self:handleReload(player, payload)
	return true
end

-- Compatibility shim: fireWeapon(player, weaponId) for test API
-- Validates ammo and consumes it
function FPSWeaponService:fireWeapon(player, weaponId)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	
	-- Validate shot and consume ammo
	if not self:validateShot(player, weaponId) then
		return false
	end
	
	return self:consumeAmmo(player, weaponId, 1)
end

-- BUG-001: Cleanup method to stop validation loop and prevent orphaned threads
function FPSWeaponService:cleanup()
	print("[FPSWeaponService] Cleanup initiated")
	
	-- Stop the validation loop
	self._isRunning = false
	
	-- Cancel the validation loop task immediately for responsive termination
	if self._ammoValidationTask then
		task.cancel(self._ammoValidationTask)
		self._ammoValidationTask = nil
	end
	
	-- Disconnect player removing connection
	if self.playerRemovingConn then
		self.playerRemovingConn:Disconnect()
		self.playerRemovingConn = nil
	end
	
	-- Disconnect any other RemoteEvent / signal connections stored on this service
	for key, value in pairs(self) do
		if typeof(value) == "RBXScriptConnection" then
			value:Disconnect()
			self[key] = nil
		end
	end
	
	-- Cancel all active reload tasks
	for userId, taskHandle in pairs(self.activeReloadTasks) do
		if taskHandle then
			task.cancel(taskHandle)
		end
	end
	
	-- Clear all state
	self.activeReloadTasks = {}
	self.playerAmmo = {}
	self.playerReloadState = {}
	self.lastAmmoSync = {}
	
	print("[FPSWeaponService] Cleanup completed")
end

return FPSWeaponService
