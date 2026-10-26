# Working on WORLDBACK

WORLDBACK is an original side-scrolling dark fantasy action RPG. Use Godot 4.6.3 standard edition and typed GDScript. Read `README.md`, `docs/ARCHITECTURE.md`, and the relevant existing implementation before changing systems.

## Design rules

- Keep principal levels handcrafted. Reusable props and decorative patterns are welcome; do not generate random terrain or replace intentional routes with procedural worlds.
- Preserve fixed terrain and limit construction to designated zones or slots.
- Make combat readable and responsive. Keep attack startup, active frames, recovery, stamina costs, defensive windows, and posture behavior explicit.
- Preserve progression across sessions: bosses, shortcuts, one-time discoveries, awakened Worldbearers, migration state, and structures.
- Represent a Worldbearer's exterior and settlement separately. Migration uses discrete stops and transitions; do not carry a complete settlement through an enormous moving physics simulation.
- Reward optional exploration with meaningful equipment, lore, routes, or resources.
- Use original or properly licensed assets. No copied game characters, music, or sprites. Document attribution for any future third-party asset.
- Finish and validate the connected gameplay path before expanding into later milestones.

## Code and architecture

- Use existing scene components, signals, resource definitions, and `Game` APIs. Avoid new autoloads unless their lifetime truly spans the game.
- Keep permanent state in the versioned save schema; keep AI timers, collision, particles, and menu state transient. UI and effects must never decide authoritative damage or progression.
- Use Input Map action names rather than checking raw keys in gameplay code.
- Prefer typed values and explicit casts at dictionary/JSON boundaries. Do not rely on inferred types from untyped dictionaries.
- Keep weapon/enemy tuning in Resources. Add new content through data and reusable scenes when possible.
- Use named, stable IDs for one-time pickups, checkpoints, bosses, and permanent gates. Changing IDs requires considering old saves.
- Save schema changes require a version increment or a deliberate compatible migration. Handle missing, malformed, and unsupported saves gracefully.
- Keep modules focused. Split presentation, combat behavior, world layout, and persistence when a change would make one script difficult to review.
- Use `res://` for project resources and `user://` for saves/settings. Never commit a personal save or generated `.godot` cache.
- Preserve compatible user changes. Use the existing checkout; cloud tasks are already isolated. Do not create Git worktrees unless explicitly requested.

## Validation expectations

Run the project import, relevant native tests, and a bounded headless startup after gameplay changes. Exact commands and acceptance checks live in `docs/TESTING.md`.

Godot can print script/runtime errors while returning status zero. Preserve command exit statuses **and inspect output** for `SCRIPT ERROR`, parse errors, missing resources, and engine errors. A zero-test run is not a passing suite. Check that expected assertions and completion markers executed.

Tests must use an isolated save path and must not overwrite player progress. Exercise failure paths as well as success, especially corrupted saves, insufficient resources, locked routes, and repeated one-time rewards. For save changes, include persistence across separate processes.

Headless tests establish logic and loading behavior, not graphical quality, sound quality, input latency, balance, or a human-completable run. State exactly which checks ran and what remains untested. Keep documentation aligned with actual behavior and avoid declaring Milestone 1 complete solely because its systems exist.

## Scope

This is ongoing game development, not only environment onboarding. Implement requested source changes and tests. Prefer the installed Godot toolchain and native GDScript tests; avoid introducing dependencies or test frameworks without a concrete need.
