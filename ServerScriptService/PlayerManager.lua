-- @ScriptType: ModuleScript
-- PlayerManager.lua
-- Manages player data, inventory, currency, alliances, and health
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[PlayerManager] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[PlayerManager] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local WeaponConfig = SharedFolder:WaitForChild("WeaponConfig", 5)
if not WeaponConfig then
	error("[PlayerManager] CRITICAL: Failed to load WeaponConfig after 5 seconds")
end
WeaponConfig = require(WeaponConfig)

local RemoteEventUtil = SharedFolder:WaitForChild("RemoteEventUtil", 5)
if not RemoteEventUtil then
	error("[PlayerManager] CRITICAL: Failed to load RemoteEventUtil after 5 seconds")
end
RemoteEventUtil = require(RemoteEventUtil)

local PlayerManager = {}
PlayerManager.__index = PlayerManager

-- Singleton instance
local _instance = nil

function PlayerManager.getInstance()
	if not _instance then
		_instance = PlayerManager.new()
	end
	return _instance
end

function PlayerManager.new()
	local self = setmetatable({}, PlayerManager)

	self.players = {}   -- player.UserId -> player data
	self.alliances = {} -- player.UserId -> { allied userIds }
	self.remoteEvents = {}
	self.weaponService = nil

	self:setupRemoteEvents()

	return self
end

function PlayerManager:setWeaponService(weaponService)
	self.weaponService = weaponService
end

function PlayerManager:setupRemoteEvents()
	-- Use shared utility to create remote events
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"InventoryUpdate",
		"CurrencyUpdate",
		"WeaponLoadoutUpdate",
		"PlayerHealthUpdate"
	})
end

----------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------

function PlayerManager:addPlayer(player)
	if not player or not player.UserId then
		return false, "Invalid player"
	end

	if GameConfig.MAX_PLAYERS and self:getPlayerCount() >= GameConfig.MAX_PLAYERS then
		return false, "Server is full"
	end

	local startingWeapon = GameConfig.DEFAULT_WEAPON or WeaponConfig.DefaultWeapon

	self.players[player.UserId] = {
		player = player,
		health = GameConfig.STARTING_HEALTH,
		isAlive = true,

		cureComponents = {},
		lastBetrayalTime = 0,

		inventory = {},
		weapons = { [startingWeapon] = true },
		equippedWeapon = startingWeapon,

		currency = GameConfig.STARTING_CURRENCY,
		upgrades = {},
		connections = {}, -- Track connections for cleanup
		currentCharacter = nil, -- Track which character has health listeners
	}

	self.alliances[player.UserId] = {}

	local playerData = self.players[player.UserId]

	-- Initial health sync and listener setup for current character (if any)
	self:_syncHumanoidHealth(player)
	if player.Character then
		playerData.currentCharacter = player.Character
		self:_setupHealthListener(player, player.Character)
	end

	-- Setup character respawn tracking for health sync
	local characterAddedConnection = player.CharacterAdded:Connect(function(character)
		-- Re-fetch player data in case the player was removed
		local data = self.players[player.UserId]
		if not data then
			return
		end

		-- Ignore invalid/destroyed characters
		if not character or not character.Parent then
			return
		end

		-- Avoid duplicate setup for the same character instance
		if data.currentCharacter == character then
			return
		end

		data.currentCharacter = character
		self:_syncHumanoidHealth(player)
		self:_setupHealthListener(player, character)
	end)
	playerData.connections.characterAdded = characterAddedConnection
	self:sendCurrencyUpdate(player)
	self:sendInventoryUpdate(player)
	self:sendWeaponLoadout(player)
	self:sendHealthUpdate(player)

	return true, "Player added successfully"
end

function PlayerManager:removePlayer(player)
	if not player or not player.UserId then
		return
	end

	-- Disconnect all tracked connections to prevent memory leaks
	local playerData = self.players[player.UserId]
	if playerData and playerData.connections then
		for _, connection in pairs(playerData.connections) do
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end
		end
	end

	self.players[player.UserId] = nil
	self.alliances[player.UserId] = nil
end

function PlayerManager:getPlayerData(player)
	if not player or not player.UserId then
		return nil
	end
	return self.players[player.UserId]
end

function PlayerManager:GetPlayerData(player)
	return self:getPlayerData(player)
end

----------------------------------------------------------------
-- Currency
----------------------------------------------------------------

function PlayerManager:addCurrency(player, amount)
	if type(amount) ~= "number" or amount < 0 then
		warn("[PlayerManager] addCurrency called with negative or invalid amount: " .. tostring(amount))
		return false
	end
	if amount == 0 then
		return true
	end

	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end

	playerData.currency += amount
	self:sendCurrencyUpdate(player)
