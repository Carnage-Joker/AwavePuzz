--[[
    ItemSpawner.lua (ModuleScript)
    Manages spawning of ammo and health packs inside the base area
    Items appear every 60 seconds as pickable objects that players can collect
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))

local ItemSpawner = {}
ItemSpawner.__index = ItemSpawner

local CONFIG = {
	SPAWN_HEIGHT_OFFSET = 2,
	GROUND_CHECK_DISTANCE = 50,
	ROTATION_SPEED = 2,
}

function ItemSpawner.new()
	local self = setmetatable({}, ItemSpawner)

	self.playerManager = nil
	self.fpsWeaponService = nil
	self.activeItems = {}
	self.activeItemCount = 0 -- Track count for O(1) access
	self.spawnTimer = 0
	self.itemCounter = 0 -- For unique ID generation

	-- Create item folder in workspace
	self.itemFolder = workspace:FindFirstChild("ItemPickups")
	if not self.itemFolder then
		self.itemFolder = Instance.new("Folder")
		self.itemFolder.Name = "ItemPickups"
		self.itemFolder.Parent = workspace
	end

	print("ItemSpawner initialized")

	return self
end

function ItemSpawner:setPlayerManager(playerManager)
	self.playerManager = playerManager
end

function ItemSpawner:setFPSWeaponService(fpsWeaponService)
	self.fpsWeaponService = fpsWeaponService
end

local function getPivotPosition(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

function ItemSpawner:tryFindBasePosition()
	-- Look for common "base" objects in the workspace
	local candidates = {
		Workspace:FindFirstChild("Base"),
		Workspace:FindFirstChild("BaseCore"),
		Workspace:FindFirstChild("BaseStation"),
		Workspace:FindFirstChild("CureStation1"),
		Workspace:FindFirstChild("CureStations"),
	}

	for _, c in ipairs(candidates) do
		local pos = getPivotPosition(c)
		if pos then
			return pos
		end
		-- If folder/model, try children
		if c and c.GetDescendants then
			for _, d in ipairs(c:GetDescendants()) do
				local p = getPivotPosition(d)
				if p then
					return p
				end
			end
		end
	end

	return Vector3.new(0, 0, 0)
end

function ItemSpawner:raycastToGround(pos)
	local rayStart = Vector3.new(pos.X, pos.Y + CONFIG.GROUND_CHECK_DISTANCE, pos.Z)
	local rayDir = Vector3.new(0, -CONFIG.GROUND_CHECK_DISTANCE * 2, 0)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { self.itemFolder }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayStart, rayDir, params)
	if result and result.Position then
		return result.Position
	end
	return nil
end

function ItemSpawner:getRandomSpawnPositionNearBase()
	local basePos = self:tryFindBasePosition()
	local radius = GameConfig.ITEM_SPAWN_RADIUS
	
	-- Random position within radius of base
	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius
	local x = basePos.X + math.cos(angle) * distance
	local z = basePos.Z + math.sin(angle) * distance
	
	local candidatePos = Vector3.new(x, basePos.Y + 10, z)
	local groundPos = self:raycastToGround(candidatePos)
	
	if groundPos then
		return groundPos + Vector3.new(0, CONFIG.SPAWN_HEIGHT_OFFSET, 0)
	else
		-- Fallback to slightly above base position
		return basePos + Vector3.new(0, CONFIG.SPAWN_HEIGHT_OFFSET, 0)
	end
end

