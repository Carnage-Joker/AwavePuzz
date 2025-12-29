--[[
	ActivityService.lua
	Manages activities, cooldowns, and rewards
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Activities = require(ReplicatedStorage.Shared.Data.Activities)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local ActivityService = {}
ActivityService.__index = ActivityService

-- References to other services
local DataService = nil
local StatsService = nil
local CurrencyService = nil

function ActivityService.new()
	local self = setmetatable({}, ActivityService)
	self.initialized = false
	return self
end

function ActivityService:initialize(dataService, statsService, currencyService)
	print("🎯 ActivityService initializing...")
	
	DataService = dataService
	StatsService = statsService
	CurrencyService = currencyService
	self.initialized = true
	
	print("✅ ActivityService initialized")
	return true
end

-- Complete an activity
function ActivityService:completeActivity(player: Player, activityId: string)
	if not DataService or not StatsService or not CurrencyService then
		return {success = false, message = "Services not ready"}
	end
	
	-- Get activity definition
	local activity = Activities.getActivity(activityId)
	if not activity then
		return {success = false, message = "Activity not found"}
	end
	
	-- Check cooldown
	local profile = DataService:getProfile(player)
	if not profile then
		return {success = false, message = "Profile not loaded"}
	end
	
	local lastCompleted = profile.activityCooldowns[activityId] or 0
	local currentTime = os.time()
	local timeSinceLastComplete = currentTime - lastCompleted
	
	if timeSinceLastComplete < activity.cooldown then
		local timeRemaining = activity.cooldown - timeSinceLastComplete
		local minutes = math.floor(timeRemaining / 60)
		local seconds = timeRemaining % 60
		return {
			success = false,
			message = string.format("Activity on cooldown: %dm %ds", minutes, seconds),
			cooldownRemaining = timeRemaining,
		}
	end
	
	-- Grant rewards
	local rewardsSummary = {}
	
	-- Stat rewards
	if activity.rewards.statRewards then
		for statName, amount in pairs(activity.rewards.statRewards) do
			StatsService:add(player, statName, amount)
			table.insert(rewardsSummary, string.format("+%d %s", amount, statName))
		end
	end
	
	-- Currency rewards
	if activity.rewards.currencyRewards then
		for currencyName, amount in pairs(activity.rewards.currencyRewards) do
			CurrencyService:addCurrency(player, currencyName, amount)
			table.insert(rewardsSummary, string.format("+%d %s", amount, currencyName))
		end
	end
	
	-- Update cooldown
	profile.activityCooldowns[activityId] = currentTime
	
	-- Send toast notification
	local toastEvent = Remotes.getEvent("PushToast")
	toastEvent:FireClient(player, {
		type = Constants.TOAST_TYPES.SUCCESS,
		title = activity.name,
		message = "Completed! " .. table.concat(rewardsSummary, ", "),
		duration = 5,
	})
	
	print(string.format("%s completed activity: %s", player.Name, activity.name))
	
	return {
		success = true,
		message = "Activity completed!",
		rewards = rewardsSummary,
	}
end

-- Get available activities (with cooldown info)
function ActivityService:getActivities(player: Player)
	local profile = DataService:getProfile(player)
	if not profile then
		return {}
	end
	
	local activitiesInfo = {}
	local currentTime = os.time()
	
	for _, activity in ipairs(Activities.list) do
		local lastCompleted = profile.activityCooldowns[activity.id] or 0
		local timeSinceLastComplete = currentTime - lastCompleted
		local isAvailable = timeSinceLastComplete >= activity.cooldown
		local cooldownRemaining = math.max(0, activity.cooldown - timeSinceLastComplete)
		
		table.insert(activitiesInfo, {
			id = activity.id,
			name = activity.name,
			description = activity.description,
			isAvailable = isAvailable,
			cooldownRemaining = cooldownRemaining,
			rewards = activity.rewards,
		})
	end
	
	return activitiesInfo
end

return ActivityService
