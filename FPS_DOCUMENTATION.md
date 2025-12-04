# FPS System Documentation

This document describes the First-Person Shooter (FPS) systems added to AwavePuzz, including camera control, movement, weapons, HUD, menus, and audio.

## Table of Contents

- [Overview](#overview)
- [Configuration](#configuration)
- [First-Person Camera](#first-person-camera)
- [Movement System](#movement-system)
- [Weapon System](#weapon-system)
- [HUD System](#hud-system)
- [Menu System](#menu-system)
- [Audio System](#audio-system)
- [Adding New Weapons](#adding-new-weapons)
- [Tuning Guide](#tuning-guide)
- [Required Assets](#required-assets)

---

## Overview

The FPS system transforms AwavePuzz from a third-person perspective to a true first-person shooter experience with:

- **First-person camera** locked to the player's head with configurable FOV
- **Mouse-locked gameplay** - no visible cursor during combat
- **Full weapon mechanics** including recoil, spread, ADS, reload, and fire modes
- **Dynamic HUD** with crosshair, ammo counter, hitmarkers, and damage feedback
- **Keyboard-navigable menus** - no mouse required during gameplay
- **Comprehensive audio hooks** for weapon sounds, footsteps, and feedback

### File Structure

```
src/
├── client/
│   ├── FirstPersonCamera.client.lua     -- Camera controller
│   ├── FPSMovementController.client.lua -- Movement with crouch/sprint
│   ├── FPSWeaponController.client.lua   -- Weapon mechanics
│   ├── FPSMenuController.client.lua     -- Pause/settings menus
│   ├── FPSAudioController.client.lua    -- Sound management
│   └── UI/
│       └── FPSHUD.client.lua            -- Crosshair, ammo, hitmarkers
├── server/
│   └── FPSWeaponService.lua             -- Server-side ammo/validation
└── shared/
    └── FPSConfig.lua                    -- All FPS configuration
```

---

## Configuration

All FPS settings are centralized in `src/shared/FPSConfig.lua`. The configuration is divided into sections:

### Camera Settings

```lua
FPSConfig.Camera = {
    DefaultFOV = 70,              -- Default field of view (degrees)
    MinFOV = 50,                  -- Minimum FOV allowed
    MaxFOV = 120,                 -- Maximum FOV allowed
    ADSFOV = 50,                  -- FOV when aiming down sights
    SprintFOV = 85,               -- FOV when sprinting
    FOVTransitionSpeed = 8,       -- Speed of FOV transitions
    
    DefaultSensitivity = 0.5,     -- Mouse sensitivity (0.1 - 2.0)
    InvertY = false,              -- Invert Y-axis
    MouseSmoothing = false,       -- Enable mouse smoothing
}
```

### Movement Settings

```lua
FPSConfig.Movement = {
    WalkSpeed = 16,
    SprintSpeed = 24,
    CrouchSpeed = 8,
    ADSSpeed = 10,
    
    JumpPower = 50,
    AirControlMultiplier = 0.3,   -- Reduced control when airborne
    
    CrouchHeight = 3,             -- HipHeight when crouching
    StandHeight = 2,              -- Normal HipHeight
}
```

### Weapon Settings

```lua
FPSConfig.Weapons = {
    ADSTransitionSpeed = 8,
    ADSSpreadMultiplier = 0.3,    -- Spread reduction when ADS
    ADSRecoilMultiplier = 0.7,    -- Recoil reduction when ADS
    
    HeadshotMultiplier = 2.0,     -- Damage multiplier for headshots
    BodyshotMultiplier = 1.0,
    LimbshotMultiplier = 0.75,
}
```

### HUD Settings

```lua
FPSConfig.HUD = {
    CrosshairSize = 8,
    CrosshairThickness = 2,
    CrosshairGap = 4,
    DynamicCrosshair = true,      -- Expand when firing/moving
    
    HitmarkerEnabled = true,
    HitmarkerDuration = 0.15,
    
    LowHealthThreshold = 30,      -- Health % to show warning
}
```

---

## First-Person Camera

The `FirstPersonCamera.client.lua` provides:

### Features

- **Head-locked camera** - Camera stays at the player's head position
- **Mouse look** - Full 360° horizontal, ±89° vertical rotation
- **Character hiding** - Player's own body is hidden in first-person
- **FOV transitions** - Smooth FOV changes for sprint/ADS
- **Mouse locking** - Cursor locked to center during gameplay

### Public API

```lua
-- State setters (called by other systems)
FirstPersonCamera.setADS(isADS)           -- Set ADS state
FirstPersonCamera.setSprinting(sprinting) -- Set sprint state
FirstPersonCamera.setMenuOpen(isOpen)     -- Toggle mouse lock for menus

-- Settings
FirstPersonCamera.setSensitivity(value)   -- 0.1 to 2.0
FirstPersonCamera.setFOV(value)           -- 50 to 120
FirstPersonCamera.setInvertY(invert)      -- true/false

-- Recoil (called by weapon system)
FirstPersonCamera.applyRecoil(vertical, horizontal)

-- Get current look direction (for shooting)
local direction = FirstPersonCamera.getLookDirection()
local cframe = FirstPersonCamera.getLookCFrame()
```

---

## Movement System

The `FPSMovementController.client.lua` handles:

### Features

- **WASD movement** - Standard FPS controls
- **Sprint** - Hold Left Shift (configurable)
- **Crouch** - Toggle Left Control (configurable)
- **Air control** - Reduced control when airborne
- **Stamina sync** - Integrates with server stamina system

### Controls

| Action | Default Key |
|--------|-------------|
| Sprint | Left Shift |
| Crouch | Left Control |
| Jump | Space |

### Public API

```lua
FPSMovementController.isSprinting()  -- Check sprint state
FPSMovementController.isCrouching()  -- Check crouch state
FPSMovementController.isGrounded()   -- Check if on ground
FPSMovementController.isMoving()     -- Check if moving
```

---

## Weapon System

The `FPSWeaponController.client.lua` provides comprehensive FPS gunplay:

### Features

- **Fire modes** - Semi-automatic, burst, full-auto (per weapon)
- **Recoil system** - Camera kick with recovery
- **Spread system** - Dynamic accuracy based on movement/firing
- **ADS (Aim Down Sights)** - Right-click to aim with reduced spread
- **Reload system** - Manual reload with R key, auto-reload when empty
- **Magazine system** - Current ammo + reserve ammo tracking

### Controls

| Action | Default Key |
|--------|-------------|
| Fire | Left Mouse |
| ADS | Right Mouse |
| Reload | R |
| Weapon 1-4 | 1, 2, 3, 4 |

### Weapon Stats (Example)

```lua
FPSConfig.WeaponStats.Pistol = {
    Damage = 18,
    FireRate = 0.35,          -- Seconds between shots
    Range = 175,
    
    FireMode = "Semi",
    Automatic = false,
    
    MagSize = 12,
    ReserveAmmo = 48,
    ReloadTime = 1.5,
    
    -- Recoil
    RecoilVertical = 1.5,     -- Degrees per shot
    RecoilHorizontal = 0.5,
    RecoilRecovery = 5,
    
    -- Spread
    HipSpread = 3.0,          -- Degrees when hip-firing
    ADSSpread = 0.5,          -- Degrees when ADS
    MoveSpreadMultiplier = 1.5,
    SpreadIncreasePerShot = 0.3,
    MaxSpread = 8,
    
    -- ADS
    ADSZoom = 1.2,
    ADSSpeed = 0.15,
}
```

### Recoil Tuning

- `RecoilVertical` - How much the camera kicks up per shot (degrees)
- `RecoilHorizontal` - Random horizontal kick range (degrees)
- `RecoilRecovery` - How fast recoil returns to center (higher = faster)

### Spread Tuning

- `HipSpread` / `ADSSpread` - Base accuracy
- `MoveSpreadMultiplier` - Penalty when moving
- `SpreadIncreasePerShot` - Penalty for sustained fire
- `SpreadRecovery` - How fast spread returns to base

---

## HUD System

The `FPSHUD.client.lua` provides:

### Components

1. **Dynamic Crosshair**
   - Expands based on spread
   - Hides during ADS
   - Configurable size, color, gap

2. **Ammo Display**
   - Current magazine / Reserve ammo
   - Low ammo warning (red text)
   - Reload indicator

3. **Weapon Info**
   - Weapon name
   - Fire mode indicator

4. **Hitmarkers**
   - Standard hit feedback
   - Different colors for headshots/kills
   - Brief flash animation

5. **Damage Feedback**
   - Red vignette flash when damaged
   - Pulsing low-health indicator

### Customization

All HUD settings are in `FPSConfig.HUD`. Colors, sizes, and behavior can be adjusted.

---

## Menu System

The `FPSMenuController.client.lua` provides keyboard-navigable menus:

### Controls

| Action | Keys |
|--------|------|
| Navigate | W/S or ↑/↓ |
| Adjust Value | A/D or ←/→ |
| Select | Enter or Space |
| Back/Close | Escape |

### Menu Structure

```
Pause Menu
├── Resume
├── Settings
│   ├── Mouse Sensitivity (slider)
│   ├── Field of View (slider)
│   ├── Invert Y-Axis (toggle)
│   ├── Master Volume (slider)
│   ├── SFX Volume (slider)
│   └── Back
├── Controls (display only)
└── Leave Match
```

### Opening the Menu

Press **Escape** during gameplay to open the pause menu.

---

## Audio System

The `FPSAudioController.client.lua` provides a placeholder system for FPS sounds:

### Sound Categories

1. **Weapon Sounds**
   - Fire sound (per weapon)
   - Reload sound (per weapon)
   - Empty click

2. **Feedback Sounds**
   - Hitmarker
   - Headshot hitmarker
   - Kill confirmation

3. **Movement Sounds**
   - Footsteps (surface-based)

4. **UI Sounds**
   - Menu navigation
   - Menu selection

### Adding Sound Assets

Edit `SoundAssets` in `FPSAudioController.client.lua`:

```lua
local SoundAssets = {
    WeaponFire = {
        Pistol = "rbxassetid://123456789",  -- Replace with your asset ID
        SMG = "rbxassetid://123456790",
        -- ...
    },
    Hitmarker = "rbxassetid://123456791",
    -- ...
}
```

---

## Adding New Weapons

### Step 1: Add to FPSConfig.lua

```lua
FPSConfig.WeaponStats.NewWeapon = {
    Damage = 25,
    FireRate = 0.4,
    Range = 200,
    
    FireMode = "Auto",
    Automatic = true,
    
    MagSize = 25,
    ReserveAmmo = 100,
    ReloadTime = 2.0,
    
    RecoilVertical = 1.2,
    RecoilHorizontal = 0.6,
    RecoilRecovery = 5,
    
    HipSpread = 3.5,
    ADSSpread = 1.0,
    MoveSpreadMultiplier = 1.4,
    SpreadIncreasePerShot = 0.2,
    SpreadRecovery = 8,
    MaxSpread = 10,
    
    ADSZoom = 1.3,
    ADSSpeed = 0.18,
}
```

### Step 2: Add to WeaponConfig.lua (for shop/pricing)

```lua
WeaponConfig.Weapons.NewWeapon = {
    Name = "New Weapon",
    ModelName = "NewWeapon",
    Damage = 25,
    FireRate = 0.4,
    Range = 200,
    Automatic = true,
    RewardBonus = 3,
    Price = 600,
}
```

### Step 3: Add Sound Assets (optional)

```lua
-- In FPSAudioController.client.lua
WeaponFire = {
    NewWeapon = "rbxassetid://YOUR_FIRE_SOUND",
},
WeaponReload = {
    NewWeapon = "rbxassetid://YOUR_RELOAD_SOUND",
},
```

### Step 4: Create Gun Model

Place a gun model in `ServerStorage.Guns` with:
- A PrimaryPart (or part named "Main", "Base", or "Body")
- Proper orientation for hand attachment

---

## Tuning Guide

### Making Weapons Feel Better

**For a "snappy" pistol:**
```lua
RecoilVertical = 2.5,      -- Higher kick
RecoilRecovery = 8,        -- Fast recovery
SpreadRecovery = 10,       -- Quick accuracy return
```

**For a "heavy" rifle:**
```lua
RecoilVertical = 3.0,      -- Strong kick
RecoilHorizontal = 0.3,    -- Controlled horizontal
RecoilRecovery = 3,        -- Slow recovery (requires compensation)
```

**For a "spray" SMG:**
```lua
RecoilVertical = 0.8,      -- Low per-shot
RecoilHorizontal = 1.0,    -- Unpredictable
SpreadIncreasePerShot = 0.15,  -- Builds up over sustained fire
```

### Adjusting Game Feel

**More arcade-like:**
- Lower recoil values
- Higher `RecoilRecovery`
- Lower `SpreadIncreasePerShot`
- Higher FOV (90-100)

**More tactical:**
- Higher recoil values
- Lower `RecoilRecovery`
- Higher spread penalties
- Lower FOV (70-80)

---

## Required Assets

### Manual Asset Creation

The FPS system requires these assets to be created/imported:

#### 1. Viewmodel Arms + Weapons (Optional Enhancement)

For true FPS viewmodels, create:
- A rig with Motor6D joints for shoulder, elbow, wrist
- First-person arm models that won't clip through walls
- Weapon models positioned for first-person view

**Note:** The current system uses the full character with hidden body. A dedicated viewmodel system can be added for enhanced visuals.

#### 2. Sound Assets

Replace placeholder IDs (`rbxassetid://0`) in `FPSAudioController.client.lua`:

| Sound Type | Description |
|------------|-------------|
| WeaponFire.Pistol | Pistol firing sound |
| WeaponFire.SMG | SMG firing sound |
| WeaponFire.Shotgun | Shotgun firing sound |
| WeaponFire.Rifle | Rifle firing sound |
| WeaponReload.* | Reload sounds per weapon |
| EmptyClick | Click when out of ammo |
| Hitmarker | Hit confirmation sound |
| HeadshotHitmarker | Headshot sound |
| KillConfirm | Kill confirmation |
| Footsteps.* | Surface-specific footsteps |

#### 3. Animations (Optional Enhancement)

For enhanced weapon feel, create animations:
- Idle pose
- Walk/run cycle (arms only)
- Fire animation
- Reload animation
- Equip/unequip animation

Hook animations in `FPSWeaponController.client.lua` using the existing bindable events:
- `WeaponFired` - Play fire animation
- `ReloadStarted` - Play reload animation
- `ReloadFinished` / `ReloadCanceled` - Stop reload animation

---

## Integration Notes

### Existing Systems

The FPS system integrates with:

- **SprintController** - Syncs sprint state for FOV changes
- **WeaponService** - Server-side damage validation
- **PlayerHUD** - Health and stamina still managed by existing HUD
- **ShopUI** - Weapon purchasing unchanged

### Communication

Systems communicate via `BindableEvent`s in `PlayerGui.BindableEvents`:

| Event | Data | Purpose |
|-------|------|---------|
| AmmoUpdate | {current, reserve, max} | Update ammo display |
| Hitmarker | {isHeadshot, isKill} | Show hitmarker |
| CrosshairUpdate | {spread, isADS} | Update crosshair |
| WeaponFired | {weaponId} | Trigger fire effects |
| ReloadStarted | {duration, weaponId} | Start reload animation |
| ApplyRecoil | vertical, horizontal | Apply camera recoil |
| SettingsChanged | {setting: value} | Update settings |
| MenuStateChanged | {isOpen, menuType} | Menu opened/closed |

---

## Troubleshooting

### Camera Issues

**Problem:** Camera not following head
**Solution:** Ensure character has `Head` and `HumanoidRootPart`

**Problem:** Mouse not locked
**Solution:** Check if `FPSMenuController` is setting `isMenuOpen`

### Weapon Issues

**Problem:** Weapon not firing
**Solution:** Check:
1. Ammo > 0
2. Not reloading (`isReloading = false`)
3. Fire rate cooldown passed

**Problem:** Recoil too strong/weak
**Solution:** Adjust `RecoilVertical`, `RecoilHorizontal`, and `RecoilRecovery` in `FPSConfig.WeaponStats`

### HUD Issues

**Problem:** Crosshair not showing
**Solution:** Check `FPSConfig.HUD.CrosshairEnabled = true`

**Problem:** Hitmarkers not appearing
**Solution:** Verify `WeaponHitConfirm` remote event is firing from server

---

**Document Version:** 1.0
**Last Updated:** 2025
**Author:** GitHub Copilot
