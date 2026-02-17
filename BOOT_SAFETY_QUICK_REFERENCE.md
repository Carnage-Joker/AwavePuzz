# Boot Safety Quick Reference

## Entry Points (DO NOT MODIFY)

### Server Entry Point
**File**: `ServerScriptService/MainServerScript.legacy.lua`
- ⚠️ **This is the ONLY server boot script**
- Has duplicate execution guard
- Runs 6-phase initialization

### Client Entry Point  
**File**: `StarterPlayer/StarterPlayerScripts/BootClient.lua`
- ⚠️ **This is the ONLY client boot script**
- Delegates to `BootModule.lua`
- Has duplicate execution guard

## Testing Boot Changes

### Quick Boot Test
In Roblox Studio Command Bar:
```lua
require(game.ReplicatedStorage.tests.run_boot_tests)
```

### Expected Result
```
✅ ALL TESTS PASSED - Boot system is healthy
Tests Passed: 12
Tests Failed: 0
```

## Adding New Services

### Initialization Order Rules
1. Add service require to Phase 3 in `MainServerScript.legacy.lua`
2. If service depends on PlayerManager, initialize AFTER line 119
3. If service depends on GameManager, initialize AFTER line 101
4. Link services together AFTER all are initialized (Phase 3 end)

### Example
```lua
-- Phase 3: In MainServerScript.legacy.lua
local MyService = require(script.Parent.MyService)

-- After PlayerManager is available (line 119+)
local myService = MyService.new(playerManager)
print("[BOOT][SERVER] MyService initialized")

-- Link to other services (after line 164)
gameManager:setMyService(myService)
```

## Adding New Remotes

### DO NOT create remotes manually!

### Correct Way
1. Edit `ReplicatedStorage/Shared/Remotes/RemoteRegistry.lua`
2. Add to `REMOTE_DEFINITIONS` array:
```lua
{Name = "MyNewRemote", Type = "Event"}, -- or "Function"
```
3. RemoteRegistry creates it automatically on server boot
4. Client waits for it automatically

## Module Loading Rules

### ALWAYS use timeouts
```lua
-- ❌ BAD - Can infinite yield
local module = folder:WaitForChild("Module")

-- ✅ GOOD - With timeout
local module = folder:WaitForChild("Module", 5)
if not module then
    error("Failed to load Module")
end
```

### Standard Timeouts
- Shared folder: 10 seconds
- Config modules: 5 seconds
- RemoteRegistry: 5 seconds
- Client modules: 10 seconds

## Boot Log Format

### Use consistent prefixes
```lua
print("[BOOT][SERVER] Phase 1: Action...")
print("[BOOT][CLIENT] Phase 2: Action...")
print("[ServiceName] Initialized")
```

### Phase messages
```lua
print("[BOOT][SERVER] Phase N: Starting...")
-- ... do work ...
print("[BOOT][SERVER] Phase N complete: Result")
```

## Common Issues

### "Infinite yield" warning
**Cause**: Missing timeout or module doesn't exist
**Fix**: Add timeout parameter, verify module exists

### Duplicate execution
**Cause**: Multiple boot scripts or missing guard
**Fix**: Check for duplicate scripts, verify guard is present

### "CRITICAL: Failed to load"
**Cause**: Module not found or timeout too short
**Fix**: Verify module path, increase timeout if needed

### Service initialization fails
**Cause**: Wrong initialization order
**Fix**: Check dependencies, init parents before children

## Testing Checklist

Before committing boot changes:
- [ ] Run `boot_smoke_tests.lua` - all pass
- [ ] Test "Server & Clients" in Studio
- [ ] No red errors in output
- [ ] All phases complete successfully
- [ ] No new warnings introduced
- [ ] Test with multiple clients
- [ ] Test server reload behavior

## Documentation Files

- **BOOT_SAFETY_GUIDE.md** - Complete boot system docs
- **BOOT_FLOW.md** - Boot sequence flow
- **tests/README.md** - Test documentation
- **This file** - Quick reference

## Emergency Contacts

If boot system breaks:
1. Check `MainServerScript.legacy.lua` for errors
2. Run `boot_smoke_tests.lua` to identify issue
3. Review recent commits for boot-related changes
4. Check Output for "CRITICAL" errors
5. Consult BOOT_SAFETY_GUIDE.md for troubleshooting

## Version

Boot Safety System: **v1.0**
Last Updated: **2026-02-17**
Status: ✅ **Production Ready**
