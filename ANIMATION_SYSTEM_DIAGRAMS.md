# Weapon Animation System - Visual Overview

This document provides visual representations and diagrams to help understand the weapon animation system architecture.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PLAYER ACTIONS                                │
│  [Fire]  [Reload]  [ADS]  [Sprint]  [Switch Weapon]               │
└────────┬────────────┬──────┬────────┬─────────────┬─────────────────┘
         │            │      │        │             │
         ▼            ▼      ▼        ▼             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    FPSWeaponController.client.lua                    │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐              │
│  │ Fire Weapon │  │ Start Reload │  │ Toggle ADS    │              │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘              │
│         │                │                   │                       │
│         ▼                ▼                   ▼                       │
│  Fire Event      Reload Event        ADS Event                      │
└─────────┬────────────────┬───────────────────┬──────────────────────┘
          │                │                   │
          │                │                   │
          ▼                ▼                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                PlayerGui.BindableEvents (Event Bus)                  │
│  • WeaponFired       • ReloadStarted      • ADSStateChanged         │
│  • WeaponEquipped    • ReloadCanceled     • SprintStateChanged      │
└─────────┬────────────────┬───────────────────┬──────────────────────┘
          │                │                   │
          │                │                   │
          ▼                ▼                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│              FPSAnimationController.client.lua                       │
│  ┌────────────────────────────────────────────────────────┐         │
│  │  Event Listeners                                        │         │
│  │  • onWeaponFired()     → playFire()                    │         │
│  │  • onReloadStarted()   → playReload()                  │         │
│  │  • onADSChanged()      → setADS()                      │         │
│  │  • onSprintChanged()   → setSprinting()                │         │
│  │  • onWeaponEquipped()  → equipWeapon()                 │         │
│  └────────────────────────────────────────────────────────┘         │
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐         │
│  │  Animation Playback                                     │         │
│  │  • Load animation from asset ID                         │         │
│  │  • Set priority and loop settings                       │         │
│  │  • Play animation                                       │         │
│  │  • Handle animation cleanup                             │         │
│  └────────────────────────────────────────────────────────┘         │
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐         │
│  │  Procedural Animations (Every Frame)                    │         │
│  │  • updateWeaponSway()      - Mouse lag                  │         │
│  │  • updateBreathing()       - Idle motion                │         │
│  │  • updateRecoilRecovery()  - Smooth recovery            │         │
│  │  • updateViewmodelPosition() - Apply combined CFrame    │         │
│  └────────────────────────────────────────────────────────┘         │
└──────────────────────────────┬───────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      VIEWMODEL & RENDERING                           │
│  Camera.Viewmodel                                                    │
│  ├── Arms (Model)                                                    │
│  │   ├── RightHand ← Procedural offsets applied here                │
│  │   └── LeftHand                                                    │
│  └── WeaponModel ← Attached to RightHand                             │
│      └── Animations play on character Humanoid                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Animation State Machine

```
┌──────────┐
│  IDLE    │ ←──────────────────────────────┐
│  (Loop)  │                                 │
└────┬─────┘                                 │
     │                                       │
     │ Fire Key                              │
     ├──→ ┌──────────┐                       │
     │    │   FIRE   │ ──────────────────────┤
     │    │ (0.2s)   │ (Auto-return)         │
     │    └──────────┘                       │
     │                                       │
     │ R Key                                 │
     ├──→ ┌──────────┐                       │
     │    │  RELOAD  │ ──────────────────────┤
     │    │ (1.5-3s) │ (On complete)         │
     │    └──────────┘                       │
     │         │                             │
     │         │ Movement/Fire               │
     │         └──→ Cancel ──────────────────┤
     │                                       │
     │ Right Click                           │
     ├──→ ┌──────────┐                       │
     │    │   ADS    │ ←──────────────┐      │
     │    │  (Loop)  │                │      │
     │    └──────────┘                │      │
     │         │                      │      │
     │         │ Release Right Click  │      │
     │         └──────────────────────┘      │
     │                                       │
     │ Shift Key                             │
     ├──→ ┌──────────┐                       │
     │    │  SPRINT  │ ←──────────────┐      │
     │    │  (Loop)  │                │      │
     │    └──────────┘                │      │
     │         │                      │      │
     │         │ Release Shift        │      │
     │         └──────────────────────┘      │
     │                                       │
     │ Weapon Switch (1-4)                   │
     └──→ ┌──────────┐                       │
          │  EQUIP   │ ──────────────────────┘
          │ (0.5s)   │ (→ IDLE after)
          └──────────┘
```

