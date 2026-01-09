-- @ScriptType: ModuleScript
-- AchievementService.lua
-- Server-side achievement tracking and unlocking

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(SharedFolder:WaitForChild("StoryConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local AchievementService = {}
AchievementService.__index = AchievementService

function AchievementService.new(playerManager, gameManager)
	local self = setmetatable({}, AchievementService)

	self.playerManager = playerManager
	self.gameManager = gameManager

	-- Track achievements per player (userId -> {achievementId -> true})
	self.playerAchievements = {}

	-- Track stats for achievement conditions
	self.playerStats = {}

	self:setupRemoteEvents()
	self:setupEventListeners()

	print("[AchievementService] Initialized")

	return self
end

function AchievementService:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"AchievementUnlocked"
	})
end

function AchievementService:setupEventListeners()
	-- Listen for relevant game events to track achievements
	-- These would be connected to actual game events in a full implementation
	print("[AchievementService] Event listeners ready")
end

function AchievementService:initializePlayer(player)
	self.playerAchievements[player.UserId] = {}
	self.playerStats[player.UserId] = {
		kills = 0,
		headshots = 0,
		componentsCollected = 0,
		alliancesFormed = 0,
		alliancesBroken = 0,
		roundsWon = 0,
		roundsLost = 0,
		survivalTime = 0
	}

	print(string.format("[AchievementService] Initialized tracking for %s", player.Name))
end

function AchievementService:removePlayer(player)
	-- Could save achievements to DataStore here
	self.playerAchievements[player.UserId] = nil
	self.playerStats[player.UserId] = nil
end

function AchievementService:unlockAchievement(player, achievementId)
	if not player or not player.Parent then return end

	-- Check if already unlocked
	if self.playerAchievements[player.UserId] and self.playerAchievements[player.UserId][achievementId] then
		return false
	end

	-- Mark as unlocked
	if not self.playerAchievements[player.UserId] then
		self:initializePlayer(player)
	end
	self.playerAchievements[player.UserId][achievementId] = true

	-- Find achievement data for logging
	local achievementName = achievementId
	for _, ach in ipairs(StoryConfig.Achievements) do
		if ach.Id == achievementId then
			achievementName = ach.Name
			break
		end
	end

	print(string.format("[AchievementService] %s unlocked: %s", player.Name, achievementName))

	-- Notify client
	if self.remoteEvents.AchievementUnlocked then
		self.remoteEvents.AchievementUnlocked:FireClient(player, achievementId)
	end

	return true
end

function AchievementService:hasAchievement(player, achievementId)
	if not self.playerAchievements[player.UserId] then return false end
	return self.playerAchievements[player.UserId][achievementId] == true
end

-- Event handlers for tracking achievements

function AchievementService:onPlayerKill(player, isHeadshot)
	if not self.playerStats[player.UserId] then return end

	self.playerStats[player.UserId].kills = self.playerStats[player.UserId].kills + 1

	if isHeadshot then
		self.playerStats[player.UserId].headshots = self.playerStats[player.UserId].headshots + 1
	end

	-- Check achievements
	if self.playerStats[player.UserId].kills == 1 then
		self:unlockAchievement(player, "first_blood")
	end

	if self.playerStats[player.UserId].headshots >= 10 then
		self:unlockAchievement(player, "headshot_specialist")
	end
end

function AchievementService:onComponentCollected(player)
	if not self.playerStats[player.UserId] then return end

	self.playerStats[player.UserId].componentsCollected = self.playerStats[player.UserId].componentsCollected + 1

	if self.playerStats[player.UserId].componentsCollected >= 10 then
		self:unlockAchievement(player, "component_collector")
	end
end

function AchievementService:onAllianceFormed(player)
	if not self.playerStats[player.UserId] then return end

	self.playerStats[player.UserId].alliancesFormed = self.playerStats[player.UserId].alliancesFormed + 1
end

function AchievementService:onAllianceBroken(player)
	if not self.playerStats[player.UserId] then return end

	self.playerStats[player.UserId].alliancesBroken = self.playerStats[player.UserId].alliancesBroken + 1

	-- Check betrayer achievement
	self:unlockAchievement(player, "betrayer")
end

function AchievementService:onPlayerBecameLastAlive(player)
	self:unlockAchievement(player, "last_stand")
end

function AchievementService:onRoundEnd(isVictory, alivePlayers, baseHealthPercent)
	-- Trigger achievements for all players
	for _, player in ipairs(Players:GetPlayers()) do
		if not self.playerStats[player.UserId] then
			-- Skip players without stats initialized
		else
			-- Check achievements based on round outcome
			if isVictory then
				self.playerStats[player.UserId].roundsWon = self.playerStats[player.UserId].roundsWon + 1

				-- Check if player helped complete the cure
				local isAlive = false
				for _, alivePlayer in ipairs(alivePlayers) do
					if alivePlayer == player then
						isAlive = true
						break
					end
				end

				if isAlive then
					self:unlockAchievement(player, "savior")

					-- Check for perfect run (no deaths)
					if #alivePlayers == #Players:GetPlayers() then
						self:unlockAchievement(player, "perfect_run")
					end

					-- Check for clutch save (base health <= 10%)
					if baseHealthPercent and baseHealthPercent <= 10 then
						self:unlockAchievement(player, "clutch_save")
					end
				end

				-- Alliance-based achievements (mutually exclusive per victory)
				local alliancesFormed = self.playerStats[player.UserId].alliancesFormed
				local alliancesBroken = self.playerStats[player.UserId].alliancesBroken

				-- Check for lone wolf (no alliances formed this round)
				if alliancesFormed == 0 then
					self:unlockAchievement(player, "lone_wolf")
					-- Check for trusted ally (alliances formed, none broken)
				elseif alliancesBroken == 0 and alliancesFormed > 0 then
					self:unlockAchievement(player, "trusted_ally")
				end

				-- Check for team player (allied with everyone)
				local totalPlayers = #Players:GetPlayers()
				if alliancesFormed >= (totalPlayers - 1) and totalPlayers > 1 then
					self:unlockAchievement(player, "team_player")
				end
			else
				self.playerStats[player.UserId].roundsLost = self.playerStats[player.UserId].roundsLost + 1
			end
		end
	end
end

function AchievementService:resetRoundStats()
	-- Reset per-round stats (keep lifetime stats)
	for userId, stats in pairs(self.playerStats) do
		stats.kills = 0
		stats.headshots = 0
		stats.componentsCollected = 0
		stats.alliancesFormed = 0
		stats.alliancesBroken = 0
	end
end

return AchievementService
