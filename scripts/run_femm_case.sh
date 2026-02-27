#!/usr/bin/env bash
set -euo pipefail
CASE_DIR="${1:?Need case directory like runs/case_0001}"
FEMM_EXE="${FEMM_EXE:-$HOME/.wine/drive_c/femm42/bin/femm.exe}"

if [[ ! -f "$CASE_DIR/run_case.lua" ]]; then
  echo "ERROR: $CASE_DIR/run_case.lua not found"
  exit 2
fi

pushd "$CASE_DIR" >/dev/null

try_cmd () {
  local cmd="$1"
  echo "[run_femm_case] $cmd"
  set +e
  eval "$cmd"
  local status=$?
  set -e
  return $status
}

if try_cmd "wine \"$FEMM_EXE\" -lua-script=\"run_case.lua\""; then popd >/dev/null; exit 0; fi
if try_cmd "wine \"$FEMM_EXE\" -lua \"run_case.lua\""; then popd >/dev/null; exit 0; fi

echo "ERROR: FEMM did not accept -lua-script or -lua."
echo "Run: wine \"$FEMM_EXE\" -h  and update scripts/run_femm_case.sh."
echo "Fallback: FEMM GUI -> File -> Open Lua Script -> runs/case_0001/run_case.lua"
popd >/dev/null
exit 3
