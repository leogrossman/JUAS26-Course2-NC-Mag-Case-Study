# JUAS26 Course2 NC Dipole Case Study

Parametric **upper-half** 2D FEMM model for an H-type normal-conducting dipole, plus a small Python/Jupyter workflow to evaluate **By(x)** and **field homogeneity** ΔBy/By0 along the gap midline.

## Repository structure

- `femm/`
  - `JUAS2-NC-Mag-Dipole_report_parametric.lua` — FEMM Lua script (builds model, solves, exports `gap_By_scan.csv`)
- `postprocessing/`
  - `gap_scan_postprocessing.ipynb` — reads `gap_By_scan.csv`, plots field + homogeneity, computes quality metrics
- `data/` — place exported CSV files here (ignored by git except `.gitkeep`)
- `figures/` — saved plots (ignored by git except `.gitkeep`)

## Requirements

### FEMM
- FEMM installed (Windows) or FEMM under Wine.
- Materials in FEMM library: **Air**, **Copper**, **1010 Steel** (default in script).

### Python (post-processing)
- Python 3.10+ recommended
- `pandas`, `matplotlib`, `numpy`

Install (example):
```bash
pip install pandas matplotlib numpy
```

## Running the FEMM simulation (Lua script)

1. Open **FEMM**.
2. `File → Open Lua Script…`
3. Select: `femm/JUAS2-NC-Mag-Dipole_report_parametric.lua`
4. Run the script.
   - The script will:
     - create a new magnetics problem
     - build the geometry (upper-half, symmetry at y=0)
     - mesh + solve
     - export a scan file **`gap_By_scan.csv`** in FEMM's working directory

### Where does the CSV end up?
FEMM writes relative paths into its *current working directory*. To keep things tidy:
- Start FEMM with the repo folder as working directory **or**
- After the run, move `gap_By_scan.csv` into `data/`

## Running the post-processing notebook

1. Put your CSV at: `data/gap_By_scan.csv`
2. Open the notebook:
   - `postprocessing/gap_scan_postprocessing.ipynb`
3. Run all cells.
4. Plots are displayed and optionally saved to `figures/`.

## Notes on sign conventions
- The script drives the **left** coil with opposite current by setting a negative circuit current in `CoilL`.
- This follows the common H-magnet excitation convention; if you change coil orientation / block label turn sign, re-check the field direction.

## License
Add your preferred license (MIT/CC-BY/etc.) for the repo.
