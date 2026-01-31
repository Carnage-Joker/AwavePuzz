# UI Inventory and Architecture Audit

**Date:** 2026-01-20  
**Purpose:** Complete audit of UI systems, controls, input architecture for mobile parity and standardization

---

## A) UI INVENTORY TABLE

| UI Name | StarterPlayerScripts | ReplicatedStorage | UI Type | Primary Inputs | RemoteEvents Used | Touch Support | Recommendation |
|---------|---------------------|-------------------|---------|----------------|-------------------|---------------|----------------|
| **FPSHUD** | ✓ LocalScript | ✗ | Always-on HUD | None (passive display) | AmmoUpdate, WeaponHitConfirm | ✓ Passive display | **KEEP** in StarterPlayerScripts |
| **PlayerHUD** | ✓ LocalScript | ✗ | Always-on HUD | None (passive display) | PlayerHealthUpdate | ✓ Passive display | **KEEP** in StarterPlayerScripts |
| **WaveUI** | ✓ LocalScript | ✓ ModuleScript | Always-on HUD | None (passive display) | WaveAnnounce, WaveUpdate | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **BaseHealthUI** | ✓ LocalScript | ✓ ModuleScript | Always-on HUD | None (passive display) | BaseHealthUpdate | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **InventoryUI** | ✓ LocalScript | ✓ ModuleScript | Always-on HUD | None (passive display) | InventoryUpdate, CurrencyUpdate | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **TouchControlsUI** | ✓ LocalScript | ✓ ModuleScript | Touch Controls | Virtual buttons/joystick | SprintRequest, WeaponFire, etc. | ✓ Primary purpose | **MERGE** - remove ReplicatedStorage |
| **ScoreboardUI** | ✓ LocalScript | ✓ ModuleScript | Panel (toggle) | Tab (PC), Touch button (mobile) | ScoreboardUpdate, ShowScoreboard, HideScoreboard | ⚠️ Needs button | **MERGE** + add touch button |
| **ShopUI** | ✓ LocalScript | ✓ ModuleScript | Panel (toggle) | B (PC), W/S nav, Enter select, Backspace close | ShopRequest, ShopUpdate | ⚠️ Needs button | **MERGE** + add touch button |
| **LobbyUI** | ✓ LocalScript | ✓ ModuleScript | Screen (state) | None (automatic) | LobbyStateUpdate | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **TitleScreenUI** | ✓ LocalScript | ✗ | Screen (state) | Space/Enter continue | ShowTitleScreen, HideTitleScreen, TitleScreenContinue | ⚠️ Needs button | **KEEP** + add touch button |
| **MapVotingUI** | ✓ LocalScript | ✓ ModuleScript | Panel (state) | Click/touch votes | CastMapVote, MapVoteStart, MapVoteUpdate, MapVoteEnd | ✓ Touch works | **MERGE** - remove ReplicatedStorage |
| **PuzzleMenuUI** | ✓ LocalScript | ✓ ModuleScript | Panel (modal) | W/S nav, Enter select, Backspace close | RequestPuzzle, OpenPuzzleUI | ⚠️ Needs button | **MERGE** + add touch button |
| **PuzzleUI** | ✓ LocalScript | ✓ ModuleScript | Panel (modal) | Backspace close, Click answer | SubmitPuzzleAnswer, PuzzleUpdate, PuzzleCompleted, PuzzleFailed | ⚠️ Needs button | **MERGE** + add touch button |
| **CureUI** | ✓ LocalScript | ✓ ModuleScript | Always-on HUD | None (passive display) | CureUpdate, PlayerCureProgressUpdate | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **SynthesisUI** | ✓ LocalScript | ✓ ModuleScript | Panel (context) | Click/touch interact | (via CureSynthesisService) | ✓ Touch works | **MERGE** - remove ReplicatedStorage |
| **AllianceUI** | ✓ LocalScript | ✓ ModuleScript | Panel (toggle) | LeftShift (PC) | RequestAlliance, RespondAlliance, BreakAlliance, AllianceUpdate | ✗ Missing button | **MERGE** + add touch button |
| **SpectatorUI** | ✓ LocalScript | ✓ ModuleScript | Screen (state) | Q/A/E/D cycle, DPad | EnterSpectatorMode, ExitSpectatorMode, SpectatorCycleTarget, SpectatorStateUpdate, SpectatorTargetUpdate | ⚠️ Needs buttons | **MERGE** + add touch buttons |
| **EpilogueUI** | ✓ LocalScript | ✗ | Screen (state) | Space/Enter advance, Esc skip, M music | ShowEpilogue, HideEpilogue, EpilogueComplete | ⚠️ Needs buttons | **KEEP** + add touch buttons |
| **AchievementUI** | ✓ LocalScript | ✓ ModuleScript | Notification | None (passive display) | AchievementUnlocked | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **CreditsUI** | ✓ LocalScript | ✓ ModuleScript | Screen (state) | None (automatic scroll) | (triggered by EpilogueUI) | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **FunFactUI** | ✓ LocalScript | ✓ ModuleScript | Notification | None (passive display) | (triggered by server) | ✓ Passive display | **MERGE** - remove ReplicatedStorage |
| **ControlsTutorialUI** | ✓ LocalScript | ✗ | Modal (one-time) | Click/touch dismiss | WaveAnnounce (listens) | ✓ Touch works | **KEEP** in StarterPlayerScripts |