function ItemSpawner:spawnItem(itemType)
	-- Check if we've reached the max items on map
	if self:getActiveItemCount() >= GameConfig.MAX_ITEMS_ON_MAP then
		return nil
	end

	local spawnPoint = self:getRandomSpawnPositionNearBase()
	
	-- Generate unique ID using counter and tick for collision prevention
	self.itemCounter = self.itemCounter + 1
	local itemId = string.format("item_%d_%.0f", self.itemCounter, tick() * 1000)

	local part = Instance.new("Part")
	part.Name = itemType .. "_Pickup"
	part.Size = Vector3.new(2, 2, 2)
	part.Position = spawnPoint
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("ItemType", itemType)
	part:SetAttribute("ItemId", itemId)
	
	-- Set color and material based on type
	if itemType == "Ammo" then
		part.Color = Color3.fromRGB(255, 200, 50) -- Yellow/Gold
		part.Material = Enum.Material.Metal
	elseif itemType == "Health" then
		part.Color = Color3.fromRGB(255, 50, 50) -- Red
		part.Material = Enum.Material.Neon
	end
	
	part.Parent = self.itemFolder

	-- Add spinning animation
	local RunService = game:GetService("RunService")
	local rotationConnection
	rotationConnection = RunService.Heartbeat:Connect(function(dt)
		if not part or not part.Parent then
			if rotationConnection then
				rotationConnection:Disconnect()
			end
			return
		end
		part.CFrame = part.CFrame * CFrame.Angles(0, CONFIG.ROTATION_SPEED * dt, 0)
	end)

	part.Destroying:Connect(function()
		if rotationConnection then
			rotationConnection:Disconnect()
		end
	end)

	-- Add billboard label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	
	if itemType == "Ammo" then
		textLabel.Text = "Ammo Pack"
	elseif itemType == "Health" then
		textLabel.Text = "Health Pack"
	end
	
	textLabel.Parent = billboard

	-- Add touch collection
	local debouncing = false
	local touchConnection = part.Touched:Connect(function(hit)
		if debouncing then
			return
		end

		local character = hit and hit.Parent
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		debouncing = true

		-- Ensure debouncing is released if the item is still present after handling,
		-- so failed/early-return collection attempts don't permanently lock the item.
		local ok, err = pcall(function()
			self:onItemCollected(player, itemId, itemType, part)
		end)

		if not ok then
			warn(
				"[ItemSpawner] onItemCollected failed for itemId="
					.. tostring(itemId)
					.. ", itemType="
					.. tostring(itemType)
					.. ", player="
					.. (player and player.Name or "nil")
					.. " :: "
					.. tostring(err)
			)
		end
		-- Only clear the debounce if the item is still marked as active.
		-- This ties the debounce lifecycle to the authoritative item state
		-- (self.activeItems) instead of the physical part hierarchy, and
		-- avoids double-collection if onItemCollected logically consumed
		-- the item without immediately destroying/reparenting the part.
		if self.activeItems and self.activeItems[itemId] ~= nil then
			debouncing = false
		end
	end)

	-- Use helper method to add item and maintain synchronization
	local itemData = {
		itemType = itemType,
		instance = part,
		touchConnection = touchConnection,
		rotationConnection = rotationConnection
	}
	self:addActiveItem(itemId, itemData)

	print("Spawned " .. itemType .. " pack at " .. tostring(spawnPoint))

	return part
end

function ItemSpawner:onItemCollected(player, itemId, itemType, part)
	-- Early return if player is nil to avoid nil access errors
	if not player then
		warn("ItemSpawner:onItemCollected called with nil player")
		return
	end

	-- Retrieve the active item for this id; it may have already been cleaned up
	local item = self.activeItems[itemId]
	if not item then
		warn("ItemSpawner:onItemCollected could not find active item for id " .. tostring(itemId))
		return
	end
	local playerName = player.Name
	print(playerName .. " collected " .. itemType .. " pack")

	-- Track if reward was successfully granted
	local rewardGranted = false

	-- Grant rewards based on item type
	if itemType == "Ammo" then
		if self.fpsWeaponService and self.playerManager then
			-- Add ammo to current weapon's reserve
			local equippedWeapon = self.playerManager:getEquippedWeapon(player)
			if equippedWeapon then
				local success = self.fpsWeaponService:addAmmo(player, equippedWeapon, GameConfig.AMMO_PACK_AMOUNT, true) -- true = add to reserve
				if success then
					print(playerName .. " received " .. GameConfig.AMMO_PACK_AMOUNT .. " reserve ammo")
					rewardGranted = true
				end
			else
				-- Provide feedback when player tries to use an ammo pack without an equipped weapon
				if player and player.SetAttribute then
					player:SetAttribute("LastPickupFailed", "NoEquippedWeaponForAmmo")
					player:SetAttribute("LastPickupFailedMessage", "You need to equip a weapon before using an ammo pack.")
				end
				print(playerName .. " tried to use an ammo pack without an equipped weapon")
			end
		end
	elseif itemType == "Health" then
		if self.playerManager then
			-- Prevent consuming health packs when already at full health
			local canHeal = true

			if player and player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.MaxHealth > 0 and humanoid.Health >= humanoid.MaxHealth then
					canHeal = false
				end
			end

			if canHeal then
				-- Use PlayerManager:healPlayer for consistent health management
				local success = self.playerManager:healPlayer(player, GameConfig.HEALTH_PACK_AMOUNT)
				if success then
					print(playerName .. " healed for " .. GameConfig.HEALTH_PACK_AMOUNT .. " HP")
					rewardGranted = true
				else
					print(playerName .. " tried to use a health pack but healing failed")
				end
			else
				-- Provide feedback when player tries to pick up a health pack at full health
				if player and player.SetAttribute then
					player:SetAttribute("LastPickupFailed", "HealthFull")
					player:SetAttribute("LastPickupFailedMessage", "You are already at full health.")
				end
				print(playerName .. " tried to use a health pack but is already at full health")
			end
		end
	end

	-- Only clean up the item if the reward was successfully granted
	if rewardGranted then
		-- Get item data before removing it from activeItems
		local success, item = self:removeActiveItem(itemId)
		
		if success and item then
			if item.touchConnection then
				item.touchConnection:Disconnect()
			end
			if item.rotationConnection then
				item.rotationConnection:Disconnect()
			end

			if part and part.Parent then
				part:Destroy()
			end
		end
	end
