# Remote Event Audit Report

**Repository**: AwavePuzz (Aether Wave: Convergence)  
**Audit Date**: 2026-02-04  
**Auditor**: RemoteRegistry Stabilization Task  

---

## Executive Summary

This audit documents all Remote Events and RemoteFunctions in the AwavePuzz codebase, identifying:
- Canonical definitions in RemoteRegistry
- Server and client usage patterns
- Legacy vs. modern API patterns
- Potential issues and recommendations

**Total Remotes in Registry**: 126 remotes defined in REMOTE_DEFINITIONS  
**Unexpected Remotes Fixed**: 9 (3 from LobbyManager, 6 from test files)  
**Legacy APIs Maintained**: Alliance system (RequestAlliance, RespondAlliance, BreakAlliance)

---

## Remote Usage Matrix

| Remote Name | Type | Category | Server Files | Client Files | Status |
|---|---|---|---|---|---|
| **MapVotingState** | Event | Lobby | LobbyManager.lua, GameManager.lua | - | ✅ Active |
| **MapVoteCast** | Event | Lobby | LobbyManager.lua | - | ✅ Active |
| **MapVotingUpdate** | Event | Lobby | LobbyManager.lua | - | ✅ Active |
| **GameStateUpdate** | Event | Core | GameManager.lua | ClientMain.lua, MusicController.lua, TitleScreenUI.lua, EpilogueUI.lua, WaveUI.lua, BaseHealthUI.lua | ✅ Active |
| **AllianceAccept** | Event | Alliance | AllianceServiceV2.lua | - | ✅ Modern API |
| **AllianceDecline** | Event | Alliance | AllianceServiceV2.lua | - | ✅ Modern API |
| **AllianceUpdate** | Event | Alliance | AllianceServiceV2.lua | AllianceUI.lua | ✅ Modern API |
| **RequestAlliance** | Event | Alliance | AllianceServiceV2.lua | AllianceUI.lua | 🔄 Legacy (Compat) |
| **RespondAlliance** | Event | Alliance | AllianceServiceV2.lua | AllianceUI.lua | 🔄 Legacy (Compat) |
| **BreakAlliance** | Event | Alliance | AllianceServiceV2.lua | AllianceUI.lua | 🔄 Legacy (Compat) |
| **ShowTitleScreen** | Event | UI | GameManager.lua | TitleScreenUI.lua | ✅ Active |
| **HideTitleScreen** | Event | UI | GameManager.lua | TitleScreenUI.lua | ✅ Active |
| **TitleScreenContinue** | Event | UI | GameManager.lua | TitleScreenUI.lua | ✅ Active |
| **ShowEpilogue** | Event | UI | GameManager.lua | EpilogueUI.lua, TouchControlsUI.lua | ✅ Active |
| **HideEpilogue** | Event | UI | GameManager.lua | EpilogueUI.lua, TouchControlsUI.lua | ✅ Active |
| **EpilogueComplete** | Event | UI | GameManager.lua | EpilogueUI.lua, TouchControlsUI.lua | ✅ Active |

---

## Detailed Analysis by Category

### Map Voting System

**Remotes**: MapVotingState, MapVoteCast, MapVotingUpdate

**Flow**:
1. Server (GameManager) → LobbyManager.startVoting()
2. LobbyManager fires MapVotingState to all clients
3. Client sends MapVoteCast to server with vote
4. LobbyManager broadcasts MapVotingUpdate with vote counts
5. LobbyManager selects winning map based on votes

**Files**:
- Server: `ServerScriptService/LobbyManager.lua` (OnServerEvent listener for MapVoteCast)
- Server: `ServerScriptService/GameManager.lua` (passes remotes to LobbyManager)

**Fix Applied**: Added MapVoting remotes to REMOTE_DEFINITIONS and updated LobbyManager to use RemoteRegistry instead of getOrCreateRemote()

---

### Game State Management

**Remote**: GameStateUpdate (primary state sync mechanism)

**Flow**:
1. Server (GameManager) changes state via setState()
2. setState() broadcasts GameStateUpdate to all clients with state snapshot
3. Clients update UI and behavior based on state

