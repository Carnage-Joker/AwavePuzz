# Animation Creation Guide for AwavePuzz

This guide walks you through creating weapon animations for the AwavePuzz FPS system using Roblox Studio's Animation Editor.

## Prerequisites

- Roblox Studio installed and updated
- Animation Editor plugin (built-in to Studio)
- Basic understanding of keyframe animation
- Viewmodel rig prepared (see below)

## Table of Contents

1. [Preparing Your Viewmodel Rig](#preparing-your-viewmodel-rig)
2. [Animation Editor Basics](#animation-editor-basics)
3. [Creating Each Animation Type](#creating-each-animation-type)
4. [Publishing and Integration](#publishing-and-integration)
5. [Testing Your Animations](#testing-your-animations)
6. [Tips and Best Practices](#tips-and-best-practices)

---

## Preparing Your Viewmodel Rig

### Creating a Basic Viewmodel Rig

1. **Open Roblox Studio**
2. **Insert a Rig:**
   - Go to the Avatar tab
   - Click "Rig Builder"
   - Select "R15" or "R6" (R15 recommended for more joint control)
   
3. **Modify for First-Person:**
   - Delete or make invisible: Head, Torso, Lower body
   - Keep: Right arm, Left arm, shoulder joints
   - Add a HumanoidRootPart if not present

4. **Add Weapon Attachment Point:**
   - Create a Part named "WeaponAttach"
   - Weld to RightHand
   - This is where the weapon model will attach

5. **Test the Rig:**
   - Ensure all Motor6D connections work
   - Move joints manually to verify range of motion

### Basic Viewmodel Structure

```
ViewmodelRig (Model)
├── HumanoidRootPart (Part)
├── Humanoid
├── UpperTorso (Part)
├── RightUpperArm (Part)
│   └── RightShoulder (Motor6D)
├── RightLowerArm (Part)
│   └── RightElbow (Motor6D)
├── RightHand (Part)
│   └── RightWrist (Motor6D)
│   └── WeaponAttach (Part)
├── LeftUpperArm (Part)
│   └── LeftShoulder (Motor6D)
├── LeftLowerArm (Part)
│   └── LeftElbow (Motor6D)
└── LeftHand (Part)
    └── LeftWrist (Motor6D)
```

---

## Animation Editor Basics

### Opening the Animation Editor

1. **Select your rig** in the workspace
2. **Go to Plugins tab** → Click "Animation Editor"
3. **Click "Create" in the Animation Editor window**

### Understanding the Interface

- **Timeline:** Shows keyframes across time
- **Track List:** Lists all animatable parts (bones/joints)
- **Playback Controls:** Play, pause, stop, scrub
- **Keyframe Controls:** Add, delete, move keyframes

### Adding Keyframes

1. **Move the timeline** to desired time (e.g., 0.5 seconds)
2. **Select a body part** (e.g., RightHand)
3. **Rotate/move the part** to desired position
4. **Click the diamond icon** to add keyframe
   - Or press `K` key

### Easing Types

- **Linear:** Constant speed (robotic)
- **Constant:** No interpolation (instant change)
- **Cubic:** Smooth acceleration/deceleration (natural)
- **Elastic:** Bouncy overshoot effect

**Recommended:** Use Cubic for most animations

---

## Creating Each Animation Type

### 1. Idle Animation

**Duration:** 2-3 seconds (looped)  
**Keyframes:** 3-5

**Steps:**

1. **Keyframe 0 (Start):**
   - Arms in natural holding position
   - Weapon pointed forward
   - Slight downward angle

2. **Keyframe 1 (1 second):**
   - Arms slightly lower (breathing)
   - Minimal rotation
   
3. **Keyframe 2 (2 seconds):**
   - Back to starting position
   - Creates loop

**Details:**
- Very subtle movement
- Simulates natural breathing/stance
- Should loop seamlessly

### 2. Fire Animation

**Duration:** 0.1-0.2 seconds  
**Keyframes:** 2-3

**Steps:**

1. **Keyframe 0 (Start):**
   - Idle position

2. **Keyframe 1 (0.05s):**
   - Arms pushed back slightly (recoil)
   - Weapon rotates up ~5-10 degrees
   - Shoulders push back

3. **Keyframe 2 (0.15s):**
   - Return toward idle (recovery handled by code)

**Details:**
- Quick and snappy
- Simulate recoil kick
- Don't overdo the movement (camera also has recoil)

### 3. Reload Animation

**Duration:** Matches weapon's ReloadTime (e.g., 1.5s for pistol)  
**Keyframes:** 6-8

**Pistol Reload Steps:**

1. **Keyframe 0 (0s) - Start:**
   - Idle position

2. **Keyframe 1 (0.2s) - Magazine Release:**
   - Left hand moves to magazine
   - Slight weapon tilt

3. **Keyframe 2 (0.4s) - Magazine Out:**
   - Left hand pulls magazine down and away
   - Right hand adjusts grip

4. **Keyframe 3 (0.6s) - New Magazine:**
   - Left hand returns with new magazine
   - Position below mag well

5. **Keyframe 4 (0.9s) - Magazine Insert:**
   - Left hand pushes magazine in
   - Slight upward motion

6. **Keyframe 5 (1.2s) - Tap Magazine:**
   - Quick tap to seat magazine
   - Left hand moves to slide

7. **Keyframe 6 (1.5s) - Chamber Round (if needed):**
   - Slide pull/release
   - Back to idle

**Details:**
- Most complex animation
- Reference real reload videos
- Timing is crucial - match weapon ReloadTime exactly

### 4. Equip Animation

**Duration:** 0.3-0.5 seconds  
**Keyframes:** 2-3

**Steps:**

1. **Keyframe 0 (Start):**
   - Arms at side/below camera view
   - Weapon pointed down

2. **Keyframe 1 (0.2s):**
   - Arms rising, weapon coming up
   - Weapon rotating to forward position

3. **Keyframe 2 (0.4s):**
   - Idle position
   - Weapon ready

**Details:**
- Quick and satisfying
- Creates "draw" feel
- Slight overshoot then settle adds weight

### 5. Sprint Animation

**Duration:** 1-2 seconds (looped)  
**Keyframes:** 3-4

**Steps:**

1. **Keyframe 0 (Start):**
   - Weapon lowered and angled
   - Arms relaxed

2. **Keyframe 1 (0.5s):**
   - Slight weapon bob up
   - Natural running motion

3. **Keyframe 2 (1s):**
   - Weapon bob down
   - Opposite of keyframe 1

4. **Keyframe 3 (1.5s):**
   - Back to start (seamless loop)

**Details:**
- Simulates running motion
- Weapon angled down and to side
- Rhythmic bobbing

### 6. ADS (Aim Down Sights) Animation

**Duration:** 0.2-0.3 seconds  
**Keyframes:** 2-3

**Steps:**

1. **Keyframe 0 (Start):**
   - Idle position

2. **Keyframe 1 (0.15s):**
   - Weapon moves toward camera/face
   - Arms pull in
   - Weapon centered

3. **Keyframe 2 (0.25s):**
   - Sights aligned with camera
   - Stable position (will loop)

**Details:**
- Smooth transition
- Weapon should center on screen
- Create "looking down sights" feel

---

## Publishing and Integration

### Publishing Your Animation

1. **In Animation Editor**, click the three dots (⋯)
2. **Select "Publish to Roblox"**
3. **Name your animation** (e.g., "PistolReload")
4. **Add description** (optional)
5. **Click "Submit"**
6. **Copy the Asset ID** that appears

### Adding to FPSConfig

1. **Open** `src/shared/FPSConfig.lua`
2. **Find** `FPSConfig.Animations.WeaponAnimations`
3. **Replace placeholder** with your asset ID:

```lua
FPSConfig.Animations.WeaponAnimations.Pistol = {
    idle = "rbxassetid://1234567890",    -- Your idle animation ID
    fire = "rbxassetid://1234567891",    -- Your fire animation ID
    reload = "rbxassetid://1234567892",  -- Your reload animation ID
    equip = "rbxassetid://1234567893",   -- Your equip animation ID
    sprint = "rbxassetid://1234567894",  -- Your sprint animation ID
    ads = "rbxassetid://1234567895",     -- Your ADS animation ID
}
```

### Making Animations Public

If your game is published:
1. **Go to Create page** on Roblox
2. **Find your animation** under "Animations"
3. **Click "Configure"**
4. **Set to Public** if needed
5. Verify the asset ID matches

---

## Testing Your Animations

### In Studio

1. **Play Solo** in Roblox Studio
2. **Equip the weapon** (press 1, 2, 3, or 4)
3. **Test each action:**
   - Idle: Just hold the weapon
   - Fire: Left-click
   - Reload: Press R
   - Sprint: Hold Shift while moving
   - ADS: Right-click

### Debugging

**Animation not playing?**
- Check Output window for errors
- Verify asset ID is correct
- Ensure animation is published
- Check animation loads: Look for "[FPSAnimationController] Loaded animation" message

**Animation looks wrong?**
- Check viewmodel rig structure
- Verify Motor6D connections
- Adjust weapon offset in `FPSConfig.Animations.WeaponOffsets`

**Animation timing off?**
- For reload: Check `ReloadTime` in `FPSConfig.WeaponStats`
- Animation speed auto-adjusts to match
- Ensure animation length in Studio matches expected duration

---

## Tips and Best Practices

### General Animation Tips

✅ **Use Reference Footage:**
- Watch real-world firearm handling videos
- Study other FPS games
- Observe natural hand movements

✅ **Keep It Snappy:**
- Players want responsive controls
- Shorter animations feel more satisfying
- 0.5-2 seconds for most actions

✅ **Add Weight:**
- Heavier weapons = slower, more deliberate
- Light weapons = quick, snappy
- Use easing to create weight feel

✅ **Test in First-Person:**
- Always test from player's viewpoint
- Check for camera clipping
- Verify hand positions look natural

❌ **Avoid Common Mistakes:**
- Don't make animations too long
- Don't forget to loop idle/sprint animations
- Don't clip through the camera
- Don't use constant easing (looks robotic)

### Weapon-Specific Guidelines

**Pistol:**
- Quick draw (0.3s)
- Fast reload (1.5s)
- Snappy fire animation

**SMG:**
- Similar to pistol
- Slightly heavier feel
- Faster fire rate = shorter fire animation

**Shotgun:**
- Slower, more deliberate
- Pump action after each shot
- Heavier equip animation

**Rifle:**
- Controlled, precise movements
- Longer ADS time
- Slower reload

### Performance Considerations

- **Keep polygon count low** on viewmodel
- **Limit keyframe count** - only add what's needed
- **Reuse animations** where possible
- **Test on lower-end devices** if possible

### Advanced Techniques

**Animation Layering:**
- Fire animation plays over idle
- Uses animation priority system
- Handled automatically by FPSAnimationController

**Procedural + Keyframe:**
- Keyframed animations for major actions
- Procedural (sway, breathing) for subtle motion
- Combine for best results

**IK (Inverse Kinematics):**
- Advanced: Position hand on weapon grip
- Requires IK constraint setup
- Not covered in basic guide

---

## Checklist: Complete Animation Set

For each weapon (Pistol, SMG, Shotgun, Rifle), create:

- [ ] **Idle animation** (2-3s, looped)
- [ ] **Fire animation** (0.1-0.2s)
- [ ] **Reload animation** (matches ReloadTime)
- [ ] **Equip animation** (0.3-0.5s)
- [ ] **Sprint animation** (1-2s, looped)
- [ ] **ADS animation** (0.2-0.3s, looped)

**Total:** 24 animations (6 per weapon × 4 weapons)

## Useful Resources

- **Roblox Animation Editor Docs:** https://create.roblox.com/docs/animation/editor
- **Animation Principles:** https://en.wikipedia.org/wiki/12_basic_principles_of_animation
- **FPS Animation References:** Study popular FPS games (Call of Duty, Valorant, etc.)

---

## Getting Help

**Common Issues:**
- See [WEAPON_ANIMATIONS.md - Troubleshooting](WEAPON_ANIMATIONS.md#troubleshooting)
- Check Roblox DevForum for animation help
- Review Output window for error messages

**Animation Not Working?**
1. Verify asset ID is correct
2. Check animation is published and public
3. Ensure rig structure matches expected hierarchy
4. Test with a simple animation first

---

**Happy Animating!**

With these animations in place, your weapon system will feel polished and professional. Take your time with each animation and iterate based on playtesting feedback.

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Author:** GitHub Copilot
