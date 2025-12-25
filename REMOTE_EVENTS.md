# RemoteEvents Documentation

This document catalogues all RemoteEvents used in AwavePuzz, organized by domain.

## Combat / Weapons

### WeaponFire
**Direction:** Client → Server  
**Service:** WeaponService  
**Payload:** `{ weaponId: string, origin: Vector3, direction: Vector3, timestamp: number }`  
**Purpose:** Client requests to fire weapon, server validates and performs raycast

### WeaponEquip
**Direction:** Client → Server  
**Service:** WeaponService  
**Payload:** `weaponId: string`  
**Purpose:** Client requests to equip a weapon, server validates ownership

### WeaponHitConfirm
**Direction:** Server → Client  
**Service:** WeaponService  
**Payload:** `{ position: Vector3, target: string }`  
**Purpose:** Server confirms hit on target, client plays hitmarker/effects

### WeaponReload
**Direction:** Client → Server  
**Service:** FPSWeaponService  
**Payload:** `{ weaponId: string }`  
**Purpose:** Client requests reload, server validates and initiates reload

### AmmoUpdate
**Direction:** Server → Client  
**Service:** FPSWeaponService  
**Payload:** `{ weaponId: string, current: number, reserve: number, max: number }`  
**Purpose:** Server sends authoritative ammo counts to client for UI updates

## Animation Replication

### AnimationFire
**Direction:** Client → Server  
**Service:** FPSAnimationService  
**Payload:** `weaponId: string`  
**Purpose:** Client notifies server of fire animation for replication to other clients

### AnimationSprint
**Direction:** Client → Server  
**Service:** FPSAnimationService  
**Payload:** `isSprinting: boolean`  
**Purpose:** Client notifies server of sprint state change

### AnimationADS
**Direction:** Client → Server  
**Service:** FPSAnimationService  
**Payload:** `isADS: boolean`  
**Purpose:** Client notifies server of ADS state change

### AnimationFireReplicate
**Direction:** Server → Clients  
**Service:** FPSAnimationService  
**Payload:** `{ player: Player, weaponId: string }`  
**Purpose:** Server replicates fire animation to all other clients

### AnimationSprintReplicate
**Direction:** Server → Clients  
**Service:** FPSAnimationService  
**Payload:** `{ player: Player, isSprinting: boolean }`  
**Purpose:** Server replicates sprint state to all other clients

### AnimationADSReplicate
**Direction:** Server → Clients  
**Service:** FPSAnimationService  
**Payload:** `{ player: Player, isADS: boolean }`  
**Purpose:** Server replicates ADS state to all other clients

## Movement / Sprint

### SprintRequest
**Direction:** Client → Server  
**Service:** SprintService  
**Payload:** `isSprintKeyHeld: boolean`  
**Purpose:** Client requests to toggle sprint, server validates stamina

### StaminaUpdate
**Direction:** Server → Client  
**Service:** SprintService  
**Payload:** `{ current: number, max: number, isSprinting: boolean }`  
**Purpose:** Server sends authoritative stamina values to client

## Player Management

### InventoryUpdate
**Direction:** Server → Client  
**Service:** PlayerManager  
**Payload:** `{ inventory: table, slots: number }`  
**Purpose:** Server sends player inventory state

### CurrencyUpdate
**Direction:** Server → Client  
**Service:** PlayerManager  
**Payload:** `{ balance: number }`  
**Purpose:** Server sends player currency balance

### WeaponLoadoutUpdate
**Direction:** Server → Client  
**Service:** PlayerManager  
**Payload:** `{ weapons: table, equipped: string, stats: table }`  
**Purpose:** Server sends player weapon loadout

### PlayerHealthUpdate
**Direction:** Server → Client  
**Service:** PlayerManager  
**Payload:** `{ health: number, maxHealth: number }`  
**Purpose:** Server sends player health for UI updates

## Game State / Waves

### WaveAnnounce
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ wave: number, zombieCount: number, specialTypes: table }`  
**Purpose:** Server announces new wave starting

### WaveUpdate
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ wave: number, zombiesRemaining: number, waveComplete: boolean }`  
**Purpose:** Server sends wave progress updates