### Legend
- **✓** = Exists / Working
- **✗** = Does not exist
- **⚠️** = Partially working / needs improvement

### UI Type Definitions
- **Always-on HUD**: Permanent display, no interaction
- **Panel (toggle)**: Opens/closes on demand, player-initiated
- **Panel (state)**: Opens/closes based on game state
- **Panel (modal)**: Blocks other input when open
- **Panel (context)**: Appears near interactive objects
- **Screen (state)**: Full-screen UI for game state transitions
- **Notification**: Temporary popup message

---

## B) INPUT BINDING MAP

### Current Keyboard Bindings (PC)

| Action | Primary Key | Alt Key | UI Module | Conflict? | Touch Support |
|--------|------------|---------|-----------|-----------|---------------|
| **Movement** | W/A/S/D | Arrow Keys | FPSMovement | ✗ | ✓ Joystick |
| **Sprint** | LeftShift | - | FPSMovement | ⚠️ Conflicts with AllianceUI | ✓ Button |
| **Crouch** | LeftControl | C | FPSMovement | ✗ | ✓ Button |
| **Jump** | Space | - | FPSMovement | ⚠️ Conflicts with menu selections | ✓ Button |
| **Fire** | Mouse1 | - | FPSWeaponController | ✗ | ✓ Button |
| **Aim (ADS)** | LeftAlt | - | FPSWeaponController | ✗ | ✓ Button |
| **Reload** | R | - | FPSWeaponController | ✗ | ✓ Button |
| **Toggle Scoreboard** | Tab | - | ScoreboardUI | ⚠️ Conflicts with Prev Weapon | ✗ Missing |
| **Toggle Shop** | B | - | ShopUI | ✗ | ✗ Missing |
| **Toggle Alliance** | LeftShift | - | AllianceUI | ⚠️ Conflicts with Sprint | ✗ Missing |
| **Close Modal** | Backspace | - | ShopUI, PuzzleMenuUI, PuzzleUI | ⚠️ All respond simultaneously | ✓ Close button |
| **Navigate Up** | W | Up | ShopUI, PuzzleMenuUI | ⚠️ Conflicts with Movement | ✓ Touch |
| **Navigate Down** | S | Down | ShopUI, PuzzleMenuUI | ⚠️ Conflicts with Movement | ✓ Touch |
| **Select Item** | Enter | Space | ShopUI, PuzzleMenuUI | ⚠️ Space conflicts with Jump | ✓ Touch |
| **Spectator Prev** | Q | A | SpectatorUI | ⚠️ Conflicts with Movement/Weapon Switch | ✗ Missing |
| **Spectator Next** | E | D | SpectatorUI | ⚠️ Conflicts with Movement/Use | ✗ Missing |
| **Story Advance** | Space | Enter | EpilogueUI | ⚠️ Conflicts with Jump | ✗ Missing |
| **Story Skip** | Escape | - | EpilogueUI | ✗ | ✗ Missing |
| **Toggle Music** | M | - | EpilogueUI | ✗ | ✗ Missing |