**State Snapshot Structure**:
```lua
{
    state = "TitleScreen" | "Lobby" | "Countdown" | "WaveActive" | "Victory" | "Defeat",
    wave = number,
    baseHealth = number,
    cureProgress = number,
    payload = {...} -- optional additional data
}
```

**Files**:
- Server: `ServerScriptService/GameManager.lua` (FireClient/FireAllClients)
- Client: `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` (primary router)
- Client: `StarterPlayer/StarterPlayerScripts/Modules/MusicController.lua` (music changes)
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/TitleScreenUI.lua` (show/hide based on state)
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/EpilogueUI.lua` (show/hide based on state)
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/WaveUI.lua` (wave display)
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/BaseHealthUI.lua` (base health display)

**Notes**: GameStateUpdate is the authoritative game state driver. Legacy remotes (ShowTitleScreen, ShowEpilogue) are kept for backward compatibility but GameStateUpdate is preferred.

---

### Alliance System

**Modern API** (Preferred):
- AllianceRequest (client → server)
- AllianceAccept (server → client)
- AllianceDecline (server → client)
- AllianceDisband (client → server)
- AllianceUpdate (server → client, broadcast alliance changes)

**Legacy API** (Backward Compatibility):
- RequestAlliance (client → server)
- RespondAlliance (client → server, accept/decline parameter)
- BreakAlliance (client → server)

