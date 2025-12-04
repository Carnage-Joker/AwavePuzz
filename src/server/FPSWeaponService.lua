-- FPSWeaponService.lua
-- Server-side extension for FPS weapon mechanics
-- Handles ammo tracking, reload validation, and headshot detection

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FPSConfig = require(ReplicatedStorage.Shared.FPSConfig)

local FPSWeaponService = {}
FPSWeaponService.__index = FPSWeaponService

function FPSWeaponService.new(playerManager, weaponService)
	local self = setmetatable({}, FPSWeaponService)
	
	self.playerManager = playerManager
	self.weaponService = weaponService
	
	-- Player ammo state: userId -> { weaponId -> { current, reserve, max } }
	self.playerAmmo = {}
	
	-- Player reload state: userId -> { isReloading, reloadStartTime, weaponId }
	self.playerReloadState = {}
	
	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()
	
	return self
end

function FPSWeaponService:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- Reload event
	local reloadEvent = remoteEventsFolder:FindFirstChild("WeaponReload")
	if not reloadEvent then
		reloadEvent = Instance.new("RemoteEvent")
		reloadEvent.Name = "WeaponReload"
		reloadEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.WeaponReload = reloadEvent
	
	-- Ammo update event (server -> client)
	local ammoUpdateEvent = remoteEventsFolder:FindFirstChild("AmmoUpdate")
	if not ammoUpdateEvent then
		ammoUpdateEvent = Instance.new("RemoteEvent")
		ammoUpdateEvent.Name = "AmmoUpdate"
		ammoUpdateEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.AmmoUpdate = ammoUpdateEvent
	
	-- Connect reload event
	reloadEvent.OnServerEvent:Connect(function(player, payload)
		self:handleReload(player, payload)
	end)
end

function FPSWeaponService:initializePlayer(player)
	local userId = player.UserId
	self.playerAmmo[userId] = {}
	
	-- Initialize ammo for default weapon
	local defaultWeapon = self.playerManager:getEquippedWeapon(player)
	if defaultWeapon then
		self:initializeWeaponAmmo(player, defaultWeapon)
	end
end

function FPSWeaponService:removePlayer(player)
	local userId = player.UserId
	self.playerAmmo[userId] = nil
	self.playerReloadState[userId] = nil
end

function FPSWeaponService:initializeWeaponAmmo(player, weaponId)
	local userId = player.UserId
	if not self.playerAmmo[userId] then
		self.playerAmmo[userId] = {}
	end
	
	local stats = FPSConfig.getWeaponStats(weaponId)
	if stats then
		self.playerAmmo[userId][weaponId] = {
			current = stats.MagSize,
			reserve = stats.ReserveAmmo,
			max = stats.MagSize,
		}
	else
		-- Default ammo values
		self.playerAmmo[userId][weaponId] = {
			current = 30,
			reserve = 120,
			max = 30,
		}
	end
	
	-- Send initial ammo to client
	self:sendAmmoUpdate(player, weaponId)
end

function FPSWeaponService:getAmmo(player, weaponId)
	local userId = player.UserId
	if not self.playerAmmo[userId] then return nil end
	
	local equipped = weaponId or self.playerManager:getEquippedWeapon(player)
	return self.playerAmmo[userId][equipped]
end

function FPSWeaponService:consumeAmmo(player, weaponId, amount)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return false end
	
	amount = amount or 1
	if ammo.current < amount then
		return false
	end
	
	ammo.current = ammo.current - amount
	self:sendAmmoUpdate(player, weaponId)
	return true
end

function FPSWeaponService:addAmmo(player, weaponId, amount, isReserve)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return false end
	
	if isReserve then
		ammo.reserve = ammo.reserve + amount
	else
		ammo.current = math.min(ammo.current + amount, ammo.max)
	end
	
	self:sendAmmoUpdate(player, weaponId)
	return true
end

