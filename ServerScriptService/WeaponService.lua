-- @ScriptType: ModuleScript
-- WeaponService.lua
-- Handles player weapon logic, raycast validation, and kill rewards
-- Features proper gun cloning, positioning on hand, weapon switching with cleanup,
-- and raycast firing in the direction the player is aiming


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local WeaponConfig = require(SharedFolder:WaitForChild("WeaponConfig"))
local RemoteEventUtil = require(SharedFolder:WaitForChild("RemoteEventUtil"))

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

function WeaponService.new(playerManager, allianceService)
	local self = setmetatable({}, WeaponService)
	self.playerManager = playerManager
	self.allianceService = allianceService
	self.fpsWeaponService = nil  -- Set via setFPSWeaponService
	self.playerWeaponState = {} -- userId -> state
	self.remoteEvents = {}
	self:setupRemoteEvents()
	return self
end

-- Set FPSWeaponService reference for ammo validation
function WeaponService:setFPSWeaponService(fpsWeaponService)
	self.fpsWeaponService = fpsWeaponService
end

function WeaponService:setupRemoteEvents()
	-- Use shared utility to create remote events
	-- RemoteEvent Documentation:
	-- - WeaponFire: Client -> Server, player fires weapon {origin = Vector3, direction = Vector3, weaponId = string}
	-- - WeaponEquip: Client -> Server, player requests to equip weapon {weaponId = string}
	-- - WeaponHitConfirm: Server -> Client, confirms hit on target {hitPosition = Vector3, damage = number}
	self.remoteEvents = RemoteEventUtil.getOrCreateEvents({
		"WeaponFire",
		"WeaponEquip",
		"WeaponHitConfirm"
	})

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
end


function WeaponService:removePlayer(player)
	self.playerWeaponState[player.UserId] = nil
end

function WeaponService:handleEquipRequest(player, weaponId)
	if not self.playerManager:ownsWeapon(player, weaponId) then
		return
	end

	self.playerManager:equipWeapon(player, weaponId)
	self:_equipVisualWeapon(player, weaponId)   -- NEW
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

function WeaponService:handleWeaponFire(player, payload)
	if typeof(payload) ~= "table" then
		warn("[WeaponService] Invalid payload from " .. player.Name)
		return
	end

	local weaponId = payload.weaponId
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

	local equipped = self.playerManager:getEquippedWeapon(player)
	if not equipped or equipped ~= weaponId then
		warn("[WeaponService] Weapon mismatch for " .. player.Name .. " - equipped: " .. tostring(equipped) .. ", fired: " .. tostring(weaponId))
		return
	end

	local stats = self:getModifiedStats(player, weaponId)
	if not stats then
		warn("[WeaponService] No weapon config for id: " .. tostring(weaponId) .. " (player: " .. player.Name .. ")")
		return
	end
	
	-- SECURITY: Validate origin position is near player (anti-wallhack)
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local distanceFromPlayer = (origin - humanoidRootPart.Position).Magnitude
			-- Use configurable max distance from GameConfig
			local maxDistance = 15 -- Default fallback
			if GameConfig.Security then
				maxDistance = GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE or 15
			else
				warn("[WeaponService] GameConfig.Security not found, using default MAX_WEAPON_FIRE_DISTANCE: " .. maxDistance)
			end
			if distanceFromPlayer > maxDistance then
				warn("[WeaponService] SECURITY: Rejected shot from " .. player.Name .. 
					" - origin too far from player (" .. string.format("%.1f", distanceFromPlayer) .. " studs)")
				return
			end

			-- ✅ SECURITY: Validate direction is roughly aligned with player look vector (dot-product threshold)
			-- This reduces spoofing by ensuring shots come from roughly where player is facing
			-- NOTE: In first-person mode, we use HumanoidRootPart for more reliable validation
			--       since the head may be rotated differently than the camera
			local referenceVector = humanoidRootPart.CFrame.LookVector
			local dotProduct = direction:Dot(referenceVector)
			
			-- Allow shots within a reasonable angle of look direction
			-- Default -0.5 allows ~120 degree cone (shots roughly in front half of player)
			-- This prevents backward shots while allowing FPS camera freedom
			-- For stricter validation, configure MIN_WEAPON_FIRE_DOT_PRODUCT to 0.3 (70 degrees) or higher
			local minDotProduct = -0.5  -- Allow wide arc for FPS gameplay
			if GameConfig.Security and GameConfig.Security.MIN_WEAPON_FIRE_DOT_PRODUCT then
				minDotProduct = GameConfig.Security.MIN_WEAPON_FIRE_DOT_PRODUCT
			end
			
			if dotProduct < minDotProduct then
				-- Temporary debug logging to diagnose direction issues
				warn(string.format("[WeaponService] SECURITY: Rejected shot from %s - direction not aligned with look vector (dot: %.2f, threshold: %.2f)", 
					player.Name, dotProduct, minDotProduct))
				warn(string.format("  Origin: (%.1f, %.1f, %.1f), Direction: (%.2f, %.2f, %.2f)", 
					origin.X, origin.Y, origin.Z, direction.X, direction.Y, direction.Z))
				warn(string.format("  HRP Position: (%.1f, %.1f, %.1f), HRP LookVector: (%.2f, %.2f, %.2f)",
					humanoidRootPart.Position.X, humanoidRootPart.Position.Y, humanoidRootPart.Position.Z,
					referenceVector.X, referenceVector.Y, referenceVector.Z))
				return
			end
		end
	end

	local state = self.playerWeaponState[player.UserId]
	if not state then
		return
	end

	local now = tick()
	if now - (state.lastShot or 0) < stats.FireRate then
		return -- still on cooldown
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

	state.lastShot = now

	local rayDirection = direction.Unit * stats.Range
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin, rayDirection, params)
	if result then
		local hitInstance = result.Instance
		local hitModel = hitInstance and hitInstance:FindFirstAncestorOfClass("Model")

		if hitModel then
			-- Check if hit a zombie
			if hitModel:GetAttribute("IsZombie") then
				self:damageZombie(hitModel, player, stats, weaponId)
				self.remoteEvents.WeaponHitConfirm:FireClient(player, {
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
						self.remoteEvents.WeaponHitConfirm:FireClient(player, {
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

	self.playerManager:addCurrency(player, reward + bonus)
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
return WeaponService