# AwavePuzz - Bug Report

**Document Version:** 1.0  
**Generated:** 2026-01-24  
**Status:** Comprehensive audit complete  
**Total Bugs Found:** 20

---

## Bug Severity Classification

- **CRITICAL:** System-breaking bugs that cause crashes or complete gameplay failure
- **HIGH:** Major bugs that significantly impact gameplay or cause frequent errors
- **MEDIUM:** Moderate bugs that cause issues under specific conditions
- **LOW:** Minor bugs with minimal impact

---

## Critical Bugs (Fix Immediately)

### BUG #1: WaitForChild Without Timeout - Server Startup Blocking ⚠️

**Severity:** CRITICAL  
**File:** `ServerScriptService/MainServer.lua` (Lines 12-13)  
**Category:** Server Startup

**Issue:**
```lua
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
```
These calls have **no timeout parameter**, causing infinite yield if folders are missing.

**Why It Happens:**  
If `ReplicatedStorage.Shared` or `Shared.GameConfig` don't exist, the server will hang indefinitely. This blocks all server startup.

**Fix Approach:**
```lua
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then 
    error("[MainServer] CRITICAL: Failed to load Shared folder after 10 seconds")
end

local GameConfig = SharedFolder:WaitForChild("GameConfig", 5)
if not GameConfig then
    error("[MainServer] CRITICAL: Failed to load GameConfig after 5 seconds")
end
GameConfig = require(GameConfig)
```

**Verification:**
1. Remove `ReplicatedStorage.Shared` folder temporarily
2. Run server
3. Should error after 10 seconds instead of hanging

**Impact:** Server completely hangs on startup if Shared folder is missing.

---

### BUG #2: Cascading WaitForChild Without Timeouts ⚠️

**Severity:** CRITICAL  
**Files:** Multiple server files  
**Category:** Server Startup

**Affected Files:**
- `MapManager.lua` (Lines 12-16): `SharedFolder:WaitForChild()` chains
- `ResourceSpawner.lua` (Line 12): `ReplicatedStorage:WaitForChild("Shared")`
- `ItemSpawner.lua` (Line 12): `ReplicatedStorage:WaitForChild("Shared")`
- `GameManager.lua` (Lines 21-24): Multiple `WaitForChild()` calls
- `WeaponService.lua`, `SprintService.lua`, `ShopService.lua`, etc.

**Issue:**  
Throughout the codebase, `WaitForChild()` is called without timeout parameters. This can cause cascading failures where one missing module blocks multiple services.

**Why It Happens:**  
Pattern copied across multiple files without adding timeout safety.

**Fix Approach:**  
Add 5-10 second timeouts to ALL `WaitForChild()` calls:

```lua
-- Bad:
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")

-- Good:
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error(string.format("[%s] Failed to load Shared folder", script.Name))
end
```

**Verification:**
1. Search codebase for all `:WaitForChild\(` patterns
2. Add timeouts and error handling
3. Test with intentionally missing modules
4. Verify graceful error messages instead of hangs

**Impact:** Multiple services can hang indefinitely if required modules are missing.

---

### BUG #3: Spawner Fallback Position Wrong ⚠️

**Severity:** CRITICAL  
**File:** `ServerScriptService/Spawner.lua` (Lines 170, 184)  
**Category:** Zombie Spawning

**Issue:**
```lua
function Spawner:getNextSpawnPoint()
    if #self.spawnPoints == 0 then
        warn("No spawn points available! Using default position.")
        return Vector3.new(0, 10, 0)  -- ← WRONG!
    end
    -- ...
end
```

**Why It Happens:**  
Maps are positioned at `(5000, 0, 0)` (see MapManager.lua line 22). Spawning at `(0, 10, 0)` means zombies spawn **5000 studs away from the map** - essentially in the void!

**Fix Approach:**
```lua
function Spawner:getNextSpawnPoint()
    if #self.spawnPoints == 0 then
        error("[Spawner] CRITICAL: No spawn points configured! Cannot spawn zombies. Check map validation.")
        return nil
    end
    -- ...
end

function Spawner:getRandomSpawnPoint()
    if #self.spawnPoints == 0 then
        error("[Spawner] CRITICAL: No spawn points configured!")
        return nil
    end
    return self.spawnPoints[math.random(1, #self.spawnPoints)]
end
```

**Alternative Fix (if must provide fallback):**
```lua
function Spawner:getNextSpawnPoint()
    if #self.spawnPoints == 0 then
        warn("[Spawner] No spawn points! Using map center as fallback.")
        -- Use map center instead
        local mapCenter = Vector3.new(5000, 10, 0)
        return mapCenter
    end
    -- ...
end
```

