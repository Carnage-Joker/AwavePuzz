-- TestMapSystem.lua
-- Test script for validating the multi-map system
-- Run in Roblox Studio Command Bar: require(game.ServerStorage.DevOnly.TestMapSystem).runTests()

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.MapConfig)
local MapValidator = require(game.ServerScriptService.MapValidator)
local MapGenerator = require(ServerStorage.DevOnly.MapGenerator)

local TestMapSystem = {}

function TestMapSystem.testMapConfig()
	print("\n=== Testing MapConfig ===")
	
	-- Test getDefault
	local defaultId, defaultData = MapConfig.getDefault()
	if defaultId and defaultData then
		print("✓ getDefault() returned:", defaultId, "-", defaultData.Name)
	else
		warn("✗ getDefault() failed")
		return false
	end
	
	-- Test get
	local data = MapConfig.get("ResearchOutpost")
	if data then
		print("✓ get('ResearchOutpost') returned:", data.Name)
	else
		warn("✗ get('ResearchOutpost') failed")
		return false
	end
	
	-- Test all maps are defined
	local mapCount = 0
	for mapId, mapData in pairs(MapConfig.Maps) do
		mapCount = mapCount + 1
		print("  - Map:", mapId, "->", mapData.Name, "(Model:", mapData.Model .. ")")
	end
	print(string.format("✓ Total maps defined: %d", mapCount))
	
	return true
end

function TestMapSystem.testMapValidator()
	print("\n=== Testing MapValidator ===")
	
	-- Create a test map
	local testMap = Instance.new("Model")
	testMap.Name = "TestMap"
	
	-- Add ZombieSpawnPoints
	local zombieFolder = Instance.new("Folder")
	zombieFolder.Name = "ZombieSpawnPoints"
	zombieFolder.Parent = testMap
	
	-- Add insufficient spawns (should fail)
	for i = 1, 5 do
		local part = Instance.new("Part")
		part.Name = "Spawn_" .. i
		part.Parent = zombieFolder
	end
	
	local isValid, errors, warnings, counts = MapValidator.validateMapModel(testMap)
	if not isValid and #errors > 0 then
		print("✓ Validation correctly failed for map with 5 zombie spawns (min 8)")
		print("  Error:", errors[1])
	else
		warn("✗ Validation should have failed for insufficient spawns")
		return false
	end
	
	-- Add more spawns
	for i = 6, 10 do
		local part = Instance.new("Part")
		part.Name = "Spawn_" .. i
		part.Parent = zombieFolder
	end
	
	isValid, errors, warnings, counts = MapValidator.validateMapModel(testMap)
	if isValid then
		print("✓ Validation passed with 10 zombie spawns")
		print(string.format("  Counts: Zombie=%d, Resource=%d, Item=%d", 
			counts.zombieSpawns, counts.resourceSpawns, counts.itemSpawns))
	else
		warn("✗ Validation should have passed with 10 spawns")
		for _, error in ipairs(errors) do
			warn("  Error:", error)
		end
		return false
	end
	
	testMap:Destroy()
	return true
end

function TestMapSystem.testMapGeneration()
	print("\n=== Testing MapGenerator ===")
	
	-- Generate all maps
	local success = MapGenerator.generateAll()
	if not success then
		warn("✗ MapGenerator.generateAll() failed")
		return false
	end
	
	print("✓ Maps generated successfully")
	
	-- Verify maps exist
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("✗ Maps folder not found in ServerStorage")
		return false
	end
	
	local expectedMaps = {"ResearchOutpost", "Village", "Dockyards", "ResearchOutpost_Night"}
	for _, mapName in ipairs(expectedMaps) do
		local map = mapsFolder:FindFirstChild(mapName)
		if map then
			print("  ✓ Found map:", mapName)
			
			-- Validate the generated map
			local isValid, errors, warnings, counts = MapValidator.validateMapModel(map)
			if isValid then
				print(string.format("    ✓ Valid - Z:%d R:%d I:%d", 
					counts.zombieSpawns, counts.resourceSpawns, counts.itemSpawns))
			else
				warn("    ✗ Validation failed:")
				for _, error in ipairs(errors) do
					warn("      -", error)
				end
			end
		else
			warn("  ✗ Map not found:", mapName)
			return false
		end
	end
	
	return true
