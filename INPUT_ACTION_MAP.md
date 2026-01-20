# Input Action Map & Cross-Platform Bindings

**Date:** 2026-01-20  
**Purpose:** Comprehensive map of all input actions across PC, Mobile, and Gamepad

---

## Action Map Overview

| Category | Action Name | PC Binding | Touch Binding | Gamepad Binding | Ownership | Conflicts |
|----------|-------------|------------|---------------|-----------------|-----------|-----------|
| **MOVEMENT** | Move Forward | W | Joystick ↑ | L-Stick ↑ | FPSMovement | Menu Nav ⚠️ |
| **MOVEMENT** | Move Backward | S | Joystick ↓ | L-Stick ↓ | FPSMovement | Menu Nav ⚠️ |
| **MOVEMENT** | Move Left | A | Joystick ← | L-Stick ← | FPSMovement | Spectator ⚠️ |
| **MOVEMENT** | Move Right | D | Joystick → | L-Stick → | FPSMovement | Spectator ⚠️ |
| **MOVEMENT** | Sprint | LeftShift | Sprint Button | L3 (click stick) | FPSMovement | Alliance ⚠️ |
| **MOVEMENT** | Crouch | LeftControl / C | Crouch Button | B | FPSMovement | None |
| **MOVEMENT** | Jump | Space | Jump Button | A | FPSMovement | Menu Select ⚠️ |
| **COMBAT** | Fire Weapon | Mouse1 (LMB) | Fire Button | R2 | FPSWeaponController | None |
| **COMBAT** | Aim Down Sights | Mouse2 (RMB) | ADS Button | L2 | FPSWeaponController | None |
| **COMBAT** | Reload | R | Reload Button | X | FPSWeaponController | None |
| **COMBAT** | Switch Weapon | Q | ❌ Not Impl | Y | ❌ Not Impl | Spectator ⚠️ |
| **COMBAT** | Next Weapon | E | ❌ Not Impl | R1 | ❌ Not Impl | Spectator ⚠️ |
| **COMBAT** | Prev Weapon | Tab (unused) | ❌ Not Impl | L1 | ❌ Not Impl | Scoreboard ⚠️ |
| **UI** | Toggle Scoreboard | Tab | ❌ Missing | Select | ScoreboardUI | Prev Weapon ⚠️ |
| **UI** | Toggle Shop | B | ❌ Missing | - | ShopUI | None |
| **UI** | Toggle Alliance | LeftShift | ❌ Missing | - | AllianceUI | Sprint ⚠️ |
| **UI** | Close Modal | Backspace | X Button | B | Multiple | All UIs ⚠️ |
| **UI** | Escape/Back | Escape | Back Button | Start | ❌ Not Impl | Epilogue ⚠️ |
| **MENU NAV** | Navigate Up | W / Up | Touch Scroll | D-Pad ↑ | ShopUI, PuzzleMenuUI | Movement ⚠️ |
| **MENU NAV** | Navigate Down | S / Down | Touch Scroll | D-Pad ↓ | ShopUI, PuzzleMenuUI | Movement ⚠️ |
| **MENU NAV** | Select Item | Enter / Space | Touch/Click | A | ShopUI, PuzzleMenuUI | Jump ⚠️ |
| **SPECTATOR** | Previous Target | Q / A | ❌ Missing | D-Pad ← | SpectatorUI | Movement ⚠️ |
| **SPECTATOR** | Next Target | E / D | ❌ Missing | D-Pad → | SpectatorUI | Movement ⚠️ |
| **STORY** | Advance Dialogue | Space / Enter | ❌ Missing | A | EpilogueUI | Jump ⚠️ |
| **STORY** | Skip Epilogue | Escape | ❌ Missing | Start | EpilogueUI | None |
| **STORY** | Toggle Music | M | ❌ Missing | - | EpilogueUI | None |

### Legend
- ✅ = Fully implemented
- ⚠️ = Conflict detected
- ❌ = Not implemented / Missing

---

## Detailed Action Specifications

### 1. MOVEMENT Actions

