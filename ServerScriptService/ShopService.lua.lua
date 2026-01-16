-- @ScriptType: Script
-- ShopService.lua
-- Handles server-authoritative weapon purchases and upgrades

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WeaponConfig = require(SharedFolder:WaitForChild("WeaponConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

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
	-- Use shared utility to create remote events
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"ShopRequest",
		"ShopUpdate"
	})

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
		if typeof(data) ~= "table" or data.itemId == nil then
			self:sendResult(player, false, "Invalid purchase data")
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
		self.remoteEvents.ShopUpdate:FireClient(player, {
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

		if self.playerManager.ownsWeapon and self.playerManager:ownsWeapon(player, selectedItem.WeaponId) then
			self:sendResult(player, false, "Weapon already unlocked")
			return
		end

		if not (self.playerManager.deductCurrency and self.playerManager:deductCurrency(player, price)) then
			self:sendResult(player, false, "Not enough currency")
			return
		end

		if self.playerManager.addWeapon then
			self.playerManager:addWeapon(player, selectedItem.WeaponId)
		end

		if self.playerManager.equipWeapon then
			self.playerManager:equipWeapon(player, selectedItem.WeaponId)
		end

		self:sendResult(player, true, tostring(selectedItem.WeaponId) .. " unlocked!")

		-- Handle upgrade purchase
	elseif selectedItem.Type == "upgrade" then
		if not selectedItem.UpgradeId then
			self:sendResult(player, false, "Invalid upgrade item")
			return
		end

		if not (self.playerManager.deductCurrency and self.playerManager:deductCurrency(player, price)) then
			self:sendResult(player, false, "Not enough currency")
			return
		end

		if not (self.weaponService and self.weaponService.applyUpgrade) then
			warn("[ShopService] weaponService or applyUpgrade missing")
			-- Refund due to internal error
			if self.playerManager.addCurrency then
				self.playerManager:addCurrency(player, price)
			end
			self:sendResult(player, false, "Upgrade service unavailable")
			return
		end

		local success, applyErr = pcall(function()
			return self.weaponService:applyUpgrade(player, selectedItem.UpgradeId)
		end)

		if not success then
			warn("[ShopService] applyUpgrade error: " .. tostring(applyErr))
			if self.playerManager.addCurrency then
				self.playerManager:addCurrency(player, price)
			end
			self:sendResult(player, false, "Upgrade failed")
			return
		end

		if success and applyErr then
			-- applyErr is actually the boolean result from applyUpgrade
			self:sendResult(player, true, "Upgrade applied")
		else
			-- Refund if already owned or failed
			if self.playerManager.addCurrency then
				self.playerManager:addCurrency(player, price)
			end
			self:sendResult(player, false, "Upgrade already owned")
		end
	else
		self:sendResult(player, false, "Unknown item type")
	end
end

function ShopService:sendResult(player, success, message)
	if not self.remoteEvents.ShopUpdate then
		return
	end

	self.remoteEvents.ShopUpdate:FireClient(player, {
		type = "result",
		success = success and true or false,
		message = message or "",
	})
end

return ShopService
