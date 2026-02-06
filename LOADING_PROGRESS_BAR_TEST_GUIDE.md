# Loading Progress Bar - Testing Guide

## Overview

This guide describes how to test the new loading progress bar feature on the title screen.

## Feature Description

The loading progress bar displays during client initialization and shows:
- A visual progress bar that fills from 0% to 100%
- Loading percentage text (e.g., "Loading... 45%")
- Phase name currently being loaded (e.g., "Loading CoreSystems... 75%")
- The "Press any button to continue" prompt only appears after loading reaches 100%

## Testing Checklist

### Visual Test (Roblox Studio)

1. **Start the Game**
   - [ ] Open project in Roblox Studio
   - [ ] Click Play (F5)
   
2. **Observe Title Screen**
   - [ ] Title screen appears immediately (black background with game title)
   - [ ] Loading bar is visible below the title
   - [ ] Loading bar background is dark gray/blue
   - [ ] Loading bar fill is Aether blue (cyan-ish)
   
3. **Watch Loading Progress**
   - [ ] Loading percentage starts at 0%
   - [ ] Progress bar smoothly fills from left to right
   - [ ] Loading text updates (e.g., "Loading... 15%", "Loading... 30%")
   - [ ] Phase names appear in loading text (optional, check console)
   - [ ] Progress reaches 100%
   
4. **Observe Continue Button Appearance**
   - [ ] Continue prompt is NOT visible during loading
   - [ ] After loading reaches 100%, loading bar slides down/fades out
   - [ ] "Press any button to continue" fades in smoothly
   - [ ] Continue prompt starts pulsing (opacity animation)
   
5. **Test Interaction Blocking**
   - [ ] Try pressing keys during loading (e.g., Space, Enter)
   - [ ] Verify no action occurs while loading < 100%
   - [ ] Console shows: "Key pressed but loading not complete yet"
   - [ ] After loading completes, key press works normally

### Console Log Test

1. **Check Boot Logs**
   - [ ] Open Developer Console (F9)
   - [ ] Look for `[LoadingManager]` logs:
     ```
     [LoadingManager] Initialized with 7 phases
     [LoadingManager] RemoteRegistry: 0% (Total: 0%)
     [LoadingManager] RemoteRegistry: 100% (Total: 10%)
     [LoadingManager] Configuration: 100% (Total: 20%)
     ...
     [LoadingManager] Loading complete!
     ```
   
2. **Check TitleScreenUI Logs**
   - [ ] Look for `[TitleScreenUI]` logs:
     ```
     [TitleScreenUI] Singleton instance created and registered
     [TitleScreenUI] Showing title screen
     [TitleScreenUI] Loading complete - showing continue prompt
     ```

3. **Check BootModule Logs**
   - [ ] Look for `[BOOTMODULE]` logs:
     ```
     [BOOTMODULE] ✓ LoadingManager initialized and connected to TitleScreenUI
     [BOOTMODULE] ✓ TitleScreenUI displayed immediately
     ```

### Timing Test

1. **Measure Loading Duration**
   - [ ] Start the game
   - [ ] Note the time when title screen appears
   - [ ] Note the time when continue button appears
   - [ ] Expected: 1-3 seconds (depends on system speed)
   - [ ] Loading should feel smooth, not instantaneous or too slow

### Edge Case Tests

1. **Fast System Test**
   - [ ] On a fast system, loading might complete very quickly
   - [ ] Verify loading bar is still visible (doesn't skip)
   - [ ] Verify continue button still waits for 100%

2. **Slow System Test**
   - [ ] If loading takes longer (>5 seconds), verify:
   - [ ] Loading bar updates smoothly
   - [ ] No hanging or freezing
   - [ ] Continue button appears after actual completion

3. **Multiple Player Test**
   - [ ] Test with 2 players in Studio
   - [ ] Verify both see loading bars independently
   - [ ] Verify both can continue when ready

## Expected Behavior

### During Loading (0-99%)
- Title screen visible with game title and subtitle
- Loading bar visible with progress fill
- Loading percentage text visible
- Continue prompt HIDDEN
- Keyboard/mouse input BLOCKED (no continue action)

### After Loading (100%)
- Loading bar slides down and disappears
- Continue prompt fades in smoothly
- Continue prompt starts pulsing
- Keyboard/mouse input ENABLED
- Player can press any key to continue

## Troubleshooting

### Problem: Loading bar not visible

**Possible Causes:**
- LoadingManager not initialized in BootModule
- TitleScreenUI not showing
- UI elements created incorrectly

**Check:**
- Console for `[LoadingManager]` initialization log
- Console for `[TitleScreenUI]` creation log
- Inspect PlayerGui for TitleScreenUI > TitleFrame > LoadingContainer

### Problem: Continue button appears immediately

**Possible Causes:**
- LoadingManager marking complete too early
- TitleScreenUI not checking loadingComplete flag
- Fallback to old behavior

**Check:**
- Console for loading phase logs (should see 0-100% progression)
- Console for "Loading complete" message
- Verify onContinue checks `self.loadingComplete`

### Problem: Loading stuck at certain percentage

**Possible Causes:**
- Phase not updating progress to 100%
- Error in ClientMainModule phase code
- Missing loadingManager reference

**Check:**
- Console for error messages
- Last phase that logged (may indicate which phase is stuck)
- Verify all phases call `loadingManager:updatePhase(..., 100)`

### Problem: Loading bar updates too fast

**Possible Causes:**
- Boot phases completing very quickly
- Progress updates happening all at once

**Solution:**
- This is expected on fast systems
- Loading bar should still be visible briefly
- No fix needed if continue button still waits

## Success Criteria

✅ **All tests pass if:**
1. Loading bar displays on title screen
2. Progress updates from 0% to 100%
3. Continue button only appears after 100%
4. Loading feels smooth and professional
5. No errors in console
6. Player can continue after loading completes

## Related Files

- `LoadingManager.lua` - Tracks loading progress
- `TitleScreenUI.lua` - Displays loading bar and continue button
- `BootModule.lua` - Initializes LoadingManager
- `ClientMainModule.lua` - Reports progress for each phase

## Version

- **Implemented**: 2026-02-06
- **Version**: 1.0
- **Author**: GitHub Copilot

## Notes

- This feature is part of the Title Screen First Load system
- Loading progress is client-side only
- Each client loads independently
- Loading duration may vary by system performance