#### Move Forward/Backward/Left/Right
```lua
-- Owner: FPSMovement.lua
-- Implementation: InputManager + legacy keyboard handler

PC Binding:
  Primary: W, A, S, D
  Alternative: Arrow Keys (not bound in current implementation)

Touch Binding:
  Virtual Joystick (left side of screen)
  - Continuous axis input
  - Normalized vector (-1 to 1)
  - Sent via InputManager.bindAxis("Movement")

Gamepad Binding:
  Left Thumbstick (Thumbstick1)
  - Continuous analog input
  - Deadzone: 0.15
  - Sent via InputManager axis callback

Conflicts:
  - W/S used by ShopUI and PuzzleMenuUI for menu navigation
  - Q/A/E/D used by SpectatorUI for target cycling
  Resolution: Check gameProcessedEvent + modal state
```

#### Sprint
```lua
-- Owner: FPSMovement.lua
-- Conflict: AllianceUI also uses LeftShift

PC Binding:
  LeftShift (hold to sprint)

Touch Binding:
  Sprint Button (top-left, near joystick)
  - Toggle or hold behavior
  - Visual feedback when active

Gamepad Binding:
  L3 (Click left stick)

Conflicts:
  - AllianceUI uses LeftShift to toggle alliance menu
  - Critical: Cannot sprint and open alliance at same time
  Resolution: Move AllianceUI to H key (Team/Help)

Stamina System:
  - Drains while sprinting
  - Regenerates when not sprinting
  - Server-authoritative, client prediction
```

#### Crouch
```lua
-- Owner: FPSMovement.lua

PC Binding:
  LeftControl or C (toggle)

Touch Binding:
  Crouch Button (bottom-left cluster)

Gamepad Binding:
  B button (toggle)

No conflicts detected
```

#### Jump
```lua
-- Owner: FPSMovement.lua
-- Conflict: Menu selection also uses Space

PC Binding:
  Space

Touch Binding:
  Jump Button (right side cluster)

Gamepad Binding:
  A button

Conflicts:
  - ShopUI, PuzzleMenuUI, EpilogueUI use Space/Enter for selection
  - Can accidentally jump while navigating menus
  Resolution: Check gameProcessedEvent, disable jump when modal open
```

---

### 2. COMBAT Actions

#### Fire Weapon
```lua
-- Owner: FPSWeaponController.lua

PC Binding:
  Mouse1 (Left Mouse Button)
  - Hold for automatic weapons
  - Click for semi-automatic

Touch Binding:
  Fire Button (bottom-right, largest button)
  - Touch and hold
  - Visual feedback on press

Gamepad Binding:
  R2 (Right Trigger)
  - Analog pressure (treated as binary)

No conflicts detected
Server-side validation with raycast
```

#### Aim Down Sights (ADS)
```lua
-- Owner: FPSWeaponController.lua

PC Binding:
  Mouse2 (Right Mouse Button)
  - Hold to aim

Touch Binding:
  ADS Button (right cluster, above crouch)
  - Toggle or hold

Gamepad Binding:
  L2 (Left Trigger)
  - Hold to aim

No conflicts detected
Camera FOV changes when aiming
Movement speed reduced while aiming
```

#### Reload
```lua
-- Owner: FPSWeaponController.lua

PC Binding:
  R key

Touch Binding:
  Reload Button (right cluster, left side)
  - Large button for easy access during combat

Gamepad Binding:
  X button

No conflicts detected
Animated reload sequence
Cannot fire during reload
```

#### Weapon Switching (Not Implemented)
```lua
-- Defined in InputManager but not connected to any system

Switch Weapon: Q (defined but unused)
Next Weapon: E (defined but unused)
Prev Weapon: Tab (defined but unused)

Conflicts:
  - Q conflicts with SpectatorUI (previous target)
  - E conflicts with SpectatorUI (next target)
  - Tab conflicts with ScoreboardUI

Recommendation:
  Use Mouse Wheel for weapon switching
  - Scroll Up = Next Weapon
  - Scroll Down = Previous Weapon
  Touch: Add weapon wheel or quick-switch buttons
```

---

### 3. UI Actions

