# JUAS2 NC Dipole — FEMM (Wine) + Lua + Python case studies

Batch workflow for running many H-dipole geometries in FEMM and exporting:
- `gap_By_scan.csv` (By and homogeneity along midline)
- `Bx_profile.txt` (tutorial-style transverse Bx profile, compatible with Mag_Plots.py style scripts)
- `multipoles.csv` (harmonic content from Br Fourier analysis)
- `monitor_points.csv` (field at selected points)

The default geometry is **identical (parameter-wise)** to the common JUAS/NCMagnets H-shape example:
`h=50 mm, w=151.29 mm, w_leg=75.26 mm, c_h=51 mm, c_w=75 mm, dx=4 mm`, plus shaping knobs
(`dent_pole_*`, `dl_*`).

## Prereqs
- FEMM 4.2 under Wine (default):
  `~/.wine/drive_c/femm42/bin/femm.exe`
- Python packages:
  `pandas matplotlib jupyter`

## Run a case study

### 1) Make scripts executable
```bash
chmod +x scripts/run_femm_case.sh scripts/run_all.sh
```

### 2) Generate cases
```bash
python3 tools/make_cases.py --make --n 10
```

By default cases are **quarter models** (`x>=0,y>=0`).
To run **half models** (x full, y>=0), edit `MODEL_FRACTION` in `tools/make_cases.py` (or in a case's `case_params.lua`).

To use the nonlinear laminated steel BH curve (M1200-100A):
- Set `USE_M1200 = 1` in `case_params.lua` (generated per-case)
- The curve file is stored at `materials/M1200-100A_45.dat`

### 3) Run all cases
```bash
./scripts/run_all.sh
```

If this fails, your FEMM build likely uses different CLI flags for executing Lua.
Run:
```bash
wine ~/.wine/drive_c/femm42/bin/femm.exe -h
```
and edit `scripts/run_femm_case.sh` accordingly.

Fallback:
- Open FEMM → File → Open Lua Script… → select `runs/case_0001/run_case.lua`.

### 4) Postprocess
```bash
jupyter lab
```
Open `postprocessing/gap_scan_postprocessing.ipynb`.

## Outputs per case
In `runs/case_XXXX/out/`:
- `model.fem`
- `gap_By_scan.csv`
- `Bx_profile.txt`
- `multipoles.csv`
- `monitor_points.csv`

See `TODO.md` for next steps (laminated steel, saturation metrics, energy/inductance/forces, etc.).
