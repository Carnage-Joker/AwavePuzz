-- SpectatorManager.lua
-- Manages spectator mode for players who have died during a round
-- Dead players can spectate other living players until round ends

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))

local SpectatorManager = {}
SpectatorManager.__index = SpectatorManager

function SpectatorManager.new()
	local self = setmetatable({}, SpectatorManager)

	-- Track spectating players and their targets
	self.spectators = {} -- player.UserId -> { targetUserId, spectatorActive }
	self.deadPlayers = {} -- player.UserId -> true

	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()

	return self
end

function SpectatorManager:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	local eventNames = {
		"EnterSpectatorMode",    -- Server -> Client: Put player into spectator mode
		"ExitSpectatorMode",     -- Server -> Client: Remove player from spectator mode
		"SpectatorTargetUpdate", -- Server -> Client: Update who player is spectating
		"SpectatorCycleTarget",  -- Client -> Server: Player wants to cycle to next/prev target
		"SpectatorStateUpdate"   -- Server -> Client: Update list of alive players
	}

	for _, eventName in ipairs(eventNames) do
		local event = remoteEventsFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteEventsFolder
		end
		self.remoteEvents[eventName] = event
	end

	-- Listen for cycle requests from clients
	if self.remoteEvents.SpectatorCycleTarget then
		self.remoteEvents.SpectatorCycleTarget.OnServerEvent:Connect(function(player, direction)
			-- Validate direction input from client
			if direction ~= "next" and direction ~= "prev" then
				return
			end
			self:cycleSpectatorTarget(player, direction)
		end)
	end
end

-- Mark a player as dead and put them in spectator mode
function SpectatorManager:onPlayerDied(player)
	if not player or not player.UserId then
		return
	end

	self.deadPlayers[player.UserId] = true

	-- Find an alive player to spectate
	local targetPlayer = self:findAlivePlayer(nil, player)

	self.spectators[player.UserId] = {
		targetUserId = targetPlayer and targetPlayer.UserId or nil,
		spectatorActive = true
	}

	-- Notify the client to enter spectator mode
	if self.remoteEvents.EnterSpectatorMode then
		self.remoteEvents.EnterSpectatorMode:FireClient(player, {
			targetPlayer = targetPlayer and targetPlayer.Name or nil,
			targetUserId = targetPlayer and targetPlayer.UserId or nil
		})
	end

	print("[SpectatorManager] " .. player.Name .. " entered spectator mode")
end

-- Find an alive player to spectate
function SpectatorManager:findAlivePlayer(excludeUserId, spectator)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId ~= excludeUserId and p.UserId ~= (spectator and spectator.UserId) then
			if not self.deadPlayers[p.UserId] then
				local character = p.Character
				if character then
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid and humanoid.Health > 0 then
						return p
					end
				end
			end
		end
	end
	return nil
end

-- Get all alive players
function SpectatorManager:getAlivePlayers()
	local alive = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if not self.deadPlayers[p.UserId] then
			local character = p.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					table.insert(alive, p)
				end
			end
		end
	end
	return alive
end

-- Cycle to next/previous spectator target
function SpectatorManager:cycleSpectatorTarget(player, direction)
	if not player or not player.UserId then
		return
	end

	local spectatorData = self.spectators[player.UserId]
	if not spectatorData or not spectatorData.spectatorActive then
		return
	end

	local alivePlayers = self:getAlivePlayers()
	if #alivePlayers == 0 then
		return
	end

	-- Find current index
	local currentIndex = 1
	for i, p in ipairs(alivePlayers) do
		if p.UserId == spectatorData.targetUserId then
			currentIndex = i
			break
		end
	end

	-- Calculate new index
	local newIndex
	if direction == "next" then
		newIndex = currentIndex + 1
		if newIndex > #alivePlayers then
			newIndex = 1
		end
	else -- "prev"
		newIndex = currentIndex - 1
		if newIndex < 1 then
			newIndex = #alivePlayers
		end
	end

	-- Update target
	local newTarget = alivePlayers[newIndex]
	spectatorData.targetUserId = newTarget and newTarget.UserId or nil

	-- Notify client
	if self.remoteEvents.SpectatorTargetUpdate then
		self.remoteEvents.SpectatorTargetUpdate:FireClient(player, {
			targetPlayer = newTarget and newTarget.Name or nil,
			targetUserId = newTarget and newTarget.UserId or nil
		})
	end
end

-- When a spectator's target dies, cycle to next available
function SpectatorManager:onSpectatorTargetDied(targetUserId)
	for spectatorUserId, spectatorData in pairs(self.spectators) do
		if spectatorData.targetUserId == targetUserId then
			local spectator = Players:GetPlayerByUserId(spectatorUserId)
			if spectator then
				local newTarget = self:findAlivePlayer(targetUserId, spectator)
				spectatorData.targetUserId = newTarget and newTarget.UserId or nil

				if self.remoteEvents.SpectatorTargetUpdate then
					self.remoteEvents.SpectatorTargetUpdate:FireClient(spectator, {
						targetPlayer = newTarget and newTarget.Name or nil,
						targetUserId = newTarget and newTarget.UserId or nil
					})
				end
			end
		end
	end
end

-- Remove player from spectator mode (round end)
function SpectatorManager:exitSpectatorMode(player)
	if not player or not player.UserId then
		return
	end

	local spectatorData = self.spectators[player.UserId]
	if spectatorData then
		spectatorData.spectatorActive = false
	end

	-- Notify client
	if self.remoteEvents.ExitSpectatorMode then
		self.remoteEvents.ExitSpectatorMode:FireClient(player, {})
	end
end

-- End of round - exit all spectators
function SpectatorManager:endRound()
	for userId in pairs(self.spectators) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self:exitSpectatorMode(player)
		end
	end
end

-- Reset for new round
function SpectatorManager:reset()
	-- Exit all spectators
	self:endRound()

	-- Clear tracking
	self.spectators = {}
	self.deadPlayers = {}
end

-- Handle player leaving the game
function SpectatorManager:onPlayerLeave(player)
	if not player or not player.UserId then
		return
	end

	-- Remove from spectators
	self.spectators[player.UserId] = nil
	self.deadPlayers[player.UserId] = nil

	-- If they were being spectated, update other spectators
	self:onSpectatorTargetDied(player.UserId)
end

-- Check if player is dead this round
function SpectatorManager:isPlayerDead(player)
	return player and self.deadPlayers[player.UserId] == true
end

-- Check if player is in spectator mode
function SpectatorManager:isSpectating(player)
	if not player or not player.UserId then
		return false
	end
	local data = self.spectators[player.UserId]
	return data and data.spectatorActive == true
end

-- Broadcast alive player list to all spectators
function SpectatorManager:broadcastAliveList()
	local alivePlayers = self:getAlivePlayers()
	local aliveList = {}
	for _, p in ipairs(alivePlayers) do
		table.insert(aliveList, { name = p.Name, userId = p.UserId })
	end

	for userId, spectatorData in pairs(self.spectators) do
		if spectatorData.spectatorActive then
			local player = Players:GetPlayerByUserId(userId)
			if player and self.remoteEvents.SpectatorStateUpdate then
				self.remoteEvents.SpectatorStateUpdate:FireClient(player, {
					alivePlayers = aliveList,
					aliveCount = #alivePlayers
				})
			end
		end
	end
end

return SpectatorManager
