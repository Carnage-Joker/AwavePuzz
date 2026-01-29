-- @ScriptType: ModuleScript
-- FPSAudioController.client.lua
-- Handles all FPS-related audio: gunfire, reload, footsteps, hitmarkers, etc.
-- Provides placeholder system for sounds with clear documentation for asset IDs

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local AssetValidation = require(SharedFolder:WaitForChild("AssetValidation"))

--------------------------------------------------------------------------------
-- SOUND CONFIGURATION
-- Replace these placeholder IDs with actual Roblox sound asset IDs
-- Format: "rbxassetid://XXXXXXXX" where XXXXXXXX is the asset ID
--------------------------------------------------------------------------------

local SoundAssets = {
	-- Weapon sounds (per weapon type)
	WeaponFire = {
		Pistol = "rbxassetid://1905367471", -- Replace with pistol fire sound
		SMG = "rbxassetid://77130830495173",    -- Replace with SMG fire sound
		Shotgun = "rbxassetid://8429881678", -- Replace with shotgun fire sound
		Rifle = "rbxassetid://6862108495",  -- Replace with rifle fire sound
		Default = "rbxassetid://1905367471", -- Default fire sound
	},

	WeaponReload = {
		Pistol = "rbxassetid://138084889",
		SMG = "rbxassetid://138084889",
		Shotgun = "rbxassetid://86072977471971",
		Rifle = "rbxassetid://138084889",
		Default = "rbxassetid://138084889",
	},

	-- UI/Feedback sounds
	EmptyClick = "rbxassetid://96880586397913",     -- Click when trying to fire with no ammo
	HeadshotHitmarker = "rbxassetid://131472999032031",      -- Headshot hitmarker sound
	Hitmarker = "rbxassetid://79356893392985", -- Standard hitmarker (different pitch/sound)
	KillConfirm = "rbxassetid://86596819653473",    -- Kill confirmation sound

	-- Movement sounds
	Footsteps = {
		Concrete = "rbxassetid://127328919401626",
		Grass = "rbxassetid://126726565555894",
		Metal = "rbxassetid://127328919401626",
		Wood = "rbxassetid://128186716150447",
		Default = "rbxassetid://127328919401626",
	},

	-- Damage feedback
	DamageTaken = "rbxassetid://106256862427202",    -- Sound when player takes damage
	LowHealthHeartbeat = "rbxassetid://120008174551190", -- Heartbeat when low HP

	-- UI sounds
	MenuSelect = "rbxassetid://104003605923230",
	MenuNavigate = "rbxassetid://9055474333",
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local FPSAudioController = {}

-- Volume settings (0-1)
local volumes = {
	master = FPSConfig.Audio.MasterVolume,
	sfx = FPSConfig.Audio.SFXVolume,
	music = FPSConfig.Audio.MusicVolume,
}

-- Active sounds for management
local activeSounds = {}
local heartbeatSound = nil
local isLowHealth = false

-- Footstep state
local lastFootstepTime = 0
local footstepInterval = 0.4 -- seconds between footsteps

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

local function calculateVolume(baseVolume, category)
	category = category or "sfx"
	local categoryVolume = volumes[category] or 1
	return baseVolume * categoryVolume * volumes.master
end

local function createSound(soundId, parent, properties)
	-- Validate sound ID format
	if not soundId or soundId == "" or soundId == "rbxassetid://0" then
		return nil
	end
	
	-- Extract asset ID and validate it's not suspiciously long (typical IDs are 9-13 digits)
	local assetIdStr = soundId:match("rbxassetid://(%d+)")
	if assetIdStr and #assetIdStr > 13 then
		warn("[FPSAudioController] Skipping invalid sound ID (too long): " .. soundId)
		return nil
	end
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = properties.Volume or 0.5
	sound.PlaybackSpeed = properties.PlaybackSpeed or 1
	sound.Looped = properties.Looped or false
	sound.RollOffMode = properties.RollOffMode or Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = properties.RollOffMaxDistance or 100
	sound.Parent = parent or SoundService

	return sound
end

local function playSound(soundId, properties, cleanup)
	if not soundId or soundId == "rbxassetid://0" then
		-- Placeholder sound - don't play
		return nil
	end

	properties = properties or {}
	local volume = calculateVolume(properties.Volume or 0.5, properties.Category or "sfx")
	properties.Volume = volume

	local parent = properties.Parent or SoundService
	
	-- Wrap sound creation in pcall to catch invalid asset IDs
	local success, sound = pcall(function()
		return createSound(soundId, parent, properties)
	end)
	
	if not success or not sound then
		warn("[FPSAudioController] Failed to create sound: " .. tostring(soundId))
		return nil
	end

	-- Wrap Play in pcall to catch asset loading errors
	local playSuccess = pcall(function()
		sound:Play()
	end)
	
	if not playSuccess then
		warn("[FPSAudioController] Failed to play sound: " .. tostring(soundId))
		sound:Destroy()
		return nil
	end

	-- Auto cleanup
	if cleanup ~= false then
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end

	return sound
end

local function playSoundAtPosition(soundId, position, properties)
	if not soundId or soundId == "rbxassetid://0" then
		return nil
	end

	properties = properties or {}

	-- Create a temporary part for 3D sound
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
	soundPart.Position = position
	soundPart.Parent = workspace

	local sound = playSound(soundId, {
		Volume = properties.Volume or 0.5,
		Category = properties.Category or "sfx",
		Parent = soundPart,
		RollOffMode = Enum.RollOffMode.Linear,
		RollOffMaxDistance = properties.MaxDistance or 100,
	}, false)

	if sound then
		sound.Ended:Connect(function()
			sound:Destroy()
			soundPart:Destroy()
		end)
	else
		soundPart:Destroy()
	end

	return sound
end

--------------------------------------------------------------------------------
-- WEAPON SOUNDS
--------------------------------------------------------------------------------

function FPSAudioController.playFireSound(weaponId)
	if not FPSConfig.Audio.FireSoundEnabled then return end

	local soundId = SoundAssets.WeaponFire[weaponId] or SoundAssets.WeaponFire.Default

	playSound(soundId, {
		Volume = 0.7,
		Category = "sfx",
		PlaybackSpeed = 0.95 + math.random() * 0.1, -- Slight variation
	})
end

function FPSAudioController.playReloadSound(weaponId)
	if not FPSConfig.Audio.ReloadSoundEnabled then return end

	local soundId = SoundAssets.WeaponReload[weaponId] or SoundAssets.WeaponReload.Default

	playSound(soundId, {
		Volume = 0.6,
		Category = "sfx",
	})
end

function FPSAudioController.playEmptyClick()
	if not FPSConfig.Audio.EmptyClickEnabled then return end

	playSound(SoundAssets.EmptyClick, {
		Volume = 0.4,
		Category = "sfx",
	})
end

--------------------------------------------------------------------------------
-- HITMARKER SOUNDS
--------------------------------------------------------------------------------

function FPSAudioController.playHitmarkerSound(isHeadshot, isKill)
	if not FPSConfig.Audio.HitmarkerSoundEnabled then return end

	local soundId = SoundAssets.Hitmarker
	local volume = 0.5

	if isKill then
		soundId = SoundAssets.KillConfirm
		volume = 0.6
	elseif isHeadshot and FPSConfig.Audio.HeadshotSoundEnabled then
		soundId = SoundAssets.HeadshotHitmarker
		volume = 0.55
	end

	playSound(soundId, {
		Volume = volume,
		Category = "sfx",
	})
end

--------------------------------------------------------------------------------
-- FOOTSTEP SOUNDS
--------------------------------------------------------------------------------

function FPSAudioController.playFootstep(material)
	if not FPSConfig.Audio.FootstepsEnabled then return end

	local currentTime = tick()
	if currentTime - lastFootstepTime < footstepInterval then
		return
	end
	lastFootstepTime = currentTime

	-- Determine sound based on material
	local soundId = SoundAssets.Footsteps.Default

	if material then
		local materialName = material.Name
		if materialName == Enum.Material.Concrete.Name or materialName == "Concrete" then
			soundId = SoundAssets.Footsteps.Concrete
		elseif materialName == Enum.Material.Grass.Name or materialName == "Grass" then
			soundId = SoundAssets.Footsteps.Grass
		elseif materialName == Enum.Material.Metal.Name or materialName == "Metal" then
			soundId = SoundAssets.Footsteps.Metal
		elseif materialName == Enum.Material.Wood.Name or materialName == "Wood" then
			soundId = SoundAssets.Footsteps.Wood
		end
	end

	playSound(soundId, {
		Volume = FPSConfig.Audio.FootstepVolume,
		Category = "sfx",
		PlaybackSpeed = 0.9 + math.random() * 0.2, -- Variation
	})
end

-- Automatic footstep detection
local function updateFootsteps()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if moving
	if humanoid.MoveDirection.Magnitude > 0.1 then
		-- Get floor material
		local material = humanoid.FloorMaterial
		if material ~= Enum.Material.Air then
			-- Adjust interval based on speed
			local speed = humanoid.WalkSpeed
			footstepInterval = 0.5 - (speed / 100) -- Faster steps at higher speeds
			footstepInterval = math.clamp(footstepInterval, 0.2, 0.6)

			FPSAudioController.playFootstep(material)
		end
	end
end

--------------------------------------------------------------------------------
-- DAMAGE FEEDBACK SOUNDS
--------------------------------------------------------------------------------

function FPSAudioController.playDamageSound()
	playSound(SoundAssets.DamageTaken, {
		Volume = 0.6,
		Category = "sfx",
	})
end

function FPSAudioController.setLowHealth(lowHealth)
	if not FPSConfig.Audio.LowHealthHeartbeat then return end

	if lowHealth and not isLowHealth then
		-- Start heartbeat
		isLowHealth = true
		if heartbeatSound then
			heartbeatSound:Destroy()
		end

		heartbeatSound = createSound(SoundAssets.LowHealthHeartbeat, SoundService, {
			Volume = calculateVolume(0.4, "sfx"),
			Looped = true,
		})
																																																																																																																																																																																																				heartbeatSound:Play()

	elseif not lowHealth and isLowHealth then
		-- Stop heartbeat
		isLowHealth = false
		if heartbeatSound then
			heartbeatSound:Stop()
			heartbeatSound:Destroy()
			heartbeatSound = nil
		end
	end
end

-- Cleanup heartbeat sound on character death/respawn
local function cleanupHeartbeatSound()
	if heartbeatSound then
		heartbeatSound:Stop()
		heartbeatSound:Destroy()
		heartbeatSound = nil
		isLowHealth = false
	end
end

-- Connect to character events for cleanup
local function onCharacterAdded(character)
	cleanupHeartbeatSound()
end

local function onCharacterRemoving(character)
	cleanupHeartbeatSound()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)
