--!strict
-- @ScriptType: ModuleScript
-- RemoteEventsBootstrap
--
-- Server-owned bootstrap for ReplicatedStorage.RemoteEvents and its canonical RemoteEvent instances.
-- Clients must never create/rename these. This module is the single source of truth.
--
-- Behaviour:
-- - Ensures ReplicatedStorage.RemoteEvents (Folder) exists
-- - Ensures a fixed list of RemoteEvents exist (and are RemoteEvent instances)
-- - Cleans up name conflicts + duplicates safely
-- - Idempotent: safe to require multiple times

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LOG_PREFIX = "[RemoteEventsBootstrap]"

-- Canonical list (keep names stable)
local NAMES: {string} = {
	"AnimationFire",
	"AnimationSprint",
	"AnimationADS",
	"AnimationFireReplicate",
	"AnimationSprintReplicate",
	"AnimationADSReplicate",
}

local function warnf(fmt: string, ...: any)
	warn(string.format("%s "..fmt, LOG_PREFIX, ...))
end

local function printf(fmt: string, ...: any)
	print(string.format("%s "..fmt, LOG_PREFIX, ...))
end

local function isFolder(inst: Instance?): boolean
	return inst ~= nil and inst:IsA("Folder")
end

local function getOrCreateRemoteEventsFolder(): Folder
	-- Handle duplicates by merging into one canonical Folder.
	local matches: {Instance} = {}
	for _, child in ipairs(ReplicatedStorage:GetChildren()) do
		if child.Name == "RemoteEvents" then
			table.insert(matches, child)
		end
	end

	local canonical: Folder?

	-- Prefer an existing Folder
	for _, inst in ipairs(matches) do
		if inst:IsA("Folder") then
			canonical = inst
			break
		end
	end

	-- If none are folders, destroy conflicts and create a folder
	if not canonical then
		for _, inst in ipairs(matches) do
			inst:Destroy()
		end
		local f = Instance.new("Folder")
		f.Name = "RemoteEvents"
		f.Parent = ReplicatedStorage
		canonical = f
	end

	-- Merge any duplicate "RemoteEvents" containers into canonical
	for _, inst in ipairs(matches) do
		if inst ~= canonical then
			-- If it's a folder, move children; otherwise just destroy it
			if inst:IsA("Folder") then
				for _, kid in ipairs(inst:GetChildren()) do
					kid.Parent = canonical
				end
			end
			inst:Destroy()
		end
	end

	return canonical :: Folder
end

local function ensureSingleRemoteEvent(folder: Folder, name: string): (RemoteEvent, boolean, boolean)
	-- Returns: (remoteEvent, created, replacedOrDeduped)
	local candidates: {Instance} = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == name then
			table.insert(candidates, child)
		end
	end

	local kept: RemoteEvent? = nil
	local replacedOrDeduped = false

	-- Keep the first RemoteEvent, destroy anything else with same name
	for _, inst in ipairs(candidates) do
		if inst:IsA("RemoteEvent") then
			if kept == nil then
				kept = inst
			else
				inst:Destroy()
				replacedOrDeduped = true
			end
		else
			inst:Destroy()
			replacedOrDeduped = true
		end
	end

	if kept == nil then
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
		return ev, true, replacedOrDeduped
	end

	return kept, false, replacedOrDeduped
end

-- Server-only guard
if not RunService:IsServer() then
	error(LOG_PREFIX .. " must be required from the server. Clients must not bootstrap RemoteEvents.")
end

local folder = getOrCreateRemoteEventsFolder()

local created = 0
local existing = 0
local replaced = 0

local remotesByName: {[string]: RemoteEvent} = {}

for _, name in ipairs(NAMES) do
	local ev, wasCreated, wasReplaced = ensureSingleRemoteEvent(folder, name)
	remotesByName[name] = ev

	if wasCreated then
		created += 1
	else
		existing += 1
	end

	if wasReplaced then
		replaced += 1
	end
end

printf("Animation remotes ready. Created: %d | Existing: %d | Replaced/Deduped: %d | Total: %d", created, existing, replaced, #NAMES)

-- Optional: expose canonical names too, for other systems to reference safely.
return {
	Folder = folder,
	Names = NAMES,
	Remotes = remotesByName,
}
