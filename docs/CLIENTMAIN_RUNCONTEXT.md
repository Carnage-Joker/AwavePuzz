# ClientMain RunContext Configuration

## Issue
ClientMain.client.lua may run multiple times if RunContext is not set correctly in Roblox Studio, causing warnings like:
```
[ClientMain] Already initialized, skipping duplicate execution
```

## Solution

**IMPORTANT**: The RunContext property must be set in Roblox Studio. It cannot be set via code.

### Steps to Fix

1. **Open Roblox Studio** with the AwavePuzz project
2. **Navigate** to `StarterPlayer > StarterPlayerScripts > ClientMain.client.lua`
3. **Select** the ClientMain script in the Explorer
4. **Open Properties** panel (View > Properties or press Alt+P)
5. **Find** the `RunContext` property
6. **Set** RunContext to `Legacy` (not `Client` or `Default`)
7. **Save** the place file

### Why This is Needed

When a LocalScript is placed in `StarterPlayerScripts` with a non-Legacy RunContext:
- Roblox may execute it multiple times per player
- This causes duplicate initialization warnings
- The script has a guard (`script:GetAttribute("Initialized")`) to prevent double-execution, but the warning is still logged

Setting RunContext to `Legacy` ensures:
- Script runs exactly once per player
- Deterministic boot order
- No duplicate execution warnings

### Verification

After setting RunContext to Legacy:
1. **Test** in Studio by playing the game
2. **Check** the Output console
3. **Confirm** no "[ClientMain] Already initialized" warnings appear

### Technical Details

**RunContext Options**:
- `Legacy` (Recommended): Traditional LocalScript behavior, runs once
- `Client`: Modern execution model, may run multiple times depending on Roblox's execution order
- `Server`: Not applicable for LocalScripts

**File Location**: `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`

**Related Files**:
- `/ServerScriptService/Main.server.lua` (server entry point, no RunContext needed)

### Code-Level Safety Net

Even with RunContext=Legacy, the script maintains a duplicate execution guard:

```lua
-- Guard against duplicate execution using script attribute only (no _G)
if script:GetAttribute("Initialized") then
	warn("[ClientMain] Already initialized, skipping duplicate execution")
	return
end
script:SetAttribute("Initialized", true)
```

This provides defense-in-depth in case:
- RunContext is accidentally changed
- Roblox execution model changes in the future
- Script is cloned or executed programmatically

### Troubleshooting

**If warnings still appear after setting RunContext=Legacy:**

1. **Verify** the property actually saved (check again after reopening Studio)
2. **Restart** Roblox Studio completely
3. **Check** for duplicate scripts in StarterPlayerScripts
4. **Ensure** no other code is requiring/cloning ClientMain
5. **Test** in a fresh server (not using "Resume" button)

**If the property is grayed out or unchangeable:**
- The script may be in the wrong location (should be directly in StarterPlayerScripts, not in a folder)
- Team Create may be preventing property changes (claim the script first)

### Related Documentation

- `/docs/BOOT_FLOW.md` - Client and server boot sequence
- `/docs/CODE_ARCHITECTURE.md` - Overall system architecture
- [Roblox Docs: RunContext](https://create.roblox.com/docs/reference/engine/enums/RunContext)

---

**Last Updated**: 2026-02-04  
**Status**: Configuration Required in Studio  
**Priority**: Medium (warning only, does not break functionality)
