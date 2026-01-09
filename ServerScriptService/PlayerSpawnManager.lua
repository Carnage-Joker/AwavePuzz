-- @ScriptType: ModuleScript
-- PlayerSpawnManager.lua
-- Manages player character spawning:
-- - waiting state: lobby (frozen + optionally hidden)
-- - map state: spawn near BaseCamp (unfrozen + visible)
-- Ensures state is set BEFORE LoadCharacter().

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LobbySetup = require(script.Parent.LobbySetup)

local PlayerSpawnManager = {}
PlayerSpawnManager.__index = PlayerSpawnManager

local MAP_OFFSET = Vector3.new(5000, 0, 0)
local LOBBY_POS = LobbySetup.LOBBY_POSITION

-- Ground-safe tuning
local RAYCAST_HEIGHT = 300
local RAYCAST_DEPTH = 800
local SPAWN_CLEARANCE_Y = 4         -- stand a little above hit surface
local MIN_VALID_Y = -1000           -- safety: if we hit nothing and y is awful, bump up
local MAX_GROUND_SNAP_TRIES = 8

-- Exclusion tuning
local MAX_EXCLUSION_REROLLS = 12
local EXCLUSION_PUSH_OUT = 18       -- if we detect we're inside, we try to push out a bit

function PlayerSpawnManager.new()
	local self = setmetatable({}, PlayerSpawnManager)

	self.playersSpawnedOnMap = {} -- userId -> boolean
	self.playerSpawnState = {}    -- userId -> "waiting" | "map"
	self.gameManager = nil

	self.playerConnections = {}   -- userId -> RBXScriptConnection
	self._charHandling = {}       -- userId -> boolean

	-- spawn bag (shuffled round-robin across Spawn1..SpawnN)
	self._spawnBag = nil
	self._spawnBagIndex = 1
	self._spawnBagSource = nil

	return self
end

function PlayerSpawnManager:setGameManager(gameManager)
	self.gameManager = gameManager
end

local function setAttrIfNil(inst, key, value)
	if inst:GetAttribute(key) == nil then
		inst:SetAttribute(key, value)
	end
end

local function setCharacterHidden(character, hidden)
	if not character then return end

	for _, inst in ipairs(character:GetDescendants()) do
		if inst:IsA("BasePart") then
			if hidden then
				setAttrIfNil(inst, "PreHideTransparency", inst.Transparency)
				setAttrIfNil(inst, "PreHideCanCollide", inst.CanCollide)
				setAttrIfNil(inst, "PreHideCanTouch", inst.CanTouch)
				setAttrIfNil(inst, "PreHideCanQuery", inst.CanQuery)

				inst.Transparency = 1
				inst.CanCollide = false
				inst.CanTouch = false
				inst.CanQuery = false
			else
				local preT = inst:GetAttribute("PreHideTransparency")
				if typeof(preT) == "number" then inst.Transparency = preT end

				local preC = inst:GetAttribute("PreHideCanCollide")
				if typeof(preC) == "boolean" then inst.CanCollide = preC end

				local preTouch = inst:GetAttribute("PreHideCanTouch")
				if typeof(preTouch) == "boolean" then inst.CanTouch = preTouch end

				local preQ = inst:GetAttribute("PreHideCanQuery")
				if typeof(preQ) == "boolean" then inst.CanQuery = preQ end
			end
		elseif inst:IsA("Decal") then
			if hidden then
				setAttrIfNil(inst, "PreHideTransparency", inst.Transparency)
				inst.Transparency = 1
			else
				local pre = inst:GetAttribute("PreHideTransparency")
				if typeof(pre) == "number" then inst.Transparency = pre end
			end
		end
	end
end

local function freezeCharacter(character, frozen)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")

	if hrp then
		hrp.Anchored = frozen
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	if hum then
		hum.PlatformStand = frozen
	end
end

-- ---------- Exclusion Volumes ----------