## Viewmodel Structure

```
Workspace.CurrentCamera
└── Viewmodel (Model) ← Created by FPSAnimationController
    ├── Arms (Model)
    │   ├── RightHand (Part)
    │   │   ├── RightWeld (Weld) ← Attaches to camera
    │   │   └── C0 = BasePosition * ProceduralOffset
    │   │
    │   └── LeftHand (Part)
    │       ├── LeftWeld (Weld)
    │       └── C0 = BasePosition * ProceduralOffset
    │
    └── [WeaponModel] (Model) ← Loaded per weapon
        └── PrimaryPart
            └── WeaponWeld (Weld) ← Attaches to RightHand
                └── C0 = WeaponOffset (from config)
```

## Procedural Animation Flow

```
Every Frame (RenderStepped):
    │
    ├─→ Get Mouse Delta
    │   └─→ Calculate Sway Offset
    │       └─→ Lerp to target sway
    │
    ├─→ Increment Breath Time
    │   └─→ Calculate Sine Wave
    │       └─→ Apply vertical/depth offset
    │
    ├─→ Check Recoil Offset
    │   └─→ Lerp toward zero
    │       └─→ Smooth recovery
    │
    └─→ Combine All Offsets
        └─→ Apply to RightHand.Weld.C0
            └─→ Visual update complete
```

## Configuration Hierarchy

```
FPSConfig.lua
└── Animations
    ├── Enabled (bool)
    ├── Procedural Settings
    │   ├── WeaponSwayEnabled
    │   ├── SwayAmount
    │   ├── SwaySpeed
    │   ├── BreathingEnabled
    │   ├── BreathSpeed
    │   ├── BreathAmount
    │   ├── RecoilAnimationEnabled
    │   └── RecoilRecoverySpeed
    │
    ├── WeaponAnimations
    │   ├── Pistol
    │   │   ├── idle: "rbxassetid://..."
    │   │   ├── fire: "rbxassetid://..."
    │   │   ├── reload: "rbxassetid://..."
    │   │   ├── equip: "rbxassetid://..."
    │   │   ├── sprint: "rbxassetid://..."
    │   │   └── ads: "rbxassetid://..."
    │   ├── SMG
    │   ├── Shotgun
    │   └── Rifle
    │
    └── WeaponOffsets
        ├── Pistol: CFrame.new(...)
        ├── SMG: CFrame.new(...)
        ├── Shotgun: CFrame.new(...)
        └── Rifle: CFrame.new(...)
```

## Event Timeline (Example: Firing Weapon)

```
Time  │ Component                 │ Action
──────┼───────────────────────────┼─────────────────────────────────
0.00s │ Player                    │ Clicks left mouse button
      ▼                           │
0.00s │ UserInputService          │ Captures MouseButton1 down
      ▼                           │
0.00s │ FPSWeaponController       │ Calls fireWeapon()
      │                           │ • Validates can fire
      │                           │ • Calculates spread
      │                           │ • Sends to server
      │                           │ • Fires WeaponFired event
      ▼                           │
0.00s │ BindableEvent             │ WeaponFired.Fire()
      ▼                           │
0.00s │ FPSAnimationController    │ Receives WeaponFired
      │                           │ • Calls playFire()
      │                           │ • Loads fire animation
      │                           │ • Plays animation
      │                           │ • Applies recoil offset
      ▼                           │
0.00s │ Animation System          │ Fire animation plays
      │                           │ Duration: 0.1-0.2s
      ▼                           │
0.20s │ Animation System          │ Fire animation completes
      │                           │ Auto-cleanup
      ▼                           │
0.00s-│ Procedural (Every Frame)  │ Recoil recovery
...   │                           │ • Lerp offset back to zero
0.50s │                           │ • Smooth visual return
      ▼                           │
DONE  │                           │ Ready for next shot
```

