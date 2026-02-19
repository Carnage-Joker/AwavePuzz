# AwavePuzz RemoteEvents - Complete List

**Generated**: 2026-02-19  
**Source**: `/ReplicatedStorage/Shared/Remotes/RemoteRegistry` (v1.0.0)  
**Total RemoteEvents**: 99

This document lists all **current, active RemoteEvents** used in AwavePuzz. Legacy/backward-compat remotes are included only in clearly labeled **Legacy API** sections.

---

## Animation System (6 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| AnimationFire | Client → Server | Player fires weapon animation trigger |
| AnimationSprint | Client → Server | Player sprint animation trigger |
| AnimationADS | Client → Server | Player aim down sights animation trigger |
| AnimationFireReplicate | Server → Clients | Replicate fire animation to other players |
| AnimationSprintReplicate | Server → Clients | Replicate sprint animation to other players |
| AnimationADSReplicate | Server → Clients | Replicate ADS animation to other players |

---

## Game State & Waves (4 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| WaveAnnounce | Server → Clients | Announces the start of a new wave |
| WaveUpdate | Server → Clients | Updates wave status (zombies remaining, time, etc.) |
| GameStateUpdate | Server → Clients | Updates overall game state (TitleScreen, Lobby, WaveActive, Victory, Defeat) |
| ClientReady | Client → Server | Client signals it's ready (reserved for future synchronization) |

---

## Cure System (3 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| CureUpdate | Server → Clients | Updates cure progress percentage |
| CureProgress | Server → Clients | Alternative cure progress update |
| PlayerCureProgressUpdate | Server → Clients | Updates individual player's cure component collection |

---

## Base & Map (2 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| BaseHealthUpdate | Server → Clients | Updates base health status |
| MapUpdate | Server → Clients | Sends map information to clients |

---

## UI State Management (11 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| ShowScoreboard | Server → Clients | Signals to display scoreboard |
| HideScoreboard | Server → Clients | Signals to hide scoreboard |
| ScoreboardUpdate | Server → Clients | Updates scoreboard data (player stats) |
| ShowTitleScreen | Server → Clients | Signals to show title screen |
| HideTitleScreen | Server → Clients | Signals to hide title screen |
| TitleScreenContinue | Client → Server | Player clicks continue on title screen |
| ShowEpilogue | Server → Clients | Signals to show epilogue/results screen |
| HideEpilogue | Server → Clients | Signals to hide epilogue screen |
| EpilogueComplete | Client → Server | Player completes epilogue interaction |
| ShowCredits | Server → Clients | Signals to show credits screen |
| HideCredits | Server → Clients | Signals to hide credits screen |

---

## Player Systems (11 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| AchievementUnlocked | Server → Clients | Notifies player of achievement unlock |
| BetrayalStarted | Server → Clients | Notifies betrayal event has started |
| SpectatorCycleTarget | Client → Server | Request to cycle spectator target |
| SpectatorStateUpdate | Server → Clients | Updates spectator state |
| SpectatorTargetUpdate | Server → Clients | Updates spectator camera target |
| SprintRequest | Client → Server | Player sprint request |
| PlayerHealthUpdate | Server → Clients | Updates player's health |
| StaminaUpdate | Server → Clients | Updates player's stamina |
| EnterSpectatorMode | Server → Clients | Player enters spectator mode |
| ExitSpectatorMode | Server → Clients | Player exits spectator mode |
| CrouchUpdate | Client → Server | Client movement crouch state updates |

---

## Matchmaking & Lobby (11 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| PortalQueueUpdate | Server → Clients | Updates portal queue information |
| LobbyVoteUpdate | Server → Clients | Updates lobby voting status |
| LobbyStateUpdate | Server → Clients | Updates lobby state (timer, player count) |
| MapVoteStart | Server → Clients | Voting has started, send map options |
| MapVoteUpdate | Server → Clients | Updates vote counts |
| MapVoteEnd | Server → Clients | Voting ended, show selected map |
| CastMapVote | Client → Server | Player casts a vote |
| MapVotingState | Server → Clients | Legacy map voting state (backward compatibility) |
| MapVoteCast | Client → Server | Legacy map voting cast (backward compatibility) |
| MapVotingUpdate | Server → Clients | Legacy map voting update (backward compatibility) |
| PortalQueueStatus | Server → Clients | Portal queue status update |

---