### InputManager Actions (Defined but not all used)

| Action | PC Default | Gamepad Default | Touch Mapping | Used By |
|--------|-----------|-----------------|---------------|---------|
| MOVE_FORWARD | W | Thumbstick1 Y+ | VirtualJoystick | FPSMovement |
| MOVE_BACKWARD | S | Thumbstick1 Y- | VirtualJoystick | FPSMovement |
| MOVE_LEFT | A | Thumbstick1 X- | VirtualJoystick | FPSMovement |
| MOVE_RIGHT | D | Thumbstick1 X+ | VirtualJoystick | FPSMovement |
| SPRINT | LeftShift | ButtonL3 | VirtualButton_Sprint | FPSMovement |
| CROUCH | LeftControl, C | ButtonB | VirtualButton_Crouch | FPSMovement |
| JUMP | Space | ButtonA | VirtualButton_Jump | FPSMovement |
| FIRE | Mouse1 | ButtonR2 | VirtualButton_Fire | FPSWeaponController |
| AIM | LeftAlt | ButtonL2 | VirtualButton_Aim | FPSWeaponController |
| RELOAD | R | ButtonX | VirtualButton_Reload | FPSWeaponController |
| SWITCH_WEAPON | Q | ButtonY | - | ❌ Not implemented |
| NEXT_WEAPON | E | ButtonR1 | - | ❌ Not implemented |
| PREV_WEAPON | Tab | ButtonL1 | - | ❌ Not implemented |
| INTERACT | F | ButtonX | VirtualButton_Interact | ❌ Not implemented |
| USE | E | ButtonA | - | ❌ Conflicts with NEXT_WEAPON |
| MENU | Escape | ButtonStart | VirtualButton_Menu | ❌ Not centralized |
| PAUSE | P | ButtonStart | - | ❌ Not implemented |
| SCOREBOARD | Tab | ButtonSelect | - | ❌ Uses direct binding |
| INVENTORY | I | DPadUp | - | ❌ Not implemented (passive display) |
| MAP | M | DPadDown | - | ❌ Not implemented |

---

## C) IDENTIFIED CONFLICTS AND ISSUES

### Critical Input Conflicts

1. **LeftShift: Sprint vs Alliance Toggle**
   - FPSMovement uses for sprint (core gameplay)
   - AllianceUI uses for alliance menu (secondary feature)
   - **Resolution:** Move AllianceUI to different key (suggest: H for "Help" or T for "Team")

2. **Tab: Scoreboard vs Weapon Switch**
   - ScoreboardUI uses for toggle
   - InputManager defines for PREV_WEAPON (not implemented yet)
   - **Resolution:** Keep Tab for Scoreboard, use Mouse Wheel or different keys for weapon switching

3. **Backspace: Multiple UI Close**
   - ShopUI, PuzzleMenuUI, PuzzleUI all listen to Backspace
   - No priority system - all respond simultaneously
   - **Resolution:** Implement modal stack/priority system

4. **W/S: Movement vs Menu Navigation**
   - FPSMovement uses for forward/backward
   - ShopUI and PuzzleMenuUI use for menu navigation
   - No `gameProcessedEvent` check to prevent double-triggering
   - **Resolution:** Add proper GPE checks, only allow menu nav when UI is focused

5. **Space/Enter: Jump vs Menu Select**
   - FPSMovement uses Space for jump
   - ShopUI, PuzzleMenuUI, EpilogueUI use Space/Enter for selections
   - **Resolution:** Add proper GPE checks, disable jump when modal is open

6. **Q/A/E/D: Spectator vs Movement/Weapon**
   - SpectatorUI uses for cycling targets
   - Core gameplay uses for movement and weapon switching
   - **Resolution:** Only active in spectator mode, but needs proper mode check

