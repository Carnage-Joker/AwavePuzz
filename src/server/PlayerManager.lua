-- PlayerManager.lua
-- Manages player data, inventory, currency, and alliance relationships

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local WeaponConfig = require(SharedFolder:WaitForChild("WeaponConfig"))

local PlayerManager = {}
PlayerManager.__index = PlayerManager

function PlayerManager.new()
	local self = setmetatable({}, PlayerManager)
	self.players = {} -- player userId -> player data
	self.alliances = {} -- player userId -> table of allied player userIds
	self.remoteEvents = {}
	self.weaponService = nil -- Will be set after WeaponService is created
	self:setupRemoteEvents()
	return self
end

function PlayerManager:setWeaponService(weaponService)
	self.weaponService = weaponService
end

function PlayerManager:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	local inventoryEvent = remoteEventsFolder:FindFirstChild("InventoryUpdate")
	if not inventoryEvent then
		inventoryEvent = Instance.new("RemoteEvent")
		inventoryEvent.Name = "InventoryUpdate"
		inventoryEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.InventoryUpdate = inventoryEvent

	local currencyEvent = remoteEventsFolder:FindFirstChild("CurrencyUpdate")
	if not currencyEvent then
		currencyEvent = Instance.new("RemoteEvent")
		currencyEvent.Name = "CurrencyUpdate"
		currencyEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.CurrencyUpdate = currencyEvent

	local loadoutEvent = remoteEventsFolder:FindFirstChild("WeaponLoadoutUpdate")
	if not loadoutEvent then
		loadoutEvent = Instance.new("RemoteEvent")
		loadoutEvent.Name = "WeaponLoadoutUpdate"
		loadoutEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.WeaponLoadoutUpdate = loadoutEvent




	-- NEW: Player health
	local healthEvent = remoteEventsFolder:FindFirstChild("PlayerHealthUpdate")
	if not healthEvent then
		healthEvent = Instance.new("RemoteEvent")
		healthEvent.Name = "PlayerHealthUpdate"
		healthEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.PlayerHealthUpdate = healthEvent
end

function PlayerManager:addPlayer(player)
	if not player or not player.UserId then
		return false, "Invalid player"
	end

	if GameConfig.MAX_PLAYERS and #self:getAllPlayers() >= GameConfig.MAX_PLAYERS then
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
	}

	self.alliances[player.UserId] = {}

	self:sendCurrencyUpdate(player)
	self:sendInventoryUpdate(player)
	self:sendWeaponLoadout(player)
	self:sendHealthUpdate(player)  -- NEW

	return true, "Player added successfully"
end

function PlayerManager:removePlayer(player)
	if not player or not player.UserId then
		return
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

function PlayerManager:addCurrency(player, amount)
	-- Only allow non-negative amounts to be added. Use deductCurrency for deductions.
	if type(amount) ~= "number" or amount < 0 then
		warn("[PlayerManager] addCurrency called with negative or invalid amount: " .. tostring(amount))
		return
	end
	if amount == 0 then
		return
	end

	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end

	playerData.currency = playerData.currency + amount
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

	playerData.currency = playerData.currency - amount
	self:sendCurrencyUpdate(player)
	return true
end

function PlayerManager:getCurrency(player)
	local playerData = self.players[player.UserId]
	return playerData and playerData.currency or 0
end

function PlayerManager:addWeapon(player, weaponId)
	local playerData = self.players[player.UserId]
	if not playerData or not weaponId then
		return false
	end

	playerData.weapons[weaponId] = true
	self:sendWeaponLoadout(player)
	return true
end
function PlayerManager:damagePlayer(player, damage)
	local playerData = self.players[player.UserId]
	if not playerData or not playerData.isAlive then
		return false
	end

	if type(damage) ~= "number" or damage <= 0 then
		return false
	end

	playerData.health = math.max(0, playerData.health - damage)

	-- NEW: notify client
	self:sendHealthUpdate(player)

	if playerData.health <= 0 then
		playerData.isAlive = false
		return true -- Player died
	end

	return false
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
	if not playerData then
		return nil
	end
	return playerData.equippedWeapon
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
function PlayerManager:healPlayer(player, amount)
	local playerData = self.players[player.UserId]
	if not playerData or not playerData.isAlive then
		return false
	end

	if type(amount) ~= "number" or amount <= 0 then
		return false
	end

	playerData.health = math.min(GameConfig.STARTING_HEALTH, playerData.health + amount)

	-- NEW: notify client
	self:sendHealthUpdate(player)

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
	if not playerData then
		return {}
	end
	return playerData.inventory
end

function PlayerManager:sendInventoryUpdate(player)
	if self.remoteEvents.InventoryUpdate and player then
		self.remoteEvents.InventoryUpdate:FireClient(player, {
			inventory = self:getInventory(player),
		})
	end
end

function PlayerManager:sendCurrencyUpdate(player)
	if self.remoteEvents.CurrencyUpdate and player then
		self.remoteEvents.CurrencyUpdate:FireClient(player, {
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

	self.remoteEvents.PlayerHealthUpdate:FireClient(player, {
		current = playerData.health,
		max = GameConfig.STARTING_HEALTH,
	})
end

function PlayerManager:sendWeaponLoadout(player)
	if not self.remoteEvents.WeaponLoadoutUpdate or not player then
		return
	end

	local weaponStats = {}

	-- Gather stats for all owned weapons (with upgrades applied)
	if self.weaponService then
		local weapons = self:getWeapons(player)
		for _, weaponId in ipairs(weapons) do
			local stats = self.weaponService:getModifiedStats(player, weaponId)
			if stats then
				weaponStats[weaponId] = stats
			else
				warn(string.format(
					"[PlayerManager] Warning: No modified stats found for player '%s' weaponId '%s'",
					tostring(player), tostring(weaponId)
					))
			end
		end
	end

	self.remoteEvents.WeaponLoadoutUpdate:FireClient(player, {
		weapons = self:getWeapons(player),
		equipped = self:getEquippedWeapon(player),
		stats = weaponStats,
	})
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

	-- Avoid duplicate entries
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

	-- Remove player2 from player1's alliance list
	if self.alliances[userId1] then
		for i, allyId in ipairs(self.alliances[userId1]) do
			if allyId == userId2 then
				table.remove(self.alliances[userId1], i)
				break
			end
		end
	end

	-- Remove player1 from player2's alliance list
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

function PlayerManager:addCureComponent(player, componentName)
	local playerData = self.players[player.UserId]
	if not playerData or not componentName then
		return false
	end

	if not playerData.cureComponents[componentName] then
		playerData.cureComponents[componentName] = 0
	end

	playerData.cureComponents[componentName] = playerData.cureComponents[componentName] + 1
	return true
end

function PlayerManager:getCureComponents(player)
	local playerData = self.players[player.UserId]
	if not playerData then
		return {}
	end

	return playerData.cureComponents
end

return PlayerManager
