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
**Location**: `ServerScriptService/WeaponService.lua:194-210`, `ServerScriptService/FPSWeaponService.lua`

All weapon fire is validated server-side before damage is applied:
- Ammo consumption is server-authoritative via `FPSWeaponService`
- Players cannot fire while reloading
- Ammo must be available in reserve and magazine
- Client-side ammo display is updated after server validates
- **✅ NEW: Periodic Sync**: Every 30 seconds, server resends authoritative ammo values to clients
- **✅ NEW: Desync Detection**: Periodic ammo sync helps detect and correct client-side manipulation

**Periodic Ammo Synchronization** (Added 2026-02-02):
```lua
-- Security: Periodic ammo validation to detect client-side manipulation
-- Runs every 30 seconds to resend server-authoritative ammo to all clients
function FPSWeaponService:startAmmoValidationLoop()
    -- Syncs ammo for all players periodically
end
```

### Fire Rate Limiting
**Location**: `ServerScriptService/WeaponService.lua:189-192`

Fire rate is enforced server-side to prevent rapid-fire exploits:
- Server tracks last shot timestamp per player
- Shots faster than weapon's `FireRate` are rejected
- Prevents speedhacking and fire rate modifications

## Player Data Security

### Currency Management
**Location**: `ServerScriptService/PlayerManager.lua`, `ServerScriptService/GameManager.lua`

All currency transactions are server-controlled with rate limiting:
- Currency is stored server-side only
- Shop purchases validated before deduction
- Wave rewards granted by server only with duplicate protection
- **✅ NEW: Rate Limiting**: Wave rewards tracked to prevent multiple grants per wave
- **✅ NEW: Security Logging**: Duplicate wave completion attempts are logged as security warnings
- No client can modify currency values

**Wave Reward Protection** (Added 2026-02-02):
```lua
-- Security: Prevent multiple reward grants for the same wave (rate limiting)
if not self.waveRewardsGranted[self.currentWave] then
    self.waveRewardsGranted[self.currentWave] = true
    -- Grant rewards...
else
    warn("SECURITY: Duplicate wave completion detected")
end
```

### Health & Damage
**Location**: `ServerScriptService/WeaponService.lua`, `ServerScriptService/PlayerManager.lua`, `ServerScriptService/BaseManager.lua`

Health and damage are fully server-authoritative with source tracking:
- All damage calculations happen on server
- Client cannot modify player or zombie health
- Death detection uses server-side Humanoid.Died event
- Base damage is tracked and validated server-side
- **✅ NEW: Damage Logging**: All base damage events logged with source (zombie name)
- **✅ NEW: Audit Trail**: Damage sources tracked for security monitoring

**Base Damage Logging** (Added 2026-02-02):
```lua
-- Security: Log base damage events with source tracking
print(string.format("[BaseManager] DAMAGE: Base took %.1f damage from %s (Health: %.1f/%.1f)", 
    damage, sourceStr, self.health, self.maxHealth))
```

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

### ✅ Completed Security Improvements (2026-02-02)

1. **✅ Currency Rate Limiting**: Implemented duplicate wave reward prevention
   - **Status**: COMPLETE
   - **Implementation**: Wave reward tracking prevents multiple grants per wave
   - **Location**: `ServerScriptService/GameManager.lua:925-950`

2. **✅ Base Damage Logging**: Implemented source tracking for damage events
   - **Status**: COMPLETE
   - **Implementation**: All base damage logged with zombie name/source
   - **Location**: `ServerScriptService/BaseManager.lua:102-130`

3. **✅ Ammo Synchronization**: Implemented periodic server-client ammo sync
   - **Status**: COMPLETE
   - **Implementation**: 30-second periodic sync of ammo counts
   - **Location**: `ServerScriptService/FPSWeaponService.lua:400-430`

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
