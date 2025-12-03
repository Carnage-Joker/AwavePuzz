-- SprintService.lua
-- Server-authoritative sprint and stamina management
-- Handles sprint validation, stamina tracking, and walk speed control

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))

local SprintService = {}
SprintService.__index = SprintService

function SprintService.new(playerManager)
	local self = setmetatable({}, SprintService)
	
	self.playerManager = playerManager
	self.sprintState = {} -- userId -> sprint state
	self.remoteEvents = {}
	
	-- Configuration
	self.SPRINT_SPEED_MULTIPLIER = GameConfig.SPRINT_SPEED_MULTIPLIER or 1.5
	self.STAMINA_MAX = GameConfig.STAMINA_MAX or 100
	self.STAMINA_DEPLETION_RATE = GameConfig.STAMINA_DEPLETION_RATE or 20
	self.STAMINA_REGEN_RATE = GameConfig.STAMINA_REGEN_RATE or 15
	self.STAMINA_REGEN_DELAY = GameConfig.STAMINA_REGEN_DELAY or 1.0
	
	self:setupRemoteEvents()
	self:startUpdateLoop()
	
	return self
end

function SprintService:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- Client requests to start/stop sprinting
	local sprintRequestEvent = remoteEventsFolder:FindFirstChild("SprintRequest")
	if not sprintRequestEvent then
		sprintRequestEvent = Instance.new("RemoteEvent")
		sprintRequestEvent.Name = "SprintRequest"
		sprintRequestEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.SprintRequest = sprintRequestEvent
	
	-- Server sends stamina updates to client
	local staminaUpdateEvent = remoteEventsFolder:FindFirstChild("StaminaUpdate")
	if not staminaUpdateEvent then
		staminaUpdateEvent = Instance.new("RemoteEvent")
		staminaUpdateEvent.Name = "StaminaUpdate"
		staminaUpdateEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.StaminaUpdate = staminaUpdateEvent
	
	-- Handle sprint requests from clients
	sprintRequestEvent.OnServerEvent:Connect(function(player, wantsSprint)
		self:handleSprintRequest(player, wantsSprint)
	end)
end

function SprintService:initializePlayer(player)
	local userId = player.UserId
	
	self.sprintState[userId] = {
		stamina = self.STAMINA_MAX,
		isSprinting = false,
		wantsSprint = false,
		timeSinceSprintStopped = 0,
		baseWalkSpeed = 16, -- Default Roblox walk speed, will be updated on character spawn
	}
	
	-- Send initial stamina state
	self:sendStaminaUpdate(player)
end

function SprintService:removePlayer(player)
	self.sprintState[player.UserId] = nil
end

function SprintService:onCharacterAdded(player, character)
	local state = self.sprintState[player.UserId]
	if not state then
		return
	end
	
	-- Reset sprint state
	state.isSprinting = false
	state.stamina = self.STAMINA_MAX
	state.timeSinceSprintStopped = 0
	
	-- Store base walk speed immediately when character spawns
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		state.baseWalkSpeed = humanoid.WalkSpeed
	end
	
	-- Send updated state to client
	self:sendStaminaUpdate(player)
end

function SprintService:handleSprintRequest(player, wantsSprint)
	local state = self.sprintState[player.UserId]
	if not state then
		return
	end
	
	state.wantsSprint = wantsSprint == true
end

function SprintService:isPlayerMoving(player)
	local character = player.Character
	if not character then
		return false
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.MoveDirection.Magnitude > 0.1
	end
	
	return false
end

function SprintService:updatePlayerSprint(player, state, deltaTime)
	local character = player.Character
	if not character then
		return
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	
	-- Determine if player can sprint
	local canSprint = state.wantsSprint and state.stamina > 0 and self:isPlayerMoving(player)
	
	if canSprint and not state.isSprinting then
		-- Start sprinting
		state.isSprinting = true
		humanoid.WalkSpeed = state.baseWalkSpeed * self.SPRINT_SPEED_MULTIPLIER
	elseif not canSprint and state.isSprinting then
		-- Stop sprinting
		state.isSprinting = false
		humanoid.WalkSpeed = state.baseWalkSpeed
		state.timeSinceSprintStopped = 0
	end
	
	-- Update stamina
	if state.isSprinting then
		-- Deplete stamina while sprinting
		state.stamina = math.max(0, state.stamina - self.STAMINA_DEPLETION_RATE * deltaTime)
		state.timeSinceSprintStopped = 0
		
		-- Stop sprinting if stamina runs out
		if state.stamina <= 0 then
			state.isSprinting = false
			humanoid.WalkSpeed = state.baseWalkSpeed
			state.timeSinceSprintStopped = 0
		end
	else
		-- Regenerate stamina after delay
		state.timeSinceSprintStopped = state.timeSinceSprintStopped + deltaTime
		
		if state.timeSinceSprintStopped >= self.STAMINA_REGEN_DELAY then
			state.stamina = math.min(self.STAMINA_MAX, state.stamina + self.STAMINA_REGEN_RATE * deltaTime)
		end
	end
end

function SprintService:sendStaminaUpdate(player)
	local state = self.sprintState[player.UserId]
	if not state then
		return
	end
	
	self.remoteEvents.StaminaUpdate:FireClient(player, {
		current = state.stamina,
		max = self.STAMINA_MAX,
		isSprinting = state.isSprinting
	})
end

function SprintService:startUpdateLoop()
	local lastUpdateTime = {}
	
	RunService.Heartbeat:Connect(function(deltaTime)
		for userId, state in pairs(self.sprintState) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				self:updatePlayerSprint(player, state, deltaTime)
				
				-- Send stamina updates at a reasonable rate (10 times per second)
				lastUpdateTime[userId] = (lastUpdateTime[userId] or 0) + deltaTime
				if lastUpdateTime[userId] >= 0.1 then
					self:sendStaminaUpdate(player)
					lastUpdateTime[userId] = 0
				end
			end
		end
	end)
end

function SprintService:getStamina(player)
	local state = self.sprintState[player.UserId]
	if state then
		return state.stamina
	end
	return 0
end

function SprintService:isSprinting(player)
	local state = self.sprintState[player.UserId]
	if state then
		return state.isSprinting
	end
	return false
end

return SprintService
