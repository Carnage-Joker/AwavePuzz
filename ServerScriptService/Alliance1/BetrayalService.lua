-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- BetrayalService.lua
-- Implements 3-outcome betrayal system with snapshot pooling
-- OUTCOME 1: Betrayer kills victim within 30s -> 75% pooled transfer
-- OUTCOME 2: Victim kills betrayer within 30s -> 75% pooled transfer (mirrored)
-- OUTCOME 3: Stalemate (30s timeout) -> 100% personal transfer + Traitor flag

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local WeaponValues = require(SharedFolder:WaitForChild("WeaponValues"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local BetrayalService = {}
BetrayalService.__index = BetrayalService

-- Constants (prefer GameConfig values, fall back to existing defaults)
local POOLED_TRANSFER_PERCENT = GameConfig.POOLED_TRANSFER_PERCENT or 0.75
local PERSONAL_TRANSFER_PERCENT_ON_STALEMATE = GameConfig.PERSONAL_TRANSFER_PERCENT_ON_STALEMATE or 1.00
local BETRAYAL_WINDOW_DURATION = GameConfig.BETRAYAL_WINDOW_DURATION or 30 -- seconds
local STARTING_WEAPON = WeaponValues.PISTOL_ID -- Starting weapon to exclude from transfers

function BetrayalService.new(allianceGraph, poolCalculator, inventoryLedger, playerManager, gameManager)
	local self = setmetatable({}, BetrayalService)

	self.allianceGraph = allianceGraph
	self.poolCalculator = poolCalculator
	self.inventoryLedger = inventoryLedger
	self.playerManager = playerManager
	self.gameManager = gameManager -- Can be nil initially, set later via setGameManager

	-- Track active betrayal windows
	-- Structure: {betrayerId -> {victimId, victimSnapshot, betrayerSnapshot, startTime, windowActive}}
	self.activeWindows = {}

	-- Track players locked from alliance changes during betrayal
	self.lockedPlayers = {} -- userId -> true

	-- Track traitors (players who failed stalemate)
	self.traitors = {} -- userId -> true

	-- Setup remote events
	self:setupRemoteEvents()

	return self
end

function BetrayalService:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"BetrayalStarted",
		"BetrayalOutcome",
		"BetrayalStatus"
	})
end

-- Set game manager reference (can be called after initialization)
function BetrayalService:setGameManager(gameManager)
	self.gameManager = gameManager
end

-- Check if a player is locked from alliance changes
function BetrayalService:isPlayerLocked(player)
	return self.lockedPlayers[player.UserId] == true
end

-- Check if a player is a traitor
function BetrayalService:isTraitor(player)
	return self.traitors[player.UserId] == true
end

-- Start a betrayal between betrayer and victim
function BetrayalService:startBetrayal(betrayer, victim)
	if not betrayer or not victim then
		return false, "Invalid players"
	end

	-- Validate they are direct allies
	if not self.allianceGraph:areDirectAllies(betrayer, victim) then
		return false, "Players are not direct allies"
	end

	-- Check if either player is already in a betrayal window
	if self.activeWindows[betrayer.UserId] then
		return false, "Betrayer is already in a betrayal window"
	end

	for betrayerId, data in pairs(self.activeWindows) do
		if data.victimId == victim.UserId then
			return false, "Victim is already in a betrayal window"
		end
	end

	-- Check if betrayer is a traitor
	if self:isTraitor(betrayer) then
		return false, "Traitors cannot initiate betrayals"
	end

	-- 1) Remove the alliance edge immediately
	self.allianceGraph:removeEdge(betrayer, victim)

	-- 2) Create snapshots BEFORE any changes
	local victimSnapshot = self.poolCalculator:snapshotPool(victim)
	local betrayerSnapshot = self.poolCalculator:snapshotPool(betrayer)

	-- Helper to validate that a snapshot has a members list containing the given player
	local function snapshotHasPlayer(snapshot, player)
		if type(snapshot) ~= "table" then
			return false
		end

		local members = snapshot.members
		if type(members) ~= "table" then
			return false
		end

		for _, member in ipairs(members) do
			-- Support common representations: Player instance, UserId number, or player name string
			if member == player or member == player.UserId or member == player.Name then
				return true
			end
		end

		return false
	end

	if not victimSnapshot
		or not betrayerSnapshot
		or not snapshotHasPlayer(victimSnapshot, victim)
		or not snapshotHasPlayer(betrayerSnapshot, betrayer) then

		return false, "Failed to create valid snapshots"
	end

	-- 3) Lock both players from alliance changes
	self.lockedPlayers[betrayer.UserId] = true
	self.lockedPlayers[victim.UserId] = true

	-- 4) Create active window data
	self.activeWindows[betrayer.UserId] = {
		victimId = victim.UserId,
		victimSnapshot = victimSnapshot,
		betrayerSnapshot = betrayerSnapshot,
		startTime = os.time(),
		windowActive = true
	}

	-- 5) Start 30-second timer
	task.delay(BETRAYAL_WINDOW_DURATION, function()
		self:onWindowExpired(betrayer.UserId)
	end)

	-- 6) Notify clients
	self.remoteEvents.BetrayalStarted:FireClient(betrayer, {
		type = "betrayer",
		victim = victim.Name,
		duration = BETRAYAL_WINDOW_DURATION
	})

	self.remoteEvents.BetrayalStarted:FireClient(victim, {
		type = "victim",
		betrayer = betrayer.Name,
		duration = BETRAYAL_WINDOW_DURATION
	})

	print(string.format("[BetrayalService] %s betrayed %s - 30s window started", betrayer.Name, victim.Name))

	return true
