-- @ScriptType: ModuleScript
-- SprintService.lua
-- Server-authoritative sprint and stamina management
-- Handles sprint validation and stamina tracking
-- WalkSpeed controlled client-side (FPSMovement)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[SprintService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local FPSConfig = SharedFolder:WaitForChild("FPSConfig", 5)
if not FPSConfig then
	error("[SprintService] CRITICAL: Failed to load FPSConfig after 5 seconds")
end
FPSConfig = require(FPSConfig)

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[SprintService] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local RemoteEventUtil = SharedFolder:WaitForChild("RemoteEventUtil", 5)
if not RemoteEventUtil then
	error("[SprintService] CRITICAL: Failed to load RemoteEventUtil after 5 seconds")
end
RemoteEventUtil = require(RemoteEventUtil)

local SprintService = {}
SprintService.__index = SprintService

-- Networking tuning (safe defaults)
local NET_SEND_HZ = 5                -- 5 updates/sec typical HUD rate
local NET_SEND_INTERVAL = 1 / NET_SEND_HZ
local STAMINA_EPSILON = 0.25         -- minimum change before we bother sending

function SprintService.new(playerManager)
	local self = setmetatable({}, SprintService)

	self.playerManager = playerManager
	self.sprintState = {}       -- [userId] = state table
	self.remoteEvents = {}

	-- Use FPSConfig as source of truth, fall back to GameConfig if needed
	local moveCfg = FPSConfig.Movement or {}

	self.STAMINA_MAX = moveCfg.StaminaMax
		or GameConfig.STAMINA_MAX
		or 100

	self.STAMINA_DEPLETION_RATE = moveCfg.SprintStaminaDrain
		or GameConfig.STAMINA_DEPLETION_RATE
		or 20

	self.STAMINA_REGEN_RATE = moveCfg.StaminaRegenRate
		or GameConfig.STAMINA_REGEN_RATE
		or 15

	self.STAMINA_REGEN_DELAY = GameConfig.STAMINA_REGEN_DELAY or 1.0

	self:setupRemoteEvents()
	self:startUpdateLoop()

	return self
end

--------------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------------

function SprintService:setupRemoteEvents()
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"SprintRequest",
		"StaminaUpdate"
	})

	self.remoteEvents.SprintRequest.OnServerEvent:Connect(function(player, wantsSprint)
		self:handleSprintRequest(player, wantsSprint)
	end)
end

--------------------------------------------------------------------------------
-- PLAYER STATE
--------------------------------------------------------------------------------

function SprintService:initializePlayer(player)
	local userId = player.UserId

	self.sprintState[userId] = {
		stamina = self.STAMINA_MAX,
		isSprinting = false,
		wantsSprint = false,
		timeSinceSprintStopped = 0,

		-- net sync
		_lastSentAt = 0,
		_lastSentStamina = nil,
		_lastSentSprint = nil,
	}

	self:sendStaminaUpdate(player, true)
end

function SprintService:removePlayer(player)
	self.sprintState[player.UserId] = nil
end

function SprintService:onCharacterAdded(player, _character)
	local state = self.sprintState[player.UserId]
	if not state then return end

	state.isSprinting = false
	state.wantsSprint = false
	state.stamina = self.STAMINA_MAX
	state.timeSinceSprintStopped = 0

	-- force send after respawn
	state._lastSentAt = 0
	state._lastSentStamina = nil
	state._lastSentSprint = nil

	self:sendStaminaUpdate(player, true)
end

--------------------------------------------------------------------------------
-- REQUEST HANDLING
--------------------------------------------------------------------------------

function SprintService:handleSprintRequest(player, wantsSprint)
	local state = self.sprintState[player.UserId]
	if not state then return end

	state.wantsSprint = wantsSprint == true
	-- optional: immediate send so HUD feels responsive when toggling sprint
	self:sendStaminaUpdate(player, true)
end

--------------------------------------------------------------------------------
-- MOVEMENT CHECK (SERVER VERIFICATION)
--------------------------------------------------------------------------------

function SprintService:isPlayerMoving(player): boolean
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	return humanoid.MoveDirection.Magnitude > 0.1
end

--------------------------------------------------------------------------------
-- SPRINT / STAMINA UPDATE
--------------------------------------------------------------------------------

function SprintService:updatePlayerSprint(player, state, deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local canSprint =
		state.wantsSprint
		and state.stamina > 0
		and self:isPlayerMoving(player)

	local prevSprinting = state.isSprinting

	-- state transitions
	if canSprint and not state.isSprinting then
		state.isSprinting = true
		state.timeSinceSprintStopped = 0
	elseif (not canSprint) and state.isSprinting then
		state.isSprinting = false
		state.timeSinceSprintStopped = 0
	end

	-- stamina handling
	if state.isSprinting then
		state.stamina = math.max(0, state.stamina - self.STAMINA_DEPLETION_RATE * deltaTime)
		state.timeSinceSprintStopped = 0

		if state.stamina <= 0 then
			state.isSprinting = false
			state.timeSinceSprintStopped = 0
		end
	else
		state.timeSinceSprintStopped += deltaTime
		if state.timeSinceSprintStopped >= self.STAMINA_REGEN_DELAY then
			state.stamina = math.min(self.STAMINA_MAX, state.stamina + self.STAMINA_REGEN_RATE * deltaTime)
		end
	end

	-- If sprinting state changed, push immediately
	if prevSprinting ~= state.isSprinting then
		self:sendStaminaUpdate(player, true)
	end
end

--------------------------------------------------------------------------------
-- CLIENT SYNC
--------------------------------------------------------------------------------

function SprintService:sendStaminaUpdate(player, force: boolean?)
	local state = self.sprintState[player.UserId]
	if not state then return end

	local now = os.clock()

	-- throttle by time
	if not force then
		if (now - (state._lastSentAt or 0)) < NET_SEND_INTERVAL then
			return
		end
	end

	local currentStamina = state.stamina
	local isSprinting = state.isSprinting

	-- throttle by change (avoid spam)
	if not force then
		local lastStam = state._lastSentStamina
		local lastSprint = state._lastSentSprint

		local staminaChanged = (lastStam == nil) or (math.abs(currentStamina - lastStam) >= STAMINA_EPSILON)
		local sprintChanged = (lastSprint == nil) or (isSprinting ~= lastSprint)

		if not staminaChanged and not sprintChanged then
			return
		end
	end

	state._lastSentAt = now
	state._lastSentStamina = currentStamina
	state._lastSentSprint = isSprinting

	self.remoteEvents.StaminaUpdate:FireClient(player, {
		current = currentStamina,
		max = self.STAMINA_MAX,
		isSprinting = isSprinting,
	})
end

function SprintService:startUpdateLoop()
	RunService.Heartbeat:Connect(function(deltaTime)
		for userId, state in pairs(self.sprintState) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				self:updatePlayerSprint(player, state, deltaTime)
				self:sendStaminaUpdate(player, false)
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- QUERY API
--------------------------------------------------------------------------------

function SprintService:getStamina(player)
	local state = self.sprintState[player.UserId]
	return state and state.stamina or 0
end

function SprintService:isSprinting(player)
	local state = self.sprintState[player.UserId]
	return state and state.isSprinting or false
end

return SprintService
