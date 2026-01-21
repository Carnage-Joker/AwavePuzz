-- @ScriptType: ModuleScript

-- SpectatorManager.lua
-- Server-side spectator mode manager
-- Features:
-- - Dead players can spectate living players until round ends
-- - Spectator UI with clear labeling (see SpectatorUI.client.lua)
-- - Player cycling with Q/E or A/D keys and UI buttons
-- - Third-person camera view for spectating
-- - Spectators are invisible to zombies (via IsSpectating attribute)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

local SpectatorManager = {}
SpectatorManager.__index = SpectatorManager

local DEFAULT_CYCLE_COOLDOWN = 0.25

local function getHumanoid(player)
	if not player then return nil end
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function isPlayerAlive(player)
	local hum = getHumanoid(player)
	return hum and hum.Health > 0
end

function SpectatorManager.new()
	local self = setmetatable({}, SpectatorManager)

	self.spectators = {}    -- userId -> { targetUserId: number?, spectatorActive: boolean }
	self.deadPlayers = {}   -- userId -> true
	self._cycleCooldown = {}-- userId -> lastCycleTime
	self._roundActive = false
	
	-- ✅ FIX: Track CharacterAdded connections to prevent leaks
	self._characterAddedConnections = {} -- userId -> RBXScriptConnection

	self.remoteEvents = {}
	self:_setupRemoteEvents()

	-- Cleanup on leave
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerLeave(player)
	end)

	return self
end

function SpectatorManager:_setupRemoteEvents()
	-- Use shared utility to create remote events
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"EnterSpectatorMode",    -- Server -> Client
		"ExitSpectatorMode",     -- Server -> Client
		"SpectatorTargetUpdate", -- Server -> Client
		"SpectatorCycleTarget",  -- Client -> Server
		"SpectatorStateUpdate"   -- Server -> Client
	})

	-- Client cycle requests
	self.remoteEvents.SpectatorCycleTarget.OnServerEvent:Connect(function(player, direction)
		if direction ~= "next" and direction ~= "prev" then
			return
		end

		-- Must be dead + spectating + in an active round
		if not self._roundActive then return end
		if not self:isSpectating(player) then return end
		if not self:isPlayerDead(player) then return end

		-- Throttle
		local now = os.clock()
		local last = self._cycleCooldown[player.UserId] or 0
		local cooldown = GameConfig.SPECTATOR_CYCLE_COOLDOWN or DEFAULT_CYCLE_COOLDOWN
		if (now - last) < cooldown then
			return
		end
		self._cycleCooldown[player.UserId] = now

		self:cycleSpectatorTarget(player, direction)
	end)
end

-- Call at round start
function SpectatorManager:startRound()
	self._roundActive = true
	self.deadPlayers = {}
	self.spectators = {}
	self._cycleCooldown = {}
end