end

-- Handle player kill during betrayal window
function BetrayalService:onPlayerKilled(killer, victim)
	if not killer or not victim then
		return
	end

	-- Check if killer is a betrayer and victim is their target (Outcome 1)
	if self.activeWindows[killer.UserId] then
		local data = self.activeWindows[killer.UserId]
		if data.victimId == victim.UserId and data.windowActive then
			self:resolveOutcome1_SuccessfulBetrayal(killer, victim, data)
			return
		end
	end

	-- Check if victim is a betrayer and killer is their target (Outcome 2)
	if self.activeWindows[victim.UserId] then
		local data = self.activeWindows[victim.UserId]
		if data.victimId == killer.UserId and data.windowActive then
			self:resolveOutcome2_FailedBetrayal(killer, victim, data)
			return
		end
	end
end

-- Outcome 1: Betrayer successfully kills victim within 30s
function BetrayalService:resolveOutcome1_SuccessfulBetrayal(betrayer, victim, data)
	print(string.format("[BetrayalService] OUTCOME 1: %s killed %s - successful betrayal", betrayer.Name, victim.Name))

	-- Mark window as inactive
	data.windowActive = false

	-- Transfer 75% of victim's POOLED resources
	self:applyPooledTransfer(betrayer, data.victimSnapshot, POOLED_TRANSFER_PERCENT, "Successful Betrayal")

	-- Track betrayal for fun facts
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(betrayer, "betrayalsCommitted")
	end

	-- Unlock players
	self:unlockPlayer(betrayer)
	self:unlockPlayer(victim)

	-- Clean up window
	self.activeWindows[betrayer.UserId] = nil

	-- Notify clients
	self.remoteEvents.BetrayalOutcome:FireClient(betrayer, {
		type = "success",
		message = string.format("Betrayal successful! You eliminated %s and claimed 75%% of their pool!", victim.Name)
	})
end

-- Outcome 2: Victim kills betrayer within 30s (mirrored)
function BetrayalService:resolveOutcome2_FailedBetrayal(victor, betrayer, data)
	print(string.format("[BetrayalService] OUTCOME 2: %s killed betrayer %s - failed betrayal", victor.Name, betrayer.Name))

	-- Mark window as inactive
	data.windowActive = false

	-- Transfer 75% of betrayer's POOLED resources
	self:applyPooledTransfer(victor, data.betrayerSnapshot, POOLED_TRANSFER_PERCENT, "Failed Betrayal")

	-- Track betrayal survival for fun facts
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(victor, "betrayalsSurvived")
	end

	-- Unlock players
	self:unlockPlayer(betrayer)
	self:unlockPlayer(victor)

	-- Clean up window
	self.activeWindows[betrayer.UserId] = nil

	-- Notify clients
	self.remoteEvents.BetrayalOutcome:FireClient(victor, {
		type = "victory",
		message = string.format("You defeated betrayer %s and claimed 75%% of their pool!", betrayer.Name)
	})
end

