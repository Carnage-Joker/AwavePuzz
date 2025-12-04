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
	self.playerAmmo[player.UserId] = nil
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
	
	local weaponId = payload.weaponId
	if not weaponId then
		weaponId = self.playerManager:getEquippedWeapon(player)
	end
	
	if not weaponId then return end
	
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then
		self:initializeWeaponAmmo(player, weaponId)
		ammo = self:getAmmo(player, weaponId)
		if not ammo then return end
	end
	
	-- Check if reload is needed/possible
	if ammo.current >= ammo.max then return end
	if ammo.reserve <= 0 then return end
	
	-- Calculate ammo to transfer
	local ammoNeeded = ammo.max - ammo.current
	local ammoToAdd = math.min(ammoNeeded, ammo.reserve)
	
	-- Server validates reload timing through weapon service cooldowns
	-- For now, we trust the client timing and update state
	ammo.current = ammo.current + ammoToAdd
	ammo.reserve = ammo.reserve - ammoToAdd
	
	-- Send update to client
	self:sendAmmoUpdate(player, weaponId)
	
	print(string.format("[FPSWeaponService] %s reloaded %s: %d/%d",
		player.Name, weaponId, ammo.current, ammo.reserve))
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

function FPSWeaponService:onWeaponEquipped(player, weaponId)
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
function FPSWeaponService:getDamageMultiplier(hitPart)
	if not hitPart then return 1.0 end
	
	local partName = hitPart.Name:lower()
	
	if partName == "head" or partName:find("head") ~= nil then
		return FPSConfig.Weapons.HeadshotMultiplier
	elseif partName == "torso" or partName == "uppertorso" or partName == "lowertorso" 
		or partName == "humanoidrootpart" then
		return FPSConfig.Weapons.BodyshotMultiplier
	else
		-- Limbs
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