-- Call at round end
function SpectatorManager:endRound()
	self._roundActive = false

	-- Exit all spectators
	for userId, data in pairs(self.spectators) do
		if data and data.spectatorActive then
			local p = Players:GetPlayerByUserId(userId)
			if p then
				self:exitSpectatorMode(p)
			end
		end
	end

	-- ✅ FIX: Disconnect all CharacterAdded connections on round end to prevent leaks
	for userId, connection in pairs(self._characterAddedConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	self._characterAddedConnections = {}

	self.spectators = {}
	self.deadPlayers = {}
	self._cycleCooldown = {}
end

-- Optional helper: call when you spawn/respawn players during a round
function SpectatorManager:onPlayerSpawned(player)
	-- If they were marked dead, keep them dead for the round (common round-based behaviour)
	-- If your game allows mid-round respawns, uncomment the lines below:
	-- self.deadPlayers[player.UserId] = nil
	-- self:exitSpectatorMode(player)

	-- If a spectator had no target (nobody alive), try assign one now
	self:_fixAllSpectatorTargets()
	self:broadcastAliveList()
end

function SpectatorManager:isPlayerDead(player)
	return player and self.deadPlayers[player.UserId] == true
end

function SpectatorManager:isSpectating(player)
	if not player then return false end
	local data = self.spectators[player.UserId]
	return data and data.spectatorActive == true
end

function SpectatorManager:getAlivePlayers()
	local alive = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if not self.deadPlayers[p.UserId] and isPlayerAlive(p) then
			table.insert(alive, p)
		end
	end
	table.sort(alive, function(a, b)
		return a.UserId < b.UserId
	end)
	return alive
end

function SpectatorManager:_findAlivePlayer(excludeUserId, spectatorUserId)
	for _, p in ipairs(self:getAlivePlayers()) do
		if p.UserId ~= excludeUserId and p.UserId ~= spectatorUserId then
			return p
		end
	end
	return nil
end

-- Mark player dead + enter spectator
function SpectatorManager:onPlayerDied(player)
	if not self._roundActive then return end
	if not player or not player.UserId then return end

	self.deadPlayers[player.UserId] = true

	-- ✅ FIX: Disconnect previous CharacterAdded connection if it exists
	if self._characterAddedConnections[player.UserId] then
		self._characterAddedConnections[player.UserId]:Disconnect()
		self._characterAddedConnections[player.UserId] = nil
	end

	-- Mark player as spectating with an attribute for zombie AI to ignore
	-- Ensure that if the character respawns while the player is still dead,
	-- the IsSpectating attribute is re-applied to the new character.
	local function applySpectatorAttribute(character)
		if self.deadPlayers[player.UserId] and character then
			character:SetAttribute("IsSpectating", true)
		end
	end

	if player.Character then
		applySpectatorAttribute(player.Character)
	end

	-- ✅ FIX: Store connection for cleanup
	self._characterAddedConnections[player.UserId] = player.CharacterAdded:Connect(function(newCharacter)
		applySpectatorAttribute(newCharacter)
	end)
	
	local target = self:_findAlivePlayer(nil, player.UserId)
	self.spectators[player.UserId] = {
		targetUserId = target and target.UserId or nil,
		spectatorActive = true,
	}

	self.remoteEvents.EnterSpectatorMode:FireClient(player, {
		targetPlayer = target and target.Name or nil,
		targetUserId = target and target.UserId or nil,
	})

	self:broadcastAliveList()
end

function SpectatorManager:exitSpectatorMode(player)
	if not player or not player.UserId then return end

	local data = self.spectators[player.UserId]
	if data then
		data.spectatorActive = false
	end

	-- ✅ FIX: Disconnect CharacterAdded connection when exiting spectator mode
	if self._characterAddedConnections[player.UserId] then
		self._characterAddedConnections[player.UserId]:Disconnect()
		self._characterAddedConnections[player.UserId] = nil
	end

	-- Remove spectating attribute
	if player.Character then
		player.Character:SetAttribute("IsSpectating", false)
	end

	self.remoteEvents.ExitSpectatorMode:FireClient(player, {})
end

function SpectatorManager:cycleSpectatorTarget(player, direction)
	if not player or not player.UserId then return end

	local data = self.spectators[player.UserId]
	if not data or not data.spectatorActive then return end

	local alive = self:getAlivePlayers()
	if #alive == 0 then
		-- nobody alive: clear target
		data.targetUserId = nil
		self.remoteEvents.SpectatorTargetUpdate:FireClient(player, {
			targetPlayer = nil,
			targetUserId = nil,
		})
		self:broadcastAliveList()
		return
	end

	-- Find current index
	local currentIndex = 0
	for i, p in ipairs(alive) do
		if p.UserId == data.targetUserId then
			currentIndex = i
			break
		end
	end

	-- If current target invalid, pick first alive
	if currentIndex == 0 then
		local newTarget = alive[1]
		data.targetUserId = newTarget.UserId
		self.remoteEvents.SpectatorTargetUpdate:FireClient(player, {
			targetPlayer = newTarget.Name,
			targetUserId = newTarget.UserId,
		})
		self:broadcastAliveList()
		return
	end

	local newIndex
	if direction == "next" then
		newIndex = currentIndex + 1
		if newIndex > #alive then newIndex = 1 end
	else
		newIndex = currentIndex - 1
		if newIndex < 1 then newIndex = #alive end
	end

	local newTarget = alive[newIndex]
	data.targetUserId = newTarget.UserId

	self.remoteEvents.SpectatorTargetUpdate:FireClient(player, {
		targetPlayer = newTarget.Name,
		targetUserId = newTarget.UserId,
	})

	self:broadcastAliveList()
end

-- Call this when SOMEONE dies so spectators watching them switch away
function SpectatorManager:onSpectatorTargetDied(targetUserId)
	for spectatorUserId, data in pairs(self.spectators) do
		if data and data.spectatorActive and data.targetUserId == targetUserId then
			local spectator = Players:GetPlayerByUserId(spectatorUserId)
			if spectator then
				local newTarget = self:_findAlivePlayer(targetUserId, spectatorUserId)
				data.targetUserId = newTarget and newTarget.UserId or nil

				self.remoteEvents.SpectatorTargetUpdate:FireClient(spectator, {
					targetPlayer = newTarget and newTarget.Name or nil,
					targetUserId = newTarget and newTarget.UserId or nil,
				})
			end
		end
	end

	self:broadcastAliveList()
end

function SpectatorManager:_fixAllSpectatorTargets()
	local alive = self:getAlivePlayers()
	for spectatorUserId, data in pairs(self.spectators) do
		if data and data.spectatorActive then
			-- If target missing/dead, assign first alive that isn't themselves
			local ok = false
			if data.targetUserId then
				local t = Players:GetPlayerByUserId(data.targetUserId)
				if t and isPlayerAlive(t) and not self.deadPlayers[t.UserId] then
					ok = true
				end
			end
			if not ok then
				local newTarget = nil
				for _, p in ipairs(alive) do
					if p.UserId ~= spectatorUserId then
						newTarget = p
						break
					end
				end
				data.targetUserId = newTarget and newTarget.UserId or nil
				local spectator = Players:GetPlayerByUserId(spectatorUserId)
				if spectator then
					self.remoteEvents.SpectatorTargetUpdate:FireClient(spectator, {
						targetPlayer = newTarget and newTarget.Name or nil,
						targetUserId = newTarget and newTarget.UserId or nil,
					})
				end
			end
		end
	end
end

function SpectatorManager:onPlayerLeave(player)
	if not player or not player.UserId then return end

	-- If leaver was alive, spectators may be targeting them
	self:onSpectatorTargetDied(player.UserId)

	-- ✅ FIX: Disconnect CharacterAdded connection when player leaves
	if self._characterAddedConnections[player.UserId] then
		self._characterAddedConnections[player.UserId]:Disconnect()
		self._characterAddedConnections[player.UserId] = nil
	end

	self.spectators[player.UserId] = nil
	self.deadPlayers[player.UserId] = nil
	self._cycleCooldown[player.UserId] = nil

	self:broadcastAliveList()
end

function SpectatorManager:broadcastAliveList()
	local alivePlayers = self:getAlivePlayers()
	local aliveList = {}
	for _, p in ipairs(alivePlayers) do
		table.insert(aliveList, { name = p.Name, userId = p.UserId })
	end

	for userId, data in pairs(self.spectators) do
		if data and data.spectatorActive then
			local p = Players:GetPlayerByUserId(userId)
			if p then
				self.remoteEvents.SpectatorStateUpdate:FireClient(p, {
					alivePlayers = aliveList,
					aliveCount = #alivePlayers,
				})
			end
		end
	end
end

-- Reset method for GameManager to call when starting a new round
function SpectatorManager:reset()
	-- ✅ FIX: Disconnect all CharacterAdded connections on reset
	for userId, connection in pairs(self._characterAddedConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	self._characterAddedConnections = {}

	-- Clear all spectator and dead player data
	self.spectators = {}
	self.deadPlayers = {}
	self._cycleCooldown = {}
	self._roundActive = false

	-- Exit any remaining spectators (in case any are stuck)
	for _, player in ipairs(Players:GetPlayers()) do
		if self:isSpectating(player) then
			self:exitSpectatorMode(player)
		end
	end

	print("[SpectatorManager] Reset for new round")
end

return SpectatorManager
