--[[
	ActivityController.lua
	Handles activity interactions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local ActivityController = {}
ActivityController.__index = ActivityController

-- Reference to UIController
local UIController = nil

function ActivityController.new()
	local self = setmetatable({}, ActivityController)
	self.initialized = false
	return self
end

function ActivityController:initialize(uiController)
	print("🎯 ActivityController initializing...")
	
	UIController = uiController
	
	self.initialized = true
	print("✅ ActivityController initialized")
	return true
end

-- Complete an activity
function ActivityController:completeActivity(activityId)
	local completeFunc = Remotes.getFunction("CompleteActivity")
	local success, result = pcall(function()
		return completeFunc:InvokeServer(activityId)
	end)
	
	if success and result then
		if result.success then
			print(string.format("Completed activity: %s", activityId))
			-- Show rewards
			if result.rewards then
				local rewardsText = table.concat(result.rewards, ", ")
				self:showToast("Activity Complete!", rewardsText)
			end
			return true
		else
			warn("Failed to complete activity:", result.message)
			self:showToast("Activity Unavailable", result.message)
			return false
		end
	else
		warn("Error completing activity:", result)
		return false
	end
end

-- Show toast notification
function ActivityController:showToast(title, message)
	print(string.format("[TOAST] %s: %s", title, message))
end

return ActivityController