--------------------------------------------------------------------------------
-- UI SOUNDS
--------------------------------------------------------------------------------

function FPSAudioController.playMenuSelect()
	playSound(SoundAssets.MenuSelect, {
		Volume = 0.3,
		Category = "sfx",
	})
end

function FPSAudioController.playMenuNavigate()
	playSound(SoundAssets.MenuNavigate, {
		Volume = 0.2,
		Category = "sfx",
	})
end

--------------------------------------------------------------------------------
-- VOLUME CONTROL
--------------------------------------------------------------------------------

function FPSAudioController.setMasterVolume(volume)
	volumes.master = math.clamp(volume, 0, 1)
end

function FPSAudioController.setSFXVolume(volume)
	volumes.sfx = math.clamp(volume, 0, 1)
end

function FPSAudioController.setMusicVolume(volume)
	volumes.music = math.clamp(volume, 0, 1)
end

function FPSAudioController.getVolumes()
	return {
		master = volumes.master,
		sfx = volumes.sfx,
		music = volumes.music,
	}
end

--------------------------------------------------------------------------------
-- BINDABLE EVENT CONNECTIONS
--------------------------------------------------------------------------------

local function setupBindableConnections()
	local bindableFolder = playerGui:WaitForChild("BindableEvents", 10)
	if not bindableFolder then return end

	-- Weapon fired
	local weaponFiredEvent = bindableFolder:FindFirstChild("WeaponFired")
	if weaponFiredEvent then
		weaponFiredEvent.Event:Connect(function(data)
			if typeof(data) == "table" then
				FPSAudioController.playFireSound(data.weaponId)
			end
		end)
	end

	-- Reload
	local reloadStartedEvent = bindableFolder:FindFirstChild("ReloadStarted")
	if reloadStartedEvent then
		reloadStartedEvent.Event:Connect(function(data)
			if typeof(data) == "table" then
				FPSAudioController.playReloadSound(data.weaponId)
			end
		end)
	end

	-- Empty click
	local emptyClickEvent = bindableFolder:FindFirstChild("EmptyClick")
	if emptyClickEvent then
		emptyClickEvent.Event:Connect(function()
			FPSAudioController.playEmptyClick()
		end)
	end

	-- Hitmarker
	local hitmarkerEvent = bindableFolder:FindFirstChild("Hitmarker")
	if hitmarkerEvent then
		hitmarkerEvent.Event:Connect(function(data)
			if typeof(data) == "table" then
				FPSAudioController.playHitmarkerSound(data.isHeadshot, data.isKill)
			end
		end)
	end

	-- Damage taken
	local damageTakenEvent = bindableFolder:FindFirstChild("DamageTaken")
	if damageTakenEvent then
		damageTakenEvent.Event:Connect(function()
			FPSAudioController.playDamageSound()
		end)
	end

	-- Settings changed
	local settingsEvent = bindableFolder:FindFirstChild("SettingsChanged")
	if settingsEvent then
		settingsEvent.Event:Connect(function(data)
			if typeof(data) == "table" then
				if data.masterVolume then
					FPSAudioController.setMasterVolume(data.masterVolume)
				end
				if data.sfxVolume then
					FPSAudioController.setSFXVolume(data.sfxVolume)
				end
				if data.musicVolume then
					FPSAudioController.setMusicVolume(data.musicVolume)
				end
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- HEALTH MONITORING
--------------------------------------------------------------------------------

local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local healthEvent = remoteEventsFolder:FindFirstChild("PlayerHealthUpdate")
if healthEvent then
	healthEvent.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" then
			local healthPercent = ((data.current or 100) / (data.max or 100)) * 100
			local isLow = healthPercent <= FPSConfig.HUD.LowHealthThreshold
			FPSAudioController.setLowHealth(isLow)
		end
	end)
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(deltaTime)
	updateFootsteps()
end)

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initialize()
	-- Validate sound assets at boot time
	print("[FPSAudioController] Validating sound assets...")
	AssetValidation.validateSoundAssets(SoundAssets, "FPSAudio")
	
	-- Wait for BindableEvents folder to be created by other scripts
	task.spawn(function()
		task.wait(1)
		setupBindableConnections()
	end)

	print("[FPSAudioController] Initialized")
	print("[FPSAudioController] NOTE: Replace placeholder sound IDs in SoundAssets table")
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

local FPSAudioModule = {}

function FPSAudioModule.initialize()
	initialize()
end

function FPSAudioModule.onCharacterAdded(character)
	-- Handle character added
end

function FPSAudioModule.onCharacterRemoving()
	-- Cleanup
end

return FPSAudioModule