## Animation Priority Stack

```
Highest Priority (Plays on top)
    ↑
    │  Action4  (Not used)
    │  Action3  (Not used)
    │  Action2  ← Reload animation
    │  Action   ← Fire, Equip, ADS animations
    │  Movement ← Sprint animation
    │  Idle     ← Idle animation
    ↓
Lowest Priority (Interrupted by higher)
```

## Data Flow: Adding New Weapon

```
1. Create Animation Assets in Roblox Studio
   ├─→ Idle animation
   ├─→ Fire animation
   ├─→ Reload animation
   ├─→ Equip animation
   ├─→ Sprint animation
   └─→ ADS animation
   
2. Publish Animations
   └─→ Copy asset IDs
   
3. Update FPSConfig.lua
   ├─→ Add to WeaponAnimations.[NewWeapon]
   │   └─→ Set all 6 animation IDs
   └─→ Add to WeaponOffsets.[NewWeapon]
       └─→ Set position/rotation CFrame
       
4. Create Weapon Model
   ├─→ Model with PrimaryPart
   └─→ Place in ServerStorage.Guns.[NewWeapon]
   
5. Test in Game
   ├─→ Equip weapon
   ├─→ Verify animations play
   ├─→ Adjust offsets if needed
   └─→ Iterate until satisfied
```

## Memory and Performance

```
Viewmodel Hierarchy (Always in Memory):
├── Viewmodel Model (~1KB)
├── Arms Model (~5-10KB depending on rig)
└── Current Weapon Model (~10-50KB depending on detail)
Total: ~15-60KB per player

Per Weapon Animation Tracks (Loaded on Demand):
├── 6 animation tracks × 4 weapons = 24 tracks
├── Each track ~2-5KB
└── Total: ~50-120KB (only 1 weapon loaded at a time)

Procedural Calculations (Every Frame):
├── Mouse delta calculation
├── 3 CFrame lerp operations
├── 2 sine/cosine calculations
└── Total: <0.1ms per frame (negligible)

Total Memory Footprint: ~65-180KB per player
Performance Impact: Minimal (<1% frame time)
```

## Integration Points

```
FPSAnimationController integrates with:

┌──────────────────────────┐
│ FPSWeaponController      │ ← Fires animation events
└────────┬─────────────────┘
         │
         ├─→ WeaponFired
         ├─→ ReloadStarted
         ├─→ ReloadCanceled
         ├─→ WeaponEquipped
         └─→ ADSStateChanged

┌──────────────────────────┐
│ FPSMovementController    │ ← Sprint state
└────────┬─────────────────┘
         │
         └─→ SprintStateChanged

┌──────────────────────────┐
│ FirstPersonCamera        │ ← (Future: Camera effects)
└──────────────────────────┘

┌──────────────────────────┐
│ FPSAudioController       │ ← (Future: Sound sync)
└──────────────────────────┘
```

## Troubleshooting Decision Tree

```
Animation not playing?
├─→ Asset ID = 0 or empty?
│   ├─→ YES: Add animation asset ID
│   └─→ NO: Continue
│
├─→ Asset ID correct?
│   ├─→ NO: Fix asset ID
│   └─→ YES: Continue
│
├─→ Animation published?
│   ├─→ NO: Publish animation
│   └─→ YES: Continue
│
├─→ Animation public?
│   ├─→ NO: Make animation public
│   └─→ YES: Continue
│
├─→ Check Output window
│   ├─→ "Failed to load": Asset issue
│   ├─→ "Animation loaded": Config issue
│   └─→ No message: Event not firing
│
└─→ Still not working?
    └─→ See WEAPON_ANIMATIONS.md Troubleshooting section
```

---

## Quick Visual Summary

**Components:**
- 1 Animation Controller (FPSAnimationController)
- 1 Viewmodel per player (auto-created)
- 6 animation types per weapon
- 3 procedural animation systems
- Event-driven architecture

**Flow:**
Player Input → Weapon Controller → Events → Animation Controller → Viewmodel

**Result:**
Professional FPS weapon handling with smooth animations!

---

For detailed technical information, see:
- [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md) - Complete guide
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API reference
- [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md) - Tutorial