#### Toggle Scoreboard
```lua
-- Owner: ScoreboardUI.lua
-- Current Implementation: Direct KeyCode check

PC Binding:
  Tab (press to toggle)
  - Shows/hides player leaderboard
  - No hold detection

Touch Binding:
  ❌ MISSING - Need button in top-right corner
  Proposed: Icon with player list symbol

Gamepad Binding:
  Select button (defined in InputManager but not used by ScoreboardUI)

Conflicts:
  - Tab defined as PREV_WEAPON in InputManager (not implemented)
  - If weapon switching is added, Tab will conflict
  Resolution: Keep Tab for Scoreboard, use Mouse Wheel for weapons

Implementation Status:
  - ✅ PC works
  - ❌ Touch missing
  - ⚠️ Gamepad not connected
```

#### Toggle Shop
```lua
-- Owner: ShopUI.lua
-- Current Implementation: Direct KeyCode check

PC Binding:
  B key (toggle shop interface)

Touch Binding:
  ❌ MISSING - Need button in top-right corner
  Proposed: Icon with shopping cart or vendor symbol
  Should only appear when near shop NPC or in base camp

Gamepad Binding:
  Not defined

Conflicts:
  None detected

Context:
  - Only available in base camp or near vendor
  - Contextual button appearance preferred for touch
```

#### Toggle Alliance Menu
```lua
-- Owner: AllianceUI.lua
-- CONFLICT: Uses LeftShift (same as Sprint)

PC Binding:
  LeftShift (toggle alliance management)

Touch Binding:
  ❌ MISSING - Need button in top-right corner
  Proposed: Icon with team/handshake symbol

Gamepad Binding:
  Not defined

Conflicts:
  ⚠️ CRITICAL: Conflicts with Sprint
  - Cannot sprint and open alliance menu with same key
  - Sprint is core gameplay, alliance is secondary

Resolution:
  CHANGE AllianceUI to H key (Team/Help)
  Update ControlsTutorialUI to reflect new binding
  Add notification on first Alliance unlock
```

#### Close Modal (Backspace)
```lua
-- Owners: ShopUI, PuzzleMenuUI, PuzzleUI
-- CONFLICT: All three respond to same key simultaneously

PC Binding:
  Backspace (close current UI)

Touch Binding:
  X button on each modal (individual close buttons)
  ✅ Already implemented per-modal

Gamepad Binding:
  B button (typical back/cancel on Xbox layout)

Conflicts:
  ⚠️ CRITICAL: No priority system
  - If multiple modals open (shouldn't happen), all close at once
  - No check for which modal is actually visible
  
Resolution:
  Implement modal stack system
  Only close topmost modal
  Check if modal is visible before responding to input
```

#### Escape / Global Back
```lua
-- Not centrally implemented
-- Each UI handles Escape independently

PC Binding:
  Escape key
  - EpilogueUI: Skip story (if enabled)
  - Should close topmost modal universally

Touch Binding:
  Back button (Android hardware back)
  Not currently handled

Gamepad Binding:
  Start button (pause/menu)

Current State:
  ❌ No centralized ESC handler
  ⚠️ Only EpilogueUI responds to Escape

Recommendation:
  Create global ESC handler in ClientController
  Implement modal priority stack
  ESC always closes topmost modal
  Hardware back button on Android should do same
```

---

### 4. MENU NAVIGATION Actions

#### Navigate Up/Down
```lua
-- Owners: ShopUI, PuzzleMenuUI
-- CONFLICT: Uses W/S (movement keys)

PC Binding:
  W or Up Arrow (navigate up)
  S or Down Arrow (navigate down)

Touch Binding:
  ✅ Scroll via touch drag
  ✅ Direct button taps

Gamepad Binding:
  D-Pad Up/Down

Conflicts:
  ⚠️ W/S are movement keys
  - Can walk while menu is open
  - Character moves in background during menu navigation
  
Resolution:
  Add gameProcessedEvent check
  When menu is open and focused, mark input as processed
  Prevent movement while navigating menu

Edge Case:
  - Player opens ShopUI mid-combat
  - W/S pressed for menu navigation
  - Character also tries to move
  - Potentially dangerous gameplay interaction
```

