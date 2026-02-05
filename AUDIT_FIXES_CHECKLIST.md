# Audit Fixes Checklist
**Quick Reference for Development Team**

---

## 🚨 CRITICAL PRIORITY (Do First)

### ✅ Fix #1: Currency Race Condition
**File**: `ServerScriptService/PlayerManager.lua`  
**Location**: Lines 196-210  
**Time**: 15 minutes  

**Current issue**: Check-then-deduct pattern allows race condition

**Action required**:
```lua
function PlayerManager:deductCurrency(player, amount)
    if type(amount) ~= "number" or amount <= 0 then
        return false, "Invalid amount"
    end

    local playerData = self.players[player.UserId]
    if not playerData then
        return false, "Player data not found"
    end
    
    -- FIXED: Atomic check-and-deduct
    local newBalance = playerData.currency - amount
    if newBalance < 0 then
        return false, "Insufficient funds"
    end
    
    playerData.currency = newBalance
    self:sendCurrencyUpdate(player)
    return true, "Success"
end
```

**Test**: Rapid shop purchases with exact balance amount

---

### ✅ Fix #2: Player Disconnect Cleanup
**File**: `ServerScriptService/Main.server.lua`  
**Location**: Lines 179-192  
**Time**: 30 minutes  

**Current issue**: Missing cleanup for puzzle, spectator, shop services

**Action required in Main.server.lua**:
```lua
Players.PlayerRemoving:Connect(function(player)
    print(string.format("[STATE] Player %s left the game", player.Name))

    -- Existing cleanup
    gameManager:onPlayerRemoving(player)
    allianceService:removePlayer(player)
    sprintService:removePlayer(player)
    achievementService:removePlayer(player)
    
    if fpsWeaponService then
        fpsWeaponService:removePlayer(player)
    end
    
    -- ADD THESE:
    if puzzleService then
        puzzleService:removePlayer(player)
    end
    
    if spectatorManager then
        spectatorManager:removePlayer(player)
    end
    
    if shopService then
        shopService:removePlayer(player)
    end
end)
```

**Action required in PuzzleService.lua** - ADD NEW METHOD:
```lua
function PuzzleService:removePlayer(player)
    local userId = player.UserId
    
    -- Clean up puzzle state
    self.playerPuzzles[userId] = nil
    self.playersReadyForFinal[userId] = nil
    
    -- Clean up active puzzles
    for puzzleKey in pairs(self.activePuzzles) do
        if puzzleKey:match("^" .. userId .. "_") then
            self.activePuzzles[puzzleKey] = nil
        end
    end
    
    print(string.format("[PuzzleService] Cleaned up puzzle data for %s", player.Name))
end
```

**Test**: Player disconnects during puzzle/spectate/shopping

---

## ⚠️ HIGH PRIORITY (This Sprint)

### 🔧 Fix #3: RemoteEvent Error Handling
**Files**: FPSWeaponService.lua, PuzzleService.lua, ShopService.lua, AllianceServiceV2.lua  
**Time**: 2 hours  

**Pattern to apply to ALL RemoteEvent handlers**:

**Before**:
```lua
self.remoteEvents.SomeEvent.OnServerEvent:Connect(function(player, payload)
    self:handleSomeAction(player, payload)
end)
```

**After**:
```lua
self.remoteEvents.SomeEvent.OnServerEvent:Connect(function(player, payload)
    local ok, err = pcall(function()
        self:handleSomeAction(player, payload)
    end)
    
    if not ok then
        warn(string.format("[ServiceName] Error handling SomeEvent for %s: %s", 
            player.Name, tostring(err)))
    end
end)
```

**Files to update**:
- [ ] FPSWeaponService.lua (Line 79 - WeaponReload)
- [ ] PuzzleService.lua (All RemoteEvent handlers)
- [ ] ShopService.lua (All RemoteEvent handlers)
- [ ] AllianceServiceV2.lua (All RemoteEvent handlers)
- [ ] Any other RemoteEvent .OnServerEvent handlers

**Test**: Send malformed payload, verify handler doesn't crash

---

### 🔧 Fix #4: Puzzle State Persistence
**File**: `ServerScriptService/PuzzleService.lua`  
**Time**: 1 hour  

**Current issue**: Puzzle progress lost on death/disconnect

**Action required**:
1. Store puzzle state in PlayerManager data structure
2. Add save/load methods to PuzzleService
3. Restore state on character respawn

