-- Title Screen First Load - Setup Validator
-- Run this script in Roblox Studio Command Bar to validate setup
-- This checks that all required files and settings are in place

print("========================================")
print("Title Screen First Load - Setup Validator")
print("========================================")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local checksPassed = 0
local checksFailed = 0
local warnings = 0

local function pass(message)
	print("✅ PASS: " .. message)
	checksPassed = checksPassed + 1
end

local function fail(message)
	warn("❌ FAIL: " .. message)
	checksFailed = checksFailed + 1
end

local function warning(message)
	warn("⚠️ WARN: " .. message)
	warnings = warnings + 1
end

print("\n=== CHECKING SERVER SETUP ===\n")

-- Check CharacterAutoLoads
if Players.CharacterAutoLoads == false then
	pass("Players.CharacterAutoLoads is false")
else
	fail("Players.CharacterAutoLoads should be false (currently: " .. tostring(Players.CharacterAutoLoads) .. ")")
	warning("This might be because the script hasn't run yet. Start the game to verify.")
end

-- Check Main.server.lua exists
local mainServer = ServerScriptService:FindFirstChild("Main.server")
if mainServer then
	pass("Main.server.lua exists in ServerScriptService")
	
	-- Check for Phase 0 code (basic check)
	local source = mainServer.Source
	if source:find("CharacterAutoLoads") then
		pass("Main.server.lua contains CharacterAutoLoads setup")
	else
		fail("Main.server.lua does not contain CharacterAutoLoads setup")
	end
else
	fail("Main.server.lua not found in ServerScriptService")
end

-- Check GameManager
local gameManager = ServerScriptService:FindFirstChild("GameManager")
if gameManager then
	pass("GameManager.lua exists")
else
	fail("GameManager.lua not found in ServerScriptService")
end

print("\n=== CHECKING CLIENT SETUP ===\n")

-- Check Boot.client.lua exists
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if starterPlayerScripts then
	local bootClient = starterPlayerScripts:FindFirstChild("Boot.client")
	if bootClient then
		pass("Boot.client.lua exists in StarterPlayerScripts")
		
		-- Check for camera control code
		local source = bootClient.Source
		if source:find("CameraType") and source:find("Scriptable") then
			pass("Boot.client.lua contains camera control code")
		else
			fail("Boot.client.lua missing camera control code")
		end
	else
		fail("Boot.client.lua not found in StarterPlayerScripts")
	end
	
	-- Check ClientMain.client.lua is disabled
	local oldClientMain = starterPlayerScripts:FindFirstChild("ClientMain.client")
	if oldClientMain then
		fail("ClientMain.client.lua still exists (should be disabled/renamed)")
		warning("Rename to ClientMain.client.lua.disabled to prevent duplicate execution")
	else
		local disabledClientMain = starterPlayerScripts:FindFirstChild("ClientMain.client.lua.disabled")
		if disabledClientMain then
			pass("ClientMain.client.lua is disabled (renamed to .disabled)")
		else
			warning("ClientMain.client.lua not found (might be deleted, which is also OK)")
		end
	end
	
	-- Check ClientMainModule exists
	local clientMainModule = starterPlayerScripts:FindFirstChild("ClientMainModule")
	if clientMainModule then
		pass("ClientMainModule.lua exists")
	else
		fail("ClientMainModule.lua not found in StarterPlayerScripts")
	end
	
	-- Check TitleScreenUI
	local modulesFolder = starterPlayerScripts:FindFirstChild("Modules")
	if modulesFolder then
		local uiFolder = modulesFolder:FindFirstChild("UI")
		if uiFolder then
			local titleScreenUI = uiFolder:FindFirstChild("TitleScreenUI")
			if titleScreenUI then
				pass("TitleScreenUI.lua exists in Modules/UI")
			else
				fail("TitleScreenUI.lua not found in Modules/UI")
			end
		else
			fail("UI folder not found in Modules")
		end
	else
		fail("Modules folder not found in StarterPlayerScripts")
	end
else
	fail("StarterPlayerScripts not found in StarterPlayer")
end

print("\n=== CHECKING REMOTES ===\n")

-- Check RemoteRegistry
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if sharedFolder then
	local remotesFolder = sharedFolder:FindFirstChild("Remotes")
	if remotesFolder then
		local remoteRegistry = remotesFolder:FindFirstChild("RemoteRegistry")
		if remoteRegistry then
			pass("RemoteRegistry module exists")
			
			-- Check for ClientReady in REMOTE_DEFINITIONS (basic check)
			local source = remoteRegistry.Source
			if source:find("ClientReady") then
				pass("RemoteRegistry contains ClientReady remote definition")
			else
				fail("RemoteRegistry does not contain ClientReady remote")
			end
		else
			fail("RemoteRegistry module not found in Shared/Remotes")
		end
	else
		fail("Remotes folder not found in Shared")
	end
	
	-- Check GameConfig
	local gameConfig = sharedFolder:FindFirstChild("GameConfig")
	if gameConfig then
		pass("GameConfig module exists")
		
		-- Check SHOW_TITLE_SCREEN flag
		local source = gameConfig.Source
		if source:find("SHOW_TITLE_SCREEN") then
			pass("GameConfig contains SHOW_TITLE_SCREEN flag")
		else
			warning("GameConfig missing SHOW_TITLE_SCREEN flag (title screen might not show)")
		end
	else
		fail("GameConfig module not found in Shared")
	end
else
	fail("Shared folder not found in ReplicatedStorage")
end

-- Check RemoteEvents folder (will be created at runtime)
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEventsFolder then
	pass("RemoteEvents folder exists in ReplicatedStorage")
	
	-- Check for ClientReady remote (if server has run)
	local clientReadyRemote = remoteEventsFolder:FindFirstChild("ClientReady")
	if clientReadyRemote then
		pass("ClientReady remote event exists")
	else
		warning("ClientReady remote not found (will be created when server starts)")
	end
else
	warning("RemoteEvents folder not found (will be created when server starts)")
end

print("\n=== CHECKING DOCUMENTATION ===\n")

-- Check for documentation files (in workspace root)
local workspace = game:GetService("Workspace")
-- Note: Can't directly check filesystem from script, so skip this check
warning("Documentation check skipped (check manually for TITLE_SCREEN_FIRST_LOAD_*.md files)")

print("\n========================================")
print("VALIDATION SUMMARY")
print("========================================")
print(string.format("✅ Passed: %d", checksPassed))
print(string.format("❌ Failed: %d", checksFailed))
print(string.format("⚠️ Warnings: %d", warnings))
print("========================================")

if checksFailed == 0 then
	print("\n🎉 All critical checks passed!")
	print("The Title Screen First Load implementation appears to be set up correctly.")
	print("\nNext steps:")
	print("1. Click Play in Roblox Studio")
	print("2. Verify you see the title screen FIRST (no map/character flash)")
	print("3. Press any key to continue")
	print("4. Verify smooth transition to lobby")
	print("\nSee TITLE_SCREEN_FIRST_LOAD_TEST_GUIDE.md for full testing instructions.")
else
	print("\n⚠️ Some checks failed. Please review the errors above.")
	print("The implementation may not work correctly until these issues are resolved.")
end

if warnings > 0 then
	print("\n⚠️ Warnings detected. These may be expected (e.g., remotes created at runtime).")
	print("Review warnings and verify they are expected.")
end