### Missing Touch Controls

| Feature | Status | Required Action |
|---------|--------|-----------------|
| Scoreboard Toggle | ❌ Missing | Add button to TouchControlsUI (top-right corner) |
| Shop Toggle | ❌ Missing | Add button to TouchControlsUI (top-right corner) |
| Alliance Menu | ❌ Missing | Add button to TouchControlsUI (top-right corner) |
| Spectator Controls | ❌ Missing | Add prev/next buttons when in spectator mode |
| Epilogue Controls | ❌ Missing | Add touch buttons for advance/skip/music |
| Close Modal (ESC) | ⚠️ Partial | Each modal has X button, but no unified ESC handler |

### Connection Leaks

**StarterPlayerScripts UI Modules without cleanup:**
- AllianceUI
- EpilogueUI
- PuzzleMenuUI
- ScoreboardUI
- ShopUI
- SpectatorUI

**Pattern:** Direct `UserInputService.InputBegan:Connect()` without storing connection or cleanup on hide/destroy

**Resolution:** Add connection tracking table and disconnect on UI hide/character death

### Duplicate Code (17 modules)

**Modules with both StarterPlayerScripts and ReplicatedStorage versions:**
- AllianceUI, AchievementUI, BaseHealthUI, CreditsUI, CureUI
- FunFactUI, InventoryUI, LobbyUI, MapVotingUI, PuzzleMenuUI
- PuzzleUI, ScoreboardUI, ShopUI, SpectatorUI, SynthesisUI
- TouchControlsUI, WaveUI

**Current State:**
- Only StarterPlayerScripts versions are loaded/executed
- ReplicatedStorage versions are dead code (never required)
- ReplicatedStorage versions have better structure (ModuleScript pattern with cleanup)

**Resolution:** Delete ReplicatedStorage duplicates OR migrate all to ReplicatedStorage

---

## D) ARCHITECTURE DECISION

### Chosen Pattern: **ModuleScript-First with ClientController Bootstrap**

**Rationale:**
1. ✓ Single source of truth (no duplicates)
2. ✓ Proper initialization order control
3. ✓ Connection tracking and cleanup built-in
4. ✓ Respawn-safe (can reinitialize without leaks)
5. ✓ Easier to test and maintain
6. ✓ ReplicatedStorage versions already have better structure

### Implementation:

```lua
-- Standard UI Module Pattern
local UIModuleName = {}
UIModuleName._initialized = false
UIModuleName._connections = {}
UIModuleName._screenGui = nil

function UIModuleName.initialize()
    if UIModuleName._initialized then
        warn("[UIModuleName] Already initialized")
        return
    end
    
    -- Create UI
    UIModuleName._screenGui = Instance.new("ScreenGui")
    -- ... UI creation ...
    
    -- Setup input (if needed)
    local conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end -- ALWAYS CHECK THIS
        -- Handle input
    end)
    table.insert(UIModuleName._connections, conn)
    
    UIModuleName._initialized = true
    print("[UIModuleName] Initialized")
end

function UIModuleName.destroy()
    -- Disconnect all connections
    for _, conn in ipairs(UIModuleName._connections) do
        conn:Disconnect()
    end
    UIModuleName._connections = {}
    
    -- Destroy GUI
    if UIModuleName._screenGui then
        UIModuleName._screenGui:Destroy()
        UIModuleName._screenGui = nil
    end
    
    UIModuleName._initialized = false
end

return UIModuleName
```

### Folder Structure (After Refactor):

