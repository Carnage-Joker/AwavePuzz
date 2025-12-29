--[[
	OutfitController.lua
	Handles outfit interactions (catalog, equipping)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local OutfitController = {}
OutfitController.__index = OutfitController

-- Reference to UIController
local UIController = nil

function OutfitController.new()
	local self = setmetatable({}, OutfitController)
	self.initialized = false
	self.catalog = {}
	return self
end

function OutfitController:initialize(uiController)
	print("👗 OutfitController initializing...")
	
	UIController = uiController
	
	-- Fetch catalog
	self:fetchCatalog()
	
	self.initialized = true
	print("✅ OutfitController initialized")
	return true
end

-- Fetch catalog from server
function OutfitController:fetchCatalog()
	local getCatalogFunc = Remotes.getFunction("GetCatalog")
	local success, result = pcall(function()
		return getCatalogFunc:InvokeServer()
	end)
	
	if success and result then
		self.catalog = result
		print(string.format("Catalog loaded: %d items", #self.catalog))
	else
		warn("Failed to fetch catalog:", result)
	end
end

-- Equip an item
function OutfitController:equipItem(itemId)
	local equipFunc = Remotes.getFunction("EquipOutfit")
	local success, result = pcall(function()
		return equipFunc:InvokeServer(itemId)
	end)
	
	if success and result then
		if result.success then
			print(string.format("Equipped item: %s (Score: %d)", itemId, result.score or 0))
			-- Show toast
			self:showToast("Success", result.message)
			return true
		else
			warn("Failed to equip:", result.message)
			self:showToast("Error", result.message)
			return false
		end
	else
		warn("Error equipping item:", result)
		return false
	end
end

-- Show toast notification
function OutfitController:showToast(title, message)
	-- This would integrate with NotificationController
	print(string.format("[TOAST] %s: %s", title, message))
end

-- Get catalog
function OutfitController:getCatalog()
	return self.catalog
end

return OutfitController
