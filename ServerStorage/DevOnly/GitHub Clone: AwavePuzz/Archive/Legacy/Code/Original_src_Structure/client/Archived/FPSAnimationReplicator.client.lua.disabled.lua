-- @ScriptType: Script
-- FPSAnimationReplicator.client.lua
-- Handles replicated animations from other players
-- Plays animations on other player characters based on server replication

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local FPSAnimationReplicator = {}

-- Track other players' animation states
local otherPlayerStates = {} -- userId -> { animations, currentWeapon, isSprinting, isADS }

--------------------------------------------------------------------------------
-- Animation Loading and Playback
--------------------------------------------------------------------------------

local function loadAnimation(character, animationType, weaponId)
	if not character then return nil end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	-- Try to get animation ID from config
	local animConfig = FPSConfig.Animations
	if not animConfig or not animConfig.WeaponAnimations then
		return nil
	end
	
	local weaponAnims = animConfig.WeaponAnimations[weaponId]
	if not weaponAnims or not weaponAnims[animationType] then
		return nil
	end
	
	local animationId = weaponAnims[animationType]
	if not animationId or animationId == "" or animationId == "rbxassetid://0" then
		return nil
	end
	
	-- Create and load animation
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	
	local animTrack = animator:LoadAnimation(animation)
	return animTrack
end

local function getOrCreatePlayerState(otherPlayer)
	local userId = otherPlayer.UserId
	if not otherPlayerStates[userId] then
		otherPlayerStates[userId] = {
			player = otherPlayer,
			animations = {},
			currentWeapon = "Pistol",
			isSprinting = false,
			isADS = false,
		}
	end
	return otherPlayerStates[userId]
end

local function cleanupPlayerState(otherPlayer)
	local userId = otherPlayer.UserId
	local state = otherPlayerStates[userId]
	if state then
		-- Stop all animations
		for _, animTrack in pairs(state.animations) do
			if animTrack then
				animTrack:Stop()
			end
		end
		otherPlayerStates[userId] = nil
	end
end

--------------------------------------------------------------------------------
-- Animation Handlers
--------------------------------------------------------------------------------

local function handleFireAnimation(otherPlayer, weaponId)
	if not otherPlayer or otherPlayer == player then return end
	if not otherPlayer.Character then return end
	
	local state = getOrCreatePlayerState(otherPlayer)
	state.currentWeapon = weaponId or "Pistol"
	
	-- Load and play fire animation
	local fireAnim = loadAnimation(otherPlayer.Character, "fire", state.currentWeapon)
	if fireAnim then
		fireAnim.Looped = false
		fireAnim.Priority = Enum.AnimationPriority.Action
		fireAnim:Play()
		
		-- Store temporarily and cleanup when done
		state.animations.fire = fireAnim
		fireAnim.Stopped:Once(function()
			if state.animations.fire == fireAnim then
				state.animations.fire = nil
			end
		end)
	end
end

local function handleSprintAnimation(otherPlayer, isSprinting)
	if not otherPlayer or otherPlayer == player then return end
	if not otherPlayer.Character then return end
	
	local state = getOrCreatePlayerState(otherPlayer)
	state.isSprinting = isSprinting
	
	-- Stop existing sprint animation
	if state.animations.sprint then
		state.animations.sprint:Stop()
		state.animations.sprint = nil
	end
	
	-- Start new sprint animation if sprinting
	if isSprinting then
		local sprintAnim = loadAnimation(otherPlayer.Character, "sprint", state.currentWeapon)
		if sprintAnim then
			sprintAnim.Looped = true
			sprintAnim.Priority = Enum.AnimationPriority.Movement
			sprintAnim:Play()
			state.animations.sprint = sprintAnim
		end
	end
end

local function handleADSAnimation(otherPlayer, isADS)
	if not otherPlayer or otherPlayer == player then return end
	if not otherPlayer.Character then return end
	
	local state = getOrCreatePlayerState(otherPlayer)
	state.isADS = isADS
	
	-- Stop existing ADS animation
	if state.animations.ads then
		state.animations.ads:Stop()
		state.animations.ads = nil
	end
	
	-- Start new ADS animation if aiming
	if isADS then
		local adsAnim = loadAnimation(otherPlayer.Character, "ads", state.currentWeapon)
		if adsAnim then
			adsAnim.Looped = true
			adsAnim.Priority = Enum.AnimationPriority.Action
			adsAnim:Play()
			state.animations.ads = adsAnim
		end
	end
end

--------------------------------------------------------------------------------
-- Remote Event Setup
--------------------------------------------------------------------------------

local function setupRemoteEvents()
	local remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"AnimationFireReplicate",
		"AnimationSprintReplicate",
		"AnimationADSReplicate",
	})
	
	-- Connect to replicated animation events
	remoteEvents.AnimationFireReplicate.OnClientEvent:Connect(function(otherPlayer, weaponId)
		handleFireAnimation(otherPlayer, weaponId)
	end)
	
	remoteEvents.AnimationSprintReplicate.OnClientEvent:Connect(function(otherPlayer, isSprinting)
		handleSprintAnimation(otherPlayer, isSprinting)
	end)
	
	remoteEvents.AnimationADSReplicate.OnClientEvent:Connect(function(otherPlayer, isADS)
		handleADSAnimation(otherPlayer, isADS)
	end)
end

--------------------------------------------------------------------------------
-- Player Character Handlers
--------------------------------------------------------------------------------

local function onPlayerAdded(otherPlayer)
	if otherPlayer == player then return end
	
	-- Handle character respawns
	otherPlayer.CharacterAdded:Connect(function(character)
		-- Wait for character to be fully loaded
		character:WaitForChild("Humanoid")
		
		-- Restore animation state if it exists
		local state = otherPlayerStates[otherPlayer.UserId]
		if state then
			if state.isSprinting then
				handleSprintAnimation(otherPlayer, true)
			end
			if state.isADS then
				handleADSAnimation(otherPlayer, true)
			end
		end
	end)
end

local function onPlayerRemoving(otherPlayer)
	cleanupPlayerState(otherPlayer)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

local function initialize()
	-- Setup remote events
	setupRemoteEvents()
	
	-- Handle existing players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			onPlayerAdded(otherPlayer)
		end
	end
	
	-- Handle new players
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	print("[FPSAnimationReplicator] Initialized")
end

initialize()

return FPSAnimationReplicator
