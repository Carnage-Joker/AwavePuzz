-- @ScriptType: ModuleScript
-- ShopService.lua
-- Handles server-authoritative weapon purchases and upgrades

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[ShopService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local WeaponConfig = SharedFolder:WaitForChild("WeaponConfig", 5)
if not WeaponConfig then
	error("[ShopService] CRITICAL: Failed to load WeaponConfig after 5 seconds")
end
WeaponConfig = require(WeaponConfig)

local RemoteRegistry = SharedFolder:WaitForChild("RemoteRegistry", 5)
if not RemoteRegistry then
	error("[ShopService] CRITICAL: Failed to load RemoteRegistry after 5 seconds")
end
RemoteRegistry = require(RemoteRegistry)

local ShopService = {}
ShopService.__index = ShopService

local VALID_ACTIONS = {
	catalog = true,
	purchase = true,
}

function ShopService.new(playerManager, weaponService)
	local self = setmetatable({}, ShopService)

	self.playerManager = playerManager
	self.weaponService = weaponService
	self.remoteEvents = {}

	self:setupRemoteEvents()

	return self
end

function ShopService:setupRemoteEvents()
	-- Use RemoteRegistry to get server remotes
	local remotes = RemoteRegistry.GetServerRemotes()
	self.remoteEvents = {
		ShopRequest = remotes.ShopRequest,
		ShopUpdate = remotes.ShopUpdate,
	}

	self.remoteEvents.ShopRequest.OnServerEvent:Connect(function(player, action, data)
		self:handleRequest(player, action, data)
	end)
end

function ShopService:handleRequest(player, action, data)
	if not player or typeof(player) ~= "Instance" then
		return
	end

	if typeof(action) ~= "string" or not VALID_ACTIONS[action] then
		self:sendResult(player, false, "Invalid shop action")
		return
	end

	if action == "catalog" then
		self:sendCatalog(player)
	elseif action == "purchase" then
		-- SECURITY: Validate purchase data structure and item ID type
		if typeof(data) ~= "table" or data.itemId == nil then
			self:sendResult(player, false, "Invalid purchase data")
			return
		end
		
		if typeof(data.itemId) ~= "string" then
			warn("[ShopService] SECURITY: Invalid itemId type from " .. player.Name)
			self:sendResult(player, false, "Invalid item ID")
			return
		end

		self:attemptPurchase(player, data.itemId)
	end
end

function ShopService:sendCatalog(player)
	local catalog = nil
	local ok, err = pcall(function()
		catalog = WeaponConfig.getCatalog()
	end)

	if not ok then
		warn("[ShopService] WeaponConfig.getCatalog error: " .. tostring(err))
		self:sendResult(player, false, "Shop is currently unavailable")
		return
	end

	if typeof(catalog) ~= "table" then
		warn("[ShopService] getCatalog did not return a table")
		self:sendResult(player, false, "Shop is currently unavailable")
		return
	end

	if self.remoteEvents.ShopUpdate then
		RemoteRegistry.SafeFireClient(self.remoteEvents.ShopUpdate, player, {
			type = "catalog",
			items = catalog,
		})
	end
end

local function findCatalogItemById(catalog, itemId)
	for _, item in ipairs(catalog) do
		if item.Id == itemId then
			return item
		end
	end
	return nil
end

function ShopService:attemptPurchase(player, itemId)
	if not self.playerManager then
		warn("[ShopService] playerManager not set")
		self:sendResult(player, false, "Shop unavailable")
		return
	end

	local catalog
	local ok, err = pcall(function()
		catalog = WeaponConfig.getCatalog()
	end)

	if not ok or typeof(catalog) ~= "table" then
		warn("[ShopService] Failed to fetch catalog: " .. tostring(err))
		self:sendResult(player, false, "Shop is currently unavailable")
		return
	end

	local selectedItem = findCatalogItemById(catalog, itemId)
	if not selectedItem then
		self:sendResult(player, false, "Item not found")
		return
	end

	-- Basic validation
	local price = tonumber(selectedItem.Price) or 0
	if price < 0 then
		warn("[ShopService] Item has invalid price: " .. tostring(price))
		self:sendResult(player, false, "Purchase unavailable")
		return
	end

	-- Handle weapon purchase
	if selectedItem.Type == "weapon" then
		if not selectedItem.WeaponId then
			self:sendResult(player, false, "Invalid weapon item")
			return
		end

		-- Validate playerManager is available (required for all shop operations)
		if not self.playerManager then
			warn("[ShopService] playerManager is not initialized")
			self:sendResult(player, false, "Shop service unavailable")
			return
		end

		-- Check if player already owns the weapon
		if self.playerManager.ownsWeapon and self.playerManager:ownsWeapon(player, selectedItem.WeaponId) then
			self:sendResult(player, false, "Weapon already unlocked")
			return
		end

		-- BUGFIX (MEDIUM): Validate player has sufficient currency before attempting deduction
		-- This provides better early feedback to the player. Note: There's a small TOCTOU
		-- (time-of-check to time-of-use) window between this check and the actual deduction,
		-- but deductCurrency handles insufficient funds anyway, making this defensive.
		if self.playerManager.getCurrency then
			local currentCurrency = self.playerManager:getCurrency(player) or 0
			if currentCurrency < price then
				self:sendResult(player, false, "Not enough currency")
				return
			end
		end

		-- Deduct currency first (proper transaction order)
		if not (self.playerManager.deductCurrency and self.playerManager:deductCurrency(player, price)) then
			self:sendResult(player, false, "Not enough currency")
			return
		end

		-- Add weapon after currency deducted
		local weaponAdded = false
		if self.playerManager.addWeapon then
			weaponAdded = self.playerManager:addWeapon(player, selectedItem.WeaponId)
		end

		-- Refund if weapon add failed
		if not weaponAdded then
			if self.playerManager.addCurrency then
				self.playerManager:addCurrency(player, price)
			end
			self:sendResult(player, false, "Failed to add weapon")
			return
		end

		-- FIX: Use WeaponService to properly equip weapon and initialize ammo
		if self.weaponService and self.weaponService.forceEquip then
			self.weaponService:forceEquip(player, selectedItem.WeaponId)
		elseif self.playerManager.equipWeapon then
			warn(string.format("[ShopService] WeaponService or forceEquip method not available for player %s - falling back to PlayerManager.equipWeapon (ammo initialization will be incomplete)", player.Name))
			self.playerManager:equipWeapon(player, selectedItem.WeaponId)
		else
			warn(string.format("[ShopService] No weapon equip method available for player %s", player.Name))
		end

		self:sendResult(player, true, tostring(selectedItem.WeaponId) .. " unlocked!")

		-- Handle upgrade purchase
	elseif selectedItem.Type == "upgrade" then
		if not selectedItem.UpgradeId then
			self:sendResult(player, false, "Invalid upgrade item")
			return
		end

		-- Validate weaponService exists before attempting upgrade
		if not (self.weaponService and self.weaponService.applyUpgrade) then
			warn("[ShopService] weaponService or applyUpgrade missing")
			self:sendResult(player, false, "Service temporarily unavailable")
			return
		end

		-- BUGFIX (MEDIUM): Validate player has sufficient currency before attempting deduction
		-- This provides better early feedback. Note: There's a small TOCTOU window, but
		-- deductCurrency handles insufficient funds anyway, making this defensive.
		if self.playerManager and self.playerManager.getCurrency then
			local currentCurrency = self.playerManager:getCurrency(player) or 0
			if currentCurrency < price then
				self:sendResult(player, false, "Not enough currency")
				return
			end
		end

		-- Deduct currency first (proper transaction order)
		if not (self.playerManager and self.playerManager.deductCurrency and self.playerManager:deductCurrency(player, price)) then
			self:sendResult(player, false, "Not enough currency")
			return
		end

		-- Apply upgrade after currency deducted
		local success = self.weaponService:applyUpgrade(player, selectedItem.UpgradeId)
		if not success then
			-- Refund on failure since upgrade is not reversible
			if self.playerManager.addCurrency then
				self.playerManager:addCurrency(player, price)
			end
			self:sendResult(player, false, "Upgrade failed")
			return
		end

		self:sendResult(player, true, "Upgrade applied")
	else
		self:sendResult(player, false, "Unknown item type")
	end
end

function ShopService:sendResult(player, success, message)
	if not self.remoteEvents.ShopUpdate then
		return
	end

	RemoteRegistry.SafeFireClient(self.remoteEvents.ShopUpdate, player, {
		type = "result",
		success = success and true or false,
		message = message or "",
	})
end

-- Compatibility shim: purchaseItem(player, itemId, quantity) for test API
-- Forwards to the existing attemptPurchase implementation
--
-- IMPORTANT NOTES FOR API CONSUMERS:
-- 1. quantity parameter is ACCEPTED but IGNORED (attemptPurchase doesn't support it)
--    - Kept in signature for test API compatibility
--    - Future enhancement would require modifying attemptPurchase
-- 2. Return value of TRUE means request was PROCESSED, NOT necessarily successful
--    - Do NOT rely on this return value for success verification
--    - Actual success/failure communicated via ShopUpdate remote event
--    - For production code, use attemptPurchase directly or monitor remote events
function ShopService:purchaseItem(player, itemId, quantity)
	-- Validate inputs
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	
	if not itemId then
		return false
	end
	
	-- quantity parameter accepted for test API compatibility but explicitly ignored
	-- (attemptPurchase implementation doesn't support quantity parameter)
	
	-- Forward to existing purchase logic
	self:attemptPurchase(player, itemId)
	
	-- Return true = request processed (NOT success/failure indication)
	return true
end

return ShopService