end

function PlayerManager:deductCurrency(player, amount)
	if type(amount) ~= "number" or amount <= 0 then
		warn("[PlayerManager] deductCurrency called with invalid amount: " .. tostring(amount))
		return false
	end

	local playerData = self.players[player.UserId]
	if not playerData or playerData.currency < amount then
		return false
	end

	playerData.currency -= amount
	self:sendCurrencyUpdate(player)
	return true
end

function PlayerManager:getCurrency(player)
	local playerData = self.players[player.UserId]
	return playerData and playerData.currency or 0
end

----------------------------------------------------------------
-- Weapons
----------------------------------------------------------------

function PlayerManager:addWeapon(player, weaponId)
	local playerData = self.players[player.UserId]
	if not playerData or not weaponId then
		return false
	end

	playerData.weapons[weaponId] = true
	self:sendWeaponLoadout(player)
	return true
end

function PlayerManager:ownsWeapon(player, weaponId)
	local playerData = self.players[player.UserId]
	if not playerData or not weaponId then
		return false
	end

	return playerData.weapons[weaponId] == true
end

function PlayerManager:equipWeapon(player, weaponId)
	local playerData = self.players[player.UserId]
	if not playerData or not self:ownsWeapon(player, weaponId) then
		return false
	end

	playerData.equippedWeapon = weaponId
	self:sendWeaponLoadout(player)
	return true
end

function PlayerManager:getEquippedWeapon(player)
	local playerData = self.players[player.UserId]
	return playerData and playerData.equippedWeapon or nil
end

function PlayerManager:getWeapons(player)
	local playerData = self.players[player.UserId]
	if not playerData then
		return {}
	end

	local list = {}
	for weaponId in pairs(playerData.weapons) do
		table.insert(list, weaponId)
	end
	table.sort(list)
	return list
end

----------------------------------------------------------------
-- Health (game health + Humanoid sync)
----------------------------------------------------------------

function PlayerManager:_setupHealthListener(player, character)
	-- Internal helper: Setup listener for external Humanoid health changes
	-- This prevents desyncs from external damage sources (e.g., WeaponService)
	if not player or not player.UserId then
		return
	end

	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Disconnect existing health listener if any
	if playerData.connections.healthChanged then
		playerData.connections.healthChanged:Disconnect()
		playerData.connections.healthChanged = nil
	end

	-- Track the last known Humanoid health to detect external changes
	-- This prevents circular updates when _syncHumanoidHealth modifies Humanoid.Health
	playerData.lastHumanoidHealth = humanoid.Health
	
	-- Flag to prevent recursion during sync operations
	playerData._syncingHumanoid = false

	-- Track Humanoid health changes and sync back to internal state
	local healthChangedConnection = humanoid.HealthChanged:Connect(function(newHealth)
		if not playerData or not player.Parent then
			-- Player left or data cleared
			return
		end
		
		-- Prevent recursion: ignore changes we made ourselves
		if playerData._syncingHumanoid then
			return
		end

		-- Calculate delta from last known Humanoid health (not internal state)
		-- This way we can distinguish external changes from our own _syncHumanoidHealth calls
		local healthDelta = newHealth - (playerData.lastHumanoidHealth or newHealth)
		playerData.lastHumanoidHealth = newHealth

		-- Ignore negligible changes (rounding differences)
		if math.abs(healthDelta) < 0.01 then
			return
		end

		if healthDelta < 0 then
			-- Health decreased (external damage taken)
			-- Update internal state to match, clamped to valid range
			playerData.health = math.max(0, math.min(GameConfig.STARTING_HEALTH, newHealth))
			
			if playerData.health <= 0 then
				playerData.isAlive = false
			end

			self:sendHealthUpdate(player)
		elseif healthDelta > 0 then
			-- Health increased (external healing)
			-- Only allow if player is alive and clamp to max
			if playerData.isAlive then
				playerData.health = math.min(GameConfig.STARTING_HEALTH, newHealth)
				self:sendHealthUpdate(player)
			else
				-- SECURITY: Dead players cannot be healed via Humanoid
				playerData._syncingHumanoid = true
				humanoid.Health = 0
				playerData.lastHumanoidHealth = 0
				playerData._syncingHumanoid = false
			end
		end
	end)

	playerData.connections.healthChanged = healthChangedConnection
end

