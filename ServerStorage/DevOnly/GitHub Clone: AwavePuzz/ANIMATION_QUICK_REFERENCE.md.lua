-- @ScriptType: Script
# Weapon Animation Quick Reference

Quick reference guide for the AwavePuzz weapon animation system.

## Quick Start

1. **Animation system works automatically** - No setup required
2. **Add animation assets** to enhance visuals (optional)
3. **Configure in** `FPSConfig.Animations`

## Animation Types

| Type | Duration | Looped | Priority | Trigger |
|------|----------|--------|----------|---------|
| **Idle** | 2-3s | ✓ Yes | Idle | Auto on equip |
| **Fire** | 0.1-0.2s | ✗ No | Action | Left click |
| **Reload** | 1.5-3s | ✗ No | Action2 | R key |
| **Equip** | 0.3-0.5s | ✗ No | Action | Weapon switch (1-4) |
| **Sprint** | 1-2s | ✓ Yes | Movement | Hold Shift |
| **ADS** | 0.2-0.3s | ✓ Yes | Action | Right click |

## Configuration Locations

| Setting | File | Path |
|---------|------|------|
| Animation IDs | `FPSConfig.lua` | `FPSConfig.Animations.WeaponAnimations` |
| Weapon Offsets | `FPSConfig.lua` | `FPSConfig.Animations.WeaponOffsets` |
| Procedural Settings | `FPSConfig.lua` | `FPSConfig.Animations.*` |
| Weapon Stats | `FPSConfig.lua` | `FPSConfig.WeaponStats` |

## Adding Animation Assets

```lua
-- In src/shared/FPSConfig.lua
FPSConfig.Animations.WeaponAnimations.Pistol = {
    idle = "rbxassetid://YOUR_ID_HERE",
    fire = "rbxassetid://YOUR_ID_HERE",
    reload = "rbxassetid://YOUR_ID_HERE",
    equip = "rbxassetid://YOUR_ID_HERE",
    sprint = "rbxassetid://YOUR_ID_HERE",
    ads = "rbxassetid://YOUR_ID_HERE",
}
```

## Procedural Animation Settings

```lua
-- Weapon Sway
FPSConfig.Animations.WeaponSwayEnabled = true
FPSConfig.Animations.SwayAmount = 0.02        -- 0-1, higher = more sway
FPSConfig.Animations.SwaySpeed = 10           -- Recovery speed

-- Breathing
FPSConfig.Animations.BreathingEnabled = true
FPSConfig.Animations.BreathSpeed = 2          -- Cycles per second
FPSConfig.Animations.BreathAmount = 0.01      -- Displacement

-- Recoil Recovery
FPSConfig.Animations.RecoilRecoverySpeed = 10 -- Speed of return
```

## Weapon Positioning

Adjust per-weapon offset to position correctly in viewmodel:

```lua
FPSConfig.Animations.WeaponOffsets = {
    Pistol = CFrame.new(X, Y, Z) * CFrame.Angles(pitch, yaw, roll),
}

-- X: Left (-) / Right (+)
-- Y: Down (-) / Up (+)
-- Z: Forward (+) / Back (-)
-- Angles in radians: math.rad(degrees)
```

## Event Flow

```
Player Action          →  Weapon Controller  →  Animation Controller
─────────────────────────────────────────────────────────────────────
Left Click (Fire)      →  WeaponFired        →  playFire()
R Key (Reload)         →  ReloadStarted      →  playReload()
Right Click (ADS)      →  ADSStateChanged    →  setADS()
Shift (Sprint)         →  SprintStateChanged →  setSprinting()
1-4 Keys (Switch)      →  WeaponEquipped     →  equipWeapon()
```

## Common Tasks

### Add New Weapon Animations

1. Create 6 animations in Roblox Studio
2. Publish animations and copy asset IDs
3. Add to `FPSConfig.Animations.WeaponAnimations.[WeaponName]`
4. Add weapon offset to `FPSConfig.Animations.WeaponOffsets.[WeaponName]`
5. Test in-game

### Adjust Weapon Position

1. Open `FPSConfig.lua`
2. Find `FPSConfig.Animations.WeaponOffsets.[WeaponName]`
3. Adjust CFrame values
4. Test in first-person view
5. Iterate until correct

### Disable Procedural Animations

```lua
-- Disable all
FPSConfig.Animations.Enabled = false

-- Disable specific
FPSConfig.Animations.WeaponSwayEnabled = false
FPSConfig.Animations.BreathingEnabled = false
FPSConfig.Animations.RecoilAnimationEnabled = false
```

### Create Custom Viewmodel Arms

1. Create R15 rig in Studio
2. Keep only arms (delete torso, legs, head)
3. Name model "ViewmodelArms"
4. Save to `ServerStorage.ViewmodelArms`
5. System will automatically use custom arms

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Animations not playing | Check asset IDs, ensure published and public |
| Weapon not visible | Check `ServerStorage.Guns.[WeaponName]` exists |
| Weapon clipping camera | Adjust Z offset (increase) in `WeaponOffsets` |
| Sway too aggressive | Reduce `SwayAmount` to 0.01 or lower |
| Reload out of sync | Check `ReloadTime` in `WeaponStats` matches animation |

## File Locations

```
src/
├── client/
│   ├── FPSAnimationController.client.lua  ← Main animation system
│   ├── FPSWeaponController.client.lua     ← Fires animation events
│   └── FPSMovementController.client.lua   ← Sprint events
└── shared/
    └── FPSConfig.lua                      ← All configuration

ServerStorage/
├── Guns/                                  ← Weapon models
│   ├── Pistol
│   ├── SMG
│   ├── Shotgun
│   └── Rifle
└── ViewmodelArms                          ← (Optional) Custom arms
```

## API Quick Reference

```lua
-- Get animation controller (already initialized)
local FPSAnimationController = require(script.FPSAnimationController)

-- Equip weapon
FPSAnimationController:equipWeapon("Pistol")

-- Play animations manually
FPSAnimationController:playFire("Pistol")
FPSAnimationController:playReload("Pistol", 1.5)

-- Toggle states
FPSAnimationController:setADS(true)
FPSAnimationController:setSprinting(true)

-- Stop animations
FPSAnimationController:stopAnimation("reload")
FPSAnimationController:stopAllAnimations()
```

## Animation Creation Workflow

1. **Prepare rig** with proper Motor6D hierarchy
2. **Open Animation Editor** in Studio
3. **Create keyframes** for animation
4. **Adjust timing** to match weapon stats
5. **Publish to Roblox** and copy asset ID
6. **Add to config** in FPSConfig.lua
7. **Test in-game** and iterate

## Performance Tips

- Use low-poly viewmodel arms
- Limit keyframe count in animations
- Procedural animations are lightweight
- Disable unused procedural effects
- Test on lower-end devices

## Links

- **Full Documentation:** [WEAPON_ANIMATIONS.md](WEAPON_ANIMATIONS.md)
- **Creation Guide:** [ANIMATION_CREATION_GUIDE.md](ANIMATION_CREATION_GUIDE.md)
- **API Reference:** [API_DOCUMENTATION.md#fpsanimationcontroller](API_DOCUMENTATION.md#fpsanimationcontroller)
- **FPS Documentation:** [FPS_DOCUMENTATION.md](FPS_DOCUMENTATION.md)

---

**Quick Tip:** The system works great with just procedural animations! Add animation assets when you're ready for that extra polish.
