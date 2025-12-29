--[[
	ClientMain.client.lua
	Main client initialization
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for character
player.CharacterAdded:Wait()

print("🎮 ClientMain starting...")

-- Import modules
local Remotes = require(ReplicatedStorage.Shared.Networking.Remotes)
local Controllers = StarterPlayer.StarterPlayerScripts.Controllers

-- Initialize controllers
local UIController = require(Controllers.UIController).new()
local OutfitController = require(Controllers.OutfitController).new()
local ActivityController = require(Controllers.ActivityController).new()
local TitleController = require(Controllers.TitleController).new()
local NotificationController = require(Controllers.NotificationController).new()

-- Initialize all controllers
UIController:initialize()
OutfitController:initialize(UIController)
ActivityController:initialize(UIController)
TitleController:initialize(UIController)
NotificationController:initialize()

print("✅ Client initialized")

-- Sync stats when received from server
local syncStatsEvent = Remotes.getEvent("SyncStats")
syncStatsEvent.OnClientEvent:Connect(function(stats)
	-- Update UI with new stats
	UIController:updateStats(stats)
end)

-- Request initial profile
task.wait(0.5)
local getProfileFunc = Remotes.getFunction("GetProfile")
local profile = getProfileFunc:InvokeServer()

if profile then
	print("Profile loaded on client")
	UIController:updateStats(profile.stats)
	UIController:updateCurrencies(profile.currencies)
end
