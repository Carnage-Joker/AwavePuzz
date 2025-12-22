# Title Screen & Epilogue Testing Guide

This guide explains how to test the new title screen and epilogue system in Roblox Studio.

## Overview

The game now features:
- **Title Screen**: "Aether Wave: Convergence" with atmospheric presentation
- **Epilogue**: 7-page cinematic story introducing the outbreak and alliance mechanics
- **Skipable**: Players can skip the epilogue by pressing ESC

## How to Test

### 1. Setup in Roblox Studio

1. Open your AwavePuzz place in Roblox Studio
2. Make sure all the new files are in place:
   - `src/shared/StoryConfig.lua` → ReplicatedStorage/Shared/StoryConfig
   - `src/client/UI/TitleScreenUI.client.lua` → StarterGui (as a LocalScript)
   - `src/client/UI/EpilogueUI.client.lua` → StarterGui (as a LocalScript)
   - Updated `src/server/GameManager.lua`
   - Updated `src/shared/GameConfig.lua`

### 2. Enable Title Screen and Epilogue

In `GameConfig.lua`, ensure these are set to `true`:

```lua
GameConfig.SHOW_TITLE_SCREEN = true
GameConfig.SHOW_EPILOGUE = true
GameConfig.EPILOGUE_SKIPPABLE = true
```

### 3. Start a Test Server

1. In Roblox Studio, click **Test** → **Start**
2. Watch the Output window for debug messages

### 4. Expected Flow

#### On Server Start:
- Output should show: `[GameManager] Starting in TITLE_SCREEN state`

#### When Player Joins:
1. Title screen should appear with:
   - Game title: "Aether Wave: Convergence"
   - Subtitle: "Survive. Cooperate. Betray."
   - Prompt: "Press Any Key to Begin"
2. Output shows: `[TitleScreenUI] Received ShowTitleScreen event`
3. Output shows: `[TitleScreenUI] Showing title screen`

#### When Player Presses Any Key:
1. Title screen fades out
2. Output shows: `[TitleScreenUI] Player clicked continue, notifying server`
3. Output shows: `[GameManager] Player [Name] passed title screen`
4. Output shows: `[GameManager] All players passed title screen`
5. Output shows: `[GameManager] Transitioning to EPILOGUE state`

#### Epilogue Display:
1. Black screen with story text appears
2. Output shows: `[EpilogueUI] Received ShowEpilogue event`
3. Output shows: `[EpilogueUI] Showing epilogue`
4. First page: "THE OUTBREAK"
5. Player can:
   - Click "Click to Continue" button to advance
   - Press SPACE or ENTER to advance
   - Press ESC to skip entire epilogue
6. Pages auto-advance after their DisplayTime expires

#### Epilogue Pages (7 total):
1. THE OUTBREAK - Introduction to the virus
2. THE AETHER VIRUS - Symptoms and transformation
3. THE CURE - The five components needed
4. SURVIVE TOGETHER - Alliance benefits
5. OR DIE ALONE - Betrayal temptation
6. HISTORY REPEATS - Warning from the past
7. THE CONVERGENCE - Final choice and call to action

#### After Epilogue:
1. Output shows: `[EpilogueUI] Epilogue complete, notifying server`
2. Output shows: `[GameManager] Player [Name] completed epilogue`
3. Output shows: `[GameManager] All players completed epilogue, transitioning to WAITING`
4. Game proceeds to normal lobby/gameplay flow

### 5. Test Cases

#### Test Case 1: Single Player Flow
- Start solo test
- Should see title screen
- Press any key
- Should see epilogue
- Advance through all 7 pages
- Should reach lobby/waiting state

#### Test Case 2: Skip Epilogue
- Start solo test
- Press any key on title screen
- Press ESC when epilogue appears
- Should immediately skip to waiting state

#### Test Case 3: Multiple Players
- Start multi-player test (2+ players)
- All players should see title screen
- Each player advances independently
- Game waits for ALL players to finish epilogue
- Then transitions to waiting state

#### Test Case 4: Late Joiner
- Start test with one player
- Let first player get past title/epilogue
- Add a second player mid-game
- Second player should skip directly to game (no title/epilogue)

#### Test Case 5: Disabled Title Screen
- Set `GameConfig.SHOW_TITLE_SCREEN = false`
- Set `GameConfig.SHOW_EPILOGUE = false`
- Start test
- Should skip directly to waiting/lobby (normal flow)