local function getBaseCampExclusionParts()
	-- Preferred: Workspace.BaseCamp.ExclusionVolumes
	local baseCamp = Workspace:FindFirstChild("BaseCamp")
	if baseCamp then
		local folder = baseCamp:FindFirstChild("ExclusionVolumes")
		if folder and folder:IsA("Folder") then
			local parts = {}
			for _, c in ipairs(folder:GetChildren()) do
				if c:IsA("BasePart") then table.insert(parts, c) end
			end
			if #parts > 0 then return parts end
		end
	end

	-- Fallback: any ExclusionVolumes folder in the map
	local anyFolder = Workspace:FindFirstChild("ExclusionVolumes", true)
	if anyFolder and anyFolder:IsA("Folder") then
		local parts = {}
		for _, c in ipairs(anyFolder:GetChildren()) do
			if c:IsA("BasePart") then table.insert(parts, c) end
		end
		if #parts > 0 then return parts end
	end

	return {}
end

local function pointInsidePartVolume(point, part)
	-- Works for rotated boxes too
	local localPos = part.CFrame:PointToObjectSpace(point)
	local half = part.Size * 0.5
	return (math.abs(localPos.X) <= half.X)
		and (math.abs(localPos.Y) <= half.Y)
		and (math.abs(localPos.Z) <= half.Z)
end

local function isInAnyExclusion(point, exclusionParts)
	for _, p in ipairs(exclusionParts) do
		if p and p.Parent and pointInsidePartVolume(point, p) then
			return true, p
		end
	end
	return false, nil
end

local function pushPointOutOfVolume(point, part)
	-- crude but effective: push away from part center on XZ
	local center = part.Position
	local dir = (point - center)
	dir = Vector3.new(dir.X, 0, dir.Z)

	if dir.Magnitude < 0.01 then
		dir = Vector3.new(1, 0, 0)
	else
		dir = dir.Unit
	end

	return point + (dir * EXCLUSION_PUSH_OUT)
end

-- ---------- Ground-safe spawn (raycast snap) ----------

local function groundSnapPosition(pos, ignoreInstances)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = false
	rayParams.FilterDescendantsInstances = ignoreInstances or {}

	-- cast from above downwards
	local origin = pos + Vector3.new(0, RAYCAST_HEIGHT, 0)
	local dir = Vector3.new(0, -RAYCAST_DEPTH, 0)

	local hit = Workspace:Raycast(origin, dir, rayParams)
	if hit and hit.Position then
		return Vector3.new(pos.X, hit.Position.Y + SPAWN_CLEARANCE_Y, pos.Z), true
	end

	-- no hit: keep xz but bump y to something sane
	local safeY = pos.Y
	if safeY < MIN_VALID_Y then safeY = 30 end
	return Vector3.new(pos.X, safeY, pos.Z), false
end

function PlayerSpawnManager:onPlayerAdded(player)
	print(string.format("[PlayerSpawnManager] Player %s added, preparing spawn management", player.Name))

	self.playerSpawnState[player.UserId] = self.playerSpawnState[player.UserId] or "waiting"
	self.playersSpawnedOnMap[player.UserId] = self.playersSpawnedOnMap[player.UserId] or false

	if self.playerConnections[player.UserId] then
		self.playerConnections[player.UserId]:Disconnect()
	end

	self.playerConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
		self:onCharacterAdded(player, character)
	end)

	if player.Character then
		self:onCharacterAdded(player, player.Character)
	end
end

function PlayerSpawnManager:onCharacterAdded(player, character)
	if not player or not character then return end
	if self._charHandling[player.UserId] then return end
	self._charHandling[player.UserId] = true

	local state = self.playerSpawnState[player.UserId] or "waiting"

	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		warn(string.format("[PlayerSpawnManager] Failed to get HumanoidRootPart for %s", player.Name))
		self._charHandling[player.UserId] = nil
		return
	end

	if state == "waiting" then
		hrp.CFrame = CFrame.new(LOBBY_POS)
		freezeCharacter(character, true)
		setCharacterHidden(character, true)
		print(string.format("[PlayerSpawnManager] %s -> LOBBY (frozen/hidden)", player.Name))

	elseif state == "map" then
		local pos = self:getMapSpawnPosition()
		hrp.CFrame = CFrame.new(pos)

		setCharacterHidden(character, false)
		freezeCharacter(character, false)

		print(string.format("[PlayerSpawnManager] %s -> MAP (%s)", player.Name, tostring(pos)))
	end

	self._charHandling[player.UserId] = nil
end

function PlayerSpawnManager:keepPlayerInLobby(player)
	if not player then return end

	self.playerSpawnState[player.UserId] = "waiting"
	self.playersSpawnedOnMap[player.UserId] = false

	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(LOBBY_POS)
		end
		freezeCharacter(player.Character, true)
		setCharacterHidden(player.Character, true)
	end
