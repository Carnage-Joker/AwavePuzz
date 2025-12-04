# Custom Instructions

## Prompt Requirements
- Refactor the Roblox project into a polished first-person shooter comparable in feel to modern titles (e.g., Call of Duty).
- Convert the experience to a true first-person camera: head-locked view, optional viewmodel arms/weapon, configurable FOV and mouse sensitivity/smoothing, and hidden mouse cursor during gameplay.
- Build a robust FPS character controller: WASD, jump, crouch, sprint (with stamina/cooldown), smooth transitions between movement states, ADS vs. hip-fire, with optional slide/vault/mantle and limited air control.
- Implement modular weapon handling: per-weapon data (damage, fire rate, mag size, reload time, recoil/spread, ADS FOV, fire modes), server-authoritative damage/ammo/hit validation, recoil and spread differences for hip-fire/ADS, reload flow and cancelation, and optional semi/burst/auto modes.
- Add first-person viewmodel and animations: idle/walk/run/sprint, firing/recoil, reload, equip/unequip (and optional inspect), ensuring first-person-friendly placement and minimal clipping.
- Design controller-friendly menus (main and pause) without free cursor: keyboard/controller navigation with clear selection states.
- Build an FPS HUD: crosshair (with optional spread feedback), ammo counter, health indicator, weapon name/fire mode, hitmarkers (with headshot feedback), and optional minimap/radar/killfeed, scaling well on different resolutions.
- Ensure robust combat/networking: server-side authoritative damage with raycast/fast-cast, hit validation with head/body multipliers, replication for gunfire/tracers/impacts, death/respawn flow, round syncing for multiplayer.
- Audio and feel polish: per-weapon firing/reload sounds, footsteps, hitmarker and damage/low-HP feedback; add camera punch/shake and low-HP vignette.
- Add a settings menu: mouse sensitivity, invert Y, volume sliders, FOV slider (bounded), optional graphics presets; provide clear feedback and smooth respawn transitions.
- Maintain clean code structure: separate client visuals from server logic, use RemoteEvents/Functions appropriately, refactor to modules, add comments/docstrings for weapon additions, recoil tuning, HUD, and controls; avoid breaking compatible content.
- Provide guidance for required manual assets (animations, rigs, sounds) and how to integrate them.

## Stages of Development
1. Convert camera to a fully scriptable first-person view (head-locked, cursor hidden) and establish configurable sensitivity/FOV.
2. Refine movement: integrate sprint/crouch/ADS transitions via ContextActionService and prepare for viewmodel sway.
3. Modularize weapons: per-weapon data for fire modes, recoil/spread, ADS FOV; add server validation for head/body multipliers.
4. Add first-person viewmodels/animations and swap world model visibility accordingly.
5. Build controller-friendly menus and HUD (crosshair, ammo, health, hitmarkers) with selection navigation.
6. Polish networking/audio: tracers, impact effects, hitmarkers, footsteps, low-HP feedback, and respawn flow.
