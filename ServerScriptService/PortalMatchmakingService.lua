-- @ScriptType: ModuleScript
-- PortalMatchmakingService.lua
-- Server-authoritative portal matchmaking system
-- Handles portal queues, countdowns, and match launching

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	error("[PortalMatchmakingService] CRITICAL: Failed to load Shared folder")
end

local GameConfig = require(Shared:WaitForChild("GameConfig", 5))
local MapConfig = require(Shared:WaitForChild("MapConfig", 5))

local MatchRegistry = require(script.Parent:WaitForChild("MatchRegistry", 5))

local PortalMatchmakingService = {}
PortalMatchmakingService.__index = PortalMatchmakingService

function PortalMatchmakingService.new(gameManager)
	local self = setmetatable({}, PortalMatchmakingService)
	
	self.gameManager = gameManager
	self.matchRegistry = MatchRegistry.new()
	
	-- portalId -> { queue = {players}, countdown = number, locked = bool, config = {} }
	self.portals = {}
	
	-- userId -> { portalId = string, joinTime = tick() }
	self.playerQueues = {}
	
	-- userId -> tick() (for touch debouncing)
	self.touchDebounce = {}
	
	-- Countdown tasks (portalId -> task object for cancellation)
	self.countdownTasks = {}
	
	-- Remote events
	self.remoteEvents = {}
	self:setupRemoteEvents()
	
	-- Config shortcuts
	local pmConfig = GameConfig.PORTAL_MATCHMAKING
	self.maxPlayersPerMatch = pmConfig.MAX_PLAYERS_PER_MATCH
	self.defaultMinPlayers = pmConfig.DEFAULT_MIN_PLAYERS
	self.defaultCountdownTime = pmConfig.DEFAULT_COUNTDOWN_TIME
	self.countdownCancelThreshold = pmConfig.COUNTDOWN_CANCEL_THRESHOLD
	self.postLaunchCooldown = pmConfig.POST_LAUNCH_COOLDOWN
	self.touchDebounceTime = pmConfig.TOUCH_DEBOUNCE_TIME
	
	-- Cleanup accumulator for throttled cleanup
	self._cleanupAccumulator = 0
	
	print("[PortalMatchmakingService] Initialized")
	
	return self
end

function PortalMatchmakingService:setupRemoteEvents()
	-- Use RemoteEventUtil for consistency with the rest of the codebase
	local RemoteEventUtil = require(Shared:WaitForChild("RemoteEventUtil", 5))
	
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"PortalQueueStatus",
		"PortalLeaveQueue",
		"PortalQueueJoined",
		"PortalQueueLeft"
	})
	
	-- Hook client requests to leave queue
	self.remoteEvents.PortalLeaveQueue.OnServerEvent:Connect(function(player)
		self:onPlayerLeaveQueue(player)
	end)
	
	print("[PortalMatchmakingService] Remote events setup complete")
end