end

function PlayerSpawnManager:spawnPlayerOnMap(player)
	if not player then return end

	-- MUST set state before LoadCharacter()
	self.playerSpawnState[player.UserId] = "map"
	self.playersSpawnedOnMap[player.UserId] = true

	player:LoadCharacter()
end

function PlayerSpawnManager:spawnAllPlayersOnMap()
	for _, player in ipairs(Players:GetPlayers()) do
		if not self.playersSpawnedOnMap[player.UserId] then
			self:spawnPlayerOnMap(player)
		else
			self.playerSpawnState[player.UserId] = "map"
		end
	end
end

function PlayerSpawnManager:getMapSpawnPosition()
	-- Exclusions (base-camp / map volumes)
	local exclusionParts = getBaseCampExclusionParts()

	-- Ignore list for raycasts: characters + lobby + basecamp model so we prefer terrain/ground
	local ignore = {}
	do
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then table.insert(ignore, p.Character) end
		end
		local lobby = Workspace:FindFirstChild("LobbyArea")
		if lobby then table.insert(ignore, lobby) end
		local baseCamp = Workspace:FindFirstChild("BaseCamp")
		if baseCamp then table.insert(ignore, baseCamp) end
	end

	-- 1) Prefer explicit per-map player spawns:
	--    SpawnPoints.PlayerSpawns.Spawn1..SpawnN (or Spawn<number>) inside the loaded map model.
	local function findPlayerSpawnsContainer()
		-- First, try to find spawn points within the ActiveMap (preferred)
		local activeMap = Workspace:FindFirstChild("ActiveMap")
		if activeMap then
			local spawnPoints = activeMap:FindFirstChild("SpawnPoints")
			if spawnPoints then
				local playerSpawns = spawnPoints:FindFirstChild("PlayerSpawns")
				if playerSpawns then
					return playerSpawns
				end
			end

			-- Check for PlayerSpawns directly under ActiveMap
			local playerSpawnsInMap = activeMap:FindFirstChild("PlayerSpawns")
			if playerSpawnsInMap then
				return playerSpawnsInMap
			end
		end

		-- Fallback: search anywhere in Workspace (for compatibility)
		local spawnPoints = Workspace:FindFirstChild("SpawnPoints", true)
		if spawnPoints then
			local playerSpawns = spawnPoints:FindFirstChild("PlayerSpawns")
			if playerSpawns then
				return playerSpawns
			end
		end

		local playerSpawnsAny = Workspace:FindFirstChild("PlayerSpawns", true)
		if playerSpawnsAny then
			return playerSpawnsAny
		end

		return nil
	end

	local function buildSpawnBag(container)
		local list = {}
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("BasePart") then
				local n = tonumber(string.match(child.Name, "^Spawn(%d+)$"))
				if n then
					table.insert(list, { idx = n, part = child })
				end
			end
		end
		if #list == 0 then return nil end

		table.sort(list, function(a, b) return a.idx < b.idx end)

		local parts = {}
		for i = 1, #list do parts[i] = list[i].part end

		-- Fisher-Yates shuffle
		for i = #parts, 2, -1 do
			local j = math.random(1, i)
			parts[i], parts[j] = parts[j], parts[i]
		end

		return parts
	end

	local function pickFromBag()
		local playerSpawnsContainer = findPlayerSpawnsContainer()
		if not playerSpawnsContainer then 
			print("[PlayerSpawnManager] No PlayerSpawns container found, using fallback")
			return nil 
		end

		if self._spawnBagSource ~= playerSpawnsContainer or not self._spawnBag or #self._spawnBag == 0 then
			self._spawnBag = buildSpawnBag(playerSpawnsContainer)
			self._spawnBagIndex = 1
			self._spawnBagSource = playerSpawnsContainer
			print(string.format("[PlayerSpawnManager] Built spawn bag with %d spawn points", self._spawnBag and #self._spawnBag or 0))
		end

		if not self._spawnBag or #self._spawnBag == 0 then 
			warn("[PlayerSpawnManager] Spawn bag is empty after building")
			return nil 
		end

		if self._spawnBagIndex > #self._spawnBag then
			for i = #self._spawnBag, 2, -1 do
				local j = math.random(1, i)
				self._spawnBag[i], self._spawnBag[j] = self._spawnBag[j], self._spawnBag[i]
			end
			self._spawnBagIndex = 1
		end

		local part = self._spawnBag[self._spawnBagIndex]
		self._spawnBagIndex += 1
		if part and part:IsA("BasePart") then
			return part.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
		end
		return nil
	end

	local function resolveCandidate(candidate)
		if not candidate then return nil end

		-- Exclusion rerolls / push-outs first (on XZ), then ground snap
		local pos = candidate
		for _ = 1, MAX_EXCLUSION_REROLLS do
			local inside, which = isInAnyExclusion(pos, exclusionParts)
			if not inside then break end

			-- try push out + small random jitter
			pos = pushPointOutOfVolume(pos, which)
			pos = pos + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
		end

		-- Ground snap attempts (sometimes first ray hits something weird; re-try with slight jitters)
		local snapped = pos
		for _ = 1, MAX_GROUND_SNAP_TRIES do
			local gs, hit = groundSnapPosition(snapped, ignore)
			snapped = gs

			-- after snap, ensure we are STILL not inside exclusion (since Y changes + volumes could be tall)
			local inside = isInAnyExclusion(snapped, exclusionParts)
			if not inside then
				return snapped
			end

			-- if still inside, jitter and retry
			snapped = snapped + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
			if not hit then
				snapped = snapped + Vector3.new(0, 25, 0)
			end
		end

		return snapped
	end

	-- Try explicit spawn bag first
	do
		for _ = 1, 6 do
			local c = pickFromBag()
			if c then
				local final = resolveCandidate(c)
				if final then return final end
			end
		end
	end

	-- 2) Fallback: Prefer BaseCamp spawn if present (but still respects exclusion + ground)
	do
		local baseCamp = Workspace:FindFirstChild("BaseCamp")
		if baseCamp then
			print("[PlayerSpawnManager] Found BaseCamp, checking for spawn points")
			local ref = baseCamp:FindFirstChild("BaseCampSpawn")
			if ref and ref:IsA("BasePart") then
				local c = ref.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
				local final = resolveCandidate(c)
				if final then 
					print("[PlayerSpawnManager] Using BaseCampSpawn position")
					return final 
				end
			end

			local primary = baseCamp.PrimaryPart
			if primary then
				local c = primary.Position + Vector3.new(math.random(-18, 18), 0, math.random(-18, 18))
				local final = resolveCandidate(c)
				if final then 
					print("[PlayerSpawnManager] Using BaseCamp PrimaryPart position")
					return final 
				end
			end
		else
			warn("[PlayerSpawnManager] BaseCamp not found in Workspace, using hard fallback")
		end
	end

	-- 3) Hard fallback: map offset above ground, then snap
	local fallback = MAP_OFFSET + Vector3.new(math.random(-50, 50), 40, math.random(-50, 50))
	return resolveCandidate(fallback) or (MAP_OFFSET + Vector3.new(0, 10, 0))