#### Select Menu Item
```lua
-- Owners: ShopUI, PuzzleMenuUI, EpilogueUI
-- CONFLICT: Uses Space (jump key) and Enter

PC Binding:
  Enter or Space

Touch Binding:
  ✅ Direct button tap
  ✅ Works correctly

Gamepad Binding:
  A button

Conflicts:
  ⚠️ Space is jump key
  - Can accidentally jump when selecting menu item
  - Especially if menu closes after selection
  
Resolution:
  Prefer Enter for selection on PC
  Space should only work when modal has input focus
  Add gameProcessedEvent check
```

---

### 5. SPECTATOR Actions

#### Cycle Spectator Targets
```lua
-- Owner: SpectatorUI.lua
-- CONFLICT: Uses Q/A/E/D (movement and weapon switch keys)

PC Binding:
  Q or A: Previous target
  E or D: Next target
  D-Pad Left/Right: Gamepad alternatives

Touch Binding:
  ❌ MISSING
  Proposed: << and >> buttons on screen when spectating

Gamepad Binding:
  D-Pad Left/Right

Conflicts:
  ⚠️ Q/A/E/D overlap with:
  - Movement (A, D)
  - Weapon switching (Q, E) (if implemented)
  
Current Mitigation:
  - Only active in spectator mode
  - Player cannot move in spectator mode
  - Weapon switching not implemented yet
  
Resolution:
  No change needed - spectator mode is mutually exclusive with combat
  But add touch buttons for mobile parity
```

---

### 6. STORY/EPILOGUE Actions

#### Advance Dialogue
```lua
-- Owner: EpilogueUI.lua
-- CONFLICT: Uses Space/Enter (jump and menu select)

PC Binding:
  Space or Enter

Touch Binding:
  ❌ MISSING
  Proposed: Large "Continue" button at bottom

Gamepad Binding:
  A button

Conflicts:
  ⚠️ Space is jump key
  - But during epilogue, player has no character to control
  - Safe conflict (different game states)

Resolution:
  Add touch button
  No PC changes needed (separate game state)
```

#### Skip Epilogue
```lua
-- Owner: EpilogueUI.lua

PC Binding:
  Escape (if StoryConfig.EpilogueSkippable is true)

Touch Binding:
  ❌ MISSING
  Proposed: "Skip" button in corner

Gamepad Binding:
  Start button

No conflicts (epilogue is full-screen state)
```

#### Toggle Music (Epilogue)
```lua
-- Owner: EpilogueUI.lua

PC Binding:
  M key

Touch Binding:
  ❌ MISSING
  Proposed: 🔊/🔇 icon button

Gamepad Binding:
  Not defined

No conflicts
Low priority (nice-to-have feature)
```

---

## Input Processing Priority System

### Priority Levels (0 = Highest)

```lua
Priority 0: GAME STATE CONTROLS
- Full-screen states that block all other input
- TitleScreenUI, LobbyUI, EpilogueUI
- When active, no other input should be processed

Priority 1: MODAL UI
- Blocks gameplay but allows HUD interaction
- ShopUI, PuzzleUI, AllianceUI, MapVotingUI
- Should consume W/S/Space/Enter/Backspace
- Movement and combat disabled while modal open

Priority 2: TOGGLE UI
- Overlays that don't block gameplay
- ScoreboardUI (Tab)
- Can be used during gameplay

Priority 3: CORE GAMEPLAY
- Movement, combat, interaction
- Always active unless higher priority consumes input
- FPSMovement, FPSWeaponController

Priority 4: PASSIVE DISPLAY
- HUD elements with no input
- WaveUI, BaseHealthUI, InventoryUI, CureUI
```

### Processing Flow

```lua
function processInput(input, gameProcessedEvent)
    -- 1. Check if input already processed by Roblox UI
    if gameProcessedEvent then return end
    
    -- 2. Check for active full-screen state (Priority 0)
    if hasFullScreenState() then
        -- Only allow state-specific inputs
        return processFullScreenInput(input)
    end
    
    -- 3. Check for active modal (Priority 1)
    if hasActiveModal() then
        local consumed = processModalInput(input)
        if consumed then return end
    end
    
    -- 4. Check for toggle UI (Priority 2)
    local consumed = processToggleInput(input)
    if consumed then return end
    
    -- 5. Process gameplay input (Priority 3)
    processGameplayInput(input)
end
```

