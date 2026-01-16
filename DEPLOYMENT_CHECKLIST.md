# Deployment Checklist - AwavePuzz

This checklist ensures the game is production-ready before deployment to Roblox.

## Pre-Deployment Configuration

### 1. Debug Settings
- [ ] Set `GameConfig.DEBUG = false` in `ReplicatedStorage/Shared/GameConfig.lua`
- [ ] Set `GameConfig.DEBUG_SPAWNS = false` 
- [ ] Set `GameConfig.AI.DEBUG_MODE = false`
- [ ] Remove or disable any test print statements in critical loops

### 2. Game Balance
- [ ] Review and adjust `GameConfig.STARTING_CURRENCY` (current: 150)
- [ ] Review and adjust `GameConfig.BASE_HEALTH` (current: 1000)
- [ ] Review zombie spawn rates and health multipliers
- [ ] Test wave progression difficulty curve
- [ ] Verify weapon damage balance

### 3. Player Limits
- [ ] Set appropriate `GameConfig.MAX_PLAYERS` for server capacity
- [ ] Test with maximum player count
- [ ] Verify performance with 8 concurrent players
- [ ] Check memory usage over 30+ minute play sessions

### 4. Content Replacement
- [ ] Replace all placeholder .txt files in `ReplicatedStorage/Animations/` with actual animations
- [ ] Replace placeholder zombie models in `ServerStorage/ZombieModels/`
- [ ] Replace placeholder weapon models in `ServerStorage/Models/`
- [ ] Replace placeholder map models in `ServerStorage/Maps/`
- [ ] Verify all asset IDs are valid and published

## Security Verification

### 1. Server Authority
- [ ] Verify all damage calculations happen server-side
- [ ] Verify currency changes are server-authoritative
- [ ] Verify ammo consumption is validated server-side
- [ ] Test weapon fire origin validation (max 15 studs from player)

### 2. Input Validation
- [ ] All RemoteEvent handlers check payload types
- [ ] All RemoteEvent handlers validate ownership
- [ ] All RemoteEvent handlers enforce rate limits
- [ ] No client data is trusted without validation

### 3. Memory & Performance
- [ ] Death event connections are cleaned up on player removal
- [ ] Item/resource pickup connections are disconnected properly
- [ ] No memory leaks detected in 1+ hour play sessions
- [ ] Heartbeat loop usage is optimized

## Functional Testing

### 1. Core Gameplay
- [ ] Players can join and spawn correctly
- [ ] Weapons fire and deal damage to zombies
- [ ] Zombies spawn and attack players/base
- [ ] Wave progression works correctly
- [ ] Base health decreases when attacked

### 2. Cure System
- [ ] Resources spawn around the map
- [ ] Players can collect resources
- [ ] Inventory tracking works correctly
- [ ] Cure progress updates properly
- [ ] Victory condition triggers at 100% cure progress

### 3. Alliance System
- [ ] Players can form alliances
- [ ] Friendly fire prevention works
- [ ] Betrayal mechanics function correctly
- [ ] Resource pooling works as expected
- [ ] Alliance UI updates properly

### 4. Shop & Economy
- [ ] Shop opens and displays items correctly
- [ ] Purchases deduct currency properly
- [ ] Weapon unlocks persist
- [ ] Upgrade chips apply correctly
- [ ] Currency rewards granted on wave completion

### 5. Multiplayer
- [ ] Map voting works with 2+ players
- [ ] Lobby countdown functions correctly
- [ ] All players spawn on map after voting
- [ ] Spectator mode works when players die
- [ ] Round end displays scoreboard correctly

### 6. UI Systems
- [ ] Title screen displays and can be skipped
- [ ] Epilogue/intro cinematic plays correctly
- [ ] Victory credits display properly
- [ ] All HUD elements scale for mobile devices
- [ ] Achievement notifications display correctly

## Performance Testing

### 1. Server Performance
- [ ] Server maintains <50ms average frame time with 8 players
- [ ] No server script timeout errors
- [ ] Memory usage stays below 1GB over 1 hour
- [ ] No infinite loops or runaway processes

### 2. Client Performance
- [ ] Client maintains 60 FPS on average PC (1080p)
- [ ] Client maintains 30 FPS on mobile devices
- [ ] UI is responsive and doesn't lag
- [ ] No visual glitches or rendering issues

### 3. Network Performance
- [ ] RemoteEvent bandwidth is reasonable (<100 KB/s per player)
- [ ] No excessive RemoteEvent spam
- [ ] Latency compensation works for weapon fire
- [ ] No desync issues between clients and server

## Edge Case Testing

### 1. Player Lifecycle
- [ ] Test player joining mid-wave
- [ ] Test player leaving during wave
- [ ] Test all players leaving and rejoining
- [ ] Test rapid player join/leave cycles

### 2. Resource Edge Cases
- [ ] Test collecting all resources at once
- [ ] Test resource spawning at max capacity
- [ ] Test resource cleanup on round end
- [ ] Test resource collection by dead players (should fail)

### 3. Combat Edge Cases
- [ ] Test shooting with no ammo
- [ ] Test reloading while firing
- [ ] Test weapon switching during reload
- [ ] Test killing zombie with multiple players simultaneously

### 4. Alliance Edge Cases
- [ ] Test betraying during combat
- [ ] Test alliance member disconnect
- [ ] Test rapid alliance formation/breaking
- [ ] Test alliance with all players

## Final Checks

### 1. Documentation
- [ ] README.md is up to date
- [ ] INSTALLATION.md reflects current structure
- [ ] SECURITY.md documents all security measures
- [ ] API_DOCUMENTATION.md is accurate
- [ ] All code comments are accurate and helpful

### 2. Version Control
- [ ] All changes are committed
- [ ] Commit messages are clear and descriptive
- [ ] No debug/test commits in history
- [ ] Git repository is clean (no untracked files)

### 3. Roblox Studio Setup
- [ ] All scripts are in correct locations
- [ ] All RemoteEvents are created properly
- [ ] Workspace is properly configured
- [ ] Spawn points are placed
- [ ] Base is positioned correctly

### 4. Publishing
- [ ] Game icon is uploaded
- [ ] Game thumbnail is uploaded
- [ ] Game description is compelling
- [ ] Genre and tags are set correctly
- [ ] Max players is set appropriately
- [ ] Server fill is configured

## Post-Deployment Monitoring

### Week 1
- [ ] Monitor error logs daily
- [ ] Track player retention metrics
- [ ] Collect gameplay feedback
- [ ] Monitor server performance
- [ ] Check for exploit attempts

### Month 1
- [ ] Analyze balance data
- [ ] Review most-used weapons
- [ ] Analyze wave completion rates
- [ ] Review alliance usage statistics
- [ ] Identify common failure points

## Rollback Plan

If critical issues are discovered:

1. **Immediate**: Set game to private in Roblox
2. **Notify**: Post announcement about maintenance
3. **Diagnose**: Review error logs and player reports
4. **Fix**: Apply hotfix to production branch
5. **Test**: Verify fix in private test server
6. **Deploy**: Re-publish with fix
7. **Monitor**: Watch for recurrence

---

## Sign-Off

Before publishing, confirm the following:

- [ ] Technical Lead has approved codebase
- [ ] QA has completed all tests
- [ ] Security review is complete
- [ ] All critical bugs are fixed
- [ ] Performance meets targets
- [ ] Documentation is complete

**Deployment Date**: _______________
**Deployed By**: _______________
**Version**: _______________

---

**Last Updated**: 2026-01-15
**Checklist Version**: 1.0