## Portal Matchmaking (3 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| PortalLeaveQueue | Client → Server | Player leaves portal queue |
| PortalQueueJoined | Server → Clients | Player joined portal queue notification |
| PortalQueueLeft | Server → Clients | Player left portal queue notification |

---

## Puzzle System (10 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| PuzzlePickup | Client → Server | Player picks up puzzle component |
| PuzzleSubmit | Client → Server | Player submits puzzle |
| ItemPickup | Client → Server | Player picks up item |
| PuzzleUpdate | Server → Clients | Sends puzzle state updates |
| PuzzleCompleted | Server → Clients | Notifies puzzle completion |
| PuzzleFailed | Server → Clients | Notifies puzzle failure |
| OpenPuzzleUI | Server → Clients | Tells client to open puzzle UI |
| RequestPuzzle | Client → Server | Player requests to start a puzzle |
| RequestPuzzleProgress | Client → Server | Requests puzzle progress data |
| SubmitPuzzleAnswer | Client → Server | Player submits puzzle solution |

---

## Cure Stations (1 RemoteEvent)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| OpenCureStationMenu | Client → Server | Client requests to open cure station menu |

---

## Weapons & Combat (8 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| WeaponFire | Client → Server | Player fires weapon |
| WeaponReload | Client → Server | Player reloads weapon |
| WeaponEquip | Client → Server | Player requests to equip weapon |
| WeaponHitConfirm | Server → Clients | Confirms hit on target for visual feedback |
| WeaponLoadoutUpdate | Server → Clients | Updates player's weapon loadout |
| DealDamage | Client → Server | Player deals damage (weapon hit) |
| AmmoUpdate | Server → Clients | Updates player's ammo count |
| ReloadConfirm | Server → Clients | Server confirmation for reload requests |

---

## Shop & Economy (7 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| ShopPurchase | Client → Server | Player purchases item from shop |
| ShopOpen | Client → Server | Player opens shop |
| ShopClose | Client → Server | Player closes shop |
| ShopRequest | Client → Server | Request shop action (purchase, view catalog) |
| ShopUpdate | Server → Clients | Updates shop catalog or purchase result |
| CurrencyUpdate | Server → Clients | Updates player's currency balance |
| InventoryUpdate | Server → Clients | Updates player's inventory |

---

## Alliance System - Modern API (5 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| AllianceRequest | Client → Server | Request alliance with another player |
| AllianceAccept | Server → Clients | Alliance request accepted |
| AllianceDecline | Server → Clients | Alliance request declined |
| AllianceDisband | Client → Server | Disband existing alliance |
| AllianceUpdate | Server → Clients | Updates alliance status |

---

## Alliance System - Legacy API (3 RemoteEvents)

**Note**: These are kept for backward compatibility only. New code should use the Modern API above.

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| RequestAlliance | Client → Server | Request alliance (legacy) |
| RespondAlliance | Client → Server | Respond to alliance request (legacy) |
| BreakAlliance | Client → Server | Break existing alliance (legacy) |

---

## Betrayal System (2 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| BetrayalOutcome | Server → Clients | Notifies betrayal outcome |
| BetrayalStatus | Server → Clients | Updates betrayal status |

---

## Fun Facts (4 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| FunFactUpdate | Server → Clients | Updates fun fact display |
| RequestFunFact | Client → Server | Requests a fun fact |
| ShowFunFact | Server → Clients | Show fun fact to player |
| UpdateFactStats | Server → Clients | Updates fun fact statistics |

---

## Voiceover System (2 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| PlayVoiceover | Server → Clients | Play voiceover audio |
| StopVoiceover | Server → Clients | Stop voiceover audio |

---

## Cure Synthesis System (5 RemoteEvents)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| StartSynthesis | Client → Server | Start cure synthesis process |
| SynthesisStateUpdate | Server → Clients | Updates synthesis state |
| SynthesisPuzzleComplete | Server → Clients | Synthesis puzzle completed |
| SynthesisComplete | Server → Clients | Cure synthesis complete |
| SynthesisFailed | Server → Clients | Cure synthesis failed |

---

## Notification System (1 RemoteEvent)

| RemoteEvent Name | Direction | Purpose |
|---|---|---|
| ShowNotification | Server → Clients | Display notification to player |

---

## Summary by Direction

### Client → Server (26 RemoteEvents)
Player input, requests, and actions sent to the server for validation and processing.

