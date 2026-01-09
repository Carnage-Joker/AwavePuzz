-- @ScriptType: ModuleScript
-- InventoryLedger.lua
-- Atomic transaction system for betrayal resource transfers
-- Ensures no duping and balanced transfers

local Players = game:GetService("Players")

local InventoryLedger = {}
InventoryLedger.__index = InventoryLedger

function InventoryLedger.new(playerManager)
	local self = setmetatable({}, InventoryLedger)

	self.playerManager = playerManager
	self.activeTransaction = nil

	return self
end

-- Begin a new transaction
function InventoryLedger:begin()
	if self.activeTransaction then
		warn("[InventoryLedger] Transaction already active")
		return false
	end

	self.activeTransaction = {
		deductions = {}, -- userId -> deduction struct
		grants = {}, -- userId -> grant struct
		committed = false
	}

	return true
end

-- Add a deduction to the transaction
function InventoryLedger:applyDeduction(playerId, deductionStruct)
	if not self.activeTransaction then
		warn("[InventoryLedger] No active transaction")
		return false
	end

	if not deductionStruct then
		return false
	end

	self.activeTransaction.deductions[playerId] = deductionStruct
	return true
end

-- Add a grant to the transaction
function InventoryLedger:applyGrant(playerId, grantStruct)
	if not self.activeTransaction then
		warn("[InventoryLedger] No active transaction")
		return false
	end

	if not grantStruct then
		return false
	end

	self.activeTransaction.grants[playerId] = grantStruct
	return true
end

-- Commit the transaction (apply all deductions and grants atomically)
function InventoryLedger:commit()
	if not self.activeTransaction then
		warn("[InventoryLedger] No active transaction")
		return false
	end

	if self.activeTransaction.committed then
		warn("[InventoryLedger] Transaction already committed")
		return false
	end

	local success = true
	local errorMsg = nil

	-- First, validate all deductions are possible
	for playerId, deduction in pairs(self.activeTransaction.deductions) do
		local player = Players:GetPlayerByUserId(playerId)
		if player then
			local playerData = self.playerManager:getPlayerData(player)
			if playerData then
				-- Validate currency
				if deduction.currency and playerData.currency < deduction.currency then
					success = false
					errorMsg = "Insufficient currency for player " .. player.Name
					break
				end

				-- Validate resources
				if success and deduction.resources then
					for resourceName, amount in pairs(deduction.resources) do
						local current = playerData.inventory[resourceName] or 0
						if current < amount then
							success = false
							errorMsg = "Insufficient resource " .. resourceName .. " for player " .. player.Name
							break
						end
					end
				end

				if not success then
					break
				end

				-- Validate components
				if success and deduction.components then
					for componentName, amount in pairs(deduction.components) do
						local current = playerData.cureComponents[componentName] or 0
						if current < amount then
							success = false
							errorMsg = "Insufficient component " .. componentName .. " for player " .. player.Name
							break
						end
					end
				end

				if not success then
					break
				end

				-- Validate weapons
				if success and deduction.weapons then
					for _, weaponId in ipairs(deduction.weapons) do
						if not playerData.weapons[weaponId] then
							success = false
							errorMsg = "Player " .. player.Name .. " does not own weapon " .. weaponId
							break
						end
					end
				end
			end
		end

		if not success then
			break
		end
	end

	if not success then
		local finalErrorMsg = errorMsg
		if finalErrorMsg == nil or finalErrorMsg == "" then
			finalErrorMsg = "Unknown error"
		end
		warn("[InventoryLedger] Transaction validation failed: " .. finalErrorMsg)
		self:rollback()
		return false
	end

	-- Apply all deductions
	for playerId, deduction in pairs(self.activeTransaction.deductions) do
		local player = Players:GetPlayerByUserId(playerId)
		if player then
			local playerData = self.playerManager:getPlayerData(player)
			if playerData then
				-- Deduct currency
				if deduction.currency then
					playerData.currency = math.max(0, playerData.currency - deduction.currency)
				end

				-- Deduct resources
				if deduction.resources then
					for resourceName, amount in pairs(deduction.resources) do
						local current = playerData.inventory[resourceName] or 0
						playerData.inventory[resourceName] = math.max(0, current - amount)
						if playerData.inventory[resourceName] == 0 then
							playerData.inventory[resourceName] = nil
						end
					end
				end

				-- Deduct components
				if deduction.components then
					for componentName, amount in pairs(deduction.components) do
						local current = playerData.cureComponents[componentName] or 0
						playerData.cureComponents[componentName] = math.max(0, current - amount)
						if playerData.cureComponents[componentName] == 0 then
							playerData.cureComponents[componentName] = nil
						end
					end
				end

				-- Deduct weapons
				if deduction.weapons then
					for _, weaponId in ipairs(deduction.weapons) do
						playerData.weapons[weaponId] = nil
					end
				end

				-- Send updates to client
				self.playerManager:sendCurrencyUpdate(player)
				self.playerManager:sendInventoryUpdate(player)
				self.playerManager:sendWeaponLoadout(player)
			end
		end
	end

	-- Apply all grants
	for playerId, grant in pairs(self.activeTransaction.grants) do
		local player = Players:GetPlayerByUserId(playerId)
		if player then
			local playerData = self.playerManager:getPlayerData(player)
			if playerData then
				-- Grant currency
				if grant.currency then
					playerData.currency = playerData.currency + grant.currency
				end

				-- Grant resources
				if grant.resources then
					for resourceName, amount in pairs(grant.resources) do
						playerData.inventory[resourceName] = (playerData.inventory[resourceName] or 0) + amount
					end
				end

				-- Grant components
				if grant.components then
					for componentName, amount in pairs(grant.components) do
						playerData.cureComponents[componentName] = (playerData.cureComponents[componentName] or 0) + amount
					end
				end

				-- Grant weapons
				if grant.weapons then
					for _, weaponId in ipairs(grant.weapons) do
						playerData.weapons[weaponId] = true
					end
				end

				-- Send updates to client
				self.playerManager:sendCurrencyUpdate(player)
				self.playerManager:sendInventoryUpdate(player)
				self.playerManager:sendWeaponLoadout(player)
			end
		end
	end

	self.activeTransaction.committed = true
	self.activeTransaction = nil

	return true
end

-- Rollback the transaction (discard all pending changes)
function InventoryLedger:rollback()
	if not self.activeTransaction then
		return false
	end

	self.activeTransaction = nil
	return true
end

return InventoryLedger