-- Outcome 3: Window expires without either player killing the other
function BetrayalService:onWindowExpired(betrayerId)
	local data = self.activeWindows[betrayerId]
	if not data or not data.windowActive then
		return
	end

	local betrayer = Players:GetPlayerByUserId(betrayerId)
	local victim = Players:GetPlayerByUserId(data.victimId)

	if not betrayer or not victim then
		-- Clean up if players left
		self:cleanupWindow(betrayerId)
		return
	end

	print(string.format("[BetrayalService] OUTCOME 3: Stalemate between %s and %s", betrayer.Name, victim.Name))

	-- Mark window as inactive
	data.windowActive = false

	-- Transfer 100% of betrayer's PERSONAL inventory to victim
	self:applyPersonalTransfer(betrayer, victim, PERSONAL_TRANSFER_PERCENT_ON_STALEMATE)

	-- Track betrayal survival for fun facts (victim survived)
	if self.gameManager and self.gameManager.funFactService then
		self.gameManager.funFactService:incrementPlayerStat(victim, "betrayalsSurvived")
	end

	-- Apply Traitor flag to betrayer
	self.traitors[betrayerId] = true

	-- Sever ALL remaining alliance edges of betrayer
	self.allianceGraph:removeAllEdges(betrayer)

	-- Unlock victim only (betrayer remains locked via traitor flag)
	self:unlockPlayer(victim)
	-- Betrayer stays locked for remainder of round

	-- Clean up window
	self.activeWindows[betrayerId] = nil

	-- Notify clients
	self.remoteEvents.BetrayalOutcome:FireClient(betrayer, {
		type = "stalemate_betrayer",
		message = "Stalemate! All your personal items transferred to victim. You are marked as a Traitor."
	})

	self.remoteEvents.BetrayalOutcome:FireClient(victim, {
		type = "stalemate_victim",
		message = string.format("Stalemate! You received all of %s's personal items.", betrayer.Name)
	})
end

