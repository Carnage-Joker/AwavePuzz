-- @ScriptType: ModuleScript
-- FPSAnimationService.lua
-- Server-side animation replication service
-- Replicates player animations (sprint, fire, ADS) to other clients for multiplayer visibility

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[FPSAnimationService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local RemotesFolder = SharedFolder:WaitForChild("Remotes", 5)
if not RemotesFolder then
	error("[FPSAnimationService] CRITICAL: Failed to load Remotes folder after 5 seconds")
end
local RemoteRegistry = RemotesFolder:WaitForChild("RemoteRegistry", 5)
if not RemoteRegistry then
	error("[FPSAnimationService] CRITICAL: Failed to load RemoteRegistry after 5 seconds")
end
RemoteRegistry = require(RemoteRegistry)

local FPSAnimationService = {}
FPSAnimationService.__index = FPSAnimationService

function FPSAnimationService.new()
	local self = setmetatable({}, FPSAnimationService)

	-- Track player animation states
	self.playerStates = {} -- userId -> { isSprinting, isADS, lastFireTime, currentWeapon }

	self.remoteEvents = {}
	self._initialized = false
	self:setupRemoteEvents()

	return self
end

-- Initialize service (idempotent - can be called multiple times safely)
-- Does not require character, map, or remotes to exist
function FPSAnimationService:initialize()
	if self._initialized then 
		return true 
	end
	
	-- Call setup if needed (setupRemoteEvents is already called in new())
	-- This method exists to satisfy test requirements and future expansion
	self._initialized = true
	
	return true
end

function FPSAnimationService:setupRemoteEvents()
	-- Create remote events for animation replication
	local remotes = RemoteRegistry.GetServerRemotes()
	self.remoteEvents = {
		AnimationFire = remotes.AnimationFire,
		AnimationSprint = remotes.AnimationSprint,
		AnimationADS = remotes.AnimationADS,
		AnimationFireReplicate = remotes.AnimationFireReplicate,
		AnimationSprintReplicate = remotes.AnimationSprintReplicate,
		AnimationADSReplicate = remotes.AnimationADSReplicate,
	}

	-- Connect server event handlers
	self.remoteEvents.AnimationFire.OnServerEvent:Connect(function(player, weaponId)
		self:handleFire(player, weaponId)
	end)

	self.remoteEvents.AnimationSprint.OnServerEvent:Connect(function(player, isSprinting)
		self:handleSprint(player, isSprinting)
	end)

	self.remoteEvents.AnimationADS.OnServerEvent:Connect(function(player, isADS)
		self:handleADS(player, isADS)
	end)
end

function FPSAnimationService:initializePlayer(player)
	local userId = player.UserId
	self.playerStates[userId] = {
		isSprinting = false,
		isADS = false,
		lastFireTime = 0,
		currentWeapon = "Pistol", -- Default weapon
	}

	print("[FPSAnimationService] Initialized player:", player.Name)
end

function FPSAnimationService:removePlayer(player)
	local userId = player.UserId
	self.playerStates[userId] = nil

	print("[FPSAnimationService] Removed player:", player.Name)
end

--------------------------------------------------------------------------------
-- Animation State Handlers
--------------------------------------------------------------------------------

function FPSAnimationService:handleFire(player, weaponId)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local state = self.playerStates[userId]
	if not state then return end

	-- Validate weapon ID
	if not weaponId or typeof(weaponId) ~= "string" then
		weaponId = state.currentWeapon or "Pistol"
	end

	-- Update state
	state.lastFireTime = tick()
	state.currentWeapon = weaponId

	-- Replicate to all other clients
	self:replicateFire(player, weaponId)
end

function FPSAnimationService:handleSprint(player, isSprinting)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local state = self.playerStates[userId]
	if not state then return end

	-- Validate sprint state
	if typeof(isSprinting) ~= "boolean" then
		return
	end

	-- Only replicate if state changed
	if state.isSprinting == isSprinting then
		return
	end

	-- Update state
	state.isSprinting = isSprinting

	-- Replicate to all other clients
	self:replicateSprint(player, isSprinting)
end

function FPSAnimationService:handleADS(player, isADS)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local state = self.playerStates[userId]
	if not state then return end

	-- Validate ADS state
	if typeof(isADS) ~= "boolean" then
		return
	end

	-- Only replicate if state changed
	if state.isADS == isADS then
		return
	end

	-- Update state
	state.isADS = isADS

	-- Replicate to all other clients
	self:replicateADS(player, isADS)
end

--------------------------------------------------------------------------------
-- Replication Functions
--------------------------------------------------------------------------------

function FPSAnimationService:replicateFire(sourcePlayer, weaponId)
	-- Send to all players except the source player
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= sourcePlayer then
			RemoteRegistry.SafeFireClient(self.remoteEvents.AnimationFireReplicate, player, sourcePlayer, weaponId)
		end
	end
end

function FPSAnimationService:replicateSprint(sourcePlayer, isSprinting)
	-- Send to all players except the source player
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= sourcePlayer then
			RemoteRegistry.SafeFireClient(self.remoteEvents.AnimationSprintReplicate, player, sourcePlayer, isSprinting)
		end
	end
end

function FPSAnimationService:replicateADS(sourcePlayer, isADS)
	-- Send to all players except the source player
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= sourcePlayer then
			RemoteRegistry.SafeFireClient(self.remoteEvents.AnimationADSReplicate, player, sourcePlayer, isADS)
		end
	end
end

--------------------------------------------------------------------------------
-- State Queries
--------------------------------------------------------------------------------

function FPSAnimationService:getPlayerState(player)
	if not player then return nil end
	return self.playerStates[player.UserId]
end

function FPSAnimationService:isPlayerSprinting(player)
	local state = self:getPlayerState(player)
	return state and state.isSprinting or false
end

function FPSAnimationService:isPlayerADS(player)
	local state = self:getPlayerState(player)
	return state and state.isADS or false
end

function FPSAnimationService:getPlayerWeapon(player)
	local state = self:getPlayerState(player)
	return state and state.currentWeapon or "Pistol"
end

return FPSAnimationService