- Animation triggers: AnimationFire, AnimationSprint, AnimationADS
- Weapon actions: WeaponFire, WeaponReload, WeaponEquip, DealDamage
- Puzzle interactions: PuzzlePickup, PuzzleSubmit, ItemPickup, RequestPuzzle, RequestPuzzleProgress, SubmitPuzzleAnswer
- Shop: ShopPurchase, ShopOpen, ShopClose, ShopRequest
- Alliance: AllianceRequest, AllianceDisband, RequestAlliance, RespondAlliance, BreakAlliance
- Lobby: CastMapVote, MapVoteCast
- Player: SpectatorCycleTarget, SprintRequest
- UI: TitleScreenContinue, EpilogueComplete
- Portal: PortalLeaveQueue
- Synthesis: StartSynthesis
- Cure: OpenCureStationMenu
- Misc: RequestFunFact, ClientReady

### Server → Clients (82 RemoteEvents)
Game state updates, confirmations, and UI commands broadcast from server to clients.

- **Animation replication**: AnimationFireReplicate, AnimationSprintReplicate, AnimationADSReplicate
- **Game state**: WaveAnnounce, WaveUpdate, GameStateUpdate
- **Cure**: CureUpdate, CureProgress, PlayerCureProgressUpdate
- **Base/Map**: BaseHealthUpdate, MapUpdate
- **UI Management**: ShowScoreboard, HideScoreboard, ScoreboardUpdate, ShowTitleScreen, HideTitleScreen, ShowEpilogue, HideEpilogue, ShowCredits, HideCredits, ShowNotification
- **Player**: AchievementUnlocked, BetrayalStarted, SpectatorStateUpdate, SpectatorTargetUpdate, PlayerHealthUpdate, StaminaUpdate, EnterSpectatorMode, ExitSpectatorMode
- **Lobby/Matchmaking**: PortalQueueUpdate, LobbyVoteUpdate, LobbyStateUpdate, MapVoteStart, MapVoteUpdate, MapVoteEnd, MapVotingState, MapVotingUpdate, PortalQueueStatus, PortalQueueJoined, PortalQueueLeft
- **Puzzles**: PuzzleUpdate, PuzzleCompleted, PuzzleFailed, OpenPuzzleUI
- **Weapons**: WeaponHitConfirm, WeaponLoadoutUpdate, AmmoUpdate, ReloadConfirm
- **Shop**: ShopUpdate, CurrencyUpdate, InventoryUpdate
- **Alliance**: AllianceAccept, AllianceDecline, AllianceUpdate
- **Betrayal**: BetrayalOutcome, BetrayalStatus
- **Fun Facts**: FunFactUpdate, ShowFunFact, UpdateFactStats
- **Voiceover**: PlayVoiceover, StopVoiceover
- **Synthesis**: SynthesisStateUpdate, SynthesisPuzzleComplete, SynthesisComplete, SynthesisFailed

### Bidirectional (1 RemoteEvent)
Used for both client-to-server and server-to-client communication.

- CrouchUpdate

---

## Notes

1. **All RemoteEvents are type-checked** - The RemoteRegistry enforces proper RemoteEvent instances (vs RemoteFunction).

2. **No legacy remotes included** - Only active remotes from the current RemoteRegistry v1.0.0 are listed. Archives and .disabled files are excluded.

3. **Server-authoritative design** - All game logic is validated server-side. Client→Server remotes only send requests; the server makes final decisions.

4. **Direction notation**:
   - `Client → Server`: Client sends data/request to server
   - `Server → Clients`: Server broadcasts update to client(s)
   - `Client ↔ Server`: Bidirectional (rare)

5. **Legacy compatibility** - The three legacy alliance remotes (RequestAlliance, RespondAlliance, BreakAlliance) and three legacy map voting remotes (MapVotingState, MapVoteCast, MapVotingUpdate) are maintained for backward compatibility but new code should use the modern APIs.

---

## Related Documentation

- **Full API Reference**: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- **Remote Events Usage Guide**: [docs/REMOTE_EVENTS.md](docs/REMOTE_EVENTS.md)
- **Remote Audit Report**: [docs/REMOTE_AUDIT.md](docs/REMOTE_AUDIT.md)
- **RemoteRegistry Source**: [ReplicatedStorage/Shared/Remotes/RemoteRegistry](ReplicatedStorage/Shared/Remotes/RemoteRegistry)
