-- AmmoSystemFix.lua
-- Simple ammo system fix for testing
--
-- WHO RUNS: Server (test/debug only)
-- PURPOSE: Temporary fix script for ammo system debugging
-- REQUIRES: GameConfig.DEBUG = true to execute

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Early exit if DEBUG mode is not enabled
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
if not GameConfig.DEBUG then
	return
end

task.wait(5) -- Wait for everything to initialize

print("=== AMMO SYSTEM FIX ===")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure RemoteEvents are properly set up
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
    print("Created RemoteEvents folder")
end

-- Ensure required events exist
local requiredEvents = {
    "WeaponFire",
    "WeaponEquip", 
    "WeaponReload",
    "AmmoUpdate",
    "WeaponHitConfirm"
}

for _, eventName in ipairs(requiredEvents) do
    local event = remoteEvents:FindFirstChild(eventName)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = remoteEvents
        print("Created " .. eventName .. " event")
    end
end

-- Test ammo system with first player
local testPlayer = Players:GetPlayers()[1]
if testPlayer then
    print("Testing ammo system with:", testPlayer.Name)
    
    -- Send test ammo update
    local ammoUpdateEvent = remoteEvents:FindFirstChild("AmmoUpdate")
    if ammoUpdateEvent then
        ammoUpdateEvent:FireClient(testPlayer, {
            weaponId = "Pistol",
            current = 12,
            reserve = 48,
            max = 12
        })
        print("✅ Sent test ammo update")
    end
end

print("=== AMMO SYSTEM FIX COMPLETE ===")
task.wait(2)
script:Destroy()
