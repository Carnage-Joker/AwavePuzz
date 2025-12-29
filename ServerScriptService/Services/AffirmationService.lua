--[[
	AffirmationService.lua
	Sends random positive affirmations to players
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)

local AffirmationService = {}
AffirmationService.__index = AffirmationService

-- Safe, positive affirmations focused on self-expression and femininity
local AFFIRMATIONS = {
	"You radiate grace and confidence!",
	"Your style is a beautiful expression of who you are.",
	"Elegance comes naturally to you.",
	"You carry yourself with such poise!",
	"Your attention to detail is inspiring.",
	"You bring beauty to everything you do.",
	"Self-expression is your superpower!",
	"Your confidence shines through.",
	"You have impeccable taste!",
	"Every choice you make reflects your unique style.",
	"You are a vision of grace.",
	"Your creativity knows no bounds!",
	"You inspire others with your presence.",
	"Confidence looks wonderful on you!",
	"You have such a caring spirit.",
	"Your elegance is timeless.",
	"You make everything look effortless.",
	"You are beautiful inside and out!",
	"Your style tells your unique story.",
	"You deserve to feel confident and beautiful!",
}

-- Interval for random affirmations (seconds)
local AFFIRMATION_INTERVAL_MIN = 300  -- 5 minutes
local AFFIRMATION_INTERVAL_MAX = 600  -- 10 minutes

function AffirmationService.new()
	local self = setmetatable({}, AffirmationService)
	self.initialized = false
	self.affirmationTimers = {}  -- Player -> next affirmation time
	return self
end

function AffirmationService:initialize()
	print("💝 AffirmationService initializing...")
	
	-- Start affirmation loop
	task.spawn(function()
		while true do
			task.wait(30)  -- Check every 30 seconds
			self:checkAffirmations()
		end
	end)
	
	self.initialized = true
	print("✅ AffirmationService initialized")
	return true
end

-- Send affirmation to a player
function AffirmationService:sendAffirmation(player: Player)
	-- Pick random affirmation
	local affirmation = AFFIRMATIONS[math.random(1, #AFFIRMATIONS)]
	
	-- Send toast
	local toastEvent = Remotes.getEvent("PushToast")
	toastEvent:FireClient(player, {
		type = Constants.TOAST_TYPES.AFFIRMATION,
		title = "✨ Affirmation",
		message = affirmation,
		duration = 6,
	})
	
	print(string.format("Sent affirmation to %s: %s", player.Name, affirmation))
end

-- Check and send affirmations to players
function AffirmationService:checkAffirmations()
	local Players = game:GetService("Players")
	local currentTime = os.time()
	
	for _, player in ipairs(Players:GetPlayers()) do
		local nextTime = self.affirmationTimers[player.UserId]
		
		-- Initialize timer if not set
		if not nextTime then
			nextTime = currentTime + math.random(AFFIRMATION_INTERVAL_MIN, AFFIRMATION_INTERVAL_MAX)
			self.affirmationTimers[player.UserId] = nextTime
		end
		
		-- Send affirmation if time has come
		if currentTime >= nextTime then
			self:sendAffirmation(player)
			-- Schedule next affirmation
			self.affirmationTimers[player.UserId] = currentTime + math.random(AFFIRMATION_INTERVAL_MIN, AFFIRMATION_INTERVAL_MAX)
		end
	end
end

-- Manual trigger (can be called by other systems)
function AffirmationService:triggerAffirmation(player: Player)
	self:sendAffirmation(player)
end

return AffirmationService
