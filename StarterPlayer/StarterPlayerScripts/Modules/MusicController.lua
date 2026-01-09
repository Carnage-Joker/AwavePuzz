-- @ScriptType: ModuleScript
-- MusicController.client.lua
-- Dynamic music system that changes based on game state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryConfig = require(SharedFolder:WaitForChild("StoryConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local MusicController = {}
MusicController.__index = MusicController

function MusicController.new()
	local self = setmetatable({}, MusicController)

	self.currentTrack = nil
	self.tracks = {}

	self:createTracks()
	self:setupRemoteEvents()

	print("[MusicController] Initialized")

	return self
end

function MusicController:createTracks()
	-- Create sound objects for each track
	local soundFolder = Instance.new("Folder")
	soundFolder.Name = "GameMusic"
	soundFolder.Parent = SoundService

	-- Create tracks from config
	local trackCount = 0
	for trackName, trackConfig in pairs(StoryConfig.Music) do
		local sound = Instance.new("Sound")
		sound.Name = trackName
		sound.SoundId = trackConfig.SoundId or ""
		sound.Volume = trackConfig.Volume or 0.5
		sound.Looped = trackConfig.Looped
		sound.Parent = soundFolder

		self.tracks[trackName] = sound
		trackCount = trackCount + 1
	end

	print("[MusicController] Created", trackCount, "music tracks")
end

function MusicController:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"GameStateUpdate",
		"WaveAnnounce"
	})

	-- Listen for game state changes
	if self.remoteEvents.GameStateUpdate then
		self.remoteEvents.GameStateUpdate.OnClientEvent:Connect(function(data)
			self:onGameStateChange(data.state)
		end)
	end

	-- Listen for wave changes for intensity
	if self.remoteEvents.WaveAnnounce then
		self.remoteEvents.WaveAnnounce.OnClientEvent:Connect(function(data)
			self:onWaveStart(data.waveNumber)
		end)
	end
end

function MusicController:onGameStateChange(state)
	print("[MusicController] Game state changed to:", state)

	-- Map game states to music tracks
	if state == "TitleScreen" then
		self:playTrack("TitleTheme", 2)
	elseif state == "Epilogue" then
		self:playTrack("TitleTheme", 2) -- Same as title for continuity
	elseif state == "WaveActive" then
		self:playTrack("GameplayAmbient", 1)
	elseif state == "Victory" then
		self:playTrack("Victory", 1)
	elseif state == "Defeat" then
		self:playTrack("Defeat", 1)
	elseif state == "Scoreboard" then
		-- Fade out current track
		self:stopAllTracks(2)
	end
end

function MusicController:onWaveStart(waveNumber)
	-- Increase intensity for higher waves
	if waveNumber >= 5 then
		self:playTrack("CombatIntense", 1)
	end
end

function MusicController:playTrack(trackName, fadeTime)
	fadeTime = fadeTime or 1

	local track = self.tracks[trackName]
	if not track then
		warn("[MusicController] Track not found:", trackName)
		return
	end

	-- If this track is already playing, do nothing
	if self.currentTrack == track and track.IsPlaying then
		return
	end

	-- Fade out current track
	if self.currentTrack and self.currentTrack.IsPlaying then
		self:fadeOutTrack(self.currentTrack, fadeTime)
	end

	-- Fade in new track
	self:fadeInTrack(track, fadeTime)
	self.currentTrack = track

	print("[MusicController] Now playing:", trackName)
end

function MusicController:fadeInTrack(track, fadeTime)
	if not track or not track.SoundId or track.SoundId == "" then
		-- No sound ID set, skip
		return
	end

	local targetVolume = track:GetAttribute("OriginalVolume") or track.Volume
	track:SetAttribute("OriginalVolume", targetVolume)

	track.Volume = 0

	-- Wrap Play() in pcall to handle potential errors with invalid sound IDs
	local success, err = pcall(function()
		track:Play()
	end)

	if not success then
		warn("[MusicController] Failed to play track:", track.Name, "Error:", err)
		return
	end

	TweenService:Create(
		track,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	):Play()
end

function MusicController:fadeOutTrack(track, fadeTime)
	if not track or not track.IsPlaying then return end

	local tween = TweenService:Create(
		track,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Volume = 0 }
	)
	tween:Play()

	tween.Completed:Connect(function()
		track:Stop()
	end)
end

function MusicController:stopAllTracks(fadeTime)
	fadeTime = fadeTime or 1

	for _, track in pairs(self.tracks) do
		if track.IsPlaying then
			self:fadeOutTrack(track, fadeTime)
		end
	end

	self.currentTrack = nil
end

function MusicController:setMasterVolume(volume)
	-- Adjust all track volumes
	for _, track in pairs(self.tracks) do
		local originalVolume = track:GetAttribute("OriginalVolume") or track.Volume
		track.Volume = originalVolume * volume
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API  
--------------------------------------------------------------------------------

local MusicModule = {}

function MusicModule.initialize()
	local musicController = MusicController.new()
	return musicController
end

function MusicModule.onCharacterAdded(character)
	-- Handle character added
end

function MusicModule.onCharacterRemoving()
	-- Cleanup
end

return MusicModule
