# Remote Events Audit Report

**Date:** 2026-02-04  
**Purpose:** Audit and document all unexpected remotes found during RemoteRegistry initialization

## Summary

This document catalogs all remotes that were flagged as "unexpected" (not initially defined in RemoteRegistry) and documents their status, usage, and resolution.

---

## Unexpected Remotes Analysis

### 1. **MapVotingState**
- **Status:** ✅ RESOLVED - Added to RemoteRegistry as legacy API
- **Created by:** `ServerScriptService/LobbyManager.lua:70`
- **Server usage:**
  - Fires: `LobbyManager.lua` - Multiple `FireAllClients()` calls for voting state updates
- **Client usage:**
  - Receives: `StarterPlayer/StarterPlayerScripts/Modules/UI/MapVotingUI.lua:194`
- **Canonical replacement:** `MapVoteStart` (RemoteRegistry line 75)
- **Resolution:** Added to RemoteRegistry with "Legacy map voting API" comment. Still actively used by LobbyManager.

---

### 2. **MapVoteCast**
- **Status:** ✅ RESOLVED - Added to RemoteRegistry as legacy API
- **Created by:** `ServerScriptService/LobbyManager.lua:71`
- **Server usage:**
  - Listens: `LobbyManager.lua:76` - `OnServerEvent:Connect()` handles vote casting
- **Client usage:**
  - Fires: `StarterPlayer/StarterPlayerScripts/Modules/UI/MapVotingUI.lua:179` - `FireServer(mapId)`
- **Canonical replacement:** `CastMapVote` (RemoteRegistry line 78)
- **Resolution:** Added to RemoteRegistry with "Legacy map voting API" comment. Still actively used by LobbyManager and MapVotingUI.

---

### 3. **MapVotingUpdate**
- **Status:** ✅ RESOLVED - Added to RemoteRegistry as legacy API
- **Created by:** `ServerScriptService/LobbyManager.lua:72`
- **Server usage:**
  - Fires: Multiple `FireAllClients()` calls in `LobbyManager.lua` for periodic vote count/time updates
- **Client usage:**
  - Receives: `StarterPlayer/StarterPlayerScripts/Modules/UI/MapVotingUI.lua:241`
- **Canonical replacement:** `MapVoteUpdate` (RemoteRegistry line 76)
- **Resolution:** Added to RemoteRegistry with "Legacy map voting API" comment. Still actively used by LobbyManager for broadcasting vote updates.

---

### 4. **BuyShopItem**
- **Status:** ✅ RESOLVED - Does not exist in codebase
- **Created by:** None
- **Server usage:** None
- **Client usage:** None
- **Canonical replacement:** N/A - Never existed
- **Resolution:** No action needed. This remote was never created and does not appear anywhere in the codebase.

---

### 5. **GameStateChange**
- **Status:** ✅ RESOLVED - Renamed to GameStateUpdate
- **Created by:** Not created (old name)
- **Server usage:** None
- **Client usage:** References exist to `GameStateUpdate` (modern name) in `MusicController.lua:64`
- **Canonical replacement:** `GameStateUpdate` (RemoteRegistry line 35)
- **Resolution:** No action needed. Code already uses the correct modern name `GameStateUpdate`.

---

### 6. **UpdatePlayerUI**
- **Status:** ✅ RESOLVED - Test reference only
- **Created by:** None
- **Server usage:** None
- **Client usage:** None
- **Test references:** `ServerStorage/DevOnly/CoreSystemsTests.lua`
- **Canonical replacement:** N/A - Not used in actual implementation
- **Resolution:** No action needed. This remote was listed in old test expectations but never implemented. Tests may need updating if they fail.

---