---

## Touch Control Layout

### Mobile Screen Layout

```
┌─────────────────────────────────────────────┐
│  [Wave: 1]  [Base: 100%]  [Inventory]      │  Top HUD (always visible)
│  [Cure: 50%]                    [Alliance]  │
│                                  [Shop]     │
│                                  [Score]    │
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│              GAMEPLAY AREA                  │
│                                             │
│         [Crosshair/Hitmarker]              │
│                                             │
│     [Interact] (contextual)                │
│                                             │
├─────────────────────────────────────────────┤
│  [🕹️]                              [🔫]    │  Touch Controls
│  Joystick        [Sprint]          Fire     │
│  (Move)                    [ADS]  [Jump]   │
│                           [Reload][Crouch]  │
└─────────────────────────────────────────────┘

Legend:
- 🕹️ = Virtual joystick (movement)
- 🔫 = Primary fire button
- [Sprint] = Sprint button (above joystick)
- [ADS] = Aim down sights
- [Reload] = Reload weapon
- [Jump] = Jump button
- [Crouch] = Crouch button
- [Interact] = Contextual prompt (only appears near objects)
- [Alliance], [Shop], [Score] = Top-right UI toggles
```

### Button Size Requirements

```lua
-- From UIScaleConfig
MinimumTouchTarget = 44x44 pixels (iOS HIG standard)

Current Button Sizes:
- Fire Button: 70x70 px (scaled) ✅
- Jump Button: 70x70 px (scaled) ✅
- ADS Button: 70x70 px (scaled) ✅
- Crouch Button: 70x70 px (scaled) ✅
- Reload Button: 70x70 px (scaled) ✅
- Sprint Button: 70x70 px (scaled) ✅
- Joystick Outer: 150x150 px (scaled) ✅
- Joystick Inner: 60x60 px (scaled) ✅

Missing Buttons (Need to Add):
- Scoreboard Button: 50x50 px minimum
- Shop Button: 50x50 px minimum
- Alliance Button: 50x50 px minimum
- Spectator Prev/Next: 50x50 px each
- Interact Prompt: 80x60 px (rectangular)
```

### Safe Area Handling

```lua
-- TouchControlsUI uses UIScaleManager.getPositionWithSafeArea()
-- Respects iPhone notch, Android navigation bars, etc.

TopLeft Safe Area: (10px, 10px)
TopRight Safe Area: (-10px, 10px)
BottomLeft Safe Area: (10px, -10px)
BottomRight Safe Area: (-10px, -10px)

All touch controls positioned with safe area insets
Prevents buttons under notch or behind gesture areas
```

---

## Gamepad Support Status

### Fully Supported
- ✅ Movement (L-Stick)
- ✅ Camera (R-Stick)
- ✅ Fire (R2)
- ✅ Aim (L2)
- ✅ Jump (A)
- ✅ Crouch (B)
- ✅ Sprint (L3)
- ✅ Reload (X)

### Partially Supported
- ⚠️ Spectator cycling (D-Pad defined but not connected)
- ⚠️ Menu navigation (A for select defined but not consistently used)

### Not Supported
- ❌ Scoreboard toggle (Select button defined but not connected)
- ❌ Shop toggle
- ❌ Alliance toggle
- ❌ Weapon switching (Y, R1, L1 defined but not implemented)
- ❌ Modal closing (B should close, but not implemented)

### Gamepad Button Layout (Xbox Style)

```
         [View]              [Menu]
            |                   |
    [LB]---●---[RB]     [Y]
    [LT]---|---[RT]  [X]   [B]
           |            [A]
     [L-Stick]           [R-Stick]
         ↕︎                  ↕︎
        D-Pad           [Push=R3]
         ↕︎
    [Push=L3]

Current Mapping:
- L-Stick: Movement
- R-Stick: Camera look
- A: Jump, Menu Select, Continue
- B: Crouch, Back/Cancel
- X: Reload
- Y: (Weapon Switch - not impl)
- LB: (Prev Weapon - not impl)
- RB: (Next Weapon - not impl)
- LT (L2): Aim
- RT (R2): Fire
- L3 (L-Stick Press): Sprint
- R3: (Not assigned)
- D-Pad: Spectator cycle, Menu nav
- View (Select): Scoreboard (not connected)
- Menu (Start): Pause/ESC
```

