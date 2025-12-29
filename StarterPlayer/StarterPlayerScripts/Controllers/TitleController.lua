--[[
	TitleController.lua
	Handles title interactions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local TitleController = {}
TitleController.__index = TitleController

-- Reference to UIController
local UIController = nil

function TitleController.new()
	local self = setmetatable({}, TitleController)
	self.initialized = false
	return self
end

function TitleController:initialize(uiController)
	print("🏆 TitleController initializing...")
	
	UIController = uiController
	
	self.initialized = true
	print("✅ TitleController initialized")
	return true
end

-- Set active title
function TitleController:setTitle(titleId)
	local setTitleFunc = Remotes.getFunction("SetTitle")
	local success, result = pcall(function()
		return setTitleFunc:InvokeServer(titleId)
	end)
	
	if success and result then
		if result.success then
			print(string.format("Title set: %s", titleId or "none"))
			self:showToast("Title Equipped", result.message)
			return true
		else
			warn("Failed to set title:", result.message)
			self:showToast("Error", result.message)
			return false
		end
	else
		warn("Error setting title:", result)
		return false
	end
end

-- Show toast notification
function TitleController:showToast(title, message)
	print(string.format("[TOAST] %s: %s", title, message))
end

return TitleController