-- Discover and register portals from workspace
function PortalMatchmakingService:discoverPortals()
	print("[PortalMatchmakingService] Starting portal discovery...")
	
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		warn("[PortalMatchmakingService] No Lobby folder in Workspace - cannot discover portals")
		return
	end
	
	local portalsFolder = lobby:FindFirstChild("Portals")
	if not portalsFolder then
		warn("[PortalMatchmakingService] No Portals folder in Lobby - cannot discover portals")
		return
	end
	
	local discovered = 0
	local children = portalsFolder:GetChildren()
	print(string.format("[PortalMatchmakingService] Found %d potential portal objects in Portals folder", #children))
	
	for _, portalPart in ipairs(children) do
		if portalPart:IsA("BasePart") or portalPart:IsA("Model") then
			local success = self:registerPortal(portalPart)
			if success then
				discovered = discovered + 1
			end
		end
	end
	
	print(string.format("[PortalMatchmakingService] Discovery complete: %d portals registered", discovered))
end

-- Register a single portal
function PortalMatchmakingService:registerPortal(portalPart)
	-- ✅ FIX: Explicit portal contract validation with detailed skip reasons
	
	-- Validate portal is a Model or BasePart
	if not (portalPart:IsA("BasePart") or portalPart:IsA("Model")) then
		warn(string.format("[PortalMatchmakingService] Portal skipped: %s is not a BasePart or Model (got %s)", 
			portalPart.Name, portalPart.ClassName))
		return false
	end
	
	-- Extract configuration from portal part (attributes can be on root or TouchPart)
	local portalId = portalPart:GetAttribute("PortalId")
	local mapId = portalPart:GetAttribute("MapId")
	
	-- If it's a Model, also check TouchPart for attributes (fallback)
	local touchPart = nil
	if portalPart:IsA("Model") then
		touchPart = portalPart:FindFirstChild("TouchPart") or portalPart.PrimaryPart
		if not touchPart then
			warn(string.format("[PortalMatchmakingService] Portal skipped: Model %s has no TouchPart or PrimaryPart", 
				portalPart.Name))
			return false
		end
		
		if not touchPart:IsA("BasePart") then
			warn(string.format("[PortalMatchmakingService] Portal skipped: %s TouchPart is not a BasePart (got %s)", 
				portalPart.Name, touchPart.ClassName))
			return false
		end
		
		-- Fallback to TouchPart attributes if not on root
		if not portalId then
			portalId = touchPart:GetAttribute("PortalId")
		end
		if not mapId then
			mapId = touchPart:GetAttribute("MapId")
		end
	else
		-- If it's a BasePart, use it as the touchPart
		touchPart = portalPart
	end
	
	-- Validate PortalId
	if not portalId or portalId == "" then
		warn(string.format("[PortalMatchmakingService] Portal skipped: %s has no PortalId attribute", portalPart.Name))
		return false
	end
	
	-- Validate MapId
	if not mapId or mapId == "" then
		warn(string.format("[PortalMatchmakingService] Portal skipped: %s has no MapId attribute", portalId))
		return false
	end
	
	-- Validate TouchPart has CanTouch enabled
	if touchPart.CanTouch == false then
		warn(string.format("[PortalMatchmakingService] Portal skipped: %s TouchPart has CanTouch=false", portalId))
		return false
	end
	
	-- Validate TouchPart is anchored
	if not touchPart.Anchored then
		warn(string.format("[PortalMatchmakingService] Portal skipped: %s TouchPart is not anchored", portalId))
		return false
	end
	
	-- Extract other attributes with defaults
	local minPlayers = portalPart:GetAttribute("MinPlayers") or touchPart:GetAttribute("MinPlayers") or self.defaultMinPlayers
	local countdownTime = portalPart:GetAttribute("CountdownSeconds") or touchPart:GetAttribute("CountdownSeconds") or self.defaultCountdownTime
	
	-- Check if already registered
	if self.portals[portalId] then
		warn(string.format("[PortalMatchmakingService] Portal skipped: %s already registered", portalId))
		return false
	end
	
	-- Register portal
	self.portals[portalId] = {
		part = portalPart,
		queue = {},
		countdown = 0,
		locked = false,
		config = {
			portalId = portalId,
			mapId = mapId,
			minPlayers = minPlayers,
			countdownTime = countdownTime
		}
	}
	
	-- Setup touch detection
	self:setupPortalTouch(portalPart, portalId)
	
	-- Setup visual indicator if needed
	self:setupPortalIndicator(portalPart, portalId)
	
	print(string.format("[PortalMatchmakingService] Registered portal %s (map: %s, minPlayers: %d)", 
		portalId, mapId, minPlayers))
	
	return true
end

-- Setup touch detection for portal
function PortalMatchmakingService:setupPortalTouch(portalPart, portalId)
	local touchPart = portalPart
	
	-- If it's a model, find a part named "TouchPart" or use PrimaryPart
	if portalPart:IsA("Model") then
		touchPart = portalPart:FindFirstChild("TouchPart") or portalPart.PrimaryPart
		if not touchPart then
			warn(string.format("[PortalMatchmakingService] Portal model %s has no TouchPart or PrimaryPart", portalId))
			return
		end
	end
	
	-- Ensure it's a BasePart
	if not touchPart:IsA("BasePart") then
		warn(string.format("[PortalMatchmakingService] Portal %s touch part is not a BasePart", portalId))
		return
	end
	
	-- Connect touch event for joining
	touchPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			self:onPortalTouched(portalId, player)
		end
	end)
	
	-- Connect touch ended event for leaving portal region
	touchPart.TouchEnded:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			self:onPortalTouchEnded(portalId, player)
		end
	end)
	
	print(string.format("[PortalMatchmakingService] Touch detection setup for portal %s", portalId))
end

