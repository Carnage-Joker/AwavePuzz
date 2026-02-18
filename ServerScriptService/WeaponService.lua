-- @ScriptType: ModuleScript
-- WeaponService.lua
-- Handles player weapon logic, raycast validation, and kill rewards
-- Features proper gun cloning, positioning on hand, weapon switching with cleanup,
-- and raycast firing in the direction the player is aiming

-- Debug flag - set to true to enable detailed logging (includes origin reconstruction details)
local DEBUG = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Server-only validation
if not RunService:IsServer() then
	error("[WeaponService] This module can only be required on the server")
end

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
	error("[WeaponService] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
	error("[WeaponService] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)

local WeaponConfig = SharedFolder:WaitForChild("WeaponConfig", 5)
if not WeaponConfig then
	error("[WeaponService] CRITICAL: Failed to load WeaponConfig after 5 seconds")
end
WeaponConfig = require(WeaponConfig)

local RemotesFolder = SharedFolder:WaitForChild("Remotes", 5)
if not RemotesFolder then
	error("[WeaponService] CRITICAL: Failed to load Remotes folder after 5 seconds")
end
local RemoteRegistry = RemotesFolder:WaitForChild("RemoteRegistry", 5)
if not RemoteRegistry then
	error("[WeaponService] CRITICAL: Failed to load RemoteRegistry after 5 seconds")
end
RemoteRegistry = require(RemoteRegistry)

local function cloneTable(t)
	local copy = {}
	for key, value in pairs(t) do
		copy[key] = value
	end
	return copy
end

local WeaponService = {}
WeaponService.__index = WeaponService

--[[
    cloneGunModel( gunId )
    Safely clones a gun model from ServerStorage.Models.
    Returns the cloned Model (named "EquippedWeaponModel") or nil if anything is missing.
--]]
function WeaponService:cloneGunModel(gunId)
	-- Grab the Models folder (once per call – cheap)
	local modelsFolder = ServerStorage:FindFirstChild("Models")
	if not modelsFolder then
		warn("[WeaponService] Models folder missing in ServerStorage")
		return nil
	end

	-- Resolve the model name from the weapon config (fallback to the id itself)
	local weaponConfig = WeaponConfig.getWeapon(gunId)
	local modelName = weaponConfig
		and (weaponConfig.ModelName or weaponConfig.Name)
		or gunId

	local template = modelsFolder:FindFirstChild(modelName)
	if not template then
		warn(string.format(
			"[WeaponService] Gun model '%s' not found in ServerStorage.Models",
			modelName
			))
		return nil
	end

	-- Clone, rename, and give it a predictable name
	local clone = template:Clone()
	clone.Name = "EquippedWeaponModel"
	return clone
end

function WeaponService.new(playerManager, allianceService, gameManager)
	local self = setmetatable({}, WeaponService)
	self.playerManager = playerManager
	self.allianceService = allianceService
	self.gameManager = gameManager  -- For kill tracking
	self.fpsWeaponService = nil  -- Set via setFPSWeaponService
	self.playerWeaponState = {} -- userId -> state
	self.registeredZombies = {} -- Compatibility shim: zombie tracking for tests
	self.remoteEvents = {}
	
	-- Rate limiting: track fire events per player to prevent spam
	self.fireRateLimit = {} -- userId -> { count = number, windowStart = tick() }
	self.FIRE_RATE_WINDOW = 1 -- 1 second window
	self.MAX_FIRES_PER_WINDOW = 20 -- Max 20 fires per second (prevents spam)
	
	-- Security warning throttling: prevent log flooding from intentional spam
	self.securityWarnings = {} -- userId -> { lastWarn = tick(), warnType = string }
	self.SECURITY_WARN_COOLDOWN = 5 -- Only warn once per 5 seconds per player per type
	
	self:setupRemoteEvents()
	return self
end

-- Set FPSWeaponService reference for ammo validation
function WeaponService:setFPSWeaponService(fpsWeaponService)
	self.fpsWeaponService = fpsWeaponService
end

function WeaponService:setupRemoteEvents()
	-- Get remotes from RemoteRegistry
	-- RemoteEvent Documentation:
	-- - WeaponFire: Client -> Server, player fires weapon {origin = Vector3, direction = Vector3, weaponId = string}
	-- - WeaponEquip: Client -> Server, player requests to equip weapon {weaponId = string}
	-- - WeaponHitConfirm: Server -> Client, confirms hit on target {hitPosition = Vector3, damage = number}
	local remotes = RemoteRegistry.GetServerRemotes()
	self.remoteEvents = {
		WeaponFire = remotes.WeaponFire,
		WeaponEquip = remotes.WeaponEquip,
		WeaponHitConfirm = remotes.WeaponHitConfirm,
	}

	self.remoteEvents.WeaponFire.OnServerEvent:Connect(function(player, payload)
		self:handleWeaponFire(player, payload)
	end)

	self.remoteEvents.WeaponEquip.OnServerEvent:Connect(function(player, payload)
		-- ✅ FIX: Accept both string weaponId OR table {weaponId = "Pistol"}
		local weaponId
		if typeof(payload) == "string" then
			weaponId = payload
		elseif typeof(payload) == "table" and payload.weaponId then
			weaponId = payload.weaponId
		else
			warn("[WeaponService] Invalid WeaponEquip payload from " .. player.Name)
			return
		end

		self:handleEquipRequest(player, weaponId)
	end)
end

function WeaponService:initializePlayer(player)
	local userId = player.UserId
	self.playerWeaponState[userId] = {
		lastShot = 0,
		upgrades = {}
	}

	local startingWeapon = self.playerManager:getEquippedWeapon(player)
	if not startingWeapon then
		self.playerManager:addWeapon(player, WeaponConfig.DefaultWeapon)
		self.playerManager:equipWeapon(player, WeaponConfig.DefaultWeapon)
		startingWeapon = WeaponConfig.DefaultWeapon
	end

	-- Give them the visual weapon on spawn
	self:_equipVisualWeapon(player, startingWeapon)  -- NEW
	
	-- FIX: Notify FPSWeaponService for ammo tracking
	if self.fpsWeaponService then
		self.fpsWeaponService:onWeaponEquipped(player, startingWeapon)
	else
		warn(string.format("[WeaponService] fpsWeaponService not initialized for player %s - ammo will not be tracked", player.Name))
	end
end


function WeaponService:removePlayer(player)
	local userId = player.UserId
	self.playerWeaponState[userId] = nil
	self.fireRateLimit[userId] = nil
	self.securityWarnings[userId] = nil
end

function WeaponService:handleEquipRequest(player, weaponId)
	if not self.playerManager:ownsWeapon(player, weaponId) then
		return
	end

	self.playerManager:equipWeapon(player, weaponId)
	self:_equipVisualWeapon(player, weaponId)
	
	-- FIX: Notify FPSWeaponService for ammo tracking (like forceEquip does)
	if self.fpsWeaponService then
		self.fpsWeaponService:onWeaponEquipped(player, weaponId)
	end
end

-- ✅ NEW: forceEquip method called by PlayerSpawnManager
-- Forces a weapon to be equipped for a player (used for spawning with default weapon)
-- Idempotent: calling twice does not duplicate models, welds, or reset ammo incorrectly
function WeaponService:forceEquip(player, weaponId)
	if not player or not weaponId or typeof(weaponId) ~= "string" then
		warn("[WeaponService] forceEquip: Invalid player or weaponId")
		return false
	end

	-- Validate weaponId exists in config
	local weaponConfig = WeaponConfig.getWeapon(weaponId)
	if not weaponConfig then
		warn("[WeaponService] forceEquip: Invalid weaponId:", weaponId)
		return false
	end

	-- Ensure player owns the weapon (add if not already owned)
	if not self.playerManager:ownsWeapon(player, weaponId) then
		self.playerManager:addWeapon(player, weaponId)
	end

	-- Equip server-side (single source of truth)
	self.playerManager:equipWeapon(player, weaponId)

	-- Apply visual weapon model
	self:_equipVisualWeapon(player, weaponId)

	-- Notify FPSWeaponService for ammo tracking
	if self.fpsWeaponService then
		self.fpsWeaponService:onWeaponEquipped(player, weaponId)
	end

	-- Debug logging, gated by GameConfig.DEBUG_MODE for development/diagnostics
	if GameConfig.DEBUG then
		print(string.format("[WeaponService] forceEquip: %s equipped with %s", player.Name, weaponId))
	end
	return true
end


function WeaponService:getModifiedStats(player, weaponId)
	local baseStats = WeaponConfig.getWeapon(weaponId)
	if not baseStats then
		return nil
	end

	local state = self.playerWeaponState[player.UserId]
	if not state then
		return baseStats
	end

	local modified = cloneTable(baseStats)
	if state.upgrades then
		for upgradeId in pairs(state.upgrades) do
			local upgrade = WeaponConfig.getUpgrade(upgradeId)
			if upgrade and upgrade.Type == "stat" and modified[upgrade.Stat] then
				modified[upgrade.Stat] = modified[upgrade.Stat] * upgrade.Multiplier
			end
		end
	end

	return modified
end

-- Helper: Throttled security warning to prevent log flooding from intentional exploits
-- Only warns once per player per warning type within cooldown period
function WeaponService:_throttledSecurityWarn(userId, warnType, message)
	-- Only enable in debug mode or gate behind security telemetry
	if not GameConfig.DEBUG then
		return
	end
	
	local now = tick()
	local warnData = self.securityWarnings[userId]
	local key = tostring(userId) .. "_" .. warnType
	
	if not warnData then
		self.securityWarnings[userId] = {}
		warnData = self.securityWarnings[userId]
	end
	
	local lastWarn = warnData[key]
	if not lastWarn or (now - lastWarn) >= self.SECURITY_WARN_COOLDOWN then
		warn(message)
		warnData[key] = now
	end
end

-- Reconstruct shot origin server-side from player character
-- This eliminates false rejections caused by client/server origin mismatch
-- Returns: (reconstructedOrigin: Vector3, isValid: boolean)
function WeaponService:reconstructOrigin(player, clientDirection)
	local character = player.Character
	if not character then
		if DEBUG then
			warn("[WeaponService] DEBUG: Cannot reconstruct origin - no character for " .. player.Name)
		end
		return nil, false
	end
	
	local head = character:FindFirstChild("Head")
	if not head then
		if DEBUG then
			warn("[WeaponService] DEBUG: Cannot reconstruct origin - no head for " .. player.Name)
		end
		return nil, false
	end
	
	-- Get security settings
	local forwardOffset = GameConfig.Security.ORIGIN_FORWARD_OFFSET or 2.0
	local verticalOffset = GameConfig.Security.ORIGIN_VERTICAL_OFFSET or 0.5
	
	-- Reconstruct origin from head position + forward offset in aim direction
	-- Break into steps for clarity
	local headPosition = head.Position
	local cameraHeightOffset = Vector3.new(0, verticalOffset, 0)
	local forwardInAimDirection = clientDirection.Unit * forwardOffset
	local safeOrigin = headPosition + cameraHeightOffset + forwardInAimDirection
	
	if DEBUG then
		print(string.format("[WeaponService] DEBUG: Reconstructed origin for %s - Head: (%.1f,%.1f,%.1f), Origin: (%.1f,%.1f,%.1f)", 
			player.Name, 
			headPosition.X, headPosition.Y, headPosition.Z,
			safeOrigin.X, safeOrigin.Y, safeOrigin.Z))
	end
	
	return safeOrigin, true
end

function WeaponService:handleWeaponFire(player, payload)
	if typeof(payload) ~= "table" then
		warn("[WeaponService] Invalid payload from " .. player.Name)
		return
	end
	
	local userId = player.UserId
	
	-- SECURITY: Rate limiting - prevent remote spam
	local now = tick()
	local rateLimitData = self.fireRateLimit[userId]
	if not rateLimitData then
		self.fireRateLimit[userId] = {
			count = 1,
			windowStart = now
		}
	else
		-- Check if we're in a new window
		if (now - rateLimitData.windowStart) >= self.FIRE_RATE_WINDOW then
			-- Reset window
			rateLimitData.count = 1
			rateLimitData.windowStart = now
		else
			-- Increment count in current window
			rateLimitData.count = rateLimitData.count + 1
			
			-- Check if exceeded limit
			if rateLimitData.count > self.MAX_FIRES_PER_WINDOW then
				self:_throttledSecurityWarn(userId, "rate_limit", 
					string.format("[WeaponService] SECURITY: Rate limit exceeded for player %s (%d fires in %ds)", 
						player.Name, rateLimitData.count, self.FIRE_RATE_WINDOW))
				return
			end
		end
	end

	-- SECURITY: Ignore client-provided weaponId, use server authority
	-- Client could send any weaponId, but we only trust what the server says is equipped
	local equipped = self.playerManager:getEquippedWeapon(player)
	if not equipped then
		warn("[WeaponService] No equipped weapon for " .. player.Name)
		return
	end
	
	-- Use server-authoritative weaponId
	local weaponId = equipped
	
	local origin = payload.origin
	local direction = payload.direction
	local timestamp = payload.timestamp

	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		warn("[WeaponService] Invalid origin/direction from " .. player.Name)
		return
	end

	-- Validate direction magnitude and handle edge cases
	if direction.Magnitude < 0.001 then
		warn("[WeaponService] Invalid direction magnitude from " .. player.Name)
		return
	end
	
	-- Normalize and validate for NaN (from normalization errors)
	local unitDir = direction.Unit
	-- Check for NaN from normalization errors (NaN is the only value that doesn't equal itself)
	if unitDir.X ~= unitDir.X or unitDir.Y ~= unitDir.Y or unitDir.Z ~= unitDir.Z then
		warn("[WeaponService] NaN direction from " .. player.Name)
		return
	end
	
	-- Use the validated unit direction for all subsequent calculations
	direction = unitDir

	local stats = self:getModifiedStats(player, weaponId)
	if not stats then
		warn("[WeaponService] No weapon config for id: " .. tostring(weaponId) .. " (player: " .. player.Name .. ")")
		return
	end
	
	-- SECURITY: Hard cap fire rate to prevent config exploits
	-- Even if weapon config is modified, enforce minimum delay
	local state = self.playerWeaponState[userId]
	if not state then
		warn("[WeaponService] No weapon state for " .. player.Name)
		return
	end
	
	local MINIMUM_FIRE_DELAY = 0.05 -- 0.05 seconds = 50ms minimum between shots
	local timeSinceLastShot = now - state.lastShot
	local weaponFireRate = stats.FireRate or 1.0
	local requiredDelay = math.max(weaponFireRate, MINIMUM_FIRE_DELAY)
	
	if timeSinceLastShot < requiredDelay then
		self:_throttledSecurityWarn(userId, "fire_too_fast",
			string.format("[WeaponService] SECURITY: Shot too fast from %s (%.3fs since last, required %.3fs)", 
				player.Name, timeSinceLastShot, requiredDelay))
		return
	end
	
	state.lastShot = now
	
	-- SECURITY: Server-authoritative origin reconstruction and validation
	local character = player.Character
	local useServerOrigin = GameConfig.Security and GameConfig.Security.USE_SERVER_ORIGIN
	
	-- Reconstruct origin server-side if enabled (default: true)
	if useServerOrigin == nil then
		useServerOrigin = true
	end
	
	if useServerOrigin then
		-- Server reconstructs safe origin from player character
		local reconstructedOrigin, isValid = self:reconstructOrigin(player, direction)
		if not isValid then
			self:_throttledSecurityWarn(userId, "origin_reconstruct_failed",
				"[WeaponService] SECURITY: Failed to reconstruct origin for " .. player.Name)
			return
		end
		
		-- Use server-reconstructed origin instead of client-provided origin
		origin = reconstructedOrigin
		
		if DEBUG then
			print(string.format("[WeaponService] DEBUG: Using server-reconstructed origin for %s: (%.1f,%.1f,%.1f)",
				player.Name, origin.X, origin.Y, origin.Z))
		end
	else
		-- Legacy validation: validate client-provided origin (kept for testing/fallback)
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local originOffset = origin - humanoidRootPart.Position
				local distanceFromPlayer = originOffset.Magnitude
				
				-- Use configurable max distance from GameConfig
				local maxDistance = GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE or 15
				
				if distanceFromPlayer > maxDistance then
					self:_throttledSecurityWarn(userId, "origin_distance",
						string.format("[WeaponService] SECURITY: Rejected shot from %s - origin too far from player (%.1f studs)", 
							player.Name, distanceFromPlayer))
					return
				end
				
				-- SECURITY: Validate origin is not significantly behind player with tolerance
				-- Use local space Z coordinate to check if origin is behind
				local hrpCFrame = humanoidRootPart.CFrame
				local localOffset = hrpCFrame:PointToObjectSpace(origin)
				
				-- Add tolerance to avoid false positives from camera offsets
				local behindTolerance = GameConfig.Security.BEHIND_BODY_TOLERANCE or 1.0
				local behindThreshold = -3 - behindTolerance
				
				if localOffset.Z < behindThreshold then
					self:_throttledSecurityWarn(userId, "origin_behind",
						string.format("[WeaponService] SECURITY: Rejected shot from %s - origin behind player (localZ=%.1f, threshold=%.1f)", 
							player.Name, localOffset.Z, behindThreshold))
					return
				end
				
				-- SECURITY: Validate origin Y is not absurdly above/below player
				local verticalOffset = math.abs(localOffset.Y)
				if verticalOffset > 10 then
					self:_throttledSecurityWarn(userId, "origin_vertical",
						string.format("[WeaponService] SECURITY: Rejected shot from %s - origin too high/low (Y offset=%.1f)", 
							player.Name, verticalOffset))
					return
				end
			end
		end
	end
	
	-- SECURITY: Validate direction alignment with player look vector
	-- This is ALWAYS validated regardless of origin reconstruction mode
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local hrpCFrame = humanoidRootPart.CFrame
			local referenceVector = hrpCFrame.LookVector
			local dotProduct = direction:Dot(referenceVector)
			
			-- Get threshold from config
			local minDotProduct = GameConfig.Security.MIN_WEAPON_FIRE_DOT_PRODUCT or 0.7
			
			if dotProduct < minDotProduct then
				self:_throttledSecurityWarn(userId, "direction_alignment",
					string.format("[WeaponService] SECURITY: Rejected shot from %s - direction not aligned with look vector (dot: %.2f, threshold: %.2f)", 
						player.Name, dotProduct, minDotProduct))
				
				if DEBUG then
					warn(string.format("  DEBUG: Direction: (%.2f, %.2f, %.2f), HRP LookVector: (%.2f, %.2f, %.2f)",
						direction.X, direction.Y, direction.Z,
						referenceVector.X, referenceVector.Y, referenceVector.Z))
				end
				return
			end
		end
	end

	-- SECURITY: Validate and consume ammo server-side (if FPSWeaponService is available)
	if self.fpsWeaponService then
		-- Check if player is reloading
		if self.fpsWeaponService:isReloading(player) then
			return -- Can't fire while reloading
		end

		-- Validate ammo availability
		if not self.fpsWeaponService:validateShot(player, weaponId) then
			return -- No ammo
		end

		-- Consume ammo server-side
		if not self.fpsWeaponService:consumeAmmo(player, weaponId, 1) then
			return -- Failed to consume ammo
		end
	end

	-- Perform raycast
	local rayDirection = direction.Unit * stats.Range
	local params = RaycastParams.new()
	
	-- Filter out player's character and equipped weapon model
	local filterList = {character}
	
	-- Also filter out the weapon model if it exists
	if character then
		local weaponModel = character:FindFirstChild("EquippedWeaponModel")
		if weaponModel then
			table.insert(filterList, weaponModel)
		end
	end
	
	params.FilterDescendantsInstances = filterList
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin, rayDirection, params)
	if result then
		-- SECURITY: Additional LOS check to hit position
		-- Verify player has line of sight to the hit position (not just origin)
		local head = character and character:FindFirstChild("Head")
		if head then
			local hitLosParams = RaycastParams.new()
			hitLosParams.FilterDescendantsInstances = filterList
			hitLosParams.FilterType = Enum.RaycastFilterType.Exclude
			hitLosParams.IgnoreWater = true
			
			local hitDirection = result.Position - head.Position
			local hitLosResult = Workspace:Raycast(head.Position, hitDirection, hitLosParams)
			
			-- If we hit something before the target, it's likely a wall shot.
			-- However, allow the LOS ray to intersect other parts of the same target model.
			if hitLosResult and hitLosResult.Instance ~= result.Instance then
				local distanceToTarget = hitDirection.Magnitude
				local distanceToObstacle = hitLosResult.Distance
				
				-- Determine if the obstacle belongs to the same model as the original hit
				local targetInstance = result.Instance
				local targetModel = targetInstance and targetInstance:FindFirstAncestorOfClass("Model")
				local obstacleInstance = hitLosResult.Instance
				local obstacleModel = obstacleInstance and obstacleInstance:FindFirstAncestorOfClass("Model")
				local isSameTargetModel = targetModel ~= nil and targetModel == obstacleModel
				
				-- Only treat this as blocked LOS when the obstacle is not part of the target model
				if not isSameTargetModel then
					-- Allow small tolerance for edge cases
					if (distanceToObstacle + 2) < distanceToTarget then
						warn(string.format("[WeaponService] SECURITY: Rejected shot from %s - no LOS to hit position (blocked by %s)", 
							player.Name, hitLosResult.Instance:GetFullName()))
						return
					end
				end
			end
		end
		
		local hitInstance = result.Instance
		local hitModel = hitInstance and hitInstance:FindFirstAncestorOfClass("Model")

		if hitModel then
			-- Check if hit a zombie
			if hitModel:GetAttribute("IsZombie") then
				self:damageZombie(hitModel, player, stats, weaponId)
				RemoteRegistry.SafeFireClient(self.remoteEvents.WeaponHitConfirm, player, {
					position = result.Position,
					target = hitModel.Name
				})
				-- Check if hit a player
			elseif hitModel:FindFirstChild("Humanoid") then
				local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
				if hitPlayer and hitPlayer ~= player then
					-- Check if players are allied
					local areAllied = self.allianceService and 
						self.allianceService:areAllied(player, hitPlayer)

					if not areAllied then
						-- PvP damage is allowed for non-allied players
						self:damagePlayer(hitModel, hitPlayer, player, stats, weaponId)
						RemoteRegistry.SafeFireClient(self.remoteEvents.WeaponHitConfirm, player, {
							position = result.Position,
							target = hitPlayer.Name
						})
					end
					-- If allied (direct edge), damage is prevented (friendly fire protection)
					-- Note: Indirect allies (connected via other players) CAN damage each other
				end
			end
		end
	end
end
function WeaponService:damageZombie(zombieModel, player, stats, weaponId)
	local humanoid = zombieModel:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	zombieModel:SetAttribute("LastHitBy", player.UserId)
	zombieModel:SetAttribute("LastHitWeapon", weaponId)

	-- Wrap in pcall in case humanoid is destroyed between validation and damage application
	local success, err = pcall(function()
		humanoid:TakeDamage(stats.Damage)
	end)
	if not success then
		warn("[WeaponService] Failed to apply damage to humanoid: " .. tostring(err))
	end
end

function WeaponService:damagePlayer(characterModel, targetPlayer, attackingPlayer, stats, weaponId)
	local humanoid = characterModel:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	-- Store health before damage
	local healthBefore = humanoid.Health

	-- Apply PvP damage (non-allied players can damage each other)
	local success, err = pcall(function()
		humanoid:TakeDamage(stats.Damage)
	end)
	if not success then
		warn("[WeaponService] Failed to apply PvP damage: " .. tostring(err))
		return
	end

	-- Log the PvP hit for potential tracking/stats
	print(string.format("[WeaponService] PvP: %s hit %s for %d damage", 
		attackingPlayer.Name, targetPlayer.Name, stats.Damage))

	-- Track last attacker for kill credit using attribute
	if attackingPlayer and attackingPlayer.UserId then
		humanoid:SetAttribute("LastAttackerUserId", attackingPlayer.UserId)
		humanoid:SetAttribute("LastVictimUserId", targetPlayer.UserId)
	end

	-- Connect Died event for kill registration using :Once() to prevent leaks
	if not humanoid:GetAttribute("WeaponServiceDiedConnected") then
		humanoid:SetAttribute("WeaponServiceDiedConnected", true)
		humanoid.Died:Once(function()
			local lastAttackerUserId = humanoid:GetAttribute("LastAttackerUserId")
			local victimUserId = humanoid:GetAttribute("LastVictimUserId")
			
			-- Look up fresh player references (avoid stale closures)
			local lastAttacker = nil
			local victim = nil
			if lastAttackerUserId then
				for _, player in ipairs(Players:GetPlayers()) do
					if player.UserId == lastAttackerUserId then
						lastAttacker = player
					end
					if victimUserId and player.UserId == victimUserId then
						victim = player
					end
				end
			end
			
			-- Use fresh victim reference instead of closure variable
			local victimName = victim and victim.Name or "Unknown"
			
			if lastAttacker then
				print(string.format("[WeaponService] PvP Kill: %s eliminated %s", 
					lastAttacker.Name, victimName))
				-- Notify AllianceService of the kill for betrayal mechanics
				if victim and self.allianceService and self.allianceService.onPlayerKilled then
					local callSuccess, callErr = pcall(function()
						self.allianceService:onPlayerKilled(victim, lastAttacker)
					end)
					if not callSuccess then
						warn("[WeaponService] Error notifying AllianceService of kill: " .. tostring(callErr))
					end
				end
			end
		end)
	end
end

function WeaponService:onZombieKilled(zombieModel)
	if not zombieModel then
		return
	end

	local reward = zombieModel:GetAttribute("Reward") or 0
	local lastHitUserId = zombieModel:GetAttribute("LastHitBy")
	if not lastHitUserId then
		return
	end

	local player = Players:GetPlayerByUserId(lastHitUserId)
	if not player then
		return
	end

	local weaponId = zombieModel:GetAttribute("LastHitWeapon")
	local weaponStats = weaponId and WeaponConfig.getWeapon(weaponId) or nil
	local bonus = weaponStats and weaponStats.RewardBonus or 0

	-- Award currency and increment kill count
	self.playerManager:addCurrency(player, reward + bonus)
	
	-- FIX: Increment player kills for scoreboard tracking
	if self.gameManager and self.gameManager.incrementPlayerKills then
		self.gameManager:incrementPlayerKills(player, 1)
		if DEBUG then
			print(string.format("[WeaponService] Player %s kill count incremented", player.Name))
		end
	end
end

function WeaponService:applyUpgrade(player, upgradeId)
	local upgrade = WeaponConfig.getUpgrade(upgradeId)
	if not upgrade then
		return false
	end

	local state = self.playerWeaponState[player.UserId]
	if not state then
		state = {lastShot = 0, upgrades = {}}
		self.playerWeaponState[player.UserId] = state
	end

	state.upgrades = state.upgrades or {}
	if state.upgrades[upgradeId] then
		return false -- already owned
	end

	state.upgrades[upgradeId] = true
	return true
end

function WeaponService:_equipVisualWeapon(player, weaponId)
	local character = player.Character
	if not character then return end

	-- Validate the weapon config first
	local weaponConfig = WeaponConfig.getWeapon(weaponId)
	if not weaponConfig then
		warn("[WeaponService] No weapon config for id:", weaponId)
		return
	end

	-- -----------------------------------------------------------------
	-- 1️⃣  Get (or create) the visual model using the safe helper
	-- -----------------------------------------------------------------
	local gunModel = self:cloneGunModel(weaponId)
	if not gunModel then
		-- cloneGunModel already warned – just bail out
		return
	end
	-- Ensure the cloned asset is a Model or BasePart
	if not (gunModel:IsA("Model") or gunModel:IsA("BasePart")) then
		warn("[WeaponService] Unexpected gun model type:", gunModel.ClassName)
		return
	end
	-- -----------------------------------------------------------------
	-- 2️⃣  Clean up any previously‑equipped visual (atomic swap)
	-- -----------------------------------------------------------------
	-- Find and remove old weapon BEFORE parenting new one to avoid race condition
	local old = character:FindFirstChild("EquippedWeaponModel")
	if old then
		old:Destroy()
	end
	
	-- Now parent and name the new weapon
	gunModel.Name = "EquippedWeaponModel"
	gunModel.Parent = character

	-- -----------------------------------------------------------------
	-- 3️⃣  Determine the primary part for welding (handles Model or single Part)
	-- -----------------------------------------------------------------
	local primaryPart
	if gunModel:IsA("Model") then
		if not gunModel.PrimaryPart then
			gunModel.PrimaryPart = gunModel:FindFirstChild("Main")
				or gunModel:FindFirstChild("Base")
				or gunModel:FindFirstChild("Body")
				or gunModel:FindFirstChildWhichIsA("BasePart")
		end
		primaryPart = gunModel.PrimaryPart
		if not primaryPart then
			warn("[WeaponService] Gun model has no PrimaryPart or base part:", weaponConfig.Name or weaponId)
			return
		end
	else
		-- gunModel is a single Part; use it directly
		primaryPart = gunModel
	end

	-- -----------------------------------------------------------------
	-- 4️⃣  Attach the model/part to the player’s hand (R15) or arm (R6)
	-- -----------------------------------------------------------------
	local rightHand = character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")   -- R6 fallback

	if not rightHand then
		warn("[WeaponService] No RightHand / Right Arm to attach gun to for player:", player.Name)
		return
	end

	-- ✅ FIX: Apply physics-safe settings to ALL parts in the weapon model
	-- Prevents collision-based flinging and falling through map
	local function applyPhysicsSafeSettings(part)
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	if gunModel:IsA("Model") then
		-- Apply to all descendants in model
		for _, descendant in ipairs(gunModel:GetDescendants()) do
			applyPhysicsSafeSettings(descendant)
		end
	else
		-- Single part
		applyPhysicsSafeSettings(gunModel)
	end

	-- Position the model or part (tweak offsets/rotations if needed)
	if gunModel:IsA("Model") then
		gunModel:SetPrimaryPartCFrame(
			rightHand.CFrame
				* CFrame.new(0, -0.5, 0.3)
				* CFrame.Angles(0, math.rad(90), 0)
		)
	else
		gunModel.CFrame = rightHand.CFrame
			* CFrame.new(0, -0.5, 0.3)
			* CFrame.Angles(0, math.rad(90), 0)
	end

	-- Weld the primary part (or the single part) to the hand
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = primaryPart
	weld.Part1 = rightHand
	weld.Parent = primaryPart
end

-- Deal damage to a target (Humanoid, Model, or Player)
-- 
-- ⚠️ TEST INFRASTRUCTURE ONLY ⚠️
-- This method is a simplified damage adapter required by WeaponSystemTests.
-- It bypasses important game logic including:
--   - Kill tracking and reward bonuses (onZombieKilled)
--   - Alliance system checks (damagePlayer checks areAllied before PvP damage)
--   - Player kill credit tracking via attributes (LastAttackerUserId, LastVictimUserId)
--   - GameManager kill count incrementing
--
-- For production game logic, use the specialized methods instead:
--   - damageZombie(zombieModel, player, stats, weaponId) for zombie damage
--   - damagePlayer(characterModel, targetPlayer, attackingPlayer, stats, weaponId) for PvP damage
--
-- This method exists solely to satisfy test requirements and should NOT be used
-- in gameplay code paths where proper context (player, weapon stats, etc.) is available.
--
-- Returns boolean success
function WeaponService:dealDamage(target, amount, meta)
	-- Validate amount
	if typeof(amount) ~= "number" or amount <= 0 then
		return false
	end
	
	-- Resolve target to Humanoid
	local humanoid = nil
	local targetModel = nil
	
	if typeof(target) == "Instance" then
		if target:IsA("Humanoid") then
			humanoid = target
			targetModel = target.Parent
		elseif target:IsA("Model") then
			humanoid = target:FindFirstChild("Humanoid")
			targetModel = target
		elseif target:IsA("Player") and target.Character then
			humanoid = target.Character:FindFirstChild("Humanoid")
			targetModel = target.Character
		end
	end
	
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	
	-- Apply damage with error handling
	local success, err = pcall(function()
		humanoid:TakeDamage(amount)
	end)
	
	if not success then
		warn("[WeaponService] dealDamage failed:", err)
		return false
	end
	
	return true
end

-- Compatibility shim: registerZombie for test API
-- Tracks registered zombies in a table (no-op for gameplay)
function WeaponService:registerZombie(zombieModel)
	if not zombieModel or typeof(zombieModel) ~= "Instance" then
		return false
	end
	
	self.registeredZombies[zombieModel] = true
	return true
end

-- Compatibility shim: unregisterZombie for test API
function WeaponService:unregisterZombie(zombieModel)
	if not zombieModel or typeof(zombieModel) ~= "Instance" then
		return false
	end
	
	self.registeredZombies[zombieModel] = nil
	return true
end

return WeaponService