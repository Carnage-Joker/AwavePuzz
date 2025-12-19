# Weapon Animation System Documentation

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Animation Types](#animation-types)
- [Viewmodel System](#viewmodel-system)
- [Procedural Animations](#procedural-animations)
- [Integration Guide](#integration-guide)
- [Creating Animations](#creating-animations)
- [Asset Requirements](#asset-requirements)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

The weapon animation system provides a comprehensive first-person animation framework for AwavePuzz's FPS mechanics. It includes:

- **Viewmodel arms** - First-person arm models visible to the player
- **Weapon animations** - Idle, fire, reload, equip, sprint, and ADS animations
- **Procedural animations** - Weapon sway, breathing motion, and recoil recovery
- **Animation blending** - Smooth transitions between animation states
- **Full integration** - Works seamlessly with the existing FPS weapon controller

### Key Features

✅ **Full animation state management** - Handles all weapon animation states  
✅ **Procedural enhancements** - Adds weapon sway, breathing, and recoil  
✅ **Viewmodel system** - Dedicated first-person arm and weapon rendering  
✅ **Event-driven** - Integrates with weapon controller via bindable events  
✅ **Configurable** - All settings exposed in `FPSConfig.Animations`  
✅ **Asset-ready** - Supports Roblox animation assets when provided  

---

## Architecture

### File Structure

```
src/
├── client/
│   ├── FPSAnimationController.client.lua    -- Main animation system
│   ├── FPSWeaponController.client.lua        -- Weapon mechanics (updated)
│   └── FPSMovementController.client.lua      -- Movement (sprint events)
└── shared/
    └── FPSConfig.lua                         -- Animation configuration
```

### System Components

1. **FPSAnimationController** - Core animation manager
   - Creates and manages viewmodel
   - Loads and plays animations
   - Handles procedural animations
   - Listens for weapon/movement events

2. **FPSWeaponController** - Weapon mechanics
   - Fires animation events when weapons are used
   - Manages weapon state (firing, reloading, ADS)

3. **FPSMovementController** - Movement system
   - Broadcasts sprint state changes
   - Affects animation state (sprint animations)

4. **FPSConfig.Animations** - Configuration
   - Animation asset IDs
   - Procedural animation settings
   - Viewmodel offsets

### Communication Flow

```
FPSWeaponController                 FPSAnimationController
      │                                     │
      ├─ Fire Weapon ────────────────────► playFire()
      ├─ Start Reload ───────────────────► playReload()
      ├─ Equip Weapon ───────────────────► equipWeapon()
      ├─ ADS Toggle ─────────────────────► setADS()
      │                                     │
FPSMovementController                       │
      │                                     │
      └─ Sprint Toggle ──────────────────► setSprinting()
```

Events are communicated via `BindableEvent`s in `PlayerGui.BindableEvents`:
- `WeaponFired` - Weapon was fired
- `ReloadStarted` - Reload began
- `ReloadCanceled` - Reload was interrupted
- `WeaponEquipped` - New weapon equipped
- `ADSStateChanged` - ADS toggled on/off
- `SprintStateChanged` - Sprint toggled on/off

---

## Animation Types

### 1. Idle Animation

**Purpose:** Default animation when holding weapon  
**Looped:** Yes  
**Priority:** `Enum.AnimationPriority.Idle`

Plays continuously when the weapon is equipped. Shows subtle weapon movement and hand positioning.

**Configuration:**
```lua
FPSConfig.Animations.WeaponAnimations.Pistol.idle = "rbxassetid://YOUR_IDLE_ANIM_ID"
```

### 2. Fire Animation

**Purpose:** Plays when weapon fires  
**Looped:** No  
**Priority:** `Enum.AnimationPriority.Action`

Brief animation showing recoil, muzzle rise, and hand movement during firing.

**Configuration:**
```lua
FPSConfig.Animations.WeaponAnimations.Pistol.fire = "rbxassetid://YOUR_FIRE_ANIM_ID"
```

**Notes:**
- Should be short (0.1-0.3 seconds)
- Plays on top of idle animation
- Auto-cleans up when finished

### 3. Reload Animation

**Purpose:** Magazine removal and insertion  
**Looped:** No  
**Priority:** `Enum.AnimationPriority.Action2`

Shows the complete reload process. Animation speed is automatically adjusted to match `ReloadTime` from weapon stats.

**Configuration:**
```lua
FPSConfig.Animations.WeaponAnimations.Pistol.reload = "rbxassetid://YOUR_RELOAD_ANIM_ID"
```

**Notes:**
- Animation duration should match weapon's `ReloadTime` in `FPSConfig.WeaponStats`
- Can be interrupted by weapon switching or movement
- Automatically adjusts playback speed

### 4. Equip Animation

**Purpose:** Drawing/raising weapon  
**Looped:** No  
**Priority:** `Enum.AnimationPriority.Action`

Plays when switching to this weapon. Shows weapon being drawn and brought to ready position.

**Configuration:**
```lua
FPSConfig.Animations.WeaponAnimations.Pistol.equip = "rbxassetid://YOUR_EQUIP_ANIM_ID"
```

**Notes:**
- Should be quick (0.3-0.5 seconds)
- Idle animation starts after equip finishes

### 5. Sprint Animation

**Purpose:** Lowered weapon while running  
**Looped:** Yes  
**Priority:** `Enum.AnimationPriority.Movement`

Shows weapon lowered/angled while sprinting. Plays when sprint state is active.

**Configuration:**
```lua
FPSConfig.Animations.WeaponAnimations.Pistol.sprint = "rbxassetid://YOUR_SPRINT_ANIM_ID"
```

**Notes:**
- Automatically starts/stops with sprint state
- Overrides idle animation when active

### 6. ADS (Aim Down Sights) Animation

**Purpose:** Weapon positioned for aiming  
**Looped:** Yes  
**Priority:** `Enum.AnimationPriority.Action`

Brings weapon closer to camera, aligning sights. Plays while right-click is held.

**Configuration:**
```lua
FPSConfig.Animations.WeaponAnimations.Pistol.ads = "rbxassetid://YOUR_ADS_ANIM_ID"
```

**Notes:**
- Transitions smoothly with idle animation
- Can play fire animation on top

---

## Viewmodel System

The viewmodel is a separate model rendered in the first-person camera showing the player's arms and weapon.

### Structure

```
Camera
└── Viewmodel (Model)
    ├── Arms (Model)
    │   ├── RightHand (Part)
    │   │   └── RightWeld (Weld)
    │   └── LeftHand (Part)
    │       └── LeftWeld (Weld)
    └── [WeaponModel] (Model)
        └── WeaponWeld (Weld → RightHand)
```

### Viewmodel Creation

The system automatically creates a basic viewmodel with placeholder arms. For production:

1. **Create proper arm rig** with Motor6D joints
2. **Add to ServerStorage** as "ViewmodelArms"
3. System will use custom arms if available

### Weapon Attachment

Weapons attach to the `RightHand` part via a weld. Weapon offset is configured per weapon type:

```lua
FPSConfig.Animations.WeaponOffsets = {
    Pistol = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
    SMG = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(90), 0),
    -- Adjust per weapon for proper positioning
}
```

### Positioning States

The viewmodel adjusts position based on state:

| State | Offset | Description |
|-------|--------|-------------|
| Normal | `CFrame.new(0.5, -0.5, -1)` | Default position |
| ADS | `CFrame.new(0, -0.3, -0.8)` | Closer, centered |
| Sprint | `CFrame.new(0.3, -0.8, -0.5)` | Lower, to the side |

---

## Procedural Animations

Procedural animations add dynamic, responsive motion without animation assets.

### 1. Weapon Sway

**Purpose:** Weapon lags behind camera movement  
**Effect:** Natural feeling of weapon weight

**Settings:**
```lua
FPSConfig.Animations.WeaponSwayEnabled = true
FPSConfig.Animations.SwayAmount = 0.02      -- Amount of sway (0-1)
FPSConfig.Animations.SwaySpeed = 10         -- Recovery speed
```

**How it works:**
- Tracks mouse delta each frame
- Applies inverse offset to weapon position
- Smoothly interpolates back to center

### 2. Breathing Motion

**Purpose:** Subtle idle movement simulating breathing  
**Effect:** Weapon slowly rises and falls

**Settings:**
```lua
FPSConfig.Animations.BreathingEnabled = true
FPSConfig.Animations.BreathSpeed = 2        -- Breathing cycle speed
FPSConfig.Animations.BreathAmount = 0.01    -- Vertical displacement
```

**How it works:**
- Sine wave for vertical motion
- Cosine wave for depth variation
- Continuous loop

### 3. Recoil Recovery

**Purpose:** Smooth return to center after recoil  
**Effect:** Camera recoil feels less jarring

**Settings:**
```lua
FPSConfig.Animations.RecoilAnimationEnabled = true
FPSConfig.Animations.RecoilRecoverySpeed = 10  -- How fast recoil recovers
```

**How it works:**
- Receives recoil offset from weapon controller
- Smoothly interpolates back to zero
- Applied to viewmodel rotation

---

## Integration Guide

### For Developers

The animation system is designed to work with minimal setup:

1. **Automatic Integration** - System auto-initializes on client
2. **Event-Driven** - Uses bindable events for communication
3. **Fallback Support** - Works without animation assets (uses procedural only)

### Adding to Existing Game

If you're adding this to an existing Roblox project:

1. **Copy Files:**
   - `FPSAnimationController.client.lua` → `StarterPlayer.StarterPlayerScripts`
   - Updated `FPSWeaponController.client.lua` → Replace existing
   - Updated `FPSConfig.lua` → Merge with existing

2. **Verify BindableEvents Folder:**
   - Created automatically in `PlayerGui`
   - Used for animation event communication

3. **Test:**
   - Equip weapons - should see basic viewmodel
   - Fire weapon - procedural animations should work
   - Add animation assets for full effect

### Creating Custom Weapons

When adding a new weapon type:

1. **Add to WeaponConfig.lua:**
```lua
WeaponConfig.Weapons.NewWeapon = {
    Name = "New Weapon",
    -- ... weapon stats ...
}
```

2. **Add to FPSConfig.lua:**
```lua
FPSConfig.WeaponStats.NewWeapon = {
    -- ... FPS stats ...
}

FPSConfig.Animations.WeaponAnimations.NewWeapon = {
    idle = "rbxassetid://0",
    fire = "rbxassetid://0",
    reload = "rbxassetid://0",
    equip = "rbxassetid://0",
    sprint = "rbxassetid://0",
    ads = "rbxassetid://0",
}

FPSConfig.Animations.WeaponOffsets.NewWeapon = CFrame.new(...)
```

3. **Create weapon model in ServerStorage.Guns**

---

## Creating Animations

### Tools Required

- **Roblox Studio** with Animation Editor plugin
- **Viewmodel rig** with proper hierarchy
- **Animation reference** (optional but recommended)

### Step-by-Step: Creating a Reload Animation

1. **Prepare the Rig:**
   ```
   ViewmodelArms (Model)
   ├── HumanoidRootPart
   ├── Humanoid
   ├── RightShoulder (Motor6D)
   ├── RightElbow (Motor6D)
   ├── RightWrist (Motor6D)
   ├── LeftShoulder (Motor6D)
   ├── LeftElbow (Motor6D)
   └── LeftWrist (Motor6D)
   ```

2. **Create Animation:**
   - Open Animation Editor in Studio
   - Select viewmodel rig
   - Create new animation
   - Name: "PistolReload"

3. **Keyframe the Animation:**
   - **Frame 0:** Idle pose
   - **Frame 10:** Left hand reaches for magazine
   - **Frame 20:** Magazine removed (hidden/moved out of view)
   - **Frame 30:** New magazine in left hand
   - **Frame 40:** Magazine inserted
   - **Frame 50:** Left hand returns to weapon
   - **Frame 60:** Back to idle pose

4. **Adjust Timing:**
   - Total length should match weapon's `ReloadTime`
   - Pistol: ~1.5 seconds (90 frames at 60 FPS)
   - Smooth easing between keyframes

5. **Publish Animation:**
   - File → Publish Animation
   - Copy the asset ID (e.g., `rbxassetid://1234567890`)

6. **Add to Config:**
   ```lua
   FPSConfig.Animations.WeaponAnimations.Pistol.reload = "rbxassetid://1234567890"
   ```

### Animation Best Practices

✅ **DO:**
- Use reference footage for realistic movement
- Keep animations short and snappy for responsiveness
- Add anticipation and follow-through for weight
- Test in first-person view frequently
- Consider different weapon weights (pistol vs. rifle)

❌ **DON'T:**
- Make animations too long (players will cancel)
- Clip arms through the camera
- Forget to return to idle pose at the end
- Ignore weapon-specific characteristics

### Per-Weapon Animation Tips

**Pistol:**
- Quick, snappy movements
- Magazine ejects smoothly
- 1-2 second reload

**SMG:**
- Similar to pistol but slightly slower
- Larger magazine
- 2-2.5 second reload

**Shotgun:**
- Shell-by-shell reload (or full tube)
- Pump action after firing
- 2.5-3 seconds for full reload

**Rifle:**
- Deliberate, controlled movements
- Larger magazine change
- 2-3 second reload
- May include charging handle pull

---

## Asset Requirements

### Required Animation Assets

For each weapon type, create 6 animations:

| Animation | Duration | Notes |
|-----------|----------|-------|
| Idle | Looped | Subtle bobbing/breathing |
| Fire | 0.1-0.3s | Recoil, muzzle rise |
| Reload | 1.5-3s | Match `ReloadTime` in config |
| Equip | 0.3-0.5s | Draw weapon |
| Sprint | Looped | Weapon lowered |
| ADS | Looped | Sights aligned |

**Total Animations for 4 Weapons:** 24 animations

### Animation Asset IDs

All animation IDs are configured in `FPSConfig.Animations.WeaponAnimations`:

```lua
FPSConfig.Animations.WeaponAnimations = {
    Pistol = {
        idle = "rbxassetid://YOUR_ID",
        fire = "rbxassetid://YOUR_ID",
        reload = "rbxassetid://YOUR_ID",
        equip = "rbxassetid://YOUR_ID",
        sprint = "rbxassetid://YOUR_ID",
        ads = "rbxassetid://YOUR_ID",
    },
    -- Repeat for SMG, Shotgun, Rifle
}
```

### Optional: Viewmodel Arm Models

Create custom first-person arm models:

1. **Model Structure:**
   - Based on R15 or R6 rig
   - Only arms visible (torso/legs hidden)
   - Proper Motor6D hierarchy for animation

2. **Placement:**
   - Save to `ServerStorage.ViewmodelArms`
   - System will automatically use if present

3. **Texture/Materials:**
   - Match character skin tone (or use universal)
   - Add clothing/gloves if desired
   - Keep polygon count low for performance

### Optional: Weapon Models

Enhanced weapon models for viewmodel:

1. **Higher Detail:**
   - First-person models can be higher quality
   - Player sees them up close

2. **Attachment Points:**
   - Named parts for magazine, slide, bolt, etc.
   - Used for advanced reload animations

3. **Placement:**
   - Save to `ServerStorage.Guns`
   - Name must match weapon ID (e.g., "Pistol", "SMG")

---

## Configuration

All animation settings are in `FPSConfig.Animations`:

### Enable/Disable

```lua
FPSConfig.Animations.Enabled = true  -- Master toggle
```

### Procedural Animation Settings

```lua
-- Weapon Sway
FPSConfig.Animations.WeaponSwayEnabled = true
FPSConfig.Animations.SwayAmount = 0.02        -- 0-1, higher = more sway
FPSConfig.Animations.SwaySpeed = 10           -- Recovery speed

-- Breathing
FPSConfig.Animations.BreathingEnabled = true
FPSConfig.Animations.BreathSpeed = 2          -- Breathing rate
FPSConfig.Animations.BreathAmount = 0.01      -- Displacement amount

-- Recoil Recovery
FPSConfig.Animations.RecoilAnimationEnabled = true
FPSConfig.Animations.RecoilRecoverySpeed = 10 -- Speed of return to center
```

### Viewmodel Settings

```lua
FPSConfig.Animations.ViewmodelFOV = 70        -- Separate from camera FOV
FPSConfig.Animations.ViewmodelOffset = Vector3.new(0, -0.5, -1)  -- Base position
```

### Animation Asset IDs

```lua
FPSConfig.Animations.WeaponAnimations = {
    [WeaponId] = {
        idle = "rbxassetid://0",
        fire = "rbxassetid://0",
        reload = "rbxassetid://0",
        equip = "rbxassetid://0",
        sprint = "rbxassetid://0",
        ads = "rbxassetid://0",
    }
}
```

### Weapon Offsets

Fine-tune weapon positioning per weapon type:

```lua
FPSConfig.Animations.WeaponOffsets = {
    Pistol = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
    SMG = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(90), 0),
    Shotgun = CFrame.new(0, 0.05, 0.1) * CFrame.Angles(0, math.rad(90), 0),
    Rifle = CFrame.new(0, 0, 0.1) * CFrame.Angles(0, math.rad(90), 0),
}
```

**Adjusting Offsets:**
- **X:** Left/right position
- **Y:** Up/down position
- **Z:** Forward/backward position
- **Angles:** Rotation in radians

---

## Troubleshooting

### Animations Not Playing

**Problem:** No animations play, only procedural motion works

**Solutions:**
1. Check animation asset IDs in `FPSConfig.Animations.WeaponAnimations`
2. Verify asset IDs are published and public
3. Check Output window for animation loading errors
4. Ensure Humanoid and Animator exist in character

**Debugging:**
```lua
-- Check if animation is loaded
local animTrack = FPSAnimationController:loadAnimation("Pistol", "idle")
if animTrack then
    print("Animation loaded successfully")
else
    print("Failed to load animation")
end
```

### Weapon Model Not Showing

**Problem:** Viewmodel arms visible but no weapon

**Solutions:**
1. Check `ServerStorage.Guns` for weapon model
2. Verify weapon model has a `PrimaryPart`
3. Check weapon ID matches exactly (case-sensitive)
4. Fallback creates placeholder - adjust `WeaponOffsets` for visibility

### Clipping Through Camera

**Problem:** Arms/weapon clip through camera when looking down

**Solutions:**
1. Adjust `ViewmodelOffset` in `FPSConfig.Animations`
2. Move weapon model further from camera (increase Z offset)
3. Reduce arm model size or adjust joint positions
4. Add near-plane clipping in animations

### Sway Too Aggressive

**Problem:** Weapon sways too much, feels disconnected

**Solutions:**
1. Reduce `SwayAmount` (try 0.01 instead of 0.02)
2. Increase `SwaySpeed` for faster recovery
3. Disable sway entirely: `WeaponSwayEnabled = false`

### Reload Animation Out of Sync

**Problem:** Animation finishes before/after actual reload time

**Solutions:**
1. Check `ReloadTime` in `FPSConfig.WeaponStats.[Weapon]`
2. Animation speed auto-adjusts to match `ReloadTime`
3. If still off, manually adjust animation length in Studio
4. Verify animation is being loaded (check Output)

### Performance Issues

**Problem:** FPS drops with viewmodel enabled

**Solutions:**
1. Reduce viewmodel arm polygon count
2. Use LOD (Level of Detail) for weapon models
3. Disable procedural animations if needed
4. Check RenderStepped loop isn't doing heavy calculations

### Animation Priorities Conflicting

**Problem:** Animations override each other incorrectly

**Solutions:**
1. Check animation priorities in `FPSAnimationController`
2. Idle should be lowest priority (Idle)
3. Fire/Reload should be high priority (Action/Action2)
4. Adjust in animation creation or code

### Events Not Firing

**Problem:** Weapon fires but animation doesn't play

**Solutions:**
1. Check `BindableEvents` folder exists in `PlayerGui`
2. Verify event names match exactly
3. Check FPSWeaponController is firing events:
   ```lua
   weaponFiredBindable:Fire({weaponId = currentWeapon})
   ```
4. Ensure FPSAnimationController is listening:
   ```lua
   weaponFiredEvent.Event:Connect(...)
   ```

---

## Advanced Topics

### Custom Animation Blending

To create custom transitions between animations:

```lua
-- In FPSAnimationController
local function blendToAnimation(fromAnim, toAnim, blendTime)
    if fromAnim then
        fromAnim:AdjustWeight(0, blendTime)
    end
    if toAnim then
        toAnim:AdjustWeight(1, blendTime)
        toAnim:Play()
    end
end
```

### Per-Shot Recoil Animation

For unique recoil per shot without camera kick:

```lua
-- Apply recoil offset to viewmodel
function FPSAnimationController:applyRecoilOffset(vertical, horizontal)
    local recoilCFrame = CFrame.Angles(-math.rad(vertical), math.rad(horizontal), 0)
    self.recoilOffset = self.recoilOffset * recoilCFrame
end
```

### Shell Ejection Effects

Add shell ejection to fire animation:

1. Add `ShellEjectionPoint` to weapon model
2. In `playFire()` function, spawn shell part
3. Apply physics for realistic ejection

---

## Future Enhancements

Potential additions to the animation system:

- [ ] **Weapon Inspection** - Dedicated inspect animation (F key)
- [ ] **Melee Animations** - Knife/melee weapon attacks
- [ ] **Tactical Reload** - Different animation when magazine not empty
- [ ] **Shell-by-Shell Shotgun** - Individual shell insertion animations
- [ ] **Procedural IK** - Inverse kinematics for hand placement
- [ ] **Weapon Bob** - Enhanced walking/running weapon movement
- [ ] **Slide Lock** - Visual feedback when pistol is empty
- [ ] **Magazine Drop** - Physical magazine parts for tactical reloads

---

## Summary

The weapon animation system provides a complete, production-ready FPS animation framework:

✅ **6 animation types** per weapon  
✅ **Procedural enhancements** for dynamic feel  
✅ **Event-driven integration** with weapon controller  
✅ **Fully configurable** via FPSConfig  
✅ **Asset-ready** - works with or without animation files  

**Next Steps:**
1. Create animation assets in Roblox Studio
2. Publish animations and copy asset IDs
3. Update `FPSConfig.Animations.WeaponAnimations` with IDs
4. Test in-game and adjust offsets/timing as needed
5. Create custom viewmodel arms for enhanced visuals

For questions or issues, refer to the [Troubleshooting](#troubleshooting) section or check the Roblox Output window for error messages.

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Author:** GitHub Copilot
