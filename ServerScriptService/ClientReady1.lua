-- @ScriptType: Script

-- @ScriptType: Script
-- ClientReady.server.lua
-- Creates RemoteEvents.ClientReady and records per-player readiness.
-- Use this instead of waiting on PlayerGui:WaitForChild("ClientReady") (which can infinite-yield).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure RemoteEvents folder exists
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

-- Ensure ClientReady event exists
local evt = remoteEvents:FindFirstChild("ClientReady")
if not evt then
	evt = Instance.new("RemoteEvent")
	evt.Name = "ClientReady"
	evt.Parent = remoteEvents
end

local readyByUserId = {}

evt.OnServerEvent:Connect(function(player)
	if not player then return end
	readyByUserId[player.UserId] = true
	-- print(string.format("[ClientReady] %s is ready", player.Name))
end)

Players.PlayerRemoving:Connect(function(player)
	if not player then return end
	readyByUserId[player.UserId] = nil
end)

-- Optional global helper for other server scripts/modules
_G.IsClientReady = function(player)
	return player and readyByUserId[player.UserId] == true
end

-- Optional: a safe wait helper with timeout
_G.WaitForClientReady = function(player, timeoutSeconds)
	timeoutSeconds = timeoutSeconds or 10
	local start = os.clock()
	while not (_G.IsClientReady and _G.IsClientReady(player)) do
		if os.clock() - start > timeoutSeconds then
			return false
		end
		task.wait(0.1)
	end
	return true
end
