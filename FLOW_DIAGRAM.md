# Startup Flow Diagram

## Visual Flow Chart

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SERVER BOOT                                     │
├─────────────────────────────────────────────────────────────────────────┤
│  • GameManager.new()                                                     │
│  • Create Lobby at (8000, 5, 0)                                         │
│  • Create 3 Portals (if USE_PORTAL_MATCHMAKING)                        │
│  • State = TITLE_SCREEN                                                 │
│  • NO MAP LOADED ✅                                                      │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                         PLAYER JOIN                                      │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] Join -> TitleScreen                                             │
│  • Player spawns in lobby (visible, can move)                           │
│  • Title screen UI shown                                                │
│  • Character at (8000, 8, 0)                                            │
│  • WalkSpeed = 16, not frozen                                           │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
                     Player Clicks "Continue"
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    TITLE SCREEN CONTINUE                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] TitleScreenContinue -> Lobby                                    │
│  • Mark player as ready                                                 │
│  • When ALL players ready:                                              │
│    • Check INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN                           │
│    • If FALSE (default): Go to LOBBY ✅                                 │
│    • If TRUE: Go to EPILOGUE (not recommended)                         │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
               INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN = false
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       LOBBY STATE                                        │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] Entering lobby (state -> LOBBY)                                │
│  • Players can move freely                                              │
│  • Players visible to each other                                        │
│  • 3 Portals visible:                                                   │
│    ├─ Blue neon parts (8x10x2)                                         │
│    ├─ BillboardGui showing queue (0/8)                                 │
│    └─ Touch to join queue                                              │
│  • Physical walls prevent leaving                                       │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
               ┌──────────────┴──────────────┐
               ↓                              ↓
    USE_PORTAL_MATCHMAKING      USE_PORTAL_MATCHMAKING
           = true                      = false
               ↓                              ↓
┌──────────────────────────┐     ┌──────────────────────────┐
│   PORTAL MATCHMAKING     │     │      MAP VOTING          │
├──────────────────────────┤     ├──────────────────────────┤
│ • Touch portal           │     │ • Voting UI appears      │
│ • Queue shows N/8        │     │ • Players vote           │
│ • Countdown starts (10s) │     │ • Timer counts down      │
│ • Min players reached    │     │ • Winner selected        │
└──────────────────────────┘     └──────────────────────────┘
               ↓                              ↓
               └──────────────┬──────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      MAP LOADING                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] Lobby -> MapLoading(mapId)                                      │
│  • Load map at pivot (5000, 0, 0)                                       │
│  • Configure spawners                                                    │
│  • Clear spawn bag cache                                                │
│  [Flow] MapLoaded -> Map loaded successfully                            │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      SPAWN PLAYERS                                       │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] MapLoaded -> Spawn -> Spawning N players                        │
│  • Call spawnPlayerOnMap() for each player                              │
│  • Set state = "map"                                                    │
│  • player:LoadCharacter() respawns                                      │
│  • Character at spawn point near BaseCamp                               │
│  • Players visible, can move                                            │
│  [PlayerSpawnManager] <name> -> MAP (pos)                               │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       COUNTDOWN                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] Spawn -> Countdown -> Starting countdown                        │
│  • State = COUNTDOWN                                                    │
│  • Timer = 5 seconds (default)                                          │
│  • Players can move but game hasn't started                             │
│  • UI shows countdown                                                   │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
                      Timer reaches 0
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        WAVE 1 START                                      │
├─────────────────────────────────────────────────────────────────────────┤
│  [Flow] Countdown -> Wave1 - Starting wave                              │
│  • State = WAVE_ACTIVE                                                  │
│  • Spawn zombies                                                        │
│  • Game is live!                                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Decision Points

### 1. Server Boot
```
GameManager.new()
├─ ENABLE_MULTI_MAP = true? ✅ YES
│  ├─ Load map? ❌ NO (fixed!)
│  └─ Create lobby? ✅ YES
└─ USE_PORTAL_MATCHMAKING = true? ✅ YES
   └─ Create portals? ✅ YES
```

### 2. Title Screen Continue
```
All players clicked continue?
├─ YES
│  └─ INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN?
│     ├─ TRUE → Show Epilogue (not recommended)
│     └─ FALSE → Go to Lobby ✅ (default)
└─ NO
   └─ Wait for more players
```

### 3. Lobby Exit
```
USE_PORTAL_MATCHMAKING?
├─ TRUE
│  └─ Portal queue ready?
│     ├─ Min players reached? ✅
│     ├─ Countdown complete? ✅
│     └─ Launch match → Load map
└─ FALSE
   └─ Map voting complete?
      ├─ Timer expired? ✅
      ├─ All voted? ✅
      └─ Load winning map
```

## State Transitions

```
TITLE_SCREEN
    ↓ (all players ready)
LOBBY
    ↓ (queue ready OR voting complete)
COUNTDOWN (on map)
    ↓ (timer = 0)
WAVE_ACTIVE
    ↓ (wave complete)
INTERMISSION
    ↓ (repeat)
WAVE_ACTIVE (wave 2)
    ↓ (cure complete OR base destroyed OR all dead)
VICTORY or DEFEAT
    ↓
SCOREBOARD
    ↓
EPILOGUE (if enabled) ← Only here!
    ↓
LOBBY (repeat)
```

## Important Notes

### ❌ Old (Buggy) Flow
```
SERVER BOOT → Load Map ← Wrong!
TITLE_SCREEN → EPILOGUE → LOBBY ← Wrong!
Lobby: Players frozen ← Wrong!
```

### ✅ New (Fixed) Flow
```
SERVER BOOT → Create Lobby (no map)
TITLE_SCREEN → LOBBY (skip epilogue)
Lobby: Players can move
```

### Config Impact

```
INTRO_SHOW_EPILOGUE_ON_FIRST_JOIN
├─ false (default) ✅
│  └─ Title → Lobby → Map
└─ true (not recommended) ⚠️
   └─ Title → Epilogue → Lobby → Map
```

```
USE_PORTAL_MATCHMAKING
├─ true (default) ✅
│  └─ Lobby has portals
└─ false
   └─ Lobby has voting UI
```

## Lobby Layout

```
                     Lobby Area (8000, 5, 0)
        ┌───────────────────────────────────────────┐
        │                   Wall                     │
        ├───────────────────────────────────────────┤
        │                                           │
   Wall │   Portal 1    Portal 2    Portal 3      │ Wall
        │   (-20,12,0)   (0,12,0)    (20,12,0)    │
        │                                           │
        │           Players spawn here              │
        │            (0, 8, 0)                      │
        │                                           │
        ├───────────────────────────────────────────┤
        │                   Wall                     │
        └───────────────────────────────────────────┘

                     Map Area (5000, 0, 0)
        ┌───────────────────────────────────────────┐
        │                                           │
        │              BaseCamp                      │
        │                                           │
        │   Spawn1-8    Resources    Zombies       │
        │                                           │
        │                                           │
        └───────────────────────────────────────────┘
```

## Distances

- Lobby to Map: 3000 studs apart
- Lobby: (8000, 5, 0)
- Map: (5000, 0, 0)
- This separation prevents conflicts

## Summary

✅ Clean separation: Lobby ≠ Map
✅ No map on boot
✅ Players can move in lobby
✅ Portals visible and interactive
✅ Clear state flow
✅ Comprehensive logging

Ready for testing!
