-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- PoolCalculator.lua
-- Calculates contribution snapshots for networked alliance pools
-- Tracks per-player contributions and generates immutable snapshots for betrayal

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WeaponValues = require(SharedFolder:WaitForChild("WeaponValues"))

local PoolCalculator = {}
PoolCalculator.__index = PoolCalculator

function PoolCalculator.new(playerManager, allianceGraph)
	local self = setmetatable({}, PoolCalculator)

	self.playerManager = playerManager
	self.allianceGraph = allianceGraph

	return self
end

-- Get contribution data for a single player
-- Returns a contribution structure with all player resources
function PoolCalculator:getContribution(playerId)
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		return nil
	end

	local playerData = self.playerManager:getPlayerData(player)
	if not playerData then
		return nil
	end

	local contribution = {
		currency = playerData.currency or 0,
		resources = {},
		components = {},
		progressPoints = 0, -- Calculated from CureService if needed
		weapons = {
			list = {},
			valueTotal = 0
		}
	}

	-- Copy resources (inventory items)
	if playerData.inventory then
		for itemName, count in pairs(playerData.inventory) do
			contribution.resources[itemName] = count
		end
	end

	-- Copy cure components
	if playerData.cureComponents then
		for componentName, count in pairs(playerData.cureComponents) do
			contribution.components[componentName] = count
		end
	end

	-- Copy weapons
	if playerData.weapons then
		for weaponId in pairs(playerData.weapons) do
			table.insert(contribution.weapons.list, weaponId)
			contribution.weapons.valueTotal = contribution.weapons.valueTotal + WeaponValues.getValue(weaponId)
		end

		-- Sort weapons deterministically
		contribution.weapons.list = WeaponValues.sortWeapons(contribution.weapons.list)
	end

	return contribution
end

-- Create an immutable snapshot of the pool for a target player's component
-- Returns: {members = {userId1, userId2, ...}, contributions = {userId = contribution, ...}, totals = {...}}
function PoolCalculator:snapshotPool(targetPlayer)
	if not targetPlayer then
		return nil
	end

	-- Get all players in the connected component
	local componentUserIds = self.allianceGraph:getComponent(targetPlayer)

	local snapshot = {
		members = componentUserIds,
		contributions = {},
		totals = {
			currency = 0,
			resources = {},
			componentsByType = {},
			progressPoints = 0,
			weaponValueTotal = 0,
			weaponCount = 0
		}
	}

	-- Collect contributions from each member
	for _, userId in ipairs(componentUserIds) do
		local contribution = self:getContribution(userId)
		if contribution then
			snapshot.contributions[userId] = contribution

			-- Aggregate totals
			snapshot.totals.currency = snapshot.totals.currency + contribution.currency

			-- Aggregate resources
			for resourceName, count in pairs(contribution.resources) do
				snapshot.totals.resources[resourceName] = (snapshot.totals.resources[resourceName] or 0) + count
			end

			-- Aggregate components
			for componentName, count in pairs(contribution.components) do
				snapshot.totals.componentsByType[componentName] = (snapshot.totals.componentsByType[componentName] or 0) + count
			end

			-- Aggregate progress points
			snapshot.totals.progressPoints = snapshot.totals.progressPoints + contribution.progressPoints

			-- Aggregate weapon values
			snapshot.totals.weaponValueTotal = snapshot.totals.weaponValueTotal + contribution.weapons.valueTotal
			snapshot.totals.weaponCount = snapshot.totals.weaponCount + #contribution.weapons.list
		end
	end

	-- Store timestamp for debugging/logging
	snapshot.timestamp = os.time()

	return snapshot
end

return PoolCalculator