---

## Conflict Resolution Plan

### 1. LeftShift: Sprint vs Alliance Menu

**Current:**
- FPSMovement: LeftShift = Sprint (hold)
- AllianceUI: LeftShift = Toggle alliance menu

**Problem:**
- Cannot sprint and open alliance menu
- Sprint is core gameplay, alliance is secondary
- Conflict discovered in normal gameplay

**Resolution:**
```lua
-- Change AllianceUI binding
OLD: LeftShift
NEW: H key (mnemonic: Help, Team)

-- Update files:
1. AllianceUI.lua: Change KeyCode check
2. ControlsTutorialUI.lua: Update key display
3. Add notification when alliance unlocks: "Press H to manage alliances"
```

**Implementation:**
```lua
-- In AllianceUI.lua
if input.KeyCode == Enum.KeyCode.H then  -- Changed from LeftShift
    screenGui.Enabled = not screenGui.Enabled
end
```

---

### 2. Tab: Scoreboard vs Weapon Switch

**Current:**
- ScoreboardUI: Tab = Toggle scoreboard
- InputManager: Tab = PREV_WEAPON (not implemented)

**Problem:**
- If weapon switching is implemented, Tab will conflict
- Scoreboard is actively used, weapon switch is not implemented yet

**Resolution:**
```lua
-- Keep Tab for Scoreboard (established UX)
-- Use Mouse Wheel for weapon switching when implemented

Weapon Switching:
- Mouse Wheel Up = Next Weapon
- Mouse Wheel Down = Previous Weapon
- Touch: Weapon wheel or quick-switch buttons
- Gamepad: RB (next), LB (previous) - already defined

Remove Tab from InputManager PREV_WEAPON definition
```

---

### 3. Backspace: Multiple UI Close

**Current:**
- ShopUI listens to Backspace
- PuzzleMenuUI listens to Backspace
- PuzzleUI listens to Backspace
- No coordination, all respond

**Problem:**
- If multiple UIs are open (bug), all close at once
- No priority system
- No check for UI visibility

**Resolution:**
```lua
-- Implement Modal Stack System

local ModalManager = {}
ModalManager.stack = {}

function ModalManager.push(modalName, closeCallback)
    table.insert(ModalManager.stack, {
        name = modalName,
        close = closeCallback
    })
end

function ModalManager.pop()
    if #ModalManager.stack > 0 then
        local modal = table.remove(ModalManager.stack)
        modal.close()
        return true
    end
    return false
end

-- Global Backspace/Escape handler
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
        ModalManager.pop()  -- Close topmost modal only
    end
end)

-- Each modal registers itself
-- ShopUI:
ModalManager.push("ShopUI", function()
    screenGui.Enabled = false
end)
```

---

### 4. W/S: Movement vs Menu Navigation

**Current:**
- FPSMovement: W/S = Forward/Backward
- ShopUI: W/S = Navigate menu up/down
- PuzzleMenuUI: W/S = Navigate menu up/down
- No gameProcessedEvent check

**Problem:**
- Player walks while navigating shop
- Character moves in background during menu use
- Immersion-breaking and potentially dangerous

**Resolution:**
```lua
-- Add gameProcessedEvent check to FPSMovement
function onInputBegan(input, gameProcessedEvent)
    if gameProcessedEvent then return end  -- ADD THIS
    -- ... existing code
end

-- Menu UIs should mark input as processed (Roblox handles this automatically for GuiObjects)
-- But for manual InputBegan handlers, use:
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if screenGui.Enabled then  -- If menu is open
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
            -- Handle menu navigation
            -- Roblox automatically marks as processed if GUI consumes it
        end
    end
end)
```

---

### 5. Space/Enter: Jump vs Menu Select

**Current:**
- FPSMovement: Space = Jump
- ShopUI: Space/Enter = Select item
- PuzzleMenuUI: Space/Enter = Select puzzle
- EpilogueUI: Space/Enter = Advance dialogue