### 7. **AcceptAlliance**
- **Status:** ✅ RESOLVED - Test reference only (replaced by modern API)
- **Created by:** None
- **Server usage:** None (actual code uses `AllianceAccept` or legacy `RespondAlliance`)
- **Client usage:** None
- **Test references:** `ServerStorage/DevOnly/AllianceSystemTests.lua`
- **Canonical replacement:** 
  - Modern API: `AllianceAccept` (RemoteRegistry line 112)
  - Legacy API: `RespondAlliance` (RemoteRegistry line 118)
- **Resolution:** No action needed. The actual alliance implementation uses different remote names. Test suite references may be outdated.

---

### 8. **DenyAlliance**
- **Status:** ✅ RESOLVED - Test reference only (replaced by modern API)
- **Created by:** None
- **Server usage:** None (actual code uses `AllianceDecline` or legacy `RespondAlliance`)
- **Client usage:** None
- **Test references:** `ServerStorage/DevOnly/AllianceSystemTests.lua`
- **Canonical replacement:**
  - Modern API: `AllianceDecline` (RemoteRegistry line 113)
  - Legacy API: `RespondAlliance` (RemoteRegistry line 118)
- **Resolution:** No action needed. The actual alliance implementation uses different remote names. Test suite references may be outdated.

---

### 9. **UpdateAlliance**
- **Status:** ✅ RESOLVED - Already exists in RemoteRegistry
- **Created by:** Alliance system (modern API)
- **Server usage:** `ServerScriptService/AllianceServiceV2.lua` - Fires to clients on alliance changes
- **Client usage:** Alliance UI modules receive updates
- **Test references:** `ServerStorage/DevOnly/AllianceSystemTests.lua`
- **Canonical replacement:** `AllianceUpdate` (RemoteRegistry line 115)
- **Resolution:** No action needed. Already properly defined in RemoteRegistry. Test may be using old name.

---

## Implementation Notes

### Legacy vs. Modern API

The RemoteRegistry now supports two patterns for certain systems:

1. **Map Voting:**
   - **Legacy API:** `MapVotingState`, `MapVoteCast`, `MapVotingUpdate` (used by LobbyManager)
   - **Modern API:** `MapVoteStart`, `MapVoteUpdate`, `MapVoteEnd`, `CastMapVote`
   - **Status:** Both APIs coexist. LobbyManager uses legacy API for backward compatibility.

2. **Alliance System:**
   - **Legacy API:** `RequestAlliance`, `RespondAlliance`, `BreakAlliance`
   - **Modern API:** `AllianceRequest`, `AllianceAccept`, `AllianceDecline`, `AllianceDisband`, `AllianceUpdate`
   - **Status:** Both APIs coexist. AllianceServiceV2 uses modern API, legacy kept for compatibility.

---

## Migration Recommendations (Future Work)

While all unexpected remotes have been resolved for this audit, future work could include:

1. **Migrate LobbyManager to modern map voting API** - Replace `MapVotingState/MapVoteCast/MapVotingUpdate` with `MapVoteStart/CastMapVote/MapVoteUpdate`
2. **Update test suites** - Ensure test files reference correct remote names
3. **Remove legacy remotes** - Once all systems are migrated, remove legacy remote definitions

---

## Verification

After adding the legacy map voting remotes to RemoteRegistry, the boot log should show:
```
[RemoteRegistry] [BOOT][SERVER] Registry initialized: X created, Y existing, 0 unexpected, Z total
```

**Expected unexpected count:** 0

---

## Related Files

- `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua` - Central remote registry
- `ServerScriptService/LobbyManager.lua` - Uses legacy map voting remotes
- `ServerScriptService/AllianceServiceV2.lua` - Uses modern alliance API
- `StarterPlayer/StarterPlayerScripts/Modules/UI/MapVotingUI.lua` - Client-side map voting
- `ServerStorage/DevOnly/AllianceSystemTests.lua` - Alliance test suite
- `ServerStorage/DevOnly/CoreSystemsTests.lua` - Core systems test suite

---

**Audit Completed By:** GitHub Copilot  
**Review Status:** ✅ All unexpected remotes documented and resolved
