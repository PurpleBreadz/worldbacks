#!/usr/bin/env bash
# GODOT=/path/to/godot bash tests/validate.sh
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT:-godot}"
validation_log=$(mktemp)
trap 'rm -f "$validation_log"' EXIT
run() {
  if "$godot_bin" "$@" >"$validation_log" 2>&1; then
    cat "$validation_log"
  else
    result=$?
    cat "$validation_log" >&2
    return "$result"
  fi
  if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL:|ObjectDB instances leaked' "$validation_log"; then
    return 1
  fi
}
run --headless --path . --editor --import
run --headless --fixed-fps 60 --path . --script res://tests/run_tests.gd
run --headless --fixed-fps 60 --path . --script res://tests/ui_tests.gd
run --headless --fixed-fps 60 --path . --script res://tests/traversal_tests.gd
run --headless --fixed-fps 60 --path . --script res://tests/combat_bot.gd
run --headless --path . --script res://tests/run_tests.gd -- --write-save
run --headless --path . --script res://tests/run_tests.gd -- --read-save
run --headless --path . --quit-after 120
printf 'WORLDBACK VALIDATION COMPLETE\n'
