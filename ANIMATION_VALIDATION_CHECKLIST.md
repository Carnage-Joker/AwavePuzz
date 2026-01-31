# Animation ID Validation Checklist

Quick reference checklist for developers working with animation assets in AwavePuzz.

---

## 🚀 Quick Start

When you start the game in Roblox Studio, check the **Output** window for:

```
[MainServer] Validating animation and sound assets...
=== AssetValidation: Boot-Time Validation ===
```

If you see ✅ **green messages** → All assets are valid!  
If you see ⚠️ **yellow warnings** → Some assets need attention (see below).

---

## ✅ Pre-Commit Checklist

Before committing changes to `AssetConfig.lua`:

- [ ] All animation IDs use format `rbxassetid://XXXXXXXX`
- [ ] No placeholder IDs (`rbxassetid://0`) except documented ones
- [ ] Animation IDs are 7-11 digits (typical Roblox range)
- [ ] Animations are published and set to Public in Roblox
- [ ] Tested loading each animation in Studio
- [ ] Boot validation passes (no errors in Output)

---

## 🧪 Testing New Animations

### Step 1: Add Animation to Config

Edit `ReplicatedStorage/Shared/AssetConfig.lua`:

```lua
-- Example: Adding a new weapon animation
WeaponAnimations = {
    Pistol = {
        idle = "rbxassetid://YOUR_ANIMATION_ID",
        -- ... other animations
    }
}
```

### Step 2: Run Validation Test

1. Open `ServerStorage/DevOnly/AnimationValidationTest.lua`
2. Copy the entire script
3. Paste into **Command Bar** in Studio
4. Press **Enter**
5. Check **Output** for results

Expected output:
```
✅ All tests PASSED (ignoring expected placeholders)
```

### Step 3: Test In-Game

1. Start game in Studio (F5 or Play button)
2. Check **Output** window during server startup
3. Look for validation messages
4. Equip weapon and verify animation plays

---

## 🔍 Debugging Invalid Animation IDs

If validation reports an invalid ID:

### Check 1: Format
```lua
❌ Wrong: "507766666"
❌ Wrong: "http://www.roblox.com/asset/?id=507766666"
✅ Correct: "rbxassetid://507766666"
```

### Check 2: Animation Exists
```lua
-- Test in Command Bar:
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://YOUR_ID"
print(anim.AnimationId) -- Should echo back the ID
```

### Check 3: Animation is Public
1. Go to Roblox.com
2. Navigate to Create → Animations
3. Find your animation
4. Ensure it's set to **Public** (not Private)

### Check 4: ID is Valid Number
```lua
-- Animation IDs should be:
-- ✅ 7-11 digits: rbxassetid://507766666
-- ⚠️ 14+ digits may be invalid
```

---

## 📋 Common Issues & Solutions

### Issue: "Invalid AnimationId for 'Pistol.ads': 'rbxassetid://0'"

**Cause:** Placeholder ID not replaced  
**Solution:** Create and upload the animation, then update the ID

```lua
-- Before:
ads = "rbxassetid://0",  -- Placeholder

-- After:
ads = "rbxassetid://1234567890",  -- Your uploaded animation
```

---

### Issue: Animation loads but doesn't play

**Possible causes:**
1. Animation not compatible with rig type
2. Animation priority conflicts
3. Animator not found on character

**Solution:**
```lua
-- Check animator exists
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
end
```

---

### Issue: "Asset failed to load" error

**Cause:** Animation is private or doesn't exist  
**Solution:**
1. Verify animation exists on Roblox
2. Set animation to Public
3. Wait 5-10 minutes for Roblox to update
4. Clear cache and retry

---

### Issue: All weapons share same animations

**This is intentional** (currently)  
To create unique animations per weapon:

1. Create new animation for specific weapon
2. Upload to Roblox
3. Update specific weapon entry:

```lua
SMG = {
    idle = "rbxassetid://NEW_SMG_IDLE",  -- Unique to SMG
    -- ... other animations
}
```

---

## 🛠️ Development Workflow

### Creating a New Animation

1. **Create in Studio**
   - Open Animation Editor
   - Create keyframes
   - Preview animation

2. **Publish to Roblox**
   - File → Publish Animation
   - Set to Public
   - Copy Asset ID

