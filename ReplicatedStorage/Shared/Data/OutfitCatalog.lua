--[[
	OutfitCatalog.lua
	Contains all outfit items available in the game
]]

local OutfitCatalog = {}

-- Outfit item catalog
-- Fields:
--   id: unique identifier
--   name: display name
--   slot: which slot it occupies (Hat, Dress, Shoes, Accessory1-3)
--   paletteTags: array of palette names this item matches
--   silhouette: shape category (Flowing, Structured, Elegant, Casual)
--   rarity: Common, Uncommon, Rare, Epic, Legendary
--   price: cost in Coins
OutfitCatalog.items = {
	-- Hats
	{id = "hat_sunhat", name = "Elegant Sun Hat", slot = "Hat", paletteTags = {"Pastel", "Warm"}, silhouette = "Elegant", rarity = "Uncommon", price = 150},
	{id = "hat_beret", name = "Chic Beret", slot = "Hat", paletteTags = {"Monochrome", "Cool"}, silhouette = "Casual", rarity = "Common", price = 100},
	{id = "hat_floral", name = "Floral Crown", slot = "Hat", paletteTags = {"Nature", "Vibrant"}, silhouette = "Elegant", rarity = "Rare", price = 300},
	{id = "hat_ribbon", name = "Silk Ribbon Headband", slot = "Hat", paletteTags = {"Pastel", "Elegant"}, silhouette = "Elegant", rarity = "Uncommon", price = 180},
	
	-- Dresses
	{id = "dress_summer", name = "Summer Breeze Dress", slot = "Dress", paletteTags = {"Pastel", "Warm"}, silhouette = "Flowing", rarity = "Common", price = 200},
	{id = "dress_evening", name = "Evening Gown", slot = "Dress", paletteTags = {"Monochrome", "Elegant"}, silhouette = "Elegant", rarity = "Epic", price = 800},
	{id = "dress_garden", name = "Garden Party Dress", slot = "Dress", paletteTags = {"Nature", "Vibrant"}, silhouette = "Flowing", rarity = "Rare", price = 500},
	{id = "dress_casual", name = "Casual Day Dress", slot = "Dress", paletteTags = {"Warm", "Casual"}, silhouette = "Casual", rarity = "Common", price = 150},
	{id = "dress_cocktail", name = "Cocktail Dress", slot = "Dress", paletteTags = {"Cool", "Elegant"}, silhouette = "Structured", rarity = "Rare", price = 600},
	{id = "dress_maxi", name = "Flowing Maxi Dress", slot = "Dress", paletteTags = {"Pastel", "Nature"}, silhouette = "Flowing", rarity = "Uncommon", price = 350},
	
	-- Shoes
	{id = "shoes_heels", name = "Classic Heels", slot = "Shoes", paletteTags = {"Monochrome", "Elegant"}, silhouette = "Elegant", rarity = "Uncommon", price = 250},
	{id = "shoes_flats", name = "Ballet Flats", slot = "Shoes", paletteTags = {"Pastel", "Casual"}, silhouette = "Casual", rarity = "Common", price = 120},
	{id = "shoes_sandals", name = "Strappy Sandals", slot = "Shoes", paletteTags = {"Warm", "Casual"}, silhouette = "Casual", rarity = "Common", price = 100},
	{id = "shoes_boots", name = "Ankle Boots", slot = "Shoes", paletteTags = {"Cool", "Structured"}, silhouette = "Structured", rarity = "Uncommon", price = 280},
	
	-- Accessories
	{id = "acc_pearl", name = "Pearl Necklace", slot = "Accessory", paletteTags = {"Elegant", "Monochrome"}, silhouette = "Elegant", rarity = "Rare", price = 400},
	{id = "acc_bracelet", name = "Gold Bracelet", slot = "Accessory", paletteTags = {"Warm", "Elegant"}, silhouette = "Elegant", rarity = "Uncommon", price = 200},
	{id = "acc_earrings", name = "Crystal Earrings", slot = "Accessory", paletteTags = {"Cool", "Elegant"}, silhouette = "Elegant", rarity = "Rare", price = 350},
	{id = "acc_scarf", name = "Silk Scarf", slot = "Accessory", paletteTags = {"Vibrant", "Elegant"}, silhouette = "Flowing", rarity = "Uncommon", price = 180},
	{id = "acc_clutch", name = "Evening Clutch", slot = "Accessory", paletteTags = {"Monochrome", "Elegant"}, silhouette = "Structured", rarity = "Epic", price = 500},
	{id = "acc_sunglasses", name = "Designer Sunglasses", slot = "Accessory", paletteTags = {"Cool", "Casual"}, silhouette = "Casual", rarity = "Uncommon", price = 220},
	{id = "acc_watch", name = "Elegant Watch", slot = "Accessory", paletteTags = {"Monochrome", "Structured"}, silhouette = "Structured", rarity = "Rare", price = 450},
	{id = "acc_ring", name = "Statement Ring", slot = "Accessory", paletteTags = {"Vibrant", "Elegant"}, silhouette = "Elegant", rarity = "Epic", price = 600},
	{id = "acc_brooch", name = "Vintage Brooch", slot = "Accessory", paletteTags = {"Elegant", "Warm"}, silhouette = "Elegant", rarity = "Legendary", price = 1000},
	{id = "acc_hairpin", name = "Decorative Hairpin", slot = "Accessory", paletteTags = {"Pastel", "Elegant"}, silhouette = "Elegant", rarity = "Uncommon", price = 160},
}

-- Get item by ID
function OutfitCatalog.getItem(itemId: string)
	for _, item in ipairs(OutfitCatalog.items) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

-- Get all items in a specific slot
function OutfitCatalog.getItemsBySlot(slot: string)
	local results = {}
	for _, item in ipairs(OutfitCatalog.items) do
		if item.slot == slot or (item.slot == "Accessory" and string.find(slot, "Accessory")) then
			table.insert(results, item)
		end
	end
	return results
end

return OutfitCatalog