```
StarterPlayer/StarterPlayerScripts/
├── ClientController.client.lua         # ONLY LocalScript - bootstrap everything
├── Modules/
│   ├── UI/                             # ALL UI ModuleScripts
│   │   ├── FPSHUD.lua                 # Core HUD
│   │   ├── PlayerHUD.lua
│   │   ├── WaveUI.lua
│   │   ├── BaseHealthUI.lua
│   │   ├── CureUI.lua
│   │   ├── InventoryUI.lua
│   │   ├── TouchControlsUI.lua
│   │   ├── ScoreboardUI.lua          # Panels
│   │   ├── ShopUI.lua
│   │   ├── AllianceUI.lua
│   │   ├── PuzzleMenuUI.lua
│   │   ├── PuzzleUI.lua
│   │   ├── SynthesisUI.lua
│   │   ├── MapVotingUI.lua
│   │   ├── LobbyUI.lua               # Screens
│   │   ├── TitleScreenUI.lua
│   │   ├── EpilogueUI.lua
│   │   ├── SpectatorUI.lua
│   │   ├── AchievementUI.lua         # Notifications
│   │   ├── CreditsUI.lua
│   │   ├── FunFactUI.lua
│   │   └── ControlsTutorialUI.lua
│   ├── FPSMovement.lua                # Core gameplay
│   ├── FPSWeaponController.lua
│   ├── FirstPersonCamera.lua
│   ├── FPSAnimationController.lua
│   ├── FPSAudioController.lua
│   ├── FPSMenuController.lua
│   ├── MusicController.lua
│   └── StaminaClient.lua

ReplicatedStorage/
├── Shared/                             # Shared utilities
│   ├── InputManager.lua               # ✓ Cross-platform input
│   ├── UIScaleManager.lua             # ✓ Mobile scaling
│   ├── GameConfig.lua
│   ├── FPSConfig.lua
│   ├── WeaponConfig.lua
│   └── ...
└── RemoteEvents/                       # Server-client communication

StarterGui/                              # DELETE ALL .lua.disabled files
└── (empty - no UI scripts here)
```

**Rules:**
1. ✅ **ONE LocalScript**: `ClientController.client.lua` only
2. ✅ **ALL UI as ModuleScripts**: In `StarterPlayerScripts/Modules/UI/`
3. ✅ **Shared utilities**: In `ReplicatedStorage/Shared/`
4. ✅ **No StarterGui scripts**: Pure UI instances only (if needed)
5. ✅ **No ReplicatedStorage/Client/UI**: Eliminate duplicate location

---

## E) INPUT MANAGEMENT SYSTEM

### Centralized Input Action Map

Create `InputActionRegistry.lua` in `ReplicatedStorage/Shared/`:

```lua
local InputActionRegistry = {}
InputActionRegistry._registeredActions = {}
InputActionRegistry._activeModals = {} -- Stack of open modals

-- Register an action with conflict detection
function InputActionRegistry.registerAction(actionName, keys, owner, priority)
    -- Check for conflicts
    for keyCode, _ in pairs(keys) do
        for existingAction, data in pairs(InputActionRegistry._registeredActions) do
            if data.keys[keyCode] and data.priority == priority then
                warn(string.format(
                    "[INPUT CONFLICT] Action '%s' (%s) conflicts with '%s' (%s) on key %s",
                    actionName, owner, existingAction, data.owner, tostring(keyCode)
                ))
            end
        end
    end
    
    InputActionRegistry._registeredActions[actionName] = {
        keys = keys,
        owner = owner,
        priority = priority or 0
    }
end

-- Modal management
function InputActionRegistry.pushModal(modalName)
    table.insert(InputActionRegistry._activeModals, modalName)
end

function InputActionRegistry.popModal(modalName)
    -- Remove from stack
end

function InputActionRegistry.hasActiveModal()
    return #InputActionRegistry._activeModals > 0
end

-- Startup audit
function InputActionRegistry.auditConflicts()
    print("=== Input Action Registry Audit ===")
    for action, data in pairs(InputActionRegistry._registeredActions) do
        print(string.format("  %s: %s (priority %d)", action, data.owner, data.priority))
    end
end

return InputActionRegistry
```

### Priority Levels
- **0** = Core gameplay (movement, shooting)
- **1** = HUD toggles (scoreboard, inventory)
- **2** = Modals (shop, puzzle, alliance)
- **3** = Full-screen (epilogue, title)

---

## F) MOBILE TOUCH PARITY CHECKLIST