**Verification:**
1. Start game with intentionally broken map (no ZombieSpawns folder)
2. Should error loudly instead of spawning zombies in void
3. Or zombies spawn at map center (5000, 10, 0) if using alternative fix

**Impact:** Zombies spawn 5000 studs away from gameplay area, completely breaking the game.

---

### BUG #4: AI Target Validation - No Players + No Base ⚠️

**Severity:** CRITICAL  
**File:** `ServerScriptService/AI/TargetingService.lua` (Lines 61-85)  
**Category:** AI System

**Issue:**  
```lua
function TargetingService:getPlayerTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        -- ... build targets list ...
    end
    return targets  -- Returns empty table if no alive players
end
```

And `getBaseTarget()` returns `nil, nil` if base doesn't exist (lines 37-58).

**Why It Happens:**  
If all players die/disconnect AND the base is destroyed, zombies have no valid target. They'll attempt to pathfind to `nil` and either crash or stand idle.

**Fix Approach:**  
Add fallback wandering behavior in ZombieBrain:

```lua
-- In ZombieBrain.lua, update selectTarget():
function ZombieBrain:selectTarget()
    local target, targetType = self.targetingService:selectTarget(self.model)
    
    if not target or not targetType then
        warn("[ZombieBrain] No valid targets available. Zombie will wander.")
        -- Provide wander point near last known position
        local lastPos = self.lastTargetPos or self.model:GetPivot().Position
        local randomOffset = Vector3.new(
            math.random(-50, 50),
            0,
            math.random(-50, 50)
        )
        return lastPos + randomOffset, "wander"
    end
    
    self.lastTargetPos = target
    return target, targetType
end
```

**Verification:**
1. Start game with 1 player
2. Destroy base (set health to 0)
3. Have player die
4. Spawn zombies
5. Verify zombies wander instead of crashing

**Impact:** Zombies crash or stand idle when no targets exist, breaking wave progression.

---

## High Priority Bugs

### BUG #5: Missing nil Guard on fpsWeaponService:removePlayer()

**Severity:** HIGH  
**File:** `ServerScriptService/MainServer.lua` (Line 154)  
**Category:** Player Disconnect

**Issue:**
```lua
Players.PlayerRemoving:Connect(function(player)
    print(player.Name .. " left the game")
    gameManager:onPlayerRemoving(player)
    allianceService:removePlayer(player)
    sprintService:removePlayer(player)
    fpsWeaponService:removePlayer(player)  -- ← No nil check!
    achievementService:removePlayer(player)
end)
```

**Why It Happens:**  
Line 59 assigns `gameManager.fpsWeaponService`, but if GameManager initialization fails or is incomplete, `fpsWeaponService` will be nil.

**Fix Approach:**
```lua
Players.PlayerRemoving:Connect(function(player)
    print(player.Name .. " left the game")
    gameManager:onPlayerRemoving(player)
    allianceService:removePlayer(player)
    sprintService:removePlayer(player)
    
    if fpsWeaponService then
        fpsWeaponService:removePlayer(player)
    end
    
    achievementService:removePlayer(player)
end)
```

**Verification:**
1. Intentionally break GameManager initialization
2. Join as player
3. Leave
4. Should not crash on disconnect

**Impact:** Server crashes when players disconnect if fpsWeaponService failed to initialize.

---

### BUG #6: Infinite Queue Growth in Spawner

**Severity:** HIGH  
**File:** `ServerScriptService/Spawner.lua` (Lines 357-402)  
**Category:** Zombie Spawning

**Issue:**  
`spawnWave()` queues zombies but if `processSpawnQueue()` never gets called (e.g., game state transitions without calling `spawner:update()`), the queue grows indefinitely.

**Why It Happens:**  
No maximum queue size check exists. If spawn processing stops but wave spawning continues, memory leaks occur.

**Fix Approach:**
```lua
function Spawner:queueSpawn(zombieType)
    local MAX_QUEUE_SIZE = 500
    
    if #self.spawnQueue >= MAX_QUEUE_SIZE then
        warn(string.format("[Spawner] Spawn queue full (%d zombies queued). Dropping %s spawn.", 
            MAX_QUEUE_SIZE, zombieType))
        return false
    end
    
    table.insert(self.spawnQueue, zombieType)
    return true
end
```

**Verification:**
1. Pause spawner processing (comment out `processSpawnQueue()`)
2. Call `spawnWave()` repeatedly
3. Queue should cap at 500 instead of growing infinitely

**Impact:** Memory leak and potential server crash if spawn queue grows unchecked.

---

