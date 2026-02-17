-- @ScriptType: Script
-- ClientReady.server.lua
-- Creates RemoteEvents.ClientReady and records per-player readiness.
-- Use this instead of waiting on PlayerGui:WaitForChild("ClientReady") (which can infinite-yield).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for RemoteEvents folder (created by RemoteRegistry during server boot)
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
	error("[ClientReady] CRITICAL: RemoteEvents folder not found after 10 seconds")
end

-- Get ClientReady event from RemoteRegistry
local evt = remoteEvents:WaitForChild("ClientReady", 5)
if not evt then
	error("[ClientReady] CRITICAL: ClientReady remote not found in RemoteRegistry")
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
