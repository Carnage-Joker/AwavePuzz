-- @ScriptType: Script
-- SprintService.lua
-- Server-authoritative sprint and stamina management
-- Handles sprint validation and stamina tracking
-- NOTE: WalkSpeed is now controlled client-side (FPSMovementController)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local SprintService = {}
SprintService.__index = SprintService

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
	
	-- Threshold for sending stamina updates (prevent network spam)
	self.STAMINA_UPDATE_THRESHOLD = GameConfig.STAMINA_UPDATE_THRESHOLD or 0.5

	self:setupRemoteEvents()
	self:startUpdateLoop()

	return self
end

--------------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------------

function SprintService:setupRemoteEvents()
	-- Use shared utility to create remote events
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"SprintRequest",
		"StaminaUpdate"
	})

	-- Handle sprint requests from clients
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
	}

	-- Initial push so HUD has correct numbers
	self:sendStaminaUpdate(player)
end

function SprintService:removePlayer(player)
	local userId = player.UserId
	self.sprintState[userId] = nil
	
	-- Clean up tracking tables to prevent memory leak
	if self.lastUpdateTime then
		self.lastUpdateTime[userId] = nil
	end
	if self.lastSentStamina then
		self.lastSentStamina[userId] = nil
	end
	if self.lastSentSprinting then
		self.lastSentSprinting[userId] = nil
	end
end

function SprintService:onCharacterAdded(player, _character)
	local state = self.sprintState[player.UserId]
	if not state then
		return
	end

	-- Reset sprint state on respawn
	state.isSprinting = false
	state.stamina = self.STAMINA_MAX
	state.timeSinceSprintStopped = 0

	self:sendStaminaUpdate(player)
end

--------------------------------------------------------------------------------
-- REQUEST HANDLING
--------------------------------------------------------------------------------

function SprintService:handleSprintRequest(player, wantsSprint)
	local state = self.sprintState[player.UserId]
	if not state then
		return
	end

	state.wantsSprint = wantsSprint == true
end

--------------------------------------------------------------------------------
-- MOVEMENT CHECK (SERVER-SIDE VERIFICATION)
--------------------------------------------------------------------------------

function SprintService:isPlayerMoving(player): boolean
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	return humanoid.MoveDirection.Magnitude > 0.1
end

--------------------------------------------------------------------------------
-- SPRINT / STAMINA UPDATE
--------------------------------------------------------------------------------

function SprintService:updatePlayerSprint(player, state, deltaTime)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Determine if player is allowed to sprint from the server perspective
	local canSprint = state.wantsSprint
		and state.stamina > 0
		and self:isPlayerMoving(player)

	-- State transitions
	if canSprint and not state.isSprinting then
		state.isSprinting = true
		state.timeSinceSprintStopped = 0
	elseif (not canSprint) and state.isSprinting then
		state.isSprinting = false
		state.timeSinceSprintStopped = 0
	end

	-- Stamina handling
	if state.isSprinting then
		-- Deplete stamina while sprinting
		state.stamina = math.max(0, state.stamina - self.STAMINA_DEPLETION_RATE * deltaTime)
		state.timeSinceSprintStopped = 0

		-- If stamina hits zero, force stop sprint
		if state.stamina <= 0 then
			state.isSprinting = false
			state.timeSinceSprintStopped = 0
		end
	else
		-- Regen starts after a short delay
		state.timeSinceSprintStopped += deltaTime

		if state.timeSinceSprintStopped >= self.STAMINA_REGEN_DELAY then
			state.stamina = math.min(self.STAMINA_MAX, state.stamina + self.STAMINA_REGEN_RATE * deltaTime)
		end
	end
end

--------------------------------------------------------------------------------
-- CLIENT SYNC
--------------------------------------------------------------------------------

function SprintService:sendStaminaUpdate(player)
	local state = self.sprintState[player.UserId]
	if not state then
		return
	end

	self.remoteEvents.StaminaUpdate:FireClient(player, {
		current = state.stamina,
		max = self.STAMINA_MAX,
		isSprinting = state.isSprinting,
	})
end

function SprintService:startUpdateLoop()
	-- Store tracking tables on self for cleanup in removePlayer
	self.lastUpdateTime = {}
	self.lastSentStamina = {}
	self.lastSentSprinting = {}

	RunService.Heartbeat:Connect(function(deltaTime)
		for userId, state in pairs(self.sprintState) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				self:updatePlayerSprint(player, state, deltaTime)

				-- Throttle network updates (~10x per second)
				self.lastUpdateTime[userId] = (self.lastUpdateTime[userId] or 0) + deltaTime
				
				-- Only send if enough time has passed AND (stamina changed significantly OR sprint state changed)
				local lastStamina = self.lastSentStamina[userId]
				local lastSprint = self.lastSentSprinting[userId]
				local staminaChanged = false
				local sprintChanged = false
				
				-- First update for this player: treat both stamina and sprint as changed
				if lastStamina == nil or lastSprint == nil then
					staminaChanged = true
					sprintChanged = true
				else
					staminaChanged = math.abs(lastStamina - state.stamina) > self.STAMINA_UPDATE_THRESHOLD
					sprintChanged = (lastSprint ~= state.isSprinting)
				end
				
				if self.lastUpdateTime[userId] >= 0.1 and (staminaChanged or sprintChanged) then
					self:sendStaminaUpdate(player)
					self.lastUpdateTime[userId] = 0
					self.lastSentStamina[userId] = state.stamina
					self.lastSentSprinting[userId] = state.isSprinting
				end
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