function PlayerManager:_syncHumanoidHealth(player)
	-- Internal helper: Sync Humanoid health from internal state
	-- Makes playerData.health the authoritative source of truth
	if not player or not player.UserId then
		return
	end

	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	
	-- Set flag to prevent recursion
	playerData._syncingHumanoid = true

	-- Set MaxHealth to match config
	humanoid.MaxHealth = GameConfig.STARTING_HEALTH

	-- Sync current health from internal state
	local newHumanoidHealth
	if playerData.isAlive then
		-- SECURITY: Clamp health to valid range
		newHumanoidHealth = math.clamp(playerData.health, 0, GameConfig.STARTING_HEALTH)
	else
		-- SECURITY: Dead players stay dead
		newHumanoidHealth = 0
	end
	
	humanoid.Health = newHumanoidHealth
	
	-- Update last known Humanoid health to prevent circular updates
	-- This tells the HealthChanged listener that WE made this change
	playerData.lastHumanoidHealth = newHumanoidHealth
	
	-- Clear flag
	playerData._syncingHumanoid = false
end

function PlayerManager:damagePlayer(player, damage)
	-- Validate player parameter
	if not player or not player.UserId then
		return false
	end
	
	local playerData = self.players[player.UserId]
	if not playerData or not playerData.isAlive then
		return false
	end

	if type(damage) ~= "number" or damage <= 0 then
		return false
	end

	playerData.health = math.max(0, playerData.health - damage)

	if playerData.health <= 0 then
		playerData.isAlive = false
	end

	-- Sync Humanoid health from internal state
	self:_syncHumanoidHealth(player)
	self:sendHealthUpdate(player)

	return playerData.health <= 0
end

function PlayerManager:healPlayer(player, amount)
	local playerData = self.players[player.UserId]
	if not playerData then
		return false
	end

	if type(amount) ~= "number" or amount <= 0 then
		return false
	end

	-- Healing cannot resurrect dead players
	-- Note: Game design decision - no resurrection mechanic in this mode
	-- Players remain dead until round reset or spectator mode
	if playerData.health <= 0 or not playerData.isAlive then
		return false
	end

	-- Update internal health state
	playerData.health = math.min(GameConfig.STARTING_HEALTH, playerData.health + amount)
	
	-- Sync Humanoid health from internal state
	self:_syncHumanoidHealth(player)
	self:sendHealthUpdate(player)

	return true
end

----------------------------------------------------------------
-- Inventory
----------------------------------------------------------------

function PlayerManager:addInventoryItem(player, itemName, amount)
	local playerData = self.players[player.UserId]
	if not playerData or not itemName then
		return false
	end

	amount = amount or 1
	if amount <= 0 then
		return false
	end

	playerData.inventory[itemName] = (playerData.inventory[itemName] or 0) + amount
	self:sendInventoryUpdate(player)
	return true
end

function PlayerManager:consumeInventoryItem(player, itemName, amount)
	local playerData = self.players[player.UserId]
	if not playerData or not itemName then
		return false
	end

	amount = amount or 1
	if amount <= 0 then
		return false
	end

	local current = playerData.inventory[itemName] or 0
	if current < amount then
		return false
	end

	local newValue = current - amount
	if newValue <= 0 then
		playerData.inventory[itemName] = nil
	else
		playerData.inventory[itemName] = newValue
	end

	self:sendInventoryUpdate(player)
	return true
end

function PlayerManager:getInventory(player)
	local playerData = self.players[player.UserId]
	return playerData and playerData.inventory or {}
end

----------------------------------------------------------------
-- Cure components
----------------------------------------------------------------

function PlayerManager:addCureComponent(player, componentName)
	local playerData = self.players[player.UserId]
	if not playerData or not componentName then
		return false
	end

	playerData.cureComponents[componentName] = (playerData.cureComponents[componentName] or 0) + 1
	return true
end

function PlayerManager:removeCureComponent(player, componentName, amount)
	local playerData = self.players[player.UserId]
	if not playerData or not componentName or not amount or amount <= 0 then
		return 0
	end

	local currentCount = playerData.cureComponents[componentName] or 0
	local actualRemoved = math.min(currentCount, amount)
	
	playerData.cureComponents[componentName] = currentCount - actualRemoved
	if playerData.cureComponents[componentName] == 0 then
		playerData.cureComponents[componentName] = nil
	end
	
	return actualRemoved
end

function PlayerManager:getCureComponents(player)
	local playerData = self.players[player.UserId]
	return playerData and playerData.cureComponents or {}
end

----------------------------------------------------------------
-- Alliances
----------------------------------------------------------------

function PlayerManager:addAlliance(player1, player2)
	if not player1 or not player2 then
		return false
	end

	local userId1 = player1.UserId
	local userId2 = player2.UserId
	if not userId1 or not userId2 or userId1 == userId2 then
		return false
	end

	self.alliances[userId1] = self.alliances[userId1] or {}
	self.alliances[userId2] = self.alliances[userId2] or {}

	local function addUnique(list, id)
		for _, existing in ipairs(list) do
			if existing == id then
				return
			end
		end
		table.insert(list, id)
	end

	addUnique(self.alliances[userId1], userId2)
	addUnique(self.alliances[userId2], userId1)

	return true
