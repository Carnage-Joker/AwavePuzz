-- safe_fire_client_test.lua
-- Unit test for RemoteRegistry.SafeFireClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== SafeFireClient unit test ===")

local RemotesFolder = ReplicatedStorage.Shared:WaitForChild("Remotes", 5)
local RemoteRegistry = require(RemotesFolder:WaitForChild("RemoteRegistry", 5))
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
local testEvent = remotes:FindFirstChild("_Test_SafeFire") or Instance.new("RemoteEvent")
testEvent.Name = "_Test_SafeFire"
if not testEvent.Parent then
	testEvent.Parent = remotes
end

local function assertEquals(a, b, msg)
	if a ~= b then
		warn("ASSERT FAIL: " .. tostring(msg) .. " (", tostring(a), " ~= ", tostring(b), ")")
		return false
	end
	print("ASSERT PASS: " .. tostring(msg))
	return true
end

-- Test 1: nil player should return false and not error
local ok, result = pcall(function()
	return RemoteRegistry.SafeFireClient(testEvent, nil, {hello = "world"})
end)
assertEquals(ok, true, "SafeFireClient should not throw when player is nil")
assertEquals(result, false, "SafeFireClient returns false for nil player")

-- Test 2: valid player should return true (requires at least one connected player)
local players = Players:GetPlayers()
if #players >= 1 then
	local player = players[1]
	local fired = RemoteRegistry.SafeFireClient(testEvent, player, {msg = "ok"})
	assertEquals(fired, true, "SafeFireClient returns true for connected player")
else
	print("SKIP: No players available to fully validate 'connected player' case")
end

print("=== SafeFireClient unit test complete ===")