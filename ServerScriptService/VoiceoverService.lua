-- @ScriptType: ModuleScript
-- VoiceoverService.lua
-- Server-side voiceover audio management
-- Triggers voiceover playback on clients for story moments and game events
-- Note: Audio assets not yet created - system ready for integration when assets are available

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[VoiceoverService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local StoryConfig = SharedFolder:WaitForChild("StoryConfig", 5)
if not StoryConfig then
	error("[VoiceoverService] CRITICAL: Failed to load StoryConfig after 5 seconds")
end
StoryConfig = require(StoryConfig)

local RemoteEventUtil = SharedFolder:WaitForChild("RemoteEventUtil", 5)
if not RemoteEventUtil then
	error("[VoiceoverService] CRITICAL: Failed to load RemoteEventUtil after 5 seconds")
end
RemoteEventUtil = require(RemoteEventUtil)

local VoiceoverService = {}
VoiceoverService.__index = VoiceoverService

function VoiceoverService.new()
	local self = setmetatable({}, VoiceoverService)
	
	-- Track which voiceovers have been played this session (to prevent repeats)
	self.playedVoiceovers = {}
	
	self:setupRemoteEvents()
	
	print("[VoiceoverService] Initialized (audio assets pending)")
	
	return self
end

function VoiceoverService:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"PlayVoiceover",  -- Server -> Client: Play a voiceover
		"StopVoiceover"   -- Server -> Client: Stop current voiceover
	})
end

-- Play a voiceover for a specific player
function VoiceoverService:playVoiceoverForPlayer(player, voiceoverId, voiceoverData)
	if not player or not player:IsDescendantOf(game) then
		return
	end
	
	-- Validate voiceover data
	if not voiceoverData then
		warn("[VoiceoverService] No voiceover data for ID:", voiceoverId)
		return
	end
	
	-- Send to client
	if self.remoteEvents.PlayVoiceover then
		self.remoteEvents.PlayVoiceover:FireClient(player, {
			id = voiceoverId,
			soundId = voiceoverData.SoundId or "",
			text = voiceoverData.Text or "",
			style = voiceoverData.VoiceoverStyle or "System",
			duration = voiceoverData.Duration or 5
		})
		
		print("[VoiceoverService] Sent voiceover to", player.Name, ":", voiceoverId)
	end
end

-- Play a voiceover for all players
function VoiceoverService:playVoiceoverForAll(voiceoverId, voiceoverData)
	-- Validate voiceover data
	if not voiceoverData then
		warn("[VoiceoverService] No voiceover data for ID:", voiceoverId)
		return
	end
	
	-- Check if already played
	if self.playedVoiceovers[voiceoverId] then
		print("[VoiceoverService] Voiceover already played this session:", voiceoverId)
		return
	end
	
	-- Mark as played
	self.playedVoiceovers[voiceoverId] = true
	
	-- Broadcast to all clients
	if self.remoteEvents.PlayVoiceover then
		self.remoteEvents.PlayVoiceover:FireAllClients({
			id = voiceoverId,
			soundId = voiceoverData.SoundId or "",
			text = voiceoverData.Text or "",
			style = voiceoverData.VoiceoverStyle or "System",
			duration = voiceoverData.Duration or 5
		})
		
		print("[VoiceoverService] Broadcast voiceover to all players:", voiceoverId)
	end
end

-- Play epilogue voiceover for a player
function VoiceoverService:playEpilogueVoiceover(player, epilogueEntry)
	if not epilogueEntry then
		return
	end
	
	-- Build voiceover data from epilogue entry
	local voiceoverData = {
		SoundId = "",  -- Placeholder - audio assets not yet created
		Text = epilogueEntry.text or "",
		VoiceoverStyle = epilogueEntry.VoiceoverStyle or "System",
		Duration = #(epilogueEntry.text or "") / 20  -- Rough estimate: 20 characters per second
	}
	
	self:playVoiceoverForPlayer(player, "epilogue_" .. (epilogueEntry.timestamp or ""), voiceoverData)
end

-- Play wave start voiceover
function VoiceoverService:playWaveStartVoiceover(waveNumber)
	local voiceoverData = {
		SoundId = "",  -- Placeholder
		Text = string.format("Wave %d incoming. All personnel to defensive positions.", waveNumber),
		VoiceoverStyle = "Warning",
		Duration = 3
	}
	
	self:playVoiceoverForAll("wave_start_" .. waveNumber, voiceoverData)
end

-- Play synthesis start voiceover
function VoiceoverService:playSynthesisStartVoiceover()
	local voiceoverData = {
		SoundId = "",  -- Placeholder
		Text = "Cure synthesis initiated. Warning: Increased hostile activity detected.",
		VoiceoverStyle = "Warning",
		Duration = 4
	}
	
	self:playVoiceoverForAll("synthesis_start", voiceoverData)
end

-- Play victory voiceover
function VoiceoverService:playVictoryVoiceover()
	local voiceoverData = {
		SoundId = "",  -- Placeholder
		Text = "Cure synthesis complete. Outbreak contained. All personnel: well done.",
		VoiceoverStyle = "System",
		Duration = 5
	}
	
	self:playVoiceoverForAll("victory", voiceoverData)
end

-- Play defeat voiceover
function VoiceoverService:playDefeatVoiceover()
	local voiceoverData = {
		SoundId = "",  -- Placeholder
		Text = "Base defenses compromised. Evacuation protocols initiated. This is not a drill.",
		VoiceoverStyle = "Warning",
		Duration = 5
	}
	
	self:playVoiceoverForAll("defeat", voiceoverData)
end

-- Stop all voiceovers for a player
function VoiceoverService:stopVoiceoverForPlayer(player)
	if not player or not player:IsDescendantOf(game) then
		return
	end
	
	if self.remoteEvents.StopVoiceover then
		self.remoteEvents.StopVoiceover:FireClient(player)
	end
end

-- Stop all voiceovers for all players
function VoiceoverService:stopVoiceoverForAll()
	if self.remoteEvents.StopVoiceover then
		self.remoteEvents.StopVoiceover:FireAllClients()
	end
end

-- Reset played voiceovers (for new round)
function VoiceoverService:reset()
	self.playedVoiceovers = {}
	print("[VoiceoverService] Reset played voiceovers")
end

return VoiceoverService
