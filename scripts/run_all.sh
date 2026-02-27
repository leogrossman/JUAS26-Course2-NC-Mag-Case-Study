#!/usr/bin/env bash
set -euo pipefail

RUNS_DIR="${1:-runs}"

for c in "$RUNS_DIR"/case_*; do
  [[ -d "$c" ]] || continue
  ./scripts/run_femm_case.sh "$c"
done