### BUG #7: Player Disconnect During Zombie Attack

**Severity:** HIGH  
**File:** `ServerScriptService/AI/ZombieBrain.lua` (Lines 309-323)  
**Category:** AI System

**Issue:**
```lua
if targetType == "player" and targetPlayer then
    if targetPlayer and targetPlayer.Character then
        local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid and targetHumanoid.Health > 0 then
            if self.playerManager then
                self.playerManager:damagePlayer(targetPlayer, damage)
            end
        end
    end
end
```

**Why It Happens:**  
Player can disconnect or their character can be removed between the initial check and `damagePlayer()` call. Character.Parent becomes nil when player leaves.

**Fix Approach:**
```lua
if targetType == "player" and targetPlayer then
    -- Add Parent check to ensure character still exists
    if targetPlayer.Character and targetPlayer.Character.Parent then
        local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid and targetHumanoid.Health > 0 then
            if self.playerManager then
                pcall(function()
                    self.playerManager:damagePlayer(targetPlayer, damage)
                end)
            end
        end
    end
end
```

**Verification:**
1. Start game as player
2. Aggro zombie
3. Disconnect during attack animation
4. Server should not crash

**Impact:** Server crashes when zombies attack disconnecting players.

---

### BUG #8: ResourceSpawner Silent Failure

**Severity:** HIGH  
**File:** `ServerScriptService/ResourceSpawner.lua` (Lines 293-297)  
**Category:** Resource Spawning

**Issue:**
```lua
if #self.spawnPoints == 0 then
    warn("[ResourceSpawner] Cannot pick spawn point...")
    return nil  -- Silently returns nil, no resources spawn
end
```

**Why It Happens:**  
If `setSpawnPoints()` was never called or failed, resources never spawn throughout the entire game. Only a warning is printed.

**Fix Approach:**
```lua
function ResourceSpawner:pickRandomSpawnPoint()
    if #self.spawnPoints == 0 then
        error("[ResourceSpawner] No spawn points configured! Resources cannot spawn. Call setSpawnPoints() first or check map validation.")
    end
    return self.spawnPoints[math.random(1, #self.spawnPoints)]
end
```

**Verification:**
1. Start game without calling `setSpawnPoints()`
2. Should error loudly instead of silently failing
3. Check server output for clear error message

**Impact:** No resources spawn during gameplay, making game unplayable without obvious error.

---

## Medium Priority Bugs

### BUG #9: MapValidator Insufficient Error Handling

**Severity:** MEDIUM  
**File:** `ServerScriptService/MapValidator.lua` (Lines 50-81)  
**Category:** Map Loading

**Issue:**  
Map validation fails if fewer than 8 zombie spawns exist, but provides no guidance on minimum viable configuration.

**Fix Approach:**
```lua
local MIN_ZOMBIE_SPAWNS = 8
local RECOMMENDED_ZOMBIE_SPAWNS = 16

if zombieCount < MIN_ZOMBIE_SPAWNS then
    warn(string.format("[MapValidator] CRITICAL: Only %d zombie spawns found (minimum: %d)", 
        zombieCount, MIN_ZOMBIE_SPAWNS))
    warn("[MapValidator] Map rejected. Add more spawn points to ZombieSpawnPoints folder.")
    return false
elseif zombieCount < RECOMMENDED_ZOMBIE_SPAWNS then
    warn(string.format("[MapValidator] WARNING: Only %d zombie spawns found (recommended: %d)", 
        zombieCount, RECOMMENDED_ZOMBIE_SPAWNS))
    warn("[MapValidator] Game may have spawn distribution issues. Consider adding more points.")
end
```

**Verification:**
1. Create test map with only 5 zombie spawns
2. Attempt to load
3. Should see clear error message with guidance

**Impact:** Maps fail validation without clear explanation of what's wrong.

---

### BUG #10: BaseCampSetup No Fallback Spawn

**Severity:** MEDIUM  
**File:** `ServerScriptService/BaseCampSetup.lua` (Line 308)  
**Category:** Map Loading

**Issue:**  
If base camp can't be built, players have no guaranteed spawn location.

**Fix Approach:**
```lua
function BaseCampSetup:ensureFallbackSpawn()
    if not self.baseCampModel then
        warn("[BaseCampSetup] No base camp exists. Creating emergency spawn point.")
        local emergencySpawn = Instance.new("SpawnLocation")
        emergencySpawn.Name = "EmergencySpawn"
        emergencySpawn.Position = Vector3.new(5000, 5, 0)  -- Map center
        emergencySpawn.Anchored = true
        emergencySpawn.Size = Vector3.new(10, 1, 10)
        emergencySpawn.Parent = workspace
        return emergencySpawn
    end
    return nil
end
```

