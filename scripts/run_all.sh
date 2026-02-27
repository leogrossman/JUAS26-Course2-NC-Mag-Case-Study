#!/usr/bin/env bash
set -euo pipefail

RUNS_DIR="${1:-runs}"

# Prefer user override. Otherwise try common Wine/FEMM locations.
if [[ -n "${FEMM_EXE:-}" ]]; then
  FEMM_EXE="$FEMM_EXE"
else
  CANDIDATES=(
    "$HOME/.wine/drive_c/femm42/bin/femm.exe"
    "$HOME/.wine/drive_c/Program Files/FEMM42/bin/femm.exe"
    "$HOME/.wine/drive_c/Program Files (x86)/FEMM42/bin/femm.exe"
  )

  FEMM_EXE=""
  for p in "${CANDIDATES[@]}"; do
    if [[ -f "$p" ]]; then
      FEMM_EXE="$p"
      break
    fi
  done
fi

if [[ -z "$FEMM_EXE" || ! -f "$FEMM_EXE" ]]; then
  echo "ERROR: Could not find FEMM executable."
  echo "Tried:"
  echo "  $HOME/.wine/drive_c/femm42/bin/femm.exe"
  echo "  $HOME/.wine/drive_c/Program Files/FEMM42/bin/femm.exe"
  echo "  $HOME/.wine/drive_c/Program Files (x86)/FEMM42/bin/femm.exe"
  echo
  echo "Fix: set FEMM_EXE explicitly, e.g."
  echo '  export FEMM_EXE="$HOME/.wine/drive_c/femm42/bin/femm.exe"'
  exit 1
fi

echo "Using FEMM_EXE: $FEMM_EXE"
echo "Running cases in: $RUNS_DIR"

for case_dir in "$RUNS_DIR"/*; do
  [[ -d "$case_dir" ]] || continue
  if [[ -f "$case_dir/run_case.lua" ]]; then
    echo "============================================================"
    echo "Case: $(basename "$case_dir")"
    (cd "$case_dir" && wine "$FEMM_EXE" -lua-script=run_case.lua)
  fi
done

echo "All done."