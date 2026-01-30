-- @ScriptType: ModuleScript
-- PoolCalculator.lua
-- Calculates contribution snapshots for networked alliance pools
-- Tracks per-player contributions and generates immutable snapshots for betrayal

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[PoolCalculator] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local WeaponValues = SharedFolder:WaitForChild("WeaponValues", 5)
if not WeaponValues then
	error("[PoolCalculator] CRITICAL: Failed to load WeaponValues after 5 seconds")
end
WeaponValues = require(WeaponValues)

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

--------------------------------------------------------------------------------
-- Adapter methods for test compatibility
--------------------------------------------------------------------------------

-- Calculate total pooled currency from members and ledger/balances (test-compatible)
-- Can accept:
-- 1. list of players/userIds + a ledger with balance methods
-- 2. plain table of {userId = balance}
function PoolCalculator.calculatePooledCurrency(members, ledgerOrBalances)
	-- Safe defaults - return 0 if invalid inputs
	if not members and not ledgerOrBalances then
		return 0
	end
	
	local total = 0
	
	-- Detect if ledgerOrBalances is a plain balance table by checking if all values are numbers
	if type(ledgerOrBalances) == "table" then
		local isPlainBalanceTable = true
		local hasNumericValues = false
		
		-- Check if it has any method-like properties (functions)
		if ledgerOrBalances.getCurrency or ledgerOrBalances.getBalance or ledgerOrBalances.playerManager then
			isPlainBalanceTable = false
		else
			-- Verify all values are numbers
			for key, value in pairs(ledgerOrBalances) do
				if type(value) ~= "number" then
					isPlainBalanceTable = false
					break
				else
					hasNumericValues = true
				end
			end
		end
		
		-- Case 1: It's a plain balance table
		if isPlainBalanceTable and hasNumericValues then
			for userId, balance in pairs(ledgerOrBalances) do
				if type(balance) == "number" then
					total = total + balance
				end
			end
			return total
		end
	end
	
	-- Case 2: members list + ledger with methods
	if type(members) ~= "table" then
		return 0
	end
	
	-- Try to get balances from ledger
	if type(ledgerOrBalances) == "table" then
		-- Check if it has balance methods
		if ledgerOrBalances.getCurrency then
			-- Has getCurrency method
			for _, member in ipairs(members) do
				local userId = type(member) == "number" and member or (member.UserId or 0)
				local success, balance = pcall(ledgerOrBalances.getCurrency, ledgerOrBalances, userId)
				if success and type(balance) == "number" then
					total = total + balance
				end
			end
		elseif ledgerOrBalances.getBalance then
			-- Has getBalance method
			for _, member in ipairs(members) do
				local userId = type(member) == "number" and member or (member.UserId or 0)
				local success, balance = pcall(ledgerOrBalances.getBalance, ledgerOrBalances, userId)
				if success and type(balance) == "number" then
					total = total + balance
				end
			end
		elseif ledgerOrBalances.playerManager then
			-- It's an InventoryLedger or similar with playerManager
			-- Use getInventory or access player data
			for _, member in ipairs(members) do
				local player
				if type(member) == "number" then
					player = Players:GetPlayerByUserId(member)
				else
					player = member
				end
				
				if player and ledgerOrBalances.playerManager then
					local playerData = ledgerOrBalances.playerManager:getPlayerData(player)
					if playerData and playerData.currency then
						total = total + playerData.currency
					end
				end
			end
		end
	end
	
	return total
end

return PoolCalculator