--[[
	OutfitService.lua
	Handles outfit catalog, equip validation, and outfit scoring
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OutfitCatalog = require(ReplicatedStorage.Shared.Data.OutfitCatalog)
local ColorPalettes = require(ReplicatedStorage.Shared.Data.ColorPalettes)
local Constants = require(ReplicatedStorage.Shared.Constants)

local OutfitService = {}
OutfitService.__index = OutfitService

-- References to other services
local DataService = nil
local CurrencyService = nil

function OutfitService.new()
	local self = setmetatable({}, OutfitService)
	self.initialized = false
	return self
end

function OutfitService:initialize(dataService, currencyService)
	print("👗 OutfitService initializing...")
	
	DataService = dataService
	CurrencyService = currencyService
	self.initialized = true
	
	print("✅ OutfitService initialized")
	return true
end

-- Get full catalog (client can request this)
function OutfitService:getCatalog()
	return OutfitCatalog.items
end

-- Validate and equip outfit item
function OutfitService:equipItem(player: Player, itemId: string)
	if not DataService then
		return {success = false, message = "Service not ready"}
	end
	
	-- Get item from catalog
	local item = OutfitCatalog.getItem(itemId)
	if not item then
		return {success = false, message = "Item not found"}
	end
	
	-- Check if player owns the item
	if not DataService:ownsItem(player, itemId) then
		return {success = false, message = "You don't own this item"}
	end
	
	-- Determine which slot to use
	local slot = item.slot
	
	-- Handle accessories (need to find an available accessory slot)
	if slot == "Accessory" then
		slot = self:findAvailableAccessorySlot(player)
		if not slot then
			return {success = false, message = "All accessory slots are full"}
		end
	end
	
	-- Equip the item
	DataService:equipItem(player, slot, itemId)
	
	-- Calculate outfit score
	local score = self:calculateOutfitScore(player)
	
	return {
		success = true,
		message = "Item equipped!",
		slot = slot,
		score = score,
	}
end

-- Unequip item from slot
function OutfitService:unequipSlot(player: Player, slot: string)
	if not DataService then
		return {success = false, message = "Service not ready"}
	end
	
	DataService:equipItem(player, slot, nil)
	
	return {success = true, message = "Item unequipped"}
end

-- Find available accessory slot
function OutfitService:findAvailableAccessorySlot(player: Player)
	local outfit = DataService:getEquippedOutfit(player)
	if not outfit then
		return nil
	end
	
	-- Check accessory slots 1-3
	for i = 1, Constants.MAX_ACCESSORIES do
		local slotName = "Accessory" .. i
		if not outfit[slotName] then
			return slotName
		end
	end
	
	return nil  -- All slots full
end

-- Calculate outfit score based on harmony, silhouette, balance
function OutfitService:calculateOutfitScore(player: Player)
	local outfit = DataService:getEquippedOutfit(player)
	if not outfit then
		return 0
	end
	
	-- Collect equipped items
	local equippedItems = {}
	for _, itemId in pairs(outfit) do
		if itemId then
			local item = OutfitCatalog.getItem(itemId)
			if item then
				table.insert(equippedItems, item)
			end
		end
	end
	
	if #equippedItems == 0 then
		return 0
	end
	
	-- Calculate sub-scores
	local harmonyScore = ColorPalettes.calculateHarmony(equippedItems)
	local silhouetteScore = self:calculateSilhouetteScore(equippedItems)
	local balanceScore = self:calculateBalanceScore(outfit)
	
	-- Weighted average
	local totalScore = (harmonyScore * 0.4) + (silhouetteScore * 0.3) + (balanceScore * 0.3)
	
	return math.floor(totalScore)
end

-- Calculate silhouette consistency score
function OutfitService:calculateSilhouetteScore(items)
	-- Count silhouette tags
	local silhouettes = {}
	for _, item in ipairs(items) do
		local sil = item.silhouette
		silhouettes[sil] = (silhouettes[sil] or 0) + 1
	end
	
	-- Find dominant silhouette
	local maxCount = 0
	for _, count in pairs(silhouettes) do
		maxCount = math.max(maxCount, count)
	end
	
	-- Score based on consistency
	local consistency = maxCount / #items
	return consistency * 100
end

-- Calculate accessory balance score
function OutfitService:calculateBalanceScore(outfit)
	-- Count equipped items
	local itemCount = 0
	local accessoryCount = 0
	
	for slot, itemId in pairs(outfit) do
		if itemId then
			itemCount = itemCount + 1
			if string.find(slot, "Accessory") then
				accessoryCount = accessoryCount + 1
			end
		end
	end
	
	-- Reward having multiple items
	local itemScore = math.min(itemCount / 5, 1) * 50
	
	-- Reward balanced accessories (1-2 is good, 0 or 3 is okay)
	local accessoryScore = 50
	if accessoryCount == 1 or accessoryCount == 2 then
		accessoryScore = 50  -- Perfect
	elseif accessoryCount == 0 or accessoryCount == 3 then
		accessoryScore = 30  -- Okay
	end
	
	return itemScore + accessoryScore
end

-- Purchase item (validate and deduct currency)
function OutfitService:purchaseItem(player: Player, itemId: string)
	if not DataService or not CurrencyService then
		return {success = false, message = "Services not ready"}
	end
	
	-- Get item from catalog
	local item = OutfitCatalog.getItem(itemId)
	if not item then
		return {success = false, message = "Item not found"}
	end
	
	-- Check if already owned
	if DataService:ownsItem(player, itemId) then
		return {success = false, message = "You already own this item"}
	end
	
	-- Check if player can afford
	if not CurrencyService:canAfford(player, "Coins", item.price) then
		return {success = false, message = "Not enough Coins"}
	end
	
	-- Deduct currency
	if not CurrencyService:removeCurrency(player, "Coins", item.price) then
		return {success = false, message = "Transaction failed"}
	end
	
	-- Add item to inventory
	DataService:addItem(player, itemId)
	
	return {
		success = true,
		message = string.format("Purchased %s!", item.name),
		item = item,
	}
end

return OutfitService
