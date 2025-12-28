-- TestBaseCampConfig.lua
-- Test script to verify BaseCampSetup reads config from GameConfig and supports map overrides
-- Place in ServerStorage/DevOnly for testing purposes

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("===== BaseCamp Configuration Test Script =====")

-- Load required modules
local BaseCampSetup = require(ServerScriptService:WaitForChild("BaseCampSetup"))
local GameConfig = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))

print("✓ Modules loaded successfully")

-- Test 1: Verify GameConfig has BASE_CAMP configuration
print("\n--- Test 1: GameConfig.BASE_CAMP Exists ---")
assert(GameConfig.BASE_CAMP ~= nil, "GameConfig.BASE_CAMP should exist")
assert(type(GameConfig.BASE_CAMP) == "table", "GameConfig.BASE_CAMP should be a table")
print("✓ GameConfig.BASE_CAMP configuration exists")

-- Test 2: Verify required configuration fields
print("\n--- Test 2: Required Configuration Fields ---")
local requiredFields = {
	"BASE_SIZE", "WALL_HEIGHT", "WALL_THICKNESS", "DEFAULT_HEIGHT",
	"GATE_WIDTH", "GATE_TRANSPARENCY", "NUM_GATES", "COVER_COUNT", "COVER_SIZE",
	"WALL_COLOR", "BASE_COLOR", "GATE_COLOR", "COVER_COLOR",
	"WALL_MATERIAL", "BASE_MATERIAL", "GATE_MATERIAL", "COVER_MATERIAL"
}

for _, field in ipairs(requiredFields) do
	assert(GameConfig.BASE_CAMP[field] ~= nil, "GameConfig.BASE_CAMP." .. field .. " should exist")
end
print("✓ All required configuration fields exist")

-- Test 3: Create BaseCampSetup without map config (uses defaults)
print("\n--- Test 3: Default Configuration ---")
local baseCampSetup1 = BaseCampSetup.new()
assert(baseCampSetup1.campConfig ~= nil, "campConfig should be initialized")
assert(baseCampSetup1.campConfig.BASE_SIZE == GameConfig.BASE_CAMP.BASE_SIZE, 
	"Should use GameConfig.BASE_CAMP.BASE_SIZE by default")
assert(baseCampSetup1.campConfig.WALL_HEIGHT == GameConfig.BASE_CAMP.WALL_HEIGHT,
	"Should use GameConfig.BASE_CAMP.WALL_HEIGHT by default")
print("✓ Default configuration loaded from GameConfig")
print("  - BASE_SIZE:", baseCampSetup1.campConfig.BASE_SIZE)
print("  - WALL_HEIGHT:", baseCampSetup1.campConfig.WALL_HEIGHT)

-- Test 4: Create BaseCampSetup with empty map config (uses defaults)
print("\n--- Test 4: Empty Map Config ---")
local emptyMapConfig = {}
local baseCampSetup2 = BaseCampSetup.new(emptyMapConfig)
assert(baseCampSetup2.campConfig.BASE_SIZE == GameConfig.BASE_CAMP.BASE_SIZE,
	"Should use defaults with empty map config")
print("✓ Empty map config falls back to defaults")

-- Test 5: Create BaseCampSetup with partial override
print("\n--- Test 5: Partial Configuration Override ---")
local partialOverride = {
	BaseCampConfig = {
		BASE_SIZE = 40, -- Override default (30)
		WALL_COLOR = Color3.fromRGB(255, 0, 0), -- Override to red
	}
}
local baseCampSetup3 = BaseCampSetup.new(partialOverride)

assert(baseCampSetup3.campConfig.BASE_SIZE == 40, "BASE_SIZE should be overridden to 40")
assert(baseCampSetup3.campConfig.WALL_COLOR == Color3.fromRGB(255, 0, 0), "WALL_COLOR should be overridden to red")
assert(baseCampSetup3.campConfig.WALL_HEIGHT == GameConfig.BASE_CAMP.WALL_HEIGHT,
	"Non-overridden values should use defaults")
assert(baseCampSetup3.campConfig.GATE_TRANSPARENCY == GameConfig.BASE_CAMP.GATE_TRANSPARENCY,
	"Non-overridden values should use defaults")
print("✓ Partial override correctly applied")
print("  - BASE_SIZE:", baseCampSetup3.campConfig.BASE_SIZE, "(overridden)")
print("  - WALL_HEIGHT:", baseCampSetup3.campConfig.WALL_HEIGHT, "(default)")
print("  - WALL_COLOR:", baseCampSetup3.campConfig.WALL_COLOR, "(overridden)")

