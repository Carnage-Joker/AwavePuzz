# Security Measures - AwavePuzz

This document outlines the security measures implemented in the game to prevent exploits and ensure fair gameplay.

## Server-Authoritative Design

The game follows a **server-authoritative** architecture where all critical game logic and state changes are validated and executed on the server. Clients send input requests which the server validates before applying changes.

## Weapon & Combat Security

### Anti-Wallhack Protection
**Location**: `ServerScriptService/WeaponService.lua:184-196`

The server validates weapon fire origin positions to prevent players from shooting through walls:
- Maximum fire distance: **15 studs** from player's HumanoidRootPart (configurable via `GameConfig.Security.MAX_WEAPON_FIRE_DISTANCE`)
- Rejected shots are logged with player name and distance
- Prevents exploiters from spoofing fire position to shoot through geometry

```lua
-- Validate origin is near player (max 15 studs)
local distanceFromPlayer = (origin - humanoidRootPart.Position).Magnitude
if distanceFromPlayer > MAX_FIRE_DISTANCE then
    warn("[WeaponService] SECURITY: Rejected shot from " .. player.Name)
    return
end
```

### Ammo Validation
**Location**: `ServerScriptService/WeaponService.lua:194-210`

All weapon fire is validated server-side before damage is applied:
- Ammo consumption is server-authoritative via `FPSWeaponService`
- Players cannot fire while reloading
- Ammo must be available in reserve and magazine
- Client-side ammo display is updated after server validates

### Fire Rate Limiting
**Location**: `ServerScriptService/WeaponService.lua:189-192`

Fire rate is enforced server-side to prevent rapid-fire exploits:
- Server tracks last shot timestamp per player
- Shots faster than weapon's `FireRate` are rejected
- Prevents speedhacking and fire rate modifications

## Player Data Security

### Currency Management
**Location**: `ServerScriptService/PlayerManager.lua`

All currency transactions are server-controlled:
- Currency is stored server-side only
- Shop purchases validated before deduction
- Wave rewards granted by server only
- No client can modify currency values

### Health & Damage
**Location**: `ServerScriptService/WeaponService.lua`, `ServerScriptService/PlayerManager.lua`

Health and damage are fully server-authoritative:
- All damage calculations happen on server
- Client cannot modify player or zombie health
- Death detection uses server-side Humanoid.Died event
- Base damage is tracked and validated server-side

## Alliance System Security

### Betrayal Validation
**Location**: `ServerScriptService/AllianceServiceV2.lua`

Betrayal mechanics are server-controlled to prevent resource duplication:
- Alliance state tracked server-side
- Resource transfers validated and locked during betrayal window
- Cooldowns enforced to prevent rapid betrayal cycling
- Friendly fire is controlled via server-side alliance graph

## Performance & Anti-Exploit

### Connection Cleanup
Memory leaks are prevented through proper connection lifecycle management:
- Death event connections disconnected on player removal
- Item pickup connections cleaned up when items despawn
- Heartbeat connections tracked for potential shutdown cleanup

### Rate Limiting
**Location**: Multiple services

Various systems implement rate limiting:
- Spectator camera cycling: 1-second cooldown
- Map loading: 1-second debounce to prevent race conditions
- Weapon fire: Per-weapon fire rate enforcement
- Shop purchases: Cooldown between transactions

### Input Validation

All client payloads are validated:
```lua
-- Type checking
if typeof(payload) ~= "table" then return end
if typeof(origin) ~= "Vector3" then return end

-- Range checking  
if direction.Magnitude < 0.001 then return end

-- Ownership checking
if not self.playerManager:ownsWeapon(player, weaponId) then return end
```

## Known Limitations

### Areas for Future Improvement

1. **Currency Rate Limiting**: Currently no rate limit on wave completion rewards
   - **Risk**: Low (wave progression controlled by server)
   - **Recommendation**: Add cooldown between wave completions

2. **Base Damage Logging**: Base damage events not logged with source tracking
   - **Risk**: Low (damage is server-authoritative)
   - **Recommendation**: Add audit log for base damage events

3. **Ammo Synchronization**: Client and server ammo counts can desync temporarily
   - **Risk**: Low (server is authoritative)
   - **Recommendation**: Add periodic sync check

## Security Best Practices

When adding new features:

1. ✅ **Never trust client data** - Always validate on server
2. ✅ **Validate input types** - Check typeof() for all client payloads
3. ✅ **Check ownership** - Ensure player owns resources they're modifying
4. ✅ **Enforce cooldowns** - Prevent rapid-fire exploits
5. ✅ **Log suspicious activity** - Warn on validation failures
6. ✅ **Clean up connections** - Disconnect events on player removal

## Security Testing Checklist

Before production deployment:

- [ ] Test weapon fire with modified client position
- [ ] Test currency modification attempts
- [ ] Test ammo depletion and reload timing
- [ ] Test rapid fire rate exploits
- [ ] Test alliance betrayal edge cases
- [ ] Test base damage from various sources
- [ ] Test memory usage over extended play
- [ ] Test with malicious client modifications

## Reporting Security Issues

Security vulnerabilities should be reported privately to avoid exploitation:
- Create a private security advisory on GitHub
- Email: [Repository owner's contact]
- Do NOT create public issues for security vulnerabilities

---

**Last Updated**: 2026-01-15
**Security Review Version**: 1.0
