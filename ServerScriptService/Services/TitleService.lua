--[[
	TitleService.lua
	Manages unlockable titles and title equipping
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Titles = require(ReplicatedStorage.Shared.Data.Titles)

local TitleService = {}
TitleService.__index = TitleService

-- References to other services
local DataService = nil

function TitleService.new()
	local self = setmetatable({}, TitleService)
	self.initialized = false
	return self
end

function TitleService:initialize(dataService)
	print("🏆 TitleService initializing...")
	
	DataService = dataService
	self.initialized = true
	
	print("✅ TitleService initialized")
	return true
end

-- Check and unlock titles for a player
function TitleService:checkUnlocks(player: Player)
	if not DataService then
		return {}
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return {}
	end
	
	local newlyUnlocked = {}
	
	for _, title in ipairs(Titles.list) do
		-- Skip if already unlocked
		local alreadyUnlocked = false
		for _, unlockedId in ipairs(profile.unlockedTitles) do
			if unlockedId == title.id then
				alreadyUnlocked = true
				break
			end
		end
		
		if not alreadyUnlocked then
			-- Check if requirements are met
			if Titles.checkUnlockRequirements(title, profile) then
				table.insert(profile.unlockedTitles, title.id)
				table.insert(newlyUnlocked, title)
				print(string.format("%s unlocked title: %s", player.Name, title.name))
			end
		end
	end
	
	return newlyUnlocked
end

-- Set active title
function TitleService:setTitle(player: Player, titleId: string?)
	if not DataService then
		return {success = false, message = "Service not ready"}
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return {success = false, message = "Profile not loaded"}
	end
	
	-- Allow unsetting title (nil)
	if titleId == nil then
		profile.activeTitle = nil
		return {success = true, message = "Title unequipped"}
	end
	
	-- Check if title is unlocked
	local isUnlocked = false
	for _, unlockedId in ipairs(profile.unlockedTitles) do
		if unlockedId == titleId then
			isUnlocked = true
			break
		end
	end
	
	if not isUnlocked then
		return {success = false, message = "Title not unlocked"}
	end
	
	-- Set active title
	profile.activeTitle = titleId
	
	local title = Titles.getTitle(titleId)
	return {
		success = true,
		message = string.format("Title equipped: %s", title and title.name or titleId),
	}
end

-- Get player's unlocked titles
function TitleService:getUnlockedTitles(player: Player)
	if not DataService then
		return {}
	end
	
	local profile = DataService:getProfile(player)
	if not profile then
		return {}
	end
	
	local unlockedTitles = {}
	for _, titleId in ipairs(profile.unlockedTitles) do
		local title = Titles.getTitle(titleId)
		if title then
			table.insert(unlockedTitles, title)
		end
	end
	
	return unlockedTitles
end

-- Get active title
function TitleService:getActiveTitle(player: Player)
	if not DataService then
		return nil
	end
	
	local profile = DataService:getProfile(player)
	if not profile or not profile.activeTitle then
		return nil
	end
	
	return Titles.getTitle(profile.activeTitle)
end

return TitleService
