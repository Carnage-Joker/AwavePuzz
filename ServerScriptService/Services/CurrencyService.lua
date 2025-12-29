--[[
	CurrencyService.lua
	Manages player currencies (Coins, Gems)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local CurrencyService = {}
CurrencyService.__index = CurrencyService

-- Reference to DataService
local DataService = nil

function CurrencyService.new()
	local self = setmetatable({}, CurrencyService)
	self.initialized = false
	return self
end

function CurrencyService:initialize(dataService)
	print("💰 CurrencyService initializing...")
	
	DataService = dataService
	self.initialized = true
	
	print("✅ CurrencyService initialized")
	return true
end

-- Get player currency amount
function CurrencyService:getCurrency(player: Player, currencyName: string): number
	if not DataService then
		return 0
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return 0
	end
	
	return profile.currencies[currencyName] or 0
end

-- Add currency
function CurrencyService:addCurrency(player: Player, currencyName: string, amount: number)
	if not DataService then
		warn("DataService not initialized")
		return false
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return false
	end
	
	if not profile.currencies[currencyName] then
		warn(string.format("Invalid currency: %s", currencyName))
		return false
	end
	
	profile.currencies[currencyName] = profile.currencies[currencyName] + amount
	
	-- Sync to client
	self:syncCurrencies(player)
	
	print(string.format("%s gained +%d %s (Total: %d)", player.Name, amount, currencyName, profile.currencies[currencyName]))
	return true
end

-- Remove currency (returns true if successful)
function CurrencyService:removeCurrency(player: Player, currencyName: string, amount: number): boolean
	if not DataService then
		return false
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return false
	end
	
	if not profile.currencies[currencyName] then
		return false
	end
	
	-- Check if player has enough
	if profile.currencies[currencyName] < amount then
		return false
	end
	
	profile.currencies[currencyName] = profile.currencies[currencyName] - amount
	self:syncCurrencies(player)
	
	return true
end

-- Check if player can afford
function CurrencyService:canAfford(player: Player, currencyName: string, amount: number): boolean
	return self:getCurrency(player, currencyName) >= amount
end

-- Sync currencies to client
function CurrencyService:syncCurrencies(player: Player)
	local profile = DataService:getProfile(player)
	if profile then
		local syncEvent = Remotes.getEvent("SyncStats")
		syncEvent:FireClient(player, profile.stats)
	end
end

return CurrencyService