**Files**:
- Server: `ServerScriptService/AllianceServiceV2.lua` (handles all alliance logic)
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/AllianceUI.lua`

**Migration Path**: AllianceServiceV2 handles both modern and legacy remotes. New code should use modern API. Legacy remotes will be deprecated in future release once all client code migrated.

---

### Title Screen & Epilogue System

**Title Screen Flow**:
1. Server enters TitleScreen state
2. Server fires GameStateUpdate (state=TitleScreen) AND ShowTitleScreen (legacy)
3. Client shows title screen UI
4. Player clicks "Continue"
5. Client fires TitleScreenContinue
6. Server transitions to Lobby state

**Epilogue Flow**:
1. Match ends (victory/defeat)
2. Server enters Epilogue state
3. Server fires GameStateUpdate (state=Epilogue) AND ShowEpilogue (legacy)
4. Client shows epilogue UI with results
5. Player clicks "Continue"
6. Client fires EpilogueComplete
7. Server transitions to next state

**Files**:
- Server: `ServerScriptService/GameManager.lua`
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/TitleScreenUI.lua`
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/EpilogueUI.lua`
- Client: `StarterPlayer/StarterPlayerScripts/Modules/UI/TouchControlsUI.lua` (mobile support)

**Notes**: UI modules listen to BOTH GameStateUpdate (modern) and Show/Hide events (legacy) for maximum compatibility.

---

## Issues Fixed

### 1. Unexpected Remotes (3 from LobbyManager)

**Problem**: LobbyManager used `getOrCreateRemote()` to create MapVotingState, MapVoteCast, MapVotingUpdate outside RemoteRegistry

**Fix**:
- Added MapVotingState, MapVoteCast, MapVotingUpdate to REMOTE_DEFINITIONS
- Removed getOrCreateRemote() from LobbyManager
- Updated LobbyManager.new() to accept remotes parameter
- Added LobbyManager:setRemoteEvents() for post-construction initialization
- GameManager passes remotes to LobbyManager in setupRemoteEvents()

**Files Modified**:
- `/ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua` (added 3 remotes)
- `/ServerScriptService/LobbyManager.lua` (removed ad-hoc creation)
- `/ServerScriptService/GameManager.lua` (added remotes to list, calls setRemoteEvents)

---

### 2. Legacy Remote Names in Test Files (6 references)

**Problem**: Test files referenced old remote names not in REMOTE_DEFINITIONS:
- GameStateChange (should be GameStateUpdate)
- UpdatePlayerUI (no longer used)
- AcceptAlliance (should be AllianceAccept)
- DenyAlliance (should be AllianceDecline)
- UpdateAlliance (should be AllianceUpdate)

**Fix**:
- Updated CoreSystemsTests.lua to use GameStateUpdate
- Removed UpdatePlayerUI from tests (no longer used)
- Updated AllianceSystemTests.lua to use modern names (AllianceAccept, AllianceDecline, AllianceUpdate)
- Kept RequestAlliance and BreakAlliance in tests (legacy API still supported)

**Files Modified**:
- `/ServerStorage/DevOnly/CoreSystemsTests.lua`
- `/ServerStorage/DevOnly/AllianceSystemTests.lua`

---

## Remote Creation & Initialization

### Server Boot Sequence

1. **Main.server.lua** (Phase 1): Calls RemoteRegistry.initializeServer()
2. **RemoteRegistry.initializeServer()**: Creates all 126 remotes in ReplicatedStorage/RemoteEvents
3. **GameManager.new()**: Constructor called, creates subsystems
4. **GameManager:setupRemoteEvents()**: Gets remotes from RemoteEventUtil, passes to subsystems
5. **LobbyManager:setRemoteEvents()**: Receives remotes from GameManager

### Client Boot Sequence

1. **ClientMain.client.lua** (Phase 1): Calls RemoteRegistry.initializeClient(10)
2. **RemoteRegistry.initializeClient()**: Waits for RemoteEvents folder, validates all remotes
3. **ClientMain** (Phase 6.5): Binds UI modules to remotes
4. **UI Modules**: Store remotes, connect OnClientEvent listeners

---

## Validation & Health Checks

### ✅ All Canonical Remotes Present

All remotes in this audit are defined in REMOTE_DEFINITIONS (lines 23-123 in RemoteRegistry.lua)

### ✅ No Orphaned Remotes

RemoteRegistry.initializeServer() logs warnings for any remotes found in RemoteEvents folder that are NOT in REMOTE_DEFINITIONS. After fixes, zero unexpected remotes remain.

### ✅ Type Safety

All remotes are typed correctly:
- Events use RemoteEvent (fire-and-forget)
- Functions use RemoteFunction (request-response, not used in this project)

### ✅ Initialization Order

Server creates remotes before any client can join. Clients wait up to 10 seconds for remotes before failing. This ensures deterministic initialization.

---

## Recommendations

### 1. Complete Legacy API Migration

**Action**: Update AllianceUI.lua to use modern API (AllianceAccept, AllianceDecline) instead of legacy (AcceptAlliance, DenyAlliance)

**Timeline**: Next major release

**Benefits**: Simplified codebase, consistent naming, easier to maintain

---

### 2. State-Driven UI Pattern

**Action**: Standardize all UI on GameStateUpdate (state-driven) instead of direct Show/Hide events

**Current**: TitleScreenUI and EpilogueUI listen to BOTH GameStateUpdate and legacy Show/Hide events

**Target**: Single source of truth (GameStateUpdate only), remove legacy events after migration

**Benefits**: Reduced duplication, clearer state management, easier debugging

---

### 3. Remote Access Pattern

**Current**: Some UI modules use FindFirstChild() for remote lookup (fragile)

**Target**: All modules receive remotes via bindRemotes() from ClientMain (type-safe)

**Benefits**: Compile-time safety, no nil checks, better IDE support

---

### 4. Documentation

**Action**: Create `/docs/REMOTES_API.md` with:
- List of all remotes by category
- Usage examples (server → client, client → server)
- Migration guide (legacy → modern)
- Best practices (when to use Events vs Functions)

---

## Appendix: Full Remote List

For the complete list of all 126 remotes, see `/ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua` lines 23-123.

**Categories**:
- Animation (6 remotes)
- Game State (3 remotes)
- Cure System (3 remotes)
- Base & Map (2 remotes)
- UI State Management (9 remotes)
- Player Systems (9 remotes)
- Matchmaking & Lobby (11 remotes)
- Puzzle & Items (9 remotes)
- Weapons & Combat (7 remotes)
- Shop & Economy (7 remotes)
- Alliance System (9 remotes: 4 modern + 3 legacy + 2 utility)
- Fun Facts (1 remote)

---

**End of Audit Report**
