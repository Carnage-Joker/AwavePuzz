-- FPSWeaponService.lua
-- Server-side extension for FPS weapon mechanics
-- Handles ammo tracking, reload validation, and (optional) hit multipliers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FPSConfig = require(ReplicatedStorage.Shared.FPSConfig)

local FPSWeaponService = {}
FPSWeaponService.__index = FPSWeaponService

function FPSWeaponService.new(playerManager, weaponService)
	local self = setmetatable({}, FPSWeaponService)

	self.playerManager = playerManager
	self.weaponService = weaponService

	self.playerAmmo = {} -- userId -> { weaponId -> { current, reserve, max } }
	self.playerReloadState = {} -- userId -> { isReloading, reloadStartTime, weaponId }

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

	local reloadEvent = remoteEventsFolder:FindFirstChild("WeaponReload")
	if not reloadEvent then
		reloadEvent = Instance.new("RemoteEvent")
		reloadEvent.Name = "WeaponReload"
		reloadEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.WeaponReload = reloadEvent

	local ammoUpdateEvent = remoteEventsFolder:FindFirstChild("AmmoUpdate")
	if not ammoUpdateEvent then
		ammoUpdateEvent = Instance.new("RemoteEvent")
		ammoUpdateEvent.Name = "AmmoUpdate"
		ammoUpdateEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.AmmoUpdate = ammoUpdateEvent

	reloadEvent.OnServerEvent:Connect(function(player, payload)
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

function FPSWeaponService:removePlayer(player)
	local userId = player.UserId
	self.playerAmmo[userId] = nil
	self.playerReloadState[userId] = nil
end

function FPSWeaponService:initializeWeaponAmmo(player, weaponId)
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
	if not weaponId then return end

	if not self.playerManager:ownsWeapon(player, weaponId) then
		return
	end

	local equippedWeapon = self.playerManager:getEquippedWeapon(player)
	if equippedWeapon ~= weaponId then
		return
	end

	local reloadState = self.playerReloadState[userId]
	if reloadState and reloadState.isReloading then
		local elapsed = tick() - reloadState.reloadStartTime
		local stats = FPSConfig.getWeaponStats(reloadState.weaponId)
		local reloadTime = stats and stats.ReloadTime or 2.0
		if elapsed < reloadTime then
			return
		end
	end

	local ammo = self:getAmmo(player, weaponId)
	if not ammo then
		self:initializeWeaponAmmo(player, weaponId)
		ammo = self:getAmmo(player, weaponId)
		if not ammo then return end
	end

	if ammo.current >= ammo.max then return end
	if ammo.reserve <= 0 then return end

	local stats = FPSConfig.getWeaponStats(weaponId)
	local reloadTime = stats and stats.ReloadTime or 2.0

	self.playerReloadState[userId] = {
		isReloading = true,
		reloadStartTime = tick(),
		weaponId = weaponId,
	}

	task.delay(reloadTime, function()
		if not player or not player.Parent then return end

		local currentReloadState = self.playerReloadState[userId]
		if not currentReloadState or not currentReloadState.isReloading then return end
		if currentReloadState.weaponId ~= weaponId then return end

		local currentEquipped = self.playerManager:getEquippedWeapon(player)
		if currentEquipped ~= weaponId then
			self.playerReloadState[userId] = nil
			return
		end

		local currentAmmo = self:getAmmo(player, weaponId)
		if not currentAmmo then
			self.playerReloadState[userId] = nil
			return
		end

		local ammoNeeded = currentAmmo.max - currentAmmo.current
		local ammoToAdd = math.min(ammoNeeded, currentAmmo.reserve)

		currentAmmo.current += ammoToAdd
		currentAmmo.reserve -= ammoToAdd

		self.playerReloadState[userId] = nil
		self:sendAmmoUpdate(player, weaponId)
	end)
end

function FPSWeaponService:sendAmmoUpdate(player, weaponId)
	local ammo = self:getAmmo(player, weaponId)
	if not ammo then return end

	self.remoteEvents.AmmoUpdate:FireClient(player, {
		weaponId = weaponId,
		current = ammo.current,
		reserve = ammo.reserve,
		max = ammo.max,
	})
end

function FPSWeaponService:cancelReload(player)
	self.playerReloadState[player.UserId] = nil
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

return FPSWeaponService