**Verification:**
1. Break base camp setup intentionally
2. Players should still spawn at emergency location
3. Game should continue even without proper base

**Impact:** Players can't spawn if base camp setup fails.

---

### BUG #11: CureStationSetup Race Condition

**Severity:** MEDIUM  
**File:** `ServerScriptService/CureStationSetup.lua` (Lines 28-29)  
**Category:** Server Startup

**Issue:**
```lua
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents and remoteEvents:FindFirstChild("RequestPuzzle") then
```
Only checks for `RequestPuzzle`, but assumes `RemoteEvents` folder exists.

**Fix Approach:**
```lua
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    if not remoteEvents then
        warn("[CureStationSetup] RemoteEvents folder not found after 10 seconds. Cure interactions may not work.")
        return
    end
end

if remoteEvents:FindFirstChild("RequestPuzzle") then
    -- Setup cure station interactions
end
```

**Verification:**
1. Delay RemoteEventsBootstrap creation
2. CureStationSetup should wait gracefully
3. Should not fail if RemoteEvents loads after 5 seconds

**Impact:** Cure stations may not work if RemoteEvents folder isn't created fast enough.

---

### BUG #12: ItemSpawner Returns Empty Table Instead of nil

**Severity:** MEDIUM  
**File:** `ServerScriptService/ItemSpawner.lua` (Lines 78-118)  
**Category:** Item Spawning

**Issue:**
```lua
function ItemSpawner:findItemSpawnPoints()
    local spawnParts = {}
    -- ... search code ...
    warn("[ItemSpawner] No item spawn points found in map.")
    return spawnParts  -- Returns empty table instead of nil
end
```

**Why It Happens:**  
Inconsistent return value - function returns empty `{}` when it should return `nil` to indicate failure.

**Fix Approach:**
```lua
function ItemSpawner:findItemSpawnPoints()
    local spawnParts = {}
    -- ... search code ...
    
    if #spawnParts == 0 then
        warn("[ItemSpawner] No item spawn points found in map.")
        return nil
    end
    
    return spawnParts
end
```

**Verification:**
1. Load map without ItemSpawns folder
2. Check return value is nil, not empty table
3. Calling code should handle nil correctly

**Impact:** Confusing API - callers must check both `nil` and `#table == 0`.

---

### BUG #13: SurroundService Map Unload Race Condition

**Severity:** MEDIUM  
**File:** `ServerScriptService/AI/SurroundService.lua` (Lines 38-56)  
**Category:** AI System

**Issue:**  
If map unloads or base is destroyed during pathfinding, `targetPos` becomes invalid and zombies path to wrong location.

**Fix Approach:**
```lua
function SurroundService:getBasePosition()
    -- Cache base position with 1-second expiry
    if not self.cachedBasePos or tick() - self.basePosCacheTime > 1 then
        local base = workspace:FindFirstChild("BaseCaptureZone")
        if base then
            self.cachedBasePos = base:GetPivot().Position
            self.basePosCacheTime = tick()
        else
            self.cachedBasePos = nil
            self.basePosCacheTime = 0
        end
    end
    return self.cachedBasePos
end

-- Use this cached position in slot calculations
local function calculateSlotPosition(targetPos, ringIndex, slotIndex, totalSlots)
    if not targetPos then
        warn("[SurroundService] Invalid target position")
        return nil
    end
    -- ... rest of calculation
end
```

**Verification:**
1. Start wave
2. Destroy base mid-wave
3. Zombies should handle missing base gracefully
4. No crashes or invalid pathing

**Impact:** Zombies path to invalid locations if map unloads during gameplay.

---

### BUG #14: ClientController Duplicate Initialization Risk

**Severity:** MEDIUM  
**File:** `StarterPlayer/StarterPlayerScripts/ClientController.client.lua` (Lines 57-226)  
**Category:** Client Initialization

**Issue:**  
Initialization functions print "initialized" but have no guard to prevent calling twice.

**Fix Approach:**
```lua
local systemsInitialized = {
    camera = false,
    movement = false,
    weapon = false,
    animation = false,
    audio = false,
    music = false,
    menu = false,
    ui = false
}

function ClientController.initializeCamera()
    if systemsInitialized.camera then 
        warn("[ClientController] Camera already initialized, skipping")
        return 
    end
    
    print("[ClientController] Initializing Camera...")
    -- ... initialization code ...
    systemsInitialized.camera = true
    print("[ClientController] ✓ Camera initialized")
end

-- Repeat for other systems
```