### Always-On Touch Controls ✓
- [x] Virtual joystick (movement)
- [x] Fire button
- [x] Aim button
- [x] Jump button
- [x] Crouch button
- [x] Reload button
- [x] Sprint button

### Missing Touch Controls (High Priority)
- [ ] **Scoreboard button** (top-right, next to settings)
- [ ] **Shop button** (top-right, next to scoreboard)
- [ ] **Alliance button** (top-right, next to shop)
- [ ] **Interact prompt** (context-sensitive, center-bottom)

### Missing Touch Controls (Medium Priority)
- [ ] **Spectator controls** (prev/next buttons, only in spectator mode)
- [ ] **Epilogue controls** (next/skip buttons during story)
- [ ] **Puzzle confirm** (submit button for puzzle answers)

### Touch Button Sizing
- ✓ Minimum touch target: 44x44 pixels (UIScaleConfig)
- ✓ Thumb zone positioning (bottom corners)
- ✓ Safe area insets respected
- ✓ Dynamic scaling based on screen size

### Touch-Specific Issues
- [ ] Backspace has no touch equivalent (use X button on modals)
- [ ] Tab has no touch equivalent (add scoreboard button)
- [ ] All menu navigation needs touch-friendly scrolling

---

## G) GUI CLUTTER REDUCTION PLAN

### Always-On HUD Elements (Top-Left)
1. **WaveUI** - Wave counter (top)
2. **BaseHealthUI** - Base health (below wave)
3. **InventoryUI** - Components & currency (below base health)
4. **CureUI** - Cure progress bar (below inventory)

### Always-On HUD Elements (Top-Right)
1. **PlayerHUD** - Player health bar
2. **AchievementUI** - Achievement popups (temporary)

### Always-On HUD Elements (Bottom)
1. **FPSHUD** - Crosshair, ammo, hitmarkers (center)
2. **TouchControlsUI** - Virtual controls (corners, mobile only)

### Panels (Toggleable)
- **ScoreboardUI** - Toggle with Tab or touch button
- **ShopUI** - Toggle with B or touch button
- **AllianceUI** - Toggle with H or touch button
- **PuzzleMenuUI** - Opens contextually near cure station
- **SynthesisUI** - Opens contextually near synthesis station

### Modals (Single at a time)
- **PuzzleUI** - Puzzle mini-game (blocks other modals)
- **MapVotingUI** - Map vote screen (lobby only)
- **EpilogueUI** - Story sequence (blocks all)

### Full-Screen States
- **TitleScreenUI** - Initial loading
- **LobbyUI** - Pre-game lobby
- **SpectatorUI** - Death spectator mode
- **CreditsUI** - End credits

### Panel Priority Rules
```lua
-- Only one modal can be open
local modalStack = {
    -- Top of stack = highest priority (blocks everything below)
}

function openModal(modalName)
    -- Close all other modals first
    if #modalStack > 0 then
        closeModal(modalStack[#modalStack])
    end
    table.insert(modalStack, modalName)
end

function closeModal(modalName)
    -- Remove from stack
end

-- ESC key closes top modal
UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Escape and #modalStack > 0 then
        closeModal(modalStack[#modalStack])
    end
end)
```

---

## H) SCRIPTS TO REMOVE/MERGE

### Delete Entirely (StarterGui disabled scripts - already done)
All `.lua.disabled` files in `StarterGui/` - these are backups, not needed