end

function PlayerSpawnManager:resetForNewRound()
	self.playersSpawnedOnMap = {}
	for userId, _ in pairs(self.playerSpawnState) do
		self.playerSpawnState[userId] = "waiting"
	end

	self._spawnBag = nil
	self._spawnBagIndex = 1
	self._spawnBagSource = nil
end

-- Called when a new map is loaded to clear cached spawn points
function PlayerSpawnManager:onMapLoaded()
	print("[PlayerSpawnManager] Map loaded, clearing spawn bag cache")
	self._spawnBag = nil
	self._spawnBagIndex = 1
	self._spawnBagSource = nil
end

function PlayerSpawnManager:onPlayerRemoving(player)
	if not player then return end

	self.playersSpawnedOnMap[player.UserId] = nil
	self.playerSpawnState[player.UserId] = nil
	self._charHandling[player.UserId] = nil

	local conn = self.playerConnections[player.UserId]
	if conn then
		conn:Disconnect()
	end
	self.playerConnections[player.UserId] = nil
end

function PlayerSpawnManager:hasPlayerSpawnedOnMap(player)
	return self.playersSpawnedOnMap[player.UserId] or false
end

function PlayerSpawnManager:getPlayerSpawnState(player)
	return self.playerSpawnState[player.UserId] or "waiting"
end

return PlayerSpawnManager
