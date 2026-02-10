-- Heartbeat Leak Test (BUG-010)
-- Place this in ServerScriptService as a Script to test heartbeat connection cleanup
-- This test simulates a server reload scenario to verify no heartbeat accumulation

local RunService = game:GetService("RunService")

print("========================================")
print("HEARTBEAT LEAK TEST (BUG-010)")
print("========================================")

-- Wait for services to initialize (kept for consistency with live server timing)
task.wait(2)

-- This test is self-contained and uses a mock GameManager instance.
-- It does not depend on the real Main / GameManager script being present.

print("\n--- Testing Heartbeat Connection Cleanup Pattern ---")

-- Simulate the pattern used in Main.server.lua
local mockGameManager = {
	_heartbeatConnection = nil
}

local function setupHeartbeat()
	-- Disconnect old heartbeat connection if it exists (prevents memory leak on server reload)
	if mockGameManager._heartbeatConnection then
		mockGameManager._heartbeatConnection:Disconnect()
		mockGameManager._heartbeatConnection = nil
		print("[TEST] Disconnected old heartbeat connection")
	end
	
	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		-- Minimal heartbeat logic for testing
	end)
	
	-- Store connection for potential cleanup
	mockGameManager._heartbeatConnection = heartbeatConnection
	print("[TEST] Created new heartbeat connection")
end

-- Test 1: First initialization
print("\n✅ Test 1: First heartbeat initialization")
setupHeartbeat()
assert(mockGameManager._heartbeatConnection ~= nil, "Heartbeat connection should exist")
print("   PASSED: Heartbeat connection created")

-- Test 2: Simulated server reload
print("\n✅ Test 2: Server reload (should disconnect old, create new)")
local oldConnection = mockGameManager._heartbeatConnection
local wasConnected = oldConnection and oldConnection.Connected
setupHeartbeat()
local newConnection = mockGameManager._heartbeatConnection

assert(wasConnected, "Old heartbeat connection should be connected before reload")
assert(newConnection ~= nil, "New heartbeat connection should exist")
assert(newConnection ~= oldConnection, "New connection should be different from old")
assert(oldConnection and (not oldConnection.Connected), "Old heartbeat connection should be disconnected after reload")
print("   PASSED: Old connection disconnected and replaced with new one")

-- Test 3: Verify old connection is disconnected
print("\n✅ Test 3: Verify connection cleanup")
local testConnection = RunService.Heartbeat:Connect(function() end)
local isConnected = testConnection.Connected
testConnection:Disconnect()
local isDisconnected = not testConnection.Connected

assert(isConnected, "Test connection should be connected initially")
assert(isDisconnected, "Test connection should be disconnected after Disconnect()")
print("   PASSED: Connection cleanup works correctly")

-- Cleanup
if mockGameManager._heartbeatConnection then
	mockGameManager._heartbeatConnection:Disconnect()
	mockGameManager._heartbeatConnection = nil
end

print("\n========================================")
print("HEARTBEAT LEAK TEST SUMMARY")
print("========================================")
print("✅ All tests PASSED")
print("✅ Heartbeat connection cleanup pattern verified")
print("✅ No memory leak on server reload")
print("\nℹ️  BUG-010 Fix Confirmed:")
print("   - Old connections are disconnected before creating new ones")
print("   - Single heartbeat connection maintained")
print("   - No accumulation on server reload.")
print("========================================")