### Delete (ReplicatedStorage duplicates)
Move to Archive first, then delete after confirming StarterPlayerScripts versions work:
- `ReplicatedStorage/Client/UI/AllianceUI.lua`
- `ReplicatedStorage/Client/UI/AchievementUI.lua`
- `ReplicatedStorage/Client/UI/BaseHealthUI.lua`
- `ReplicatedStorage/Client/UI/CreditsUI.lua`
- `ReplicatedStorage/Client/UI/CureUI.lua`
- `ReplicatedStorage/Client/UI/FunFactUI.lua`
- `ReplicatedStorage/Client/UI/InventoryUI.lua`
- `ReplicatedStorage/Client/UI/LobbyUI.lua`
- `ReplicatedStorage/Client/UI/MapVotingUI.lua`
- `ReplicatedStorage/Client/UI/PuzzleMenuUI.lua`
- `ReplicatedStorage/Client/UI/PuzzleUI.lua`
- `ReplicatedStorage/Client/UI/ScoreboardUI.lua`
- `ReplicatedStorage/Client/UI/ShopUI.lua`
- `ReplicatedStorage/Client/UI/SpectatorUI.lua`
- `ReplicatedStorage/Client/UI/SynthesisUI.lua`
- `ReplicatedStorage/Client/UI/TouchControlsUI.lua`
- `ReplicatedStorage/Client/UI/WaveUI.lua`

**Total: 17 duplicate files to remove**

---

## I) IMPLEMENTATION PHASES

### Phase 1: Remove Duplicates ✓
1. Archive ReplicatedStorage/Client/UI folder
2. Delete ReplicatedStorage/Client/UI folder
3. Verify all UI still works from StarterPlayerScripts

### Phase 2: Standardize Module Pattern
1. Add connection tracking to all UI modules
2. Add `destroy()` function to all UI modules
3. Add `_initialized` flag and idempotency checks
4. Add `gameProcessedEvent` checks to all input handlers

### Phase 3: Create Input Registry
1. Create `InputActionRegistry.lua`
2. Register all actions with conflict detection
3. Run startup audit and log conflicts
4. Create modal stack system

### Phase 4: Resolve Input Conflicts
1. Move AllianceUI from LeftShift to H key
2. Implement ESC handler for modal closing
3. Add priority checks for W/S/Space/Enter when modals open
4. Disable jump when modal is active

### Phase 5: Add Missing Touch Controls
1. Add Scoreboard button to TouchControlsUI
2. Add Shop button to TouchControlsUI
3. Add Alliance button to TouchControlsUI
4. Add Spectator prev/next buttons (contextual)
5. Add Epilogue controls (contextual)

### Phase 6: Test & Polish
1. PC keyboard/mouse testing
2. Mobile emulator testing
3. Respawn testing (check for leaks)
4. Round transition testing
5. Performance profiling

---

## J) SUCCESS CRITERIA

### Functionality
- ✅ All UI modules load without errors
- ✅ No duplicate UI instances
- ✅ All inputs work on PC
- ✅ All inputs work on mobile/touch
- ✅ No memory leaks on respawn

### Architecture
- ✅ Single source of truth for each UI
- ✅ Consistent ModuleScript pattern
- ✅ Proper connection cleanup
- ✅ No dead code in repository

### Input System
- ✅ No unhandled conflicts
- ✅ All conflicts logged on startup
- ✅ Modal priority system working
- ✅ ESC closes top modal
- ✅ Touch parity with PC

### Mobile Experience
- ✅ All actions accessible on touch
- ✅ Buttons meet minimum touch target size
- ✅ No tiny text issues
- ✅ Responsive layouts
- ✅ No hover-only interactions

### Performance
- ✅ No duplicate per-frame loops
- ✅ No connection leaks
- ✅ Smooth 60fps on mid-range devices

---

## K) RISK ASSESSMENT

### Low Risk
- Removing ReplicatedStorage duplicates (not loaded anyway)
- Adding gameProcessedEvent checks (defensive fix)
- Connection tracking (internal improvement)

### Medium Risk
- Changing keybindings (AllianceUI: LeftShift → H)
  - Mitigation: Update ControlsTutorialUI, add notification
- Modal priority system (new architecture)
  - Mitigation: Test thoroughly, keep old behavior as fallback

### High Risk
- None identified - changes are surgical and backwards-compatible

---

## L) NEXT STEPS

1. ✅ Complete this inventory document
2. Create InputActionRegistry.lua
3. Standardize all UI modules to ModuleScript pattern
4. Remove ReplicatedStorage/Client/UI duplicates
5. Add missing touch controls
6. Test on PC and mobile emulator
7. Final validation and performance check
