# Changelog

## 0.1.0 — Playable prototype — 2026-10-22

Initialized the empty repository as a Godot 4.6.3 GDScript game with a complete connected prototype route.

- Main menu, New/Continue, pause/save, persistent audio settings, inventory, discovered map and HUD.
- Responsive movement, variable jumps, coyote time, buffering, dodge, sword combos, stamina, block/deflection, posture, healing, death and Waystone respawn.
- Resource-driven Scavenger, Wolf, Sentinel and two-phase Bell Warden, with readable tells and persistent boss rewards.
- Five handcrafted Rootwild areas and a separate Mossback settlement; optional tower reward, hidden cache, lore, checkpoint network and permanent shortcut.
- Boss-gated Vale, Mossback awakening, three persistent prefab building slots, storage and discovered migration route between Vale and Fallen Caravan.
- Versioned JSON saves with input validation, atomic replacement and valid-backup recovery. Item, weapon and enemy metadata use Resources.
- Original geometric pixel-style scenery, parallax, actor animations, particles and synthesized audio; no external assets or runtime packages.
- Reusable native test suites and documented architecture, design constraints and roadmap.

All automated validation passed; exact counts and limits are recorded in `TESTING.md`. The compact prototype still needs human playtesting, balance, audio audition and Windows/macOS export verification. Playtime has not been measured against the 15–30 minute target.