-- Apply proportional pooled transfer from snapshot
function BetrayalService:applyPooledTransfer(winner, loserSnapshot, transferPercent, reason)
	if not self.inventoryLedger:begin() then
		warn("[BetrayalService] Failed to begin transaction for", reason)
		return
	end

	local totalTransferred = {
		currency = 0,
		resources = {},
		components = {},
		weapons = {}
	}

	-- Track deductions per user to avoid overwriting
	local userDeductions = {} -- userId -> deduction struct

	-- Calculate deductions for each member in loser's pool
	for _, userId in ipairs(loserSnapshot.members) do
		local contribution = loserSnapshot.contributions[userId]
		if contribution then
			local deduction = {
				currency = math.floor(contribution.currency * transferPercent),
				resources = {},
				components = {},
				weapons = {}
			}

			-- Deduct resources
			for resourceName, count in pairs(contribution.resources) do
				local deductAmount = math.floor(count * transferPercent)
				if deductAmount > 0 then
					deduction.resources[resourceName] = deductAmount
					totalTransferred.resources[resourceName] = (totalTransferred.resources[resourceName] or 0) + deductAmount
				end
			end

			-- Deduct components
			for componentName, count in pairs(contribution.components) do
				local deductAmount = math.floor(count * transferPercent)
				if deductAmount > 0 then
					deduction.components[componentName] = deductAmount
					totalTransferred.components[componentName] = (totalTransferred.components[componentName] or 0) + deductAmount
				end
			end

			totalTransferred.currency = totalTransferred.currency + deduction.currency

			-- Store deduction for later weapon addition
			userDeductions[userId] = deduction
		end
	end

	-- Select weapons to transfer (deterministic, value-based)
	local targetWeaponValue = math.floor(loserSnapshot.totals.weaponValueTotal * transferPercent)
	local weaponsToTransfer = self:selectWeaponsForTransfer(loserSnapshot, targetWeaponValue)

	-- Add weapon deductions to existing user deductions (don't overwrite)
	for userId, weaponIds in pairs(weaponsToTransfer.byOwner) do
		if userDeductions[userId] then
			-- Add weapons to existing deduction
			userDeductions[userId].weapons = weaponIds
		else
			-- Create new deduction for this user (only weapons)
			userDeductions[userId] = {
				currency = 0,
				resources = {},
				components = {},
				weapons = weaponIds
			}
		end
	end

	-- Apply all deductions (now with weapons included)
	for userId, deduction in pairs(userDeductions) do
		self.inventoryLedger:applyDeduction(userId, deduction)
	end

	totalTransferred.weapons = weaponsToTransfer.list

	-- Grant everything to winner
	local grant = {
		currency = totalTransferred.currency,
		resources = totalTransferred.resources,
		components = totalTransferred.components,
		weapons = totalTransferred.weapons
	}

	self.inventoryLedger:applyGrant(winner.UserId, grant)

	-- Commit transaction
	if not self.inventoryLedger:commit() then
		warn("[BetrayalService] Transaction commit failed for", reason)
	end
end

-- Apply personal transfer (100% of betrayer's personal items)
function BetrayalService:applyPersonalTransfer(source, target, transferPercent)
	local sourceData = self.playerManager:getPlayerData(source)
	if not sourceData then
		return
	end

	if not self.inventoryLedger:begin() then
		warn("[BetrayalService] Failed to begin transaction for personal transfer")
		return
	end

	-- Deduct everything from source
	local deduction = {
		currency = sourceData.currency,
		resources = {},
		components = {},
		weapons = {}
	}

	for resourceName, count in pairs(sourceData.inventory or {}) do
		deduction.resources[resourceName] = count
	end

	for componentName, count in pairs(sourceData.cureComponents or {}) do
		deduction.components[componentName] = count
	end

	local normalizedStartingWeaponId = string.lower(tostring(STARTING_WEAPON))

	for weaponId in pairs(sourceData.weapons or {}) do
		local weaponKey = string.lower(tostring(weaponId))
		if weaponKey ~= normalizedStartingWeaponId then -- Keep starting weapon (case-insensitive)
			table.insert(deduction.weapons, weaponId)
		end
	end

	self.inventoryLedger:applyDeduction(source.UserId, deduction)

	-- Grant to target
	self.inventoryLedger:applyGrant(target.UserId, deduction)

	if not self.inventoryLedger:commit() then
		warn("[BetrayalService] Personal transfer commit failed")
	end
end

-- Select weapons for transfer using deterministic algorithm
function BetrayalService:selectWeaponsForTransfer(snapshot, targetValue)
	local result = {
		list = {},
		byOwner = {}, -- userId -> {weaponIds}
		totalValue = 0
	}

	-- Build deterministic ordered list of (weaponId, ownerId, value)
	local candidateWeapons = {}
	for userId, contribution in pairs(snapshot.contributions) do
		for _, weaponId in ipairs(contribution.weapons.list) do
			table.insert(candidateWeapons, {
				weaponId = weaponId,
				ownerId = userId,
				value = WeaponValues.getValue(weaponId)
			})
		end
	end

	-- Sort by value desc, weaponId asc, ownerId asc
	table.sort(candidateWeapons, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		if a.weaponId ~= b.weaponId then
			return a.weaponId < b.weaponId
		end
		return a.ownerId < b.ownerId
	end)

	-- Select weapons until we hit target value
	for _, weapon in ipairs(candidateWeapons) do
		if result.totalValue >= targetValue then
			break
		end

		-- Skip starting weapon
		if weapon.weaponId == STARTING_WEAPON then
			continue
		end

		-- Avoid significantly overshooting the target when we already have some value
		local newTotal = result.totalValue + weapon.value
		if newTotal > targetValue and result.totalValue > 0 then
			-- Try smaller weapons later in the sorted list instead of overshooting with this one
			continue
		end

		table.insert(result.list, weapon.weaponId)
		result.totalValue = newTotal

		if not result.byOwner[weapon.ownerId] then
			result.byOwner[weapon.ownerId] = {}
		end
		table.insert(result.byOwner[weapon.ownerId], weapon.weaponId)
	end

	return result
end

-- Handle player disconnect
function BetrayalService:onPlayerDisconnect(player)
	if not player then
		return
	end

	local userId = player.UserId

	-- Check if player is a betrayer in active window
	if self.activeWindows[userId] then
		local data = self.activeWindows[userId]
		if data.windowActive then
			local victim = Players:GetPlayerByUserId(data.victimId)
			if victim then
				-- Treat as if betrayer died (Outcome 2)
				print(string.format("[BetrayalService] Betrayer %s disconnected - applying Outcome 2", player.Name))
				self:resolveOutcome2_FailedBetrayal(victim, player, data)
			end
		end
		return
	end

	-- Check if player is a victim in active window
	for betrayerId, data in pairs(self.activeWindows) do
		if data.victimId == userId and data.windowActive then
			local betrayer = Players:GetPlayerByUserId(betrayerId)
			if betrayer then
				-- Treat as if victim died (Outcome 1)
				print(string.format("[BetrayalService] Victim %s disconnected - applying Outcome 1", player.Name))
				self:resolveOutcome1_SuccessfulBetrayal(betrayer, player, data)
			end
			break
		end
	end

	-- Clean up any remaining data
	self:cleanupPlayer(player)
end

-- Unlock a player from alliance freeze
function BetrayalService:unlockPlayer(player)
	if not player then
		return
	end

	self.lockedPlayers[player.UserId] = nil
end

-- Clean up window data
function BetrayalService:cleanupWindow(betrayerId)
	local data = self.activeWindows[betrayerId]
	if data then
		self:unlockPlayer(Players:GetPlayerByUserId(betrayerId))
		self:unlockPlayer(Players:GetPlayerByUserId(data.victimId))
	end

	self.activeWindows[betrayerId] = nil
end

-- Clean up player data
function BetrayalService:cleanupPlayer(player)
	if not player then
		return
	end

	local userId = player.UserId

	self.lockedPlayers[userId] = nil
	self.traitors[userId] = nil

	if self.activeWindows[userId] then
		self:cleanupWindow(userId)
	end
end

return BetrayalService