end

function PlayerManager:removeAlliance(player1, player2)
	if not player1 or not player2 then
		return false
	end

	local userId1 = player1.UserId
	local userId2 = player2.UserId
	if not userId1 or not userId2 then
		return false
	end

	if self.alliances[userId1] then
		for i, allyId in ipairs(self.alliances[userId1]) do
			if allyId == userId2 then
				table.remove(self.alliances[userId1], i)
				break
			end
		end
	end

	if self.alliances[userId2] then
		for i, allyId in ipairs(self.alliances[userId2]) do
			if allyId == userId1 then
				table.remove(self.alliances[userId2], i)
				break
			end
		end
	end

	return true
end

function PlayerManager:areAllied(player1, player2)
	if not player1 or not player2 then
		return false
	end

	local userId1 = player1.UserId
	local userId2 = player2.UserId
	if not userId1 or not userId2 then
		return false
	end

	local allies = self.alliances[userId1]
	if not allies then
		return false
	end

	for _, allyId in ipairs(allies) do
		if allyId == userId2 then
			return true
		end
	end

	return false
end

----------------------------------------------------------------
-- Queries
----------------------------------------------------------------

function PlayerManager:getPlayer(userIdOrPlayer)
	-- Accept either a Player instance or a userId number
	if not userIdOrPlayer then
		return nil
	end

	local userId
	if typeof(userIdOrPlayer) == "Instance" and userIdOrPlayer:IsA("Player") then
		userId = userIdOrPlayer.UserId
	elseif type(userIdOrPlayer) == "number" then
		userId = userIdOrPlayer
	else
		return nil
	end

	return self.players[userId]
end

function PlayerManager:getPlayerCount()
	-- Count active players in self.players table
	-- Do NOT use #table as it doesn't work reliably with dictionaries
	local count = 0
	for _ in pairs(self.players) do
		count = count + 1
	end
	return count
end

function PlayerManager:getActivePlayers()
	local active = {}
	for _, playerData in pairs(self.players) do
		if playerData.isAlive then
			table.insert(active, playerData.player)
		end
	end
	return active
end

function PlayerManager:getAllPlayers()
	local all = {}
	for _, playerData in pairs(self.players) do
		table.insert(all, playerData.player)
	end
	return all
end

function PlayerManager:reset()
	-- Reset the PlayerManager state for testing
	-- Disconnect all active connections first
	for _, playerData in pairs(self.players) do
		if playerData.connections then
			for _, connection in pairs(playerData.connections) do
				if typeof(connection) == "RBXScriptConnection" then
					connection:Disconnect()
				end
			end
		end
	end

	-- Clear all state
	self.players = {}
	self.alliances = {}
end

----------------------------------------------------------------
-- Remote send helpers
----------------------------------------------------------------

function PlayerManager:sendInventoryUpdate(player)
	if self.remoteEvents.InventoryUpdate and player then
		RemoteEventUtil.safeFireClient(self.remoteEvents.InventoryUpdate, player, {
			inventory = self:getInventory(player),
		})
	end
end

function PlayerManager:sendCurrencyUpdate(player)
	if self.remoteEvents.CurrencyUpdate and player then
		RemoteEventUtil.safeFireClient(self.remoteEvents.CurrencyUpdate, player, {
			balance = self:getCurrency(player),
		})
	end
end

function PlayerManager:sendHealthUpdate(player)
	if not player or not player.UserId then
		return
	end

	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end

	if not self.remoteEvents.PlayerHealthUpdate then
		return
	end

	RemoteEventUtil.safeFireClient(self.remoteEvents.PlayerHealthUpdate, player, {
		current = playerData.health,
		max = GameConfig.STARTING_HEALTH,
	})
end

function PlayerManager:sendWeaponLoadout(player)
	if not self.remoteEvents.WeaponLoadoutUpdate or not player then
		return
	end

	local weaponStats = {}

	if self.weaponService then
		local weapons = self:getWeapons(player)
		for _, weaponId in ipairs(weapons) do
			local stats = self.weaponService:getModifiedStats(player, weaponId)
			if stats then
				weaponStats[weaponId] = stats
			else
				warn(string.format(
					"[PlayerManager] Warning: No modified stats found for player '%s' weaponId '%s'",
					player.Name or "Unknown", tostring(weaponId)
					))
			end
		end
	end

	RemoteEventUtil.safeFireClient(self.remoteEvents.WeaponLoadoutUpdate, player, {
		weapons = self:getWeapons(player),
		equipped = self:getEquippedWeapon(player),
		stats = weaponStats,
	})
end

return PlayerManager
