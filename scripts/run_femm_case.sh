#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/run_femm_case.sh runs/case_0001
CASE_DIR="${1:?need case dir}"
FEMM_EXE="${FEMM_EXE:-$HOME/.wine/drive_c/femm42/bin/femm.exe}"

# We run FEMM from inside the case dir so relative paths work.
cd "$CASE_DIR"

echo "[run_femm_case] case dir: $CASE_DIR"
echo "[run_femm_case] FEMM: $FEMM_EXE"

# Option A (common): femm.exe can execute a lua script at startup.
# The exact flag can vary by FEMM build; if this doesn't work, we fall back below.
set +e
wine "$FEMM_EXE" -lua-script="run_case.lua"
STATUS=$?
set -e

if [[ $STATUS -ne 0 ]]; then
  echo "[run_femm_case] -lua-script failed (status=$STATUS)."
  echo "[run_femm_case] Fallback: open FEMM and let run_case.lua be executed manually, or adapt flags."
  exit $STATUS
fi

echo "[run_femm_case] done."