### 6. Debug Output to Monitor

Key debug messages to watch for:
```
[GameManager] Starting in TITLE_SCREEN state
[TitleScreenUI] Initialized and ready
[TitleScreenUI] Received ShowTitleScreen event
[TitleScreenUI] Showing title screen
[TitleScreenUI] Player clicked continue, notifying server
[GameManager] Player [Name] passed title screen
[GameManager] All players passed title screen
[GameManager] Transitioning to EPILOGUE state
[EpilogueUI] Initialized and ready
[EpilogueUI] Received ShowEpilogue event
[EpilogueUI] Showing epilogue
[EpilogueUI] Epilogue complete, notifying server
[GameManager] Player [Name] completed epilogue
[GameManager] All players completed epilogue, transitioning to WAITING
```

### 7. Common Issues and Solutions

#### Title Screen Not Appearing
- Check that `GameConfig.SHOW_TITLE_SCREEN = true`
- Verify TitleScreenUI.client.lua is in StarterGui
- Check Output for initialization messages
- Verify RemoteEvents are being created properly

#### Epilogue Not Appearing
- Check that `GameConfig.SHOW_EPILOGUE = true`
- Verify EpilogueUI.client.lua is in StarterGui
- Check that StoryConfig.lua is in ReplicatedStorage/Shared
- Look for errors in Output window

#### Stuck on Title Screen
- Check that RemoteEvents are properly connected
- Verify TitleScreenContinue event is being fired
- Check server-side debug output for player tracking

#### Stuck on Epilogue
- Verify EpilogueComplete event is being fired
- Check that all players are being tracked properly
- Try pressing ESC to skip

#### Game Doesn't Start After Epilogue
- Check that state transitions to WAITING
- Verify lobby system is working normally
- Check minimum player count settings

### 8. Visual Verification

When testing, verify these visual elements:

#### Title Screen:
- Background is dark blue-black (10, 10, 15)
- Title text is Aether blue (100, 200, 255)
- Title is large and readable
- Subtitle is slightly transparent
- Prompt pulses slowly
- Smooth fade-in animation

#### Epilogue:
- Black background
- Title is cyan/blue (100, 200, 255)
- Body text is light gray (220, 220, 220)
- Text is wrapped and readable
- Progress indicator shows "X / 7"
- Skip button in top-right (if enabled)
- Continue button at bottom
- Smooth fade transitions between pages

### 9. Performance Notes

- Title screen and epilogue should not impact game performance
- All UI uses TweenService for smooth animations
- Minimal network traffic (only state transitions)
- Client-side rendering for all visuals

### 10. Disabling for Testing

To quickly disable for faster testing cycles:

```lua
-- In GameConfig.lua
GameConfig.SHOW_TITLE_SCREEN = false  -- Skip title screen
GameConfig.SHOW_EPILOGUE = false      -- Skip epilogue
```

This is useful when you want to repeatedly test gameplay without watching the intro each time.

## Story Content

The epilogue tells the story of:
- **Aether Virus** outbreak 23 days ago
- How infected humans **transform** but don't die
- The **five cure components** scattered across the facility
- Why **alliances are crucial** for survival
- The **temptation of betrayal** when resources are scarce
- The **historical warning** from the first team who failed
- The **final choice** between cooperation and competition

The narrative is designed to:
1. Create emotional investment in the story
2. Explain game mechanics narratively
3. Emphasize the alliance system
4. Acknowledge the betrayal mechanics
5. Make players think about trust and cooperation

## Success Criteria

The system is working correctly when:
1. ✅ Title screen appears on server start
2. ✅ Players can advance with any key press
3. ✅ Epilogue displays all 7 pages
4. ✅ Pages auto-advance after display time
5. ✅ ESC key skips epilogue (if enabled)
6. ✅ Click to continue works
7. ✅ Game transitions to normal flow after epilogue
8. ✅ Late joiners skip the intro
9. ✅ Multiple players wait for all to complete
10. ✅ All text is readable and impactful

## Feedback

When testing, pay attention to:
- Is the story compelling?
- Is the text readable?
- Are the timings good (not too fast/slow)?
- Does it make you want to form alliances?
- Does it explain the game well?
- Are the animations smooth?
- Does anything feel broken or awkward?

Report issues or suggestions for improvements!