-- Test 6: Create BaseCampSetup with full override
print("\n--- Test 6: Full Configuration Override ---")
local fullOverride = {
	BaseCampConfig = {
		BASE_SIZE = 50,
		WALL_HEIGHT = 20,
		WALL_THICKNESS = 3,
		DEFAULT_HEIGHT = 10,
		GATE_WIDTH = 10,
		GATE_TRANSPARENCY = 0.5,
		NUM_GATES = 4,
		COVER_COUNT = 12,
		COVER_SIZE = Vector3.new(5, 4, 2),
		WALL_COLOR = Color3.fromRGB(200, 200, 200),
		BASE_COLOR = Color3.fromRGB(150, 150, 150),
		GATE_COLOR = Color3.fromRGB(100, 50, 0),
		COVER_COLOR = Color3.fromRGB(60, 60, 60),
		WALL_MATERIAL = Enum.Material.Brick,
		BASE_MATERIAL = Enum.Material.Wood,
		GATE_MATERIAL = Enum.Material.Metal,
		COVER_MATERIAL = Enum.Material.Plastic,
	}
}
local baseCampSetup4 = BaseCampSetup.new(fullOverride)

assert(baseCampSetup4.campConfig.BASE_SIZE == 50, "All overrides should be applied")
assert(baseCampSetup4.campConfig.WALL_HEIGHT == 20, "All overrides should be applied")
assert(baseCampSetup4.campConfig.COVER_COUNT == 12, "All overrides should be applied")
assert(baseCampSetup4.campConfig.WALL_MATERIAL == Enum.Material.Brick, "All overrides should be applied")
print("✓ Full configuration override correctly applied")
print("  - BASE_SIZE:", baseCampSetup4.campConfig.BASE_SIZE)
print("  - COVER_COUNT:", baseCampSetup4.campConfig.COVER_COUNT)

-- Test 7: Build base camp with custom config and verify it uses overrides
print("\n--- Test 7: Build With Custom Config ---")
local customConfig = {
	BaseCampConfig = {
		BASE_SIZE = 25,
		COVER_COUNT = 6,
		GATE_TRANSPARENCY = 0.8,
	}
}
local baseCampSetup5 = BaseCampSetup.new(customConfig)
local baseCamp, captureZone = baseCampSetup5:buildBaseCamp(Vector3.new(0, 5, 0))

-- Verify platform size matches custom config
local platform = baseCamp:FindFirstChild("BasePlatform")
assert(platform ~= nil, "Platform should exist")
assert(platform.Size.X == 25, "Platform size should match custom BASE_SIZE")
assert(platform.Size.Z == 25, "Platform size should match custom BASE_SIZE")
print("✓ Base camp built with custom BASE_SIZE:", platform.Size.X)

-- Verify cover count matches custom config
local coverCount = 0
for _, child in ipairs(baseCamp:GetChildren()) do
	if string.match(child.Name, "^Cover_") then
		coverCount = coverCount + 1
	end
end
assert(coverCount == 6, "Should have 6 cover positions from custom config")
print("✓ Base camp built with custom COVER_COUNT:", coverCount)

-- Verify gate transparency matches custom config
local gate = baseCamp:FindFirstChild("NorthGate")
assert(gate ~= nil, "Gate should exist")
assert(gate.Transparency == 0.8, "Gate transparency should match custom config")
print("✓ Base camp built with custom GATE_TRANSPARENCY:", gate.Transparency)

-- Cleanup
baseCampSetup5:cleanup()
task.wait(0.1)

-- Test 8: Verify defaults unchanged
print("\n--- Test 8: Verify Defaults Unchanged ---")
assert(GameConfig.BASE_CAMP.BASE_SIZE == 30, "GameConfig defaults should not be modified")
assert(GameConfig.BASE_CAMP.COVER_COUNT == 8, "GameConfig defaults should not be modified")
print("✓ GameConfig defaults remain unchanged after creating instances with overrides")

-- Test 9: Multiple instances with different configs
print("\n--- Test 9: Multiple Instances With Different Configs ---")
local config1 = { BaseCampConfig = { BASE_SIZE = 20 } }
local config2 = { BaseCampConfig = { BASE_SIZE = 35 } }
local instance1 = BaseCampSetup.new(config1)
local instance2 = BaseCampSetup.new(config2)

assert(instance1.campConfig.BASE_SIZE == 20, "First instance should have BASE_SIZE 20")
assert(instance2.campConfig.BASE_SIZE == 35, "Second instance should have BASE_SIZE 35")
assert(instance1.campConfig.BASE_SIZE ~= instance2.campConfig.BASE_SIZE, "Instances should be independent")
print("✓ Multiple instances can have different configurations independently")

-- All tests passed!
print("\n===================================")
print("✅ ALL TESTS PASSED!")
print("BaseCampSetup correctly reads from GameConfig")
print("Map-specific configuration overrides work correctly")
print("Configuration changes are isolated per instance")
print("===================================")
