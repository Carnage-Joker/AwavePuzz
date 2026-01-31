# UI Duplicate Detection Test

## Purpose
This test verifies that no duplicate UI ScreenGuis exist in PlayerGui after the duplicate UI fix has been implemented.

## How to Run

### In Roblox Studio

1. **Open the game in Roblox Studio**
2. **Copy the test script**:
   - Open `tests/ui_duplicate_detection.lua`
   - Copy all the contents

3. **Create a test LocalScript**:
   - In the Explorer, go to `StarterPlayer > StarterPlayerScripts`
   - Create a new LocalScript (not ModuleScript)
   - Name it "UI_Duplicate_Test"
   - Paste the copied code

4. **Run the game**:
   - Press F5 or click "Play" to test in Studio
   - Wait at least 5 seconds for all UIs to initialize

5. **Check the Output window**:
   - Open the Output window (View → Output or F9)
   - Look for the test results

6. **Remove the test script**:
   - After testing, delete the "UI_Duplicate_Test" LocalScript
   - Don't commit this script to the repository

### Expected Output (PASS)

```
========================================
UI DUPLICATE DETECTION TEST
========================================
✅ FPSHUD: OK (1 instance)
✅ PlayerHUD: OK (1 instance)
✅ WaveUI: OK (1 instance)
✅ CureUI: OK (1 instance)
... (all UIs should show OK)

========================================
SUMMARY
========================================
Total Expected UIs: 22
Missing UIs: 0
Duplicate UIs: 0
Total Duplicate Instances: 0

✅ TEST PASSED - No duplicates detected!
========================================
```

### Example Output (FAIL - Before Fix)

```
========================================
UI DUPLICATE DETECTION TEST
========================================
❌ FPSHUD: DUPLICATE (expected 1, found 2)
❌ WaveUI: DUPLICATE (expected 1, found 2)
✅ PlayerHUD: OK (1 instance)
... 

========================================
SUMMARY
========================================
Total Expected UIs: 22
Missing UIs: 0
Duplicate UIs: 2
Total Duplicate Instances: 2

❌ TEST FAILED - Duplicates detected!
Duplicate UIs:
  - FPSHUD (2 instances)
  - WaveUI (2 instances)
========================================
```

## Test Scenarios

### 1. Initial Join
- Join the game server
- Run the test after 5 seconds
- Verify no duplicates exist

### 2. Respawn Test
- Join the game
- Die/respawn 3-5 times
- Run the test
- Verify no duplicates were created

### 3. Menu Toggle Test
- Join the game
- Open and close various menus (Shop, Scoreboard, Alliance, etc.) multiple times
- Run the test
- Verify no duplicates were created

### 4. Server Rejoin
- Join the game, then leave
- Rejoin the same server
- Run the test
- Verify no duplicates exist

## Troubleshooting

### Missing UIs
Some UIs may be intentionally missing if:
- They're only shown in specific game states (e.g., EpilogueUI only shows at game end)
- They're disabled by configuration (e.g., PortalQueueUI when portal matchmaking is off)
- The player hasn't triggered them yet (e.g., ControlsTutorialUI only on first play)

This is normal and doesn't indicate a problem. The test will list them as "Missing (may be intentional)".

### Unexpected UIs
If the test shows "Unexpected" UIs, these are ScreenGuis in PlayerGui that aren't in the expected list. They could be:
- Roblox built-in UIs
- Third-party plugin UIs (in Studio)
- New UIs added after the test was created

Update the `expectedUIs` list in the test if you've added new UI modules.

## Debug Mode

To enable detailed logging during UI creation:

1. Open `ReplicatedStorage/Shared/UIDebugConfig.lua`
2. Set `DEBUG_UI_CREATION = true`
3. Run the game and check Output for detailed UI creation logs
4. Look for "[UIDebug]" messages showing when each UI is created
5. Warnings will appear if duplicates are detected and destroyed

## Related Files

- **Implementation Summary**: `UI_DUPLICATE_FIX_SUMMARY.md`
- **Debug Config**: `ReplicatedStorage/Shared/UIDebugConfig.lua`
- **UI Modules**: `StarterPlayer/StarterPlayerScripts/Modules/UI/*.lua`
- **Controller**: `StarterPlayer/StarterPlayerScripts/ClientController.client.lua`