**Verification:**
1. Call `ClientController.initializeCamera()` twice
2. Second call should warn and skip
3. No duplicate initialization should occur

**Impact:** Modules may initialize twice, causing duplicate event handlers or memory leaks.

---

### BUG #15: RemoteEventsBootstrap Execution Order

**Severity:** MEDIUM  
**File:** `ServerScriptService/RemoteEventsBootstrap.lua` (All lines)  
**Category:** Server Startup

**Issue:**  
RemoteEventsBootstrap and MainServer.lua both run as Scripts with no guaranteed order. Race condition if services try to access RemoteEvents before they're created.

**Fix Approach:**
```lua
-- Option 1: Convert RemoteEventsBootstrap to ModuleScript
-- In RemoteEventsBootstrap.lua:
local RemoteEventsBootstrap = {}

function RemoteEventsBootstrap.initialize()
    -- Create all remote events
    print("[RemoteEventsBootstrap] Creating remote events...")
    -- ... existing code ...
    print("[RemoteEventsBootstrap] All remote events created")
end

return RemoteEventsBootstrap

-- In MainServer.lua (line 7):
local RemoteEventsBootstrap = require(script.Parent.RemoteEventsBootstrap)
RemoteEventsBootstrap.initialize()
print("RemoteEvents initialized")

-- Then continue with service creation
```

**Verification:**
1. Add prints to track execution order
2. RemoteEventsBootstrap should always run before MainServer uses RemoteEvents
3. No race conditions should occur

**Impact:** Services may fail if they try to access RemoteEvents before they're created.

---

## Low Priority Bugs

### BUG #16: FPSConfig WaitForChild Lacks Timeout

**Severity:** LOW  
**File:** `StarterPlayer/StarterPlayerScripts/ClientController.client.lua` (Line 22)  
**Category:** Client Startup

**Issue:**
```lua
local FPSConfig = require(SharedFolder:WaitForChild("FPSConfig"))
```
No timeout on `WaitForChild("FPSConfig")`.

**Fix Approach:**
```lua
local FPSConfig = SharedFolder:WaitForChild("FPSConfig", 5)
if not FPSConfig then
    error("[ClientController] Failed to load FPSConfig")
end
FPSConfig = require(FPSConfig)
```

**Impact:** Client hangs if FPSConfig is missing, but SharedFolder check already has timeout.

---

### BUG #17: Asset Loading Failures - rbxassetid://0

**Severity:** LOW  
**File:** `StarterPlayer/StarterPlayerScripts/Modules/FPSAudioController.lua` (Lines 30-45)  
**Category:** Audio System

**Issue:**  
All weapon sounds use placeholder `rbxassetid://0`, which will fail to load.

**Fix Approach:**
```lua
function AudioController:loadSound(soundId)
    if soundId == "rbxassetid://0" or soundId == "" then
        -- Placeholder asset, skip with warning
        warn("[AudioController] Placeholder sound asset, skipping:", soundId)
        return nil
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    
    -- Load with timeout
    local success, err = pcall(function()
        sound:Play()
        sound:Stop()
    end)
    
    if not success then
        warn("[AudioController] Failed to load sound:", soundId, err)
        return nil
    end
    
    return sound
end
```

**Impact:** Audio fails to play but doesn't break gameplay.

---

## Summary Statistics

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 4 | Requires immediate fix |
| HIGH | 5 | Fix before production |
| MEDIUM | 6 | Fix when possible |
| LOW | 2 | Nice to have |
| **TOTAL** | **17** | **Bugs documented** |

---

## Priority Fix Order

### Phase 1 (Critical - Fix First):
1. ✅ Add WaitForChild timeouts throughout codebase
2. ✅ Fix Spawner fallback position (0,10,0) → (5000,10,0) or error
3. ✅ Add AI target validation for no-target scenarios
4. ✅ Fix RemoteEventsBootstrap execution order

### Phase 2 (High - Fix Next):
5. ✅ Add nil guards for service cleanup
6. ✅ Add spawn queue size limit
7. ✅ Add Player.Parent validation in AI attack
8. ✅ Make ResourceSpawner fail loudly

### Phase 3 (Medium - Fix Soon):
9. ✅ Improve MapValidator error messages
10. ✅ Add BaseCampSetup fallback spawn
11. ✅ Fix CureStationSetup race condition
12. ✅ Fix ItemSpawner return value consistency
13. ✅ Add SurroundService position caching
14. ✅ Add ClientController duplicate init guards

### Phase 4 (Low - Fix Eventually):
15. ✅ Add FPSConfig timeout
16. ✅ Add audio asset fallback handling

---

**End of Bug Report**
