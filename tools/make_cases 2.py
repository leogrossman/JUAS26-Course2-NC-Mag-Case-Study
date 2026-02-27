#!/usr/bin/env python3
from __future__ import annotations
import argparse
import json
import subprocess
from dataclasses import dataclass, asdict
from pathlib import Path
from string import Template

REPO_ROOT = Path(__file__).resolve().parents[1]
RUNS_DIR = REPO_ROOT / "runs"

# ============================================================
# Lua case_params template (safe Template-based)
# ============================================================

CASE_PARAMS_TEMPLATE = Template(r'''-- auto-generated: case_params.lua

units    = "millimeters"
depth_mm = $depth_mm

I_amp   = $I_amp
N_turns = $N_turns

MAT_AIR   = "Air"
MAT_CU    = "Copper"
MAT_STEEL = "1010 Steel"

-- Geometry / model options
GEOM_MODE = "H_SHAPE"
MODEL_FRACTION = "$MODEL_FRACTION"  -- "quarter" or "half"

-- Nonlinear steel option (M1200-100A)
USE_M1200 = $USE_M1200
BH_DAT_PATH = "$BH_DAT_PATH"
STEEL_LAM_FILL = $STEEL_LAM_FILL

-- Mesh settings
mesh_air_far = $mesh_air_far
mesh_steel   = $mesh_steel
mesh_air_win = $mesh_air_win
mesh_cu      = $mesh_cu
mesh_gap     = $mesh_gap

USE_A0_OUTER = $USE_A0_OUTER

-- H-shape geometry (identical to tutorial repo)
h_ap_mm   = $h_ap_mm
w_pole_mm = $w_pole_mm
w_leg_mm  = $w_leg_mm
c_h_mm    = $c_h_mm
c_w_mm    = $c_w_mm
dx_mm     = $dx_mm

dent_pole_h = $dent_pole_h
dent_pole_w = $dent_pole_w
dl_int      = $dl_int
dl_ext      = $dl_ext

-- Airbox
x_air = $x_air
y_air = $y_air

-- Output
out_dir = "$out_dir"
csv_gap_scan   = out_dir .. "/gap_By_scan.csv"
csv_multipoles = out_dir .. "/multipoles.csv"
txt_Bx_profile = out_dir .. "/Bx_profile.txt"
csv_monitors   = out_dir .. "/monitor_points.csv"

-- Gap scan
scan_y    = $scan_y
scan_xmin = $scan_xmin
scan_xmax = $scan_xmax
scan_N    = $scan_N

-- Bx profile
bx_scan_y    = $bx_scan_y
bx_scan_xmin = $bx_scan_xmin
bx_scan_xmax = $bx_scan_xmax
bx_scan_N    = $bx_scan_N

-- Multipoles
multipoles_case_index = 2
multipoles_nh = $multipoles_nh
multipoles_np = $multipoles_np
multipoles_Rs_mm = $multipoles_Rs_mm

-- Monitor points
monitor_points = {
    {"gap_center", 0.0, $scan_y},
    {"yoke_hotspot", $yoke_hotspot_x, $yoke_hotspot_y}
}
''')

RUN_CASE_LUA = 'dofile("case_params.lua")\ndofile("../../femm/build_and_solve.lua")\n'

# ============================================================
# Case definition
# ============================================================

@dataclass
class Case:
    name: str

    # Excitation
    I_amp: float = 521.33
    N_turns: int = 24
    depth_mm: float = 100.0

    # Model selection
    MODEL_FRACTION: str = "quarter"  # "quarter" or "half"
    USE_M1200: int = 0
    STEEL_LAM_FILL: float = 0.98

    # H-shape geometry (identical to tutorial defaults)
    h_ap_mm: float = 50.0
    w_pole_mm: float = 151.29
    w_leg_mm: float = 75.26
    c_h_mm: float = 51.0
    c_w_mm: float = 75.0
    dx_mm: float = 4.0

    dent_pole_h: float = 0.30
    dent_pole_w: float = 0.20
    dl_int: float = 0.25
    dl_ext: float = 0.50

    # Airbox
    x_air: float = 350.0
    y_air: float = 250.0

    # Mesh
    mesh_air_far: float = 25
    mesh_steel: float = 10
    mesh_air_win: float = 8
    mesh_cu: float = 3
    mesh_gap: float = 1.5

    USE_A0_OUTER: int = 1

    # Scans
    scan_N: int = 401
    bx_scan_N: int = 401

    multipoles_nh: int = 15
    multipoles_np: int = 200
    multipoles_Rs_mm: float = 20.0

    def to_params(self, out_dir: str) -> dict:

        # Gap scan along midplane (avoid exact symmetry plane)
        scan_y = 0.001

        # Quarter vs half model x-range
        if self.MODEL_FRACTION == "quarter":
            scan_xmin = 0.0
            scan_xmax = self.w_pole_mm / 2
        else:
            scan_xmin = -self.w_pole_mm / 2
            scan_xmax = self.w_pole_mm / 2

        bx_scan_y = 0.0
        bx_scan_xmin = 0.0
        bx_scan_xmax = 60.0

        return {
            **asdict(self),
            "out_dir": out_dir,
            "scan_y": scan_y,
            "scan_xmin": scan_xmin,
            "scan_xmax": scan_xmax,
            "bx_scan_y": bx_scan_y,
            "bx_scan_xmin": bx_scan_xmin,
            "bx_scan_xmax": bx_scan_xmax,
            "BH_DAT_PATH": "../../materials/M1200-100A_45.dat",
            "yoke_hotspot_x": (
                self.w_pole_mm/2 + self.c_w_mm + self.dx_mm + self.w_leg_mm*0.5
            ),
            "yoke_hotspot_y": (
                self.h_ap_mm/2 + (self.c_h_mm + self.dx_mm + self.w_leg_mm)*0.5
            ),
        }

# ============================================================
# Case writer
# ============================================================

def write_case(case_dir: Path, case: Case) -> None:
    out_dir = "out"
    (case_dir/out_dir).mkdir(parents=True, exist_ok=True)

    params = case.to_params(out_dir)

    (case_dir/"case_params.lua").write_text(
        CASE_PARAMS_TEMPLATE.substitute(params)
    )

    (case_dir/"run_case.lua").write_text(RUN_CASE_LUA)
    (case_dir/"params.json").write_text(json.dumps(params, indent=2))

# ============================================================
# Main
# ============================================================

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--make", action="store_true")
    ap.add_argument("--run", action="store_true")
    ap.add_argument("--n", type=int, default=5)
    args = ap.parse_args()

    cases = []

    for i in range(args.n):
        c = Case(name=f"case_{i+1:04d}")

        # Example sweep: vary current and insulation gap
        c.I_amp = 400 + 20*i
        c.dx_mm = 4.0 + 0.25*i

        cases.append(c)

    if args.make:
        RUNS_DIR.mkdir(exist_ok=True)
        for c in cases:
            write_case(RUNS_DIR/c.name, c)
        print(f"Wrote {len(cases)} cases to {RUNS_DIR}")

    if args.run:
        subprocess.run(
            ["bash", str(REPO_ROOT/"scripts/run_all.sh"), str(RUNS_DIR)],
            check=True
        )

if __name__ == "__main__":
    main()