-- Handle portal touch ended (player leaving portal region)
function PortalMatchmakingService:onPortalTouchEnded(portalId, player)
	if not player or not player.Parent then return end
	
	-- Check if player is in this portal's queue
	local queueInfo = self.playerQueues[player.UserId]
	if queueInfo and queueInfo.portalId == portalId then
		-- Check if portal countdown/lock allows leaving
		local portal = self.portals[portalId]
		if portal and not portal.locked and portal.countdown <= 0 then
			-- Allow leaving if not in countdown or locked
			self:removePlayerFromQueue(player, portalId)
		end
	end
end

-- Setup visual indicator for portal (BillboardGui)
function PortalMatchmakingService:setupPortalIndicator(portalPart, portalId)
	-- Find existing BillboardGui (search descendants for Model-based portals)
	local billboard = portalPart:FindFirstChild("QueueIndicator", true)
	if billboard and billboard:IsA("BillboardGui") then
		-- Already exists, store reference
		self.portals[portalId].indicator = billboard
		-- Find the StatusLabel within
		local statusLabel = billboard:FindFirstChild("StatusLabel", true)
		if statusLabel and statusLabel:IsA("TextLabel") then
			self.portals[portalId].indicatorLabel = statusLabel
		end
		return
	end
	
	-- Create new indicator (basic version - can be enhanced)
	billboard = Instance.new("BillboardGui")
	billboard.Name = "QueueIndicator"
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = portalPart
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 0.3
	textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = "0/8"
	textLabel.Parent = billboard
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = textLabel
	
	self.portals[portalId].indicator = billboard
	self.portals[portalId].indicatorLabel = textLabel
end

-- Handle portal touch
function PortalMatchmakingService:onPortalTouched(portalId, player)
	if not player or not player.Parent then return end
	
	-- Debounce check
	local now = tick()
	local lastTouch = self.touchDebounce[player.UserId]
	if lastTouch and (now - lastTouch) < self.touchDebounceTime then
		return
	end
	self.touchDebounce[player.UserId] = now
	
	-- Check if player is already in a match
	if self.matchRegistry:isPlayerInMatch(player) then
		print(string.format("[PortalMatchmakingService] Player %s already in a match", player.Name))
		return
	end
	
	-- Check if player is already in a queue
	local existingQueue = self.playerQueues[player.UserId]
	if existingQueue then
		-- If same portal, ignore (already queued)
		if existingQueue.portalId == portalId then
			return
		end
		-- Different portal - remove from old queue first
		self:removePlayerFromQueue(player, existingQueue.portalId)
	end
	
	-- Try to join portal queue
	self:addPlayerToQueue(portalId, player)
end

