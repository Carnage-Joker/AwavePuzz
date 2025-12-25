-- DEV/TEST SCRIPT - Only runs in Studio
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
return
end

-- FixSystemAmmo.lua
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

task.wait(2)

print("=== FIXING AMMO SYSTEM ===")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure RemoteEvents exist
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Create AmmoUpdate event if missing
local ammoUpdateEvent = remoteEvents:FindFirstChild("AmmoUpdate")
if not ammoUpdateEvent then
    ammoUpdateEvent = Instance.new("RemoteEvent")
    ammoUpdateEvent.Name = "AmmoUpdate"
    ammoUpdateEvent.Parent = remoteEvents
    print("Created AmmoUpdate event")
end

-- Function to send ammo to player
local function sendAmmoToPlayer(player)
    if not player or not player.Parent then return end
    
    ammoUpdateEvent:FireClient(player, {
        weaponId = "Pistol",
        current = 12,
        reserve = 48,
        max = 12
    })
    
    print("Sent ammo update to", player.Name)
end

-- Send ammo to all current players
for _, player in ipairs(Players:GetPlayers()) do
    sendAmmoToPlayer(player)
end

-- Send ammo to new players
Players.PlayerAdded:Connect(function(player)
    task.wait(3) -- Wait for character to load
    sendAmmoToPlayer(player)
end)

print("=== AMMO SYSTEM FIXED ===")
