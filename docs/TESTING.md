# Validation

Run from the repository root with Godot **4.6.3 standard edition**. No external test framework is needed.

```sh
# Prepared Codex environment:
export PATH=/workspace/.worldback-tools/bin:$PATH
cd /workspace/worldbacks
# Bash on Linux/macOS; GODOT can point to another executable:
bash tests/validate.sh
```

The validation script preserves command exit statuses and rejects Godot error diagnostics even when the engine exits zero. It runs project import, native integration/UI/traversal/combat suites, separate-process save restoration, and a bounded normal startup. Test data uses separate filenames; normal campaign saves are untouched. Audio preference tests restore the prior settings.

Equivalent individual commands:

```sh
godot --headless --path . --editor --import
godot --headless --fixed-fps 60 --path . --script res://tests/run_tests.gd
godot --headless --fixed-fps 60 --path . --script res://tests/ui_tests.gd
godot --headless --fixed-fps 60 --path . --script res://tests/traversal_tests.gd
godot --headless --fixed-fps 60 --path . --script res://tests/combat_bot.gd
godot --headless --path . --script res://tests/run_tests.gd -- --write-save
godot --headless --path . --script res://tests/run_tests.gd -- --read-save
godot --headless --path . --quit-after 120
```

Import and scene-loading tests validate scripts in their project/autoload context. Standalone `--check-only --script` on an actor can fail to resolve `Game`, so it is not the authoritative project check. Pure scripts that do not depend on autoload globals can still use `--check-only`.

## Recorded results — 2026-10-22

Godot `4.6.3.stable.official.7d41c59c4`, Linux x86_64. `tests/validate.sh` completed with exit **0**, no script/engine errors or object-leak warnings.

| Check | Result | Scope |
| --- | --- | --- |
| Project editor import | Passed | Scripts, Resources and scene references |
| `run_tests.gd` | **113 passed, 0 failed** | Save schema/error recovery; campaign operations; combat; instantiated Main/UI/World; movement; actual world interactions; death/respawn; boss reward; settlement and Continue |
| `ui_tests.gd` | **53 passed, 0 failed** | Actual button signals; menu/pause/inventory/map/settings; save/continue; building/storage; HUD dimensions |
| `traversal_tests.gd` | **18 passed, 0 failed** | Six worlds, initial grounded state, eleven consecutive watchtower jumps using Input Map and real player physics |
| `combat_bot.gd` | Passed | Input-only Scavenger and Bell Warden fights; no direct damage or stat restoration |
| Separate save writer | **1 passed** | Writes full progression to isolated file |
| Fresh-process save reader | **9 passed** | Restores position/resources/inventory/flags/checkpoints/Worldbearer/buildings/cargo |
| Bounded main-scene launch | Passed | Normal main menu startup |
| Graphical UI suite | **61 passed, 0 failed** | 53 UI checks plus eight actual screenshots under Xvfb/llvmpipe |

The combat bot reads enemy tells and times inputs precisely. It defeated the Scavenger in 104 physics frames and the Bell Warden in 804 frames (13.4 simulated seconds), reached boss phase two, and finished with 71 health and all three flasks. This demonstrates that the encounter is mechanically beatable with starting equipment; it does **not** establish human difficulty.

The traversal test removes enemies to isolate platform geometry and movement. The campaign integration suite positions actors directly for some interactions and applies direct damage for state assertions. Together these tests validate the systems and connected scene transitions, **not** a complete unaided human playthrough.

Graphical screenshots were inspected at the 640×360 logical resolution for title, caravan, pause, settings, inventory, map, building, and storage. The inspection caught and fixed HUD minimum-size overlap. A software-renderer V-Sync warning is expected under Xvfb; no script errors or object leaks were present. To repeat screenshot checks on a desktop display:

```sh
godot --path . --script res://tests/ui_tests.gd -- --visual
```

PNG files are written as `user://ui-*.png`. Xvfb is a temporary test tool outside the project, not a runtime dependency. Headless/Dummy audio output skips playback; actual sound quality has not been auditioned.

## Remaining manual acceptance

- Complete the entire route with a keyboard and no developer intervention. Check prompts, game feel, camera limits, jumps during encounters, and all transitions.
- Fight all archetypes and both boss phases; tune spacing, tells, recovery, deflection, stamina, and healing against real players.
- Awaken Mossback, discover the route tablet farther right in the Vale, build, use storage, migrate, disembark, and reboard. Repeat after saving and restarting the application graphically.
- Check audio levels and presentation at different desktop resolutions and integer scales.
- Measure playtime; the 15–30 minute goal is unverified and this build is a compact prototype.
- Build and verify Windows/macOS exports and complete controller navigation. No packaged desktop binaries are included.
