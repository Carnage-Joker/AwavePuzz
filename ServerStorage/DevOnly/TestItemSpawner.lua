-- TestItemSpawner.lua
-- Test script to verify ItemSpawner helper methods maintain synchronization
-- Place in ServerStorage/DevOnly for testing purposes

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("===== ItemSpawner Test Script =====")

-- Load required modules
local ItemSpawner = require(ServerScriptService:WaitForChild("ItemSpawner"))
local GameConfig = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))

print("✓ Modules loaded successfully")

-- Test 1: Create ItemSpawner instance
print("\n--- Test 1: ItemSpawner Instance ---")
local itemSpawner = ItemSpawner.new()
assert(itemSpawner ~= nil, "Failed to create ItemSpawner instance")
print("✓ ItemSpawner instance created")

-- Test 2: Verify initial state
print("\n--- Test 2: Initial State ---")
assert(itemSpawner:getActiveItemCount() == 0, "Initial item count should be 0")
assert(next(itemSpawner.activeItems) == nil, "activeItems table should be empty")
print("✓ Initial state is correct (count: 0, table empty)")

-- Test 3: Test addActiveItem helper method
print("\n--- Test 3: addActiveItem Helper ---")
local testItemData1 = {
	itemType = "Ammo",
	instance = nil, -- Mock instance
	touchConnection = nil,
	rotationConnection = nil
}
local success1 = itemSpawner:addActiveItem("test_item_1", testItemData1)
assert(success1 == true, "addActiveItem should return true on success")
assert(itemSpawner:getActiveItemCount() == 1, "Item count should be 1 after adding")
assert(itemSpawner.activeItems["test_item_1"] ~= nil, "Item should exist in activeItems table")
print("✓ addActiveItem correctly adds item and updates count")

-- Test 4: Verify synchronization after adding multiple items
print("\n--- Test 4: Multiple Items Synchronization ---")
local testItemData2 = {
	itemType = "Health",
	instance = nil,
	touchConnection = nil,
	rotationConnection = nil
}
itemSpawner:addActiveItem("test_item_2", testItemData2)
itemSpawner:addActiveItem("test_item_3", testItemData2)

assert(itemSpawner:getActiveItemCount() == 3, "Item count should be 3")
local tableCount = 0
for _ in pairs(itemSpawner.activeItems) do
	tableCount = tableCount + 1
end
assert(tableCount == 3, "activeItems table should have 3 entries")
assert(itemSpawner:getActiveItemCount() == tableCount, "Count and table size should match")
print("✓ Count synchronized with table size after multiple additions")

-- Test 5: Test duplicate prevention
print("\n--- Test 5: Duplicate Prevention ---")
local duplicateSuccess = itemSpawner:addActiveItem("test_item_1", testItemData1)
assert(duplicateSuccess == false, "Adding duplicate item should return false")
assert(itemSpawner:getActiveItemCount() == 3, "Count should remain 3 after duplicate attempt")
print("✓ Duplicate item addition prevented correctly")

-- Test 6: Test removeActiveItem helper method
print("\n--- Test 6: removeActiveItem Helper ---")
local removeSuccess, removedItem = itemSpawner:removeActiveItem("test_item_2")
assert(removeSuccess == true, "removeActiveItem should return true on success")
assert(removedItem ~= nil, "Removed item data should be returned")
assert(removedItem.itemType == "Health", "Removed item should have correct type")
assert(itemSpawner:getActiveItemCount() == 2, "Item count should be 2 after removing")
assert(itemSpawner.activeItems["test_item_2"] == nil, "Removed item should not exist in table")
print("✓ removeActiveItem correctly removes item and updates count")

-- Test 7: Test removing non-existent item
print("\n--- Test 7: Remove Non-existent Item ---")
local nonExistSuccess = itemSpawner:removeActiveItem("non_existent_item")
assert(nonExistSuccess == false, "Removing non-existent item should return false")
assert(itemSpawner:getActiveItemCount() == 2, "Count should remain 2 after failed removal")
print("✓ Non-existent item removal handled correctly")

-- Test 8: Test clearAllItems using helper method
print("\n--- Test 8: clearAllItems Method ---")
-- Add a few more items first
itemSpawner:addActiveItem("test_item_4", testItemData1)
itemSpawner:addActiveItem("test_item_5", testItemData2)
assert(itemSpawner:getActiveItemCount() == 4, "Should have 4 items before clear")

itemSpawner:clearAllItems()
assert(itemSpawner:getActiveItemCount() == 0, "Item count should be 0 after clear")
assert(next(itemSpawner.activeItems) == nil, "activeItems table should be empty after clear")
print("✓ clearAllItems correctly clears all items and resets count")

-- Test 9: Verify synchronization remains intact after clear and add
print("\n--- Test 9: Post-Clear Synchronization ---")
itemSpawner:addActiveItem("new_item_1", testItemData1)
itemSpawner:addActiveItem("new_item_2", testItemData2)
assert(itemSpawner:getActiveItemCount() == 2, "Count should be 2 after adding new items")
local finalTableCount = 0
for _ in pairs(itemSpawner.activeItems) do
	finalTableCount = finalTableCount + 1
end
assert(finalTableCount == 2, "Table should have 2 entries")
assert(itemSpawner:getActiveItemCount() == finalTableCount, "Final count and table size should match")
print("✓ Synchronization maintained after clear and new additions")

-- Test 10: Stress test - Many additions and removals
print("\n--- Test 10: Stress Test ---")
itemSpawner:clearAllItems()
local itemIds = {}
-- Add 20 items
for i = 1, 20 do
	local itemId = "stress_test_" .. i
	table.insert(itemIds, itemId)
	itemSpawner:addActiveItem(itemId, testItemData1)
end
assert(itemSpawner:getActiveItemCount() == 20, "Should have 20 items after additions")

-- Remove every other item
for i = 1, 20, 2 do
	itemSpawner:removeActiveItem(itemIds[i])
end
assert(itemSpawner:getActiveItemCount() == 10, "Should have 10 items after removing every other")

-- Verify table count matches
local stressTableCount = 0
for _ in pairs(itemSpawner.activeItems) do
	stressTableCount = stressTableCount + 1
end
assert(stressTableCount == 10, "Table should have 10 entries")
assert(itemSpawner:getActiveItemCount() == stressTableCount, "Count should match table size in stress test")
print("✓ Stress test passed - synchronization maintained through many operations")

-- Cleanup
itemSpawner:clearAllItems()

-- All tests passed!
print("\n===================================")
print("✅ ALL TESTS PASSED!")
print("ItemSpawner helper methods correctly maintain synchronization")
print("===================================")
