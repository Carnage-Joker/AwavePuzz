--!strict
-- @ScriptType: ModuleScript
-- RemoteEventsBootstrap
--
-- ⚠️⚠️⚠️ FULLY DEPRECATED - DO NOT USE ⚠️⚠️⚠️
-- This module has been completely replaced by RemoteRegistry (ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua)
-- Kept ONLY for backward compatibility with legacy code. Will be removed in a future version.
--
-- All remote creation should now happen through RemoteRegistry.initializeServer() during server boot.
-- See MainServerScript.legacy.lua Phase 1 for the proper initialization pattern.
--
-- DO NOT require this module in new code.
-- DO NOT add new functionality to this module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LOG_PREFIX = "[RemoteEventsBootstrap]"

-- Server-only guard
if not RunService:IsServer() then
	error(LOG_PREFIX .. " must be required from the server. Clients must not bootstrap RemoteEvents.")
end

-- Module exposes an explicit initializer; auto-initialization on require is kept for backward compatibility
local RemoteEventsBootstrap = {}
RemoteEventsBootstrap.initialized = false

-- Canonical list (keep names stable for backward compatibility)
local NAMES: {string} = {
	"AnimationFire",
	"AnimationSprint",
	"AnimationADS",
	"AnimationFireReplicate",
	"AnimationSprintReplicate",
	"AnimationADSReplicate",
}

local function printf(fmt: string, ...: any)
	print(string.format("%s "..fmt, LOG_PREFIX, ...))
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

--[[
	Initialize animation remotes
	This is now an explicit function instead of auto-executing code
	Idempotent: safe to call multiple times
]]
function RemoteEventsBootstrap.initialize()
	if RemoteEventsBootstrap.initialized then
		warn(LOG_PREFIX .. " Already initialized, skipping")
		return RemoteEventsBootstrap
	end
	
	print(LOG_PREFIX .. " [BOOT][SERVER] Initializing (DEPRECATED - use RemoteRegistry)")
	
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
	
	RemoteEventsBootstrap.initialized = true
	RemoteEventsBootstrap.Folder = folder
	RemoteEventsBootstrap.Names = NAMES
	RemoteEventsBootstrap.Remotes = remotesByName
	
	return RemoteEventsBootstrap
end

-- For backward compatibility with old code that just requires this module
-- Auto-initialize but warn that this is deprecated
RemoteEventsBootstrap.initialize()

return RemoteEventsBootstrap