3. **Add to Config**
   ```lua
   -- In AssetConfig.lua
   WeaponAnimations = {
       NewWeapon = {
           idle = "rbxassetid://YOUR_ID",
           -- ... add all 6 animation types
       }
   }
   ```

4. **Test Validation**
   - Run `AnimationValidationTest.lua`
   - Check Output for errors
   - Fix any issues

5. **Test In-Game**
   - Start game
   - Equip weapon
   - Verify animation plays

6. **Commit Changes**
   - Git add `AssetConfig.lua`
   - Git commit with descriptive message
   - Git push

---

## 📊 Validation Output Reference

### ✅ Success Messages

```
[AssetValidation] All animation assets validated successfully (WeaponAnimations)
[AssetValidation] All sound assets validated successfully (Sounds)
[AssetValidation] ✅ All animation and sound assets validated successfully!
```

**Meaning:** All assets are valid, game will work correctly.

---

### ⚠️ Warning Messages

```
[AssetValidation] Invalid AnimationId for 'Pistol.ads': 'rbxassetid://0'
[AssetValidation] ⚠️ Found 4 invalid asset(s): 4 animation(s), 0 sound(s)
```

**Meaning:** Some assets are placeholders or invalid. Game will continue but animations may not play.

**Action:** Replace placeholder IDs with valid animation assets.

---

### ❌ Error Messages

```
[AssetValidation] Cannot load invalid animation ID: rbxassetid://0
```

**Meaning:** Attempted to load an invalid animation at runtime.

**Action:** Check AssetConfig and replace invalid IDs.

---

## 🔢 Valid Animation ID Formats

| Format | Valid? | Example |
|--------|--------|---------|
| `rbxassetid://507766666` | ✅ Yes | Modern format (preferred) |
| `rbxassetid://1234567890` | ✅ Yes | Modern format with longer ID |
| `"507766666"` | ✅ Yes | Plain number (converted automatically) |
| `507766666` | ✅ Yes | Number type |
| `http://www.roblox.com/asset/?id=507766666` | ⚠️ Legacy | Old format (works but not recommended) |
| `rbxassetid://0` | ❌ No | Placeholder (invalid) |
| `"0"` | ❌ No | Zero (invalid) |
| `""` | ❌ No | Empty string (invalid) |
| `nil` | ❌ No | Null value (invalid) |

---

## 📝 Animation Types Required

### Per Weapon (6 animations)

- [ ] **idle** - Holding weapon (looped)
- [ ] **fire** - Shooting (0.1-0.3s)
- [ ] **reload** - Magazine change (1.5-3s)
- [ ] **equip** - Drawing weapon (0.3-0.5s)
- [ ] **sprint** - Running with weapon (looped)
- [ ] **ads** - Aim down sights (looped)

### Current Status

| Weapon | Progress | Missing |
|--------|----------|---------|
| Pistol | 5/6 (83%) | ads |
| SMG | 5/6 (83%) | ads |
| Shotgun | 5/6 (83%) | ads |
| Rifle | 5/6 (83%) | ads |

**Overall:** 20/24 = 83.3% complete

---

## 🎯 Priority Tasks

### High Priority
1. ✅ Boot-time validation (DONE)
2. ⚠️ Create 4 ADS animations
3. ⚠️ Verify weapon animation IDs are valid

### Medium Priority
4. 📝 Update legacy `Animate.lua` format
5. ♻️ Consider unique animations per weapon

### Low Priority
6. 📚 Document animation creation process
7. 🧪 Add more automated tests

---

## 🔗 Quick Links

- **Audit Report:** [ANIMATION_ID_AUDIT_REPORT.md](ANIMATION_ID_AUDIT_REPORT.md)
- **Summary:** [ANIMATION_ID_AUDIT_SUMMARY.md](ANIMATION_ID_AUDIT_SUMMARY.md)
- **Test Script:** `ServerStorage/DevOnly/AnimationValidationTest.lua`
- **Asset Config:** `ReplicatedStorage/Shared/AssetConfig.lua`
- **Validation System:** `ReplicatedStorage/Shared/AssetValidation.lua`

---

## 🆘 Getting Help

If you encounter issues:

1. **Check Output window** for detailed error messages
2. **Run validation test** to identify specific problems
3. **Review audit report** for comprehensive documentation
4. **Test in Studio** before committing changes

---

**Last Updated:** 2026-01-31  
**Version:** 1.0  
**Maintainer:** Development Team
