-- WeaponService.lua
-- Handles player weapon logic, raycast validation, and kill rewards
-- Features proper gun cloning, positioning on hand, weapon switching with cleanup,
-- and raycast firing in the direction the player is aiming


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

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
    Safely clones a gun model from ServerStorage.Guns.
    Returns the cloned Model (named "EquippedWeaponModel") or nil if anything is missing.
--]]
function WeaponService:cloneGunModel(gunId)
	-- Grab the Guns folder (once per call – cheap)
	local gunsFolder = ServerStorage:FindFirstChild("Guns")
	if not gunsFolder then
		warn("[WeaponService] Guns folder missing in ServerStorage")
		return nil
	end

	-- Resolve the model name from the weapon config (fallback to the id itself)
	local weaponConfig = WeaponConfig.getWeapon(gunId)
	local modelName = weaponConfig
		and (weaponConfig.ModelName or weaponConfig.Name)
		or gunId

	local template = gunsFolder:FindFirstChild(modelName)
	if not template then
		warn(string.format(
			"[WeaponService] Gun model '%s' not found in ServerStorage.Guns",
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
	self.playerWeaponState = {} -- userId -> state
	self.remoteEvents = {}
	self:setupRemoteEvents()
	return self
end

function WeaponService:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	local fireEvent = remoteEventsFolder:FindFirstChild("WeaponFire")
	if not fireEvent then
		fireEvent = Instance.new("RemoteEvent")
		fireEvent.Name = "WeaponFire"
		fireEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.WeaponFire = fireEvent

	local equipEvent = remoteEventsFolder:FindFirstChild("WeaponEquip")
	if not equipEvent then
		equipEvent = Instance.new("RemoteEvent")
		equipEvent.Name = "WeaponEquip"
		equipEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.WeaponEquip = equipEvent

	local hitEvent = remoteEventsFolder:FindFirstChild("WeaponHitConfirm")
	if not hitEvent then
		hitEvent = Instance.new("RemoteEvent")
		hitEvent.Name = "WeaponHitConfirm"
		hitEvent.Parent = remoteEventsFolder
	end
	self.remoteEvents.WeaponHitConfirm = hitEvent

	fireEvent.OnServerEvent:Connect(function(player, payload)
		self:handleWeaponFire(player, payload)
	end)

	equipEvent.OnServerEvent:Connect(function(player, weaponId)
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
		return
	end

	local weaponId = payload.weaponId
	local origin = payload.origin
	local direction = payload.direction
	local timestamp = payload.timestamp

	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end

	if direction.Magnitude < 0.001 then
		return
	end

	local equipped = self.playerManager:getEquippedWeapon(player)
	if not equipped or equipped ~= weaponId then
		return
	end

	local stats = self:getModifiedStats(player, weaponId)
	if not stats then
		return
	end

	local state = self.playerWeaponState[player.UserId]
	if not state then
		return
	end

	local now = tick()
	if now - (state.lastShot or 0) < stats.FireRate then
		return -- still on cooldown
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
					-- If allied, damage is prevented (friendly fire protection)
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
	
	-- Check if target died from this damage
	if humanoid.Health <= 0 and healthBefore > 0 then
		print(string.format("[WeaponService] PvP Kill: %s eliminated %s", 
			attackingPlayer.Name, targetPlayer.Name))
		
		-- Notify AllianceService of the kill for betrayal mechanics
		if self.allianceService and self.allianceService.onPlayerKilled then
			local callSuccess, callErr = pcall(function()
				self.allianceService:onPlayerKilled(targetPlayer, attackingPlayer)
			end)
			if not callSuccess then
				warn("[WeaponService] Error notifying AllianceService of kill: " .. tostring(callErr))
			end
		end
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
local ServerStorage = game:GetService("ServerStorage")  -- at top of file if not already

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
	-- 2️⃣  Clean up any previously‑equipped visual
	-- -----------------------------------------------------------------
	local old = character:FindFirstChild("EquippedWeaponModel")
	if old then old:Destroy() end

	-- Parent the new model to the character
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