-- Add player to portal queue
function PortalMatchmakingService:addPlayerToQueue(portalId, player)
	local portal = self.portals[portalId]
	if not portal then
		warn(string.format("[PortalMatchmakingService] Invalid portal %s", tostring(portalId)))
		return false
	end
	
	-- Check if portal is locked
	if portal.locked then
		print(string.format("[PortalMatchmakingService] Portal %s is locked", portalId))
		-- Send feedback to client
		self.remoteEvents.PortalQueueStatus:FireClient(player, {
			portalId = portalId,
			status = "locked",
			message = "Portal is launching..."
		})
		return false
	end
	
	-- Allow queue to exceed maxPlayersPerMatch for overflow handling
	-- Extra players will form subsequent matches after the first 8 launch
	
	-- Add to queue
	table.insert(portal.queue, player)
	self.playerQueues[player.UserId] = {
		portalId = portalId,
		joinTime = tick()
	}
	
	print(string.format("[PortalMatchmakingService] Player %s joined portal %s queue (%d/%d)", 
		player.Name, portalId, #portal.queue, self.maxPlayersPerMatch))
	
	-- Send join confirmation to player
	self.remoteEvents.PortalQueueJoined:FireClient(player, {
		portalId = portalId,
		mapId = portal.config.mapId,
		queueCount = #portal.queue,
		maxPlayers = self.maxPlayersPerMatch
	})
	
	-- Broadcast queue update
	self:broadcastQueueStatus(portalId)
	
	-- Check if we should start countdown
	self:checkStartCountdown(portalId)
	
	return true
end

-- Remove player from queue
function PortalMatchmakingService:removePlayerFromQueue(player, portalId)
	if not portalId then
		-- Find which portal they're in
		local queueInfo = self.playerQueues[player.UserId]
		if queueInfo then
			portalId = queueInfo.portalId
		else
			return
		end
	end
	
	local portal = self.portals[portalId]
	if not portal then return end
	
	-- Remove from queue
	for i, queuedPlayer in ipairs(portal.queue) do
		if queuedPlayer.UserId == player.UserId then
			table.remove(portal.queue, i)
			print(string.format("[PortalMatchmakingService] Player %s left portal %s queue", 
				player.Name, portalId))
			break
		end
	end
	
	-- Remove player queue mapping
	self.playerQueues[player.UserId] = nil
	
	-- Send leave notification to player
	if player and player.Parent then
		self.remoteEvents.PortalQueueLeft:FireClient(player, {
			portalId = portalId
		})
	end
	
	-- Broadcast update
	self:broadcastQueueStatus(portalId)
	
	-- Check if countdown should be cancelled
	self:checkCancelCountdown(portalId)
end

-- Player explicitly leaves queue (called from remote or disconnect)
function PortalMatchmakingService:onPlayerLeaveQueue(player)
	local queueInfo = self.playerQueues[player.UserId]
	if queueInfo then
		self:removePlayerFromQueue(player, queueInfo.portalId)
	end
end

-- Check if countdown should start
function PortalMatchmakingService:checkStartCountdown(portalId)
	local portal = self.portals[portalId]
	if not portal then return end
	
	-- Don't start if already counting down
	if portal.countdown > 0 then return end
	
	-- Check if we have enough players
	if #portal.queue < portal.config.minPlayers then return end
	
	-- Start countdown
	portal.countdown = portal.config.countdownTime
	
	print(string.format("[PortalMatchmakingService] Starting countdown for portal %s (%d seconds)", 
		portalId, portal.countdown))
	
	-- Spawn countdown task
	local task = task.spawn(function()
		self:runCountdown(portalId)
	end)
	
	self.countdownTasks[portalId] = task
	
	-- Broadcast countdown start
	self:broadcastQueueStatus(portalId)
end

-- Check if countdown should be cancelled
function PortalMatchmakingService:checkCancelCountdown(portalId)
	local portal = self.portals[portalId]
	if not portal then return end
	
	-- Only cancel if countdown is active
	if portal.countdown <= 0 then return end
	
	-- BUGFIX (MEDIUM): Use math.min for proper cancel threshold
	-- Cancel countdown if queue drops below minimum requirement
	local effectiveCancelThreshold = math.min(portal.config.minPlayers, self.countdownCancelThreshold)
	if #portal.queue < effectiveCancelThreshold then
		print(string.format("[PortalMatchmakingService] Cancelling countdown for portal %s (queue %d < required %d)", 
			portalId, #portal.queue, effectiveCancelThreshold))
		
		portal.countdown = 0
		
		-- Cancel task
		if self.countdownTasks[portalId] then
			task.cancel(self.countdownTasks[portalId])
			self.countdownTasks[portalId] = nil
		end
		
		-- Broadcast cancellation
		self:broadcastQueueStatus(portalId)
	end
end

-- Run countdown for a portal
function PortalMatchmakingService:runCountdown(portalId)
	local portal = self.portals[portalId]
	if not portal then return end
	
	while portal.countdown > 0 do
		task.wait(1)
		
		portal.countdown = portal.countdown - 1
		
		-- Check if we still have enough players
		if #portal.queue < self.countdownCancelThreshold then
			portal.countdown = 0
			print(string.format("[PortalMatchmakingService] Countdown cancelled for portal %s", portalId))
			self:broadcastQueueStatus(portalId)
			return
		end
		
		-- Broadcast update
		self:broadcastQueueStatus(portalId)
		
		-- If countdown finished, launch match
		if portal.countdown <= 0 then
			-- BUGFIX (MEDIUM): Clean up countdown task reference to prevent memory leak
			self.countdownTasks[portalId] = nil
			self:launchMatch(portalId)
			return
		end
	end
end

-- Launch a match from portal queue
function PortalMatchmakingService:launchMatch(portalId)
	local portal = self.portals[portalId]
	if not portal then return end
	
	-- BUGFIX (MEDIUM): Prevent double launch if portal is already locked
	if portal.locked then
		warn(string.format("[PortalMatchmakingService] Portal %s already launching, ignoring duplicate launch", portalId))
		return
	end
	
	print(string.format("[PortalMatchmakingService] Launching match for portal %s", portalId))
	
	-- Lock portal to prevent concurrent modifications
	portal.locked = true
	
	-- Snapshot players (up to max) and immediately remove from queue
	-- This prevents race conditions with concurrent queue modifications
	local matchPlayers = {}
	local numToTake = math.min(#portal.queue, self.maxPlayersPerMatch)
	
	-- Remove players from queue first, store them for match
	-- Note: Iterating backwards and removing maintains correct indices
	for i = numToTake, 1, -1 do
		local player = portal.queue[i]
		if player and player.Parent then
			table.insert(matchPlayers, player) -- Append to end (O(1))
		end
		table.remove(portal.queue, i)
		if player then
			self.playerQueues[player.UserId] = nil
		end
	end
	
	-- Reverse matchPlayers to restore original order
	local orderedPlayers = {}
	for i = #matchPlayers, 1, -1 do
		table.insert(orderedPlayers, matchPlayers[i])
	end
	matchPlayers = orderedPlayers
	
	-- Determine map
	local mapId = portal.config.mapId
	if mapId == "Random" then
		-- MapConfig.getRandom() returns (mapId, mapData) or (defaultId, defaultData)
		local randomMapId, randomMapData = MapConfig.getRandom()
		if randomMapId then
			mapId = randomMapId
			print(string.format("[PortalMatchmakingService] Random map selected: %s", mapId))
		else
			warn("[PortalMatchmakingService] Failed to get random map, using default")
			mapId = select(1, MapConfig.getDefault())
		end
	end
	
	-- Validate map exists
	if not MapConfig.get(mapId) then
		warn(string.format("[PortalMatchmakingService] Invalid map %s, using default", tostring(mapId)))
		local defaultMapId = select(1, MapConfig.getDefault())
		if defaultMapId then
			mapId = defaultMapId
		else
			warn("[PortalMatchmakingService] No default map available, aborting match launch")
			portal.locked = false
			-- Rollback: re-add players to queue on failure
			for _, player in ipairs(matchPlayers) do
				if player and player.Parent then
					table.insert(portal.queue, player)
					self.playerQueues[player.UserId] = {
						portalId = portalId,
						joinTime = tick()
					}
				end
			end
			self:broadcastQueueStatus(portalId)
			return
		end
	end
	
	-- Create match in registry
	local matchId = self.matchRegistry:createMatch(matchPlayers, mapId)
	
	if not matchId then
		warn("[PortalMatchmakingService] Failed to create match")
		portal.locked = false
		-- Rollback: re-add players to queue on failure
		for _, player in ipairs(matchPlayers) do
			if player and player.Parent then
				table.insert(portal.queue, player)
				self.playerQueues[player.UserId] = {
					portalId = portalId,
					joinTime = tick()
				}
			end
		end
		self:broadcastQueueStatus(portalId)
		return
	end
	
	-- Start match via GameManager
	local success = false
	if self.gameManager and self.gameManager.startMatch then
		success = self.gameManager:startMatch(matchPlayers, mapId, matchId)
		if not success then
			warn("[PortalMatchmakingService] Failed to start match")
			self.matchRegistry:endMatch(matchId)
			portal.locked = false
			-- Rollback: re-add players to queue on failure
			for _, player in ipairs(matchPlayers) do
				if player and player.Parent then
					table.insert(portal.queue, player)
					self.playerQueues[player.UserId] = {
						portalId = portalId,
						joinTime = tick()
					}
				end
			end
			self:broadcastQueueStatus(portalId)
			return
		end
	else
		warn("[PortalMatchmakingService] GameManager does not have startMatch method")
		self.matchRegistry:endMatch(matchId)
		portal.locked = false
		-- Rollback: re-add players to queue on failure
		for _, player in ipairs(matchPlayers) do
			if player and player.Parent then
				table.insert(portal.queue, player)
				self.playerQueues[player.UserId] = {
					portalId = portalId,
					joinTime = tick()
				}
			end
		end
		self:broadcastQueueStatus(portalId)
		return
	end
	
	-- Notify players they've left the queue (match is starting)
	for _, player in ipairs(matchPlayers) do
		if player and player.Parent then
			self.remoteEvents.PortalQueueLeft:FireClient(player, {
				portalId = portalId
			})
		end
	end
	
	-- Broadcast portal status
	self:broadcastQueueStatus(portalId)
	
	-- Unlock portal after cooldown
	task.delay(self.postLaunchCooldown, function()
		portal.locked = false
		print(string.format("[PortalMatchmakingService] Portal %s unlocked", portalId))
		self:broadcastQueueStatus(portalId)
		
		-- If there are remaining players, start new countdown
		if #portal.queue >= portal.config.minPlayers then
			self:checkStartCountdown(portalId)
		end
	end)
end

-- Broadcast queue status to all clients
function PortalMatchmakingService:broadcastQueueStatus(portalId)
	local portal = self.portals[portalId]
	if not portal then return end
	
	local status = {
		portalId = portalId,
		queueCount = #portal.queue,
		maxPlayers = self.maxPlayersPerMatch,
		countdown = portal.countdown,
		locked = portal.locked,
		mapId = portal.config.mapId,
		status = portal.locked and "locked" or (portal.countdown > 0 and "countdown" or "ready")
	}
	
	-- Send to all players
	self.remoteEvents.PortalQueueStatus:FireAllClients(status)
	
	-- Update visual indicator
	self:updatePortalIndicator(portalId)
end

-- Update portal visual indicator
function PortalMatchmakingService:updatePortalIndicator(portalId)
	local portal = self.portals[portalId]
	if not portal or not portal.indicatorLabel then return end
	
	local text = string.format("%d/%d", #portal.queue, self.maxPlayersPerMatch)
	
	if portal.countdown > 0 then
		text = text .. string.format("\n%ds", math.ceil(portal.countdown))
	elseif portal.locked then
		text = text .. "\nLaunching..."
	end
	
	portal.indicatorLabel.Text = text
	
	-- Color based on status
	if portal.locked then
		portal.indicatorLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	elseif portal.countdown > 0 then
		portal.indicatorLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	else
		portal.indicatorLabel.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
	end
end

-- Update function (call from game loop if needed)
function PortalMatchmakingService:update(dt)
	-- Throttled periodic match cleanup to avoid per-frame O(n) scans
	-- Accumulate elapsed time and only run cleanup every few seconds
	self._cleanupAccumulator = self._cleanupAccumulator + (dt or 0)

	local CLEANUP_INTERVAL = 5 -- seconds between cleanup passes
	if self._cleanupAccumulator >= CLEANUP_INTERVAL then
		self._cleanupAccumulator = 0
		self.matchRegistry:cleanupInactiveMatches()
	end
end

-- Handle player disconnect
function PortalMatchmakingService:onPlayerDisconnect(player)
	-- Remove from any queue
	self:onPlayerLeaveQueue(player)
	
	-- Remove from any match
	self.matchRegistry:removePlayerFromMatch(player)
	
	-- Clear debounce
	self.touchDebounce[player.UserId] = nil
end

-- Get match registry
function PortalMatchmakingService:getMatchRegistry()
	return self.matchRegistry
end

-- Get portal info (for debugging)
function PortalMatchmakingService:getPortalInfo(portalId)
	local portal = self.portals[portalId]
	if not portal then return nil end
	
	return {
		portalId = portalId,
		queueCount = #portal.queue,
		countdown = portal.countdown,
		locked = portal.locked,
		config = portal.config
	}
end

-- Get all portals info
function PortalMatchmakingService:getAllPortalsInfo()
	local info = {}
	for portalId, _ in pairs(self.portals) do
		table.insert(info, self:getPortalInfo(portalId))
	end
	return info
end

-- End a match and return players to lobby
-- This should be called by GameManager when a match ends
function PortalMatchmakingService:endMatch(matchId)
	if not matchId then
		warn("[PortalMatchmakingService] endMatch: No matchId provided")
		return
	end
	
	-- Get match data before ending
	local match = self.matchRegistry:getMatch(matchId)
	if not match then
		warn(string.format("[PortalMatchmakingService] endMatch: Match %s not found", tostring(matchId)))
		return
	end
	
	local players = self.matchRegistry:getMatchPlayers(matchId)
	
	print(string.format("[PortalMatchmakingService] Ending match %s with %d players", matchId, #players))
	
	-- Return players to lobby
	if self.gameManager and self.gameManager.playerSpawnManager then
		for _, player in ipairs(players) do
			if player and player.Parent then
				self.gameManager.playerSpawnManager:keepPlayerInLobby(player)
			end
		end
	end
	
	-- End match in registry
	self.matchRegistry:endMatch(matchId)
	
	print(string.format("[PortalMatchmakingService] Match %s ended successfully", matchId))
end

return PortalMatchmakingService