**Problem:**
- Selecting menu item can cause jump after menu closes
- Jump queues up while menu is open
- Unexpected gameplay behavior

**Resolution:**
```lua
-- Similar to W/S conflict:
-- 1. Add gameProcessedEvent check to Jump handler
-- 2. Modal UIs consume Space/Enter
-- 3. Consider Enter-only for menu selection to avoid conflict

-- In FPSMovement:
InputManager.bindAction(InputManager.Action.JUMP, function(active)
    if active and not hasActiveModal() then  -- ADD MODAL CHECK
        local character = player.Character
        -- ... existing jump code
    end
end)
```

---

## Implementation Checklist

### Input System Improvements
- [ ] Create `ModalManager.lua` for modal stack system
- [ ] Add global ESC/Backspace handler
- [ ] Add gameProcessedEvent checks to all input handlers
- [ ] Change AllianceUI from LeftShift to H key
- [ ] Update ControlsTutorialUI with new AllianceUI binding
- [ ] Remove Tab from PREV_WEAPON in InputManager
- [ ] Add modal state checks to Jump action

### Missing Touch Controls
- [ ] Add Scoreboard button (top-right)
- [ ] Add Shop button (top-right, context-sensitive)
- [ ] Add Alliance button (top-right)
- [ ] Add Spectator prev/next buttons
- [ ] Add Epilogue continue/skip buttons
- [ ] Add Interact prompt (contextual, center-bottom)

### Gamepad Improvements
- [ ] Connect Select button to ScoreboardUI
- [ ] Implement weapon switching (RB/LB)
- [ ] Add B button for modal closing
- [ ] Test all gamepad bindings

### Documentation
- [ ] Update ControlsTutorialUI to show current bindings
- [ ] Add touch control tutorial for mobile
- [ ] Document conflict resolutions in CHANGELOG

---

## Testing Matrix

| Input | PC | Touch | Gamepad | Notes |
|-------|-------|--------|---------|-------|
| Movement | ✅ W/A/S/D | ⚠️ Test | ✅ L-Stick | Check modal conflicts |
| Sprint | ✅ Shift | ✅ Button | ✅ L3 | Test after AllianceUI change |
| Fire | ✅ Mouse1 | ✅ Button | ✅ R2 | All platforms working |
| Aim | ✅ Mouse2 | ✅ Button | ✅ L2 | All platforms working |
| Reload | ✅ R | ✅ Button | ✅ X | All platforms working |
| Jump | ✅ Space | ✅ Button | ✅ A | Test modal conflicts |
| Crouch | ✅ Ctrl/C | ✅ Button | ✅ B | All platforms working |
| Scoreboard | ✅ Tab | ❌ Missing | ⚠️ Not connected | Add touch + connect gamepad |
| Shop | ✅ B | ❌ Missing | ❌ Not defined | Add touch + gamepad |
| Alliance | ⚠️ Change to H | ❌ Missing | ❌ Not defined | Implement new binding |
| Close Modal | ⚠️ Test stack | ✅ X button | ⚠️ Test B | Test modal manager |
| Menu Nav | ⚠️ Test gpe | ✅ Touch | ⚠️ Test D-Pad | Check movement conflicts |
| Spectator | ✅ Q/E | ❌ Missing | ⚠️ Not connected | Add touch + connect gamepad |

---

## Summary of Required Changes

### High Priority (Breaking Conflicts)
1. ✅ Change AllianceUI from LeftShift to H key
2. ✅ Implement ModalManager stack system
3. ✅ Add gameProcessedEvent checks to all input handlers
4. ✅ Add modal state checks to Jump/Movement

### Medium Priority (Missing Features)
5. ⬜ Add touch buttons for Scoreboard, Shop, Alliance
6. ⬜ Connect gamepad Select button to Scoreboard
7. ⬜ Add Spectator touch controls

### Low Priority (Nice-to-Have)
8. ⬜ Implement weapon switching system
9. ⬜ Add Epilogue touch controls
10. ⬜ Add music toggle for touch/gamepad

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20  
**Status:** Ready for implementation