**Implementation**:
```lua
-- In PuzzleService.lua
function PuzzleService:savePuzzleState(player, componentName, state)
    local playerData = self.playerManager.players[player.UserId]
    if playerData then
        playerData.puzzleState = playerData.puzzleState or {}
        playerData.puzzleState[componentName] = state
    end
end

function PuzzleService:loadPuzzleState(player, componentName)
    local playerData = self.playerManager.players[player.UserId]
    if playerData and playerData.puzzleState then
        return playerData.puzzleState[componentName]
    end
    return nil
end
```

**Test**: Complete puzzle, die, verify progress retained

---

### 🔧 Fix #5: Shop Catalog Indexing
**File**: `ServerScriptService/ShopService.lua`  
**Time**: 30 minutes  

**Current issue**: O(n) linear search for every purchase

**Action required in ShopService.new()**:
```lua
function ShopService.new(playerManager)
    local self = setmetatable({}, ShopService)
    self.playerManager = playerManager
    
    -- Build catalog index for O(1) lookups
    self.catalogIndex = {}
    local ok, catalog = pcall(function()
        return WeaponConfig.getCatalog()
    end)
    
    if ok and typeof(catalog) == "table" then
        for _, item in ipairs(catalog) do
            if item.Id then
                self.catalogIndex[item.Id] = item
            end
        end
        print(string.format("[ShopService] Indexed %d catalog items", #catalog))
    else
        warn("[ShopService] Failed to build catalog index")
    end
    
    self:setupRemoteEvents()
    return self
end
```

**Action required in attemptPurchase()**:
```lua
-- REPLACE findCatalogItemById() call with:
local selectedItem = self.catalogIndex[itemId]
if not selectedItem then
    self:sendResult(player, false, "Item not found")
    return
end
```

**Test**: Shop purchases, verify faster performance

---

## 📋 MEDIUM PRIORITY (Next Sprint)

### 🔧 Fix #6: Service Dependency Validation
**Files**: Multiple services  
**Time**: 1 hour  

**Add to each service constructor**:
```lua
function ServiceName.new(dependency1, dependency2)
    assert(dependency1, "ServiceName requires Dependency1")
    assert(dependency2, "ServiceName requires Dependency2")
    
    local self = setmetatable({}, ServiceName)
    self.dependency1 = dependency1
    self.dependency2 = dependency2
    return self
end
```

**Services to update**:
- [ ] AllianceServiceV2.lua
- [ ] PuzzleService.lua
- [ ] CureSynthesisService.lua
- [ ] BetrayalService.lua

---

## 📝 LOW PRIORITY (Technical Debt)

### Documentation Improvements
- [ ] Add JSDoc-style comments to complex functions
- [ ] Document RemoteEvent payload structures
- [ ] Add parameter and return value documentation

### Code Quality
- [ ] Add string length validation to RemoteEvent handlers
- [ ] Add service :destroy() methods for cleanup
- [ ] Improve AllianceGraph mutex with timeout

---

## 🧪 Testing Checklist

### After Fixing Critical Issues:
- [ ] Test rapid shop purchases (race condition)
- [ ] Test player disconnect during:
  - [ ] Weapon reload
  - [ ] Puzzle solving
  - [ ] Shopping
  - [ ] Spectating
  - [ ] Alliance operations
- [ ] Test malformed RemoteEvent payloads
- [ ] Run full multiplayer test with 8 players
- [ ] Monitor memory usage over 30-minute session

---

## 📊 Progress Tracking

**Total Fixes**: 6 critical/high priority  
**Estimated Effort**: 8 hours  
**Completed**: 0 / 6  

Track your progress:
```
Fix #1 Currency:       [ ]
Fix #2 Cleanup:        [ ]
Fix #3 Error Handling: [ ]
Fix #4 Puzzle State:   [ ]
Fix #5 Shop Index:     [ ]
Fix #6 Dependencies:   [ ]
```

---

## 📄 Resources

- **Full Report**: COMPREHENSIVE_AUDIT_REPORT_2026.md
- **Executive Summary**: AUDIT_EXECUTIVE_SUMMARY.md
- **This Checklist**: AUDIT_FIXES_CHECKLIST.md

---

**Questions?** Refer to the comprehensive audit report for detailed explanations and additional context.

*Last updated: February 5, 2026*