function FPSWeaponService:handleReload(player, payload)
	if typeof(payload) ~= "table" then return end
	
	local userId = player.UserId
	local weaponId = payload.weaponId
	
	-- If no weaponId provided, use equipped weapon
	if not weaponId then
		weaponId = self.playerManager:getEquippedWeapon(player)
	end
	
	if not weaponId then return end
	
	-- SECURITY: Validate that the player owns this weapon
	if not self.playerManager:ownsWeapon(player, weaponId) then
		warn(string.format("[FPSWeaponService] %s tried to reload weapon they don't own: %s",
			player.Name, weaponId))
		return
	end
	
	-- SECURITY: Validate that this is the currently equipped weapon
	local equippedWeapon = self.playerManager:getEquippedWeapon(player)
	if equippedWeapon ~= weaponId then
		warn(string.format("[FPSWeaponService] %s tried to reload non-equipped weapon: %s (equipped: %s)",
			player.Name, weaponId, tostring(equippedWeapon)))
		return
	end
	
	-- SECURITY: Check if player is already reloading (prevent spam)
	local reloadState = self.playerReloadState[userId]
	if reloadState and reloadState.isReloading then
		local elapsed = tick() - reloadState.reloadStartTime
		local stats = FPSConfig.getWeaponStats(reloadState.weaponId)
		local reloadTime = stats and stats.ReloadTime or 2.0
		
		-- If still within reload time, ignore the request
		if elapsed < reloadTime then
			return
		end
	end
	
	-- Get or initialize ammo for this weapon (only for weapons player owns)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then
		self:initializeWeaponAmmo(player, weaponId)
		ammo = self:getAmmo(player, weaponId)
		if not ammo then return end
	end
	
	-- Check if reload is needed/possible
	if ammo.current >= ammo.max then return end
	if ammo.reserve <= 0 then return end
	
	-- Get weapon stats for reload timing
	local stats = FPSConfig.getWeaponStats(weaponId)
	local reloadTime = stats and stats.ReloadTime or 2.0
	
	-- Mark player as reloading
	self.playerReloadState[userId] = {
		isReloading = true,
		reloadStartTime = tick(),
		weaponId = weaponId,
	}
	
	-- Schedule the actual ammo transfer after reload time
	task.delay(reloadTime, function()
		-- Verify player is still valid and still reloading
		if not player or not player.Parent then return end
		
		local currentReloadState = self.playerReloadState[userId]
		if not currentReloadState or not currentReloadState.isReloading then return end
		if currentReloadState.weaponId ~= weaponId then return end
		
		-- Verify player still has this weapon equipped
		local currentEquipped = self.playerManager:getEquippedWeapon(player)
		if currentEquipped ~= weaponId then
			self.playerReloadState[userId] = nil
			return
		end
		
		-- Re-fetch ammo state (may have changed)
		local currentAmmo = self:getAmmo(player, weaponId)
		if not currentAmmo then
			self.playerReloadState[userId] = nil
			return
		end
		
		-- Calculate ammo to transfer
		local ammoNeeded = currentAmmo.max - currentAmmo.current
		local ammoToAdd = math.min(ammoNeeded, currentAmmo.reserve)
		
		-- Transfer ammo
		currentAmmo.current = currentAmmo.current + ammoToAdd
		currentAmmo.reserve = currentAmmo.reserve - ammoToAdd
		
		-- Clear reload state
		self.playerReloadState[userId] = nil
		
		-- Send update to client
		self:sendAmmoUpdate(player, weaponId)
		
		print(string.format("[FPSWeaponService] %s reloaded %s: %d/%d",
			player.Name, weaponId, currentAmmo.current, currentAmmo.reserve))
	end)
end

function FPSWeaponService:sendAmmoUpdate(player, weaponId)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return end
	
	self.remoteEvents.AmmoUpdate:FireClient(player, {
		current = ammo.current,
		reserve = ammo.reserve,
		max = ammo.max,
	})
end

-- Cancel reload when player switches weapons or dies
function FPSWeaponService:cancelReload(player)
	local userId = player.UserId
	self.playerReloadState[userId] = nil
end

-- Check if player is currently reloading
function FPSWeaponService:isReloading(player)
	local userId = player.UserId
	local state = self.playerReloadState[userId]
	return state and state.isReloading or false
end

function FPSWeaponService:onWeaponEquipped(player, weaponId)
	-- Cancel any ongoing reload when switching weapons
	self:cancelReload(player)
	
	-- Initialize ammo if this is a new weapon
	local userId = player.UserId
	if not self.playerAmmo[userId] then
		self.playerAmmo[userId] = {}
	end
	
	if not self.playerAmmo[userId][weaponId] then
		self:initializeWeaponAmmo(player, weaponId)
	else
		-- Send current ammo state
		self:sendAmmoUpdate(player, weaponId)
	end
end

-- Headshot detection helper
function FPSWeaponService:isHeadshot(hitPart)
	if not hitPart then return false end
	
	local partName = hitPart.Name:lower()
	return partName == "head" or partName:find("head") ~= nil
end

-- Body part damage multiplier
-- Uses lookup table for cleaner code
local BODY_PARTS = {
	-- Head parts
	head = "head",
	-- Torso parts (R15 and R6)
	torso = "body",
	uppertorso = "body",
	lowertorso = "body",
	humanoidrootpart = "body",
	-- Arms
	leftupperarm = "limb",
	leftlowerarm = "limb",
	lefthand = "limb",
	rightupperarm = "limb",
	rightlowerarm = "limb",
	righthand = "limb",
	["left arm"] = "limb",
	["right arm"] = "limb",
	-- Legs
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
	
	-- Check direct match first
	local partType = BODY_PARTS[partName]
	
	-- Fallback: check if name contains "head"
	if not partType and partName:find("head") then
		partType = "head"
	end
	
	-- Return multiplier based on part type
	if partType == "head" then
		return FPSConfig.Weapons.HeadshotMultiplier
	elseif partType == "body" then
		return FPSConfig.Weapons.BodyshotMultiplier
	else
		-- Limbs or unknown parts
		return FPSConfig.Weapons.LimbshotMultiplier
	end
end

-- Validate a shot (called from WeaponService before applying damage)
function FPSWeaponService:validateShot(player, weaponId)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return false end
	
	if ammo.current <= 0 then
		return false
	end
	
	return true
end

-- Award reserve ammo (e.g., from pickups)
function FPSWeaponService:awardAmmoPickup(player, weaponId, amount)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then
		-- Initialize if not exists
		self:initializeWeaponAmmo(player, weaponId)
		ammo = self:getAmmo(player, weaponId)
	end
	
	if ammo then
		ammo.reserve = ammo.reserve + amount
		self:sendAmmoUpdate(player, weaponId)
		return true
	end
	
	return false
end

return FPSWeaponService