### GameStateUpdate
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ state: string, wave: number, baseHealth: number, cureProgress: number }`  
**Purpose:** Server broadcasts overall game state

### BaseHealthUpdate
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ health: number, maxHealth: number, damage: number }`  
**Purpose:** Server sends base health updates

### CureUpdate
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ progress: number, components: table }`  
**Purpose:** Server broadcasts cure progress

### MapUpdate
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ mapName: string, mapData: table }`  
**Purpose:** Server sends current map information

## UI / Display

### ScoreboardUpdate
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ players: table, stats: table }`  
**Purpose:** Server sends scoreboard data

### ShowScoreboard
**Direction:** Server → Clients  
**Service:** GameManager  
**Purpose:** Server commands clients to show scoreboard

### HideScoreboard
**Direction:** Server → Clients  
**Service:** GameManager  
**Purpose:** Server commands clients to hide scoreboard

### ShowTitleScreen
**Direction:** Server → Clients  
**Service:** GameManager  
**Purpose:** Server commands clients to show title screen

### HideTitleScreen
**Direction:** Server → Clients  
**Service:** GameManager  
**Purpose:** Server commands clients to hide title screen

### TitleScreenContinue
**Direction:** Client → Server  
**Service:** GameManager  
**Payload:** `{ ready: boolean }`  
**Purpose:** Client indicates ready to continue from title screen

### ShowEpilogue
**Direction:** Server → Clients  
**Service:** GameManager  
**Payload:** `{ victory: boolean, stats: table, narrative: table }`  
**Purpose:** Server commands clients to show end-game epilogue

### HideEpilogue
**Direction:** Server → Clients  
**Service:** GameManager  
**Purpose:** Server commands clients to hide epilogue

### EpilogueComplete
**Direction:** Client → Server  
**Service:** GameManager  
**Purpose:** Client indicates epilogue viewing complete

## Shop / Economy

### ShopRequest
**Direction:** Client → Server  
**Service:** ShopService  
**Payload:** `{ action: string, itemId: string, slotIndex: number }`  
**Purpose:** Client requests shop action (buy, sell, upgrade)

### ShopUpdate
**Direction:** Server → Client  
**Service:** ShopService  
**Payload:** `{ inventory: table, balance: number, shopItems: table }`  
**Purpose:** Server sends updated shop state after transaction

## Alliance System

### RequestAlliance
**Direction:** Client → Server  
**Service:** AllianceService  
**Payload:** `{ targetPlayer: Player }`  
**Purpose:** Client requests alliance with another player

### RespondAlliance
**Direction:** Client → Server  
**Service:** AllianceService  
**Payload:** `{ requester: Player, accepted: boolean }`  
**Purpose:** Client responds to alliance request

### BreakAlliance
**Direction:** Client → Server  
**Service:** AllianceService  
**Payload:** `{ targetPlayer: Player }`  
**Purpose:** Client requests to break alliance (betrayal)

### AllianceUpdate
**Direction:** Server → Clients  
**Service:** AllianceService  
**Payload:** `{ player1: Player, player2: Player, allied: boolean }`  
**Purpose:** Server broadcasts alliance state changes

## Puzzle / Cure System

### RequestPuzzle
**Direction:** Client → Server  
**Service:** PuzzleService  
**Payload:** `{ componentType: string, difficulty: number }`  
**Purpose:** Client requests a puzzle for a cure component

### SubmitPuzzleAnswer
**Direction:** Client → Server  
**Service:** PuzzleService  
**Payload:** `{ puzzleId: string, answer: any }`  
**Purpose:** Client submits puzzle answer for validation

### PuzzleUpdate
**Direction:** Server → Client  
**Service:** PuzzleService  
**Payload:** `{ puzzleId: string, timeRemaining: number, hintsUsed: number }`  
**Purpose:** Server sends puzzle progress updates

### PuzzleFailed
**Direction:** Server → Client  
**Service:** PuzzleService  
**Payload:** `{ puzzleId: string, reason: string }`  
**Purpose:** Server notifies client of puzzle failure

### PuzzleCompleted
**Direction:** Server → Client  
**Service:** PuzzleService  
**Payload:** `{ puzzleId: string, componentType: string, reward: table }`  
**Purpose:** Server notifies client of successful puzzle completion

### OpenPuzzleUI
**Direction:** Server → Client  
**Service:** PuzzleService  
**Payload:** `{ puzzleData: table }`  
**Purpose:** Server commands client to open puzzle UI with data

### RequestPuzzleProgress
**Direction:** Client → Server  
**Service:** PuzzleService  
**Purpose:** Client requests current puzzle progress

### PlayerCureProgressUpdate
**Direction:** Server → Client  
**Service:** CureService  
**Payload:** `{ player: Player, components: table, progress: number }`  
**Purpose:** Server sends individual player's cure progress

## Lobby / Map Voting

### MapVoteStart
**Direction:** Server → Clients  
**Service:** LobbyManager  
**Payload:** `{ maps: table, voteDuration: number }`  
**Purpose:** Server starts map voting phase

### MapVoteUpdate
**Direction:** Server → Clients  
**Service:** LobbyManager  
**Payload:** `{ votes: table, leading: string }`  
**Purpose:** Server broadcasts vote counts

### MapVoteEnd
**Direction:** Server → Clients  
**Service:** LobbyManager  
**Payload:** `{ winner: string, votes: table }`  
**Purpose:** Server announces vote results

### CastMapVote
**Direction:** Client → Server  
**Service:** LobbyManager  
**Payload:** `{ mapId: string }`  
**Purpose:** Client casts vote for a map

### LobbyStateUpdate
**Direction:** Server → Clients  
**Service:** LobbyManager  
**Payload:** `{ state: string, countdown: number, playerCount: number }`  
**Purpose:** Server broadcasts lobby state

## Spectator System

### EnterSpectatorMode
**Direction:** Client → Server  
**Service:** SpectatorManager  
**Purpose:** Client requests to enter spectator mode (after death)

### ExitSpectatorMode
**Direction:** Client → Server  
**Service:** SpectatorManager  
**Purpose:** Client requests to exit spectator mode (respawn)

### SpectatorTargetUpdate
**Direction:** Server → Client  
**Service:** SpectatorManager  
**Payload:** `{ target: Player, targetName: string, targetHealth: number }`  
**Purpose:** Server sends current spectator target info

### SpectatorCycleTarget
**Direction:** Client → Server  
**Service:** SpectatorManager  
**Payload:** `{ direction: string }` ("next" or "prev")  
**Purpose:** Client requests to cycle spectator target

### SpectatorStateUpdate
**Direction:** Server → Client  
**Service:** SpectatorManager  
**Payload:** `{ isSpectating: boolean, alivePlayers: number }`  
**Purpose:** Server updates spectator mode state

## Achievements

### AchievementUnlocked
**Direction:** Server → Client  
**Service:** AchievementService  
**Payload:** `{ achievementId: string, name: string, description: string, icon: string }`  
**Purpose:** Server notifies client of achievement unlock

---

## RemoteEvent Naming Conventions

All RemoteEvents follow these conventions:

1. **PascalCase naming** - e.g., `WeaponFire`, `SprintRequest`
2. **Descriptive names** - Clearly indicate purpose
3. **Direction suffix** (optional):
   - `Request` - Client → Server requests
   - `Update` - Server → Client updates
   - No suffix - Can be either direction or action

## Security Considerations

1. **Server authority** - All game logic decisions made server-side
2. **Client validation** - Server validates all client requests
3. **Rate limiting** - Server implements cooldowns where appropriate
4. **Ownership checks** - Server verifies player ownership before actions
5. **Alliance checks** - Server validates alliance state before actions

## Adding New RemoteEvents

When adding new RemoteEvents:

1. Use `RemoteEventUtil.getOrCreateEvents()` in server services
2. Document the event in this file
3. Include: Direction, Service, Payload structure, Purpose
4. Implement server-side validation
5. Handle edge cases (disconnection, timing issues)