end

function TestMapSystem.testSpawnPointExtraction()
	print("\n=== Testing Spawn Point Extraction ===")
	
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("✗ Maps folder not found")
		return false
	end
	
	local testMap = mapsFolder:FindFirstChild("ResearchOutpost")
	if not testMap then
		warn("✗ ResearchOutpost map not found")
		return false
	end
	
	-- Test zombie spawns
	local zombieFolder = testMap:FindFirstChild("ZombieSpawnPoints")
	if zombieFolder then
		local count = #zombieFolder:GetChildren()
		print(string.format("✓ ZombieSpawnPoints folder found with %d children", count))
	else
		warn("✗ ZombieSpawnPoints folder not found")
		return false
	end
	
	-- Test resource spawns (standard convention)
	local spawnPointsFolder = testMap:FindFirstChild("SpawnPoints")
	if spawnPointsFolder then
		local resourceSpawns = spawnPointsFolder:FindFirstChild("ResourceSpawns")
		if resourceSpawns then
			local count = #resourceSpawns:GetChildren()
			print(string.format("✓ SpawnPoints/ResourceSpawns found with %d children", count))
		else
			warn("⚠ ResourceSpawns not found in SpawnPoints")
		end
		
		local itemSpawns = spawnPointsFolder:FindFirstChild("ItemSpawns")
		if itemSpawns then
			local count = #itemSpawns:GetChildren()
			print(string.format("✓ SpawnPoints/ItemSpawns found with %d children", count))
		else
			warn("⚠ ItemSpawns not found in SpawnPoints")
		end
	else
		warn("⚠ SpawnPoints folder not found (legacy convention may be used)")
	end
	
	return true
end

function TestMapSystem.runTests()
	print("\n" .. string.rep("=", 60))
	print("MULTI-MAP SYSTEM TEST SUITE")
	print(string.rep("=", 60))
	
	local tests = {
		{name = "MapConfig", func = TestMapSystem.testMapConfig},
		{name = "MapValidator", func = TestMapSystem.testMapValidator},
		{name = "MapGeneration", func = TestMapSystem.testMapGeneration},
		{name = "SpawnPointExtraction", func = TestMapSystem.testSpawnPointExtraction},
	}
	
	local passed = 0
	local failed = 0
	
	for _, test in ipairs(tests) do
		-- Test functions should return boolean: true for pass, false for fail
		local success, result = pcall(test.func)
		-- If pcall succeeds and result is explicitly true, test passed
		-- If pcall fails or result is false/nil, test failed
		if success and result == true then
			passed = passed + 1
			print(string.format("\n✓ %s: PASSED", test.name))
		else
			failed = failed + 1
			warn(string.format("\n✗ %s: FAILED", test.name))
			if not success then
				warn("  Error:", result)
			end
		end
	end
	
	print("\n" .. string.rep("=", 60))
	print(string.format("TEST RESULTS: %d passed, %d failed", passed, failed))
	print(string.rep("=", 60) .. "\n")
	
	if failed == 0 then
		print("✓ All tests passed! Multi-map system is ready.")
		print("\nNext steps:")
		print("1. Run the game to test map loading")
		print("2. Check map voting in the lobby")
		print("3. Verify spawn points work correctly in-game")
	else
		warn("✗ Some tests failed. Please review the errors above.")
	end
	
	return failed == 0
end

-- Quick test that can be called without parentheses
function TestMapSystem.test()
	return TestMapSystem.runTests()
end

return TestMapSystem