end

function ItemSpawner:update(deltaTime)
	self.spawnTimer = self.spawnTimer + deltaTime

	if self.spawnTimer >= GameConfig.ITEM_SPAWN_INTERVAL then
		self.spawnTimer = 0

		-- Determine how many items we can spawn this tick
		local currentCount = self:getActiveItemCount()
		local maxItems = GameConfig.MAX_ITEMS_ON_MAP
		local remainingSlots = maxItems - currentCount

		if remainingSlots <= 0 then
			return
		end

		-- Lazily initialize nextSpawnItemType for balanced spawning when only one slot is free
		if not self.nextSpawnItemType then
			self.nextSpawnItemType = "Ammo"
		end

		if remainingSlots == 1 then
			-- Only one slot left: alternate between Ammo and Health based on successful spawns
			local beforeCount = self:getActiveItemCount()
			self:spawnItem(self.nextSpawnItemType)
			local afterCount = self:getActiveItemCount()

			-- Only toggle the next type if we actually spawned an item
			if afterCount > beforeCount then
				if self.nextSpawnItemType == "Ammo" then
					self.nextSpawnItemType = "Health"
				else
					self.nextSpawnItemType = "Ammo"
				end
			end
		else
			-- Two or more slots: attempt to spawn both ammo and health, as before
			local itemsToSpawn = {"Ammo", "Health"}
			for _, itemType in ipairs(itemsToSpawn) do
				local updatedCount = self:getActiveItemCount()
				if updatedCount < maxItems then
					self:spawnItem(itemType)
				end
			end
		end
	end
end

-- Helper method to add an item to activeItems table
-- Centralizes add operations to keep activeItemCount synchronized
function ItemSpawner:addActiveItem(itemId, itemData)
	if self.activeItems[itemId] ~= nil then
		warn("[ItemSpawner] Attempted to add duplicate itemId: " .. tostring(itemId))
		return false
	end
	
	self.activeItems[itemId] = itemData
	self.activeItemCount = self.activeItemCount + 1
	return true
end

-- Helper method to remove an item from activeItems table
-- Centralizes remove operations to keep activeItemCount synchronized
function ItemSpawner:removeActiveItem(itemId)
	if self.activeItems[itemId] == nil then
		warn("[ItemSpawner] Attempted to remove non-existent itemId: " .. tostring(itemId))
		return false
	end
	
	local item = self.activeItems[itemId]
	self.activeItems[itemId] = nil
	self.activeItemCount = self.activeItemCount - 1
	return true, item
end

function ItemSpawner:getActiveItemCount()
	return self.activeItemCount
end

function ItemSpawner:clearAllItems()
	-- Make a copy of keys to avoid issues with modifying table during iteration
	local itemIds = {}
	for itemId in pairs(self.activeItems) do
		table.insert(itemIds, itemId)
	end
	
	-- Remove each item using the helper method
	for _, itemId in ipairs(itemIds) do
		local success, item = self:removeActiveItem(itemId)
		if success and item then
			if item.touchConnection then
				item.touchConnection:Disconnect()
			end
			if item.rotationConnection then
				item.rotationConnection:Disconnect()
			end
			if item.instance and item.instance.Parent then
				item.instance:Destroy()
			end
		end
	end
end

return ItemSpawner
