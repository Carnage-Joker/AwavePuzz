-- CureCraftingManager.lua
-- Manages the puzzle system for crafting the cure

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CureCraftingManager = {}
CureCraftingManager.__index = CureCraftingManager

function CureCraftingManager.new()
	local self = setmetatable({}, CureCraftingManager)
	self.componentsCollected = {}
	self.cureProgress = 0
	self.cureCrafted = false

	-- Initialize component tracking
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		self.componentsCollected[componentName] = 0
	end

	return self
end

function CureCraftingManager:addComponent(componentName)
	if self.cureCrafted then
		return false, "Cure already crafted"
	end

	if not self.componentsCollected[componentName] then
		return false, "Invalid component"
	end

	self.componentsCollected[componentName] = self.componentsCollected[componentName] + 1
	self:updateProgress()

	return true, "Component added"
end

function CureCraftingManager:getComponentCount(componentName)
	return self.componentsCollected[componentName] or 0
end

function CureCraftingManager:getAllComponents()
	return self.componentsCollected
end

function CureCraftingManager:updateProgress()
	local totalRequired = #GameConfig.CURE_COMPONENT_NAMES * GameConfig.CURE_COMPONENTS_REQUIRED
	local totalCollected = 0

	for _, count in pairs(self.componentsCollected) do
		totalCollected = totalCollected + count
	end

	self.cureProgress = (totalCollected / totalRequired) * 100

	-- Check if cure is complete
	if self:checkCureComplete() then
		self.cureCrafted = true
	end
end

function CureCraftingManager:checkCureComplete()
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		if self.componentsCollected[componentName] < GameConfig.CURE_COMPONENTS_REQUIRED then
			return false
		end
	end
	return true
end

function CureCraftingManager:getCureProgress()
	return self.cureProgress
end

function CureCraftingManager:isCureCrafted()
	return self.cureCrafted
end

function CureCraftingManager:getRemainingComponents()
	local remaining = {}
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		local needed = GameConfig.CURE_COMPONENTS_REQUIRED - self.componentsCollected[componentName]
		if needed > 0 then
			remaining[componentName] = needed
		end
	end
	return remaining
end

function CureCraftingManager:reset()
	for _, componentName in ipairs(GameConfig.CURE_COMPONENT_NAMES) do
		self.componentsCollected[componentName] = 0
	end
	self.cureProgress = 0
	self.cureCrafted = false
end

return CureCraftingManager
