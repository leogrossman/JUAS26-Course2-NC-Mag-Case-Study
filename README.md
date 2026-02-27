# JUAS2 NC Dipole – FEMM Automation

Automated FEMM-based simulation framework for the **JUAS 2026 Course – Normal Conducting Magnets project**.

This repository provides a parameter-driven workflow to design, simulate, and evaluate an H-type normal-conducting dipole magnet. It supports geometry sweeps, nonlinear steel studies, multipole extraction, and Good Field Region (GFR) evaluation in a reproducible way.

---

# Quick Start

Assuming Wine + FEMM are already installed and `FEMM_EXE` is configured:

### 1️⃣ Create Python environment

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2️⃣ Generate cases

```bash
python3 tools/make_cases.py --make --n 10
```

### 3️⃣ Run simulations

```bash
bash scripts/run_all.sh runs
```

### 4️⃣ Postprocess

```bash
bash scripts/postprocess.sh
```

Results will appear in:

```
runs/case_XXXX/out/
post/out/
```

If FEMM is not installed, see **Installation (Wine + FEMM)** below.

---

# Table of Contents

* [Overview](#overview)
* [Workflow](#workflow)
* [Geometry Model](#geometry-model)
* [Field Quality Evaluation (GFR)](#field-quality-evaluation-gfr)
* [Multipole Analysis](#multipole-analysis)
* [Repository Structure](#repository-structure)
* [Installation (Wine + FEMM)](#installation-wine--femm)
* [TODO – Active Development](#todo--active-development)
* [References](#references)

---

# Overview

This framework supports:

* Half and quarter symmetry models
* Linear and nonlinear (BH curve) steel
* Automated case generation
* Batch FEMM execution
* Gap field scans
* Multipole extraction
* Cross-design comparison plots

The goal is to provide a reproducible, script-driven design environment for the JUAS 2026 NC magnet project component. The structure is designed so that team members can easily:

* Add new geometry parameters
* Modify materials
* Add new postprocessing metrics
* Compare design variations

---

# Workflow

## 1. Generate Cases

```bash
python3 tools/make_cases.py --make --n 10
```

Creates parameterized case folders:

```
runs/case_XXXX/
```

Each case contains:

* `case_params.lua`
* `run_case.lua`

---

## 2. Run FEMM Batch Simulations

```bash
bash scripts/run_all.sh runs
```

Each case writes outputs to:

```
runs/case_XXXX/out/
```

---

## 3. Postprocess and Compare

```bash
bash scripts/postprocess.sh
```

Generates:

* Per-case plots
* Multipole summaries
* Global comparison plots
* `post/out/summary.csv`

---

# Geometry Model

Defined in:

```
femm/build_and_solve.lua
```

### Core Parameters

| Parameter          | Description            |
| ------------------ | ---------------------- |
| `h_ap_mm`          | Aperture height        |
| `w_pole_mm`        | Pole width             |
| `w_leg_mm`         | Yoke leg width         |
| `c_h_mm`, `c_w_mm` | Coil window dimensions |
| `dx_mm`            | Half-gap offset        |

### Wedge Parameters

* `dent_pole_h`
* `dent_pole_w`
* `dl_int`
* `dl_ext`

Half vs quarter model changes symmetry boundary conditions only.

---

# Field Quality Evaluation (GFR)

Field homogeneity is evaluated using the relative deviation:

$$
\frac{\Delta B(x)}{B_0} = \frac{B_y(x) - B_0}{B_0}
$$

where

$$
B_0 = B_y(0)
$$

The Good Field Region (GFR) requirement is:

$$
\left| \frac{\Delta B}{B_0} \right| < 10^{-3}
$$

across the required horizontal aperture width.

This metric is computed directly from `gap_By_scan.csv`.

---

# Multipole Analysis

Following accelerator magnet convention (Milanese, 2022, p. 81), the transverse dipole field is expanded as:

$$
B_y(x) = B_0 \left( 1 + \sum_{n=1}^{\infty} b_n \left(\frac{x}{R_{\text{ref}}}\right)^n \right)
$$

where:

- $b_n$ are the normal multipole coefficients  
- $R_{\text{ref}}$ is the reference radius  

Multipoles are extracted by:

1. Sampling the magnetic field on a circular arc  
2. Performing Fourier decomposition of $B_r(\theta)$  

Higher-order coefficients quantify deviations from the ideal dipole field.

Nonlinear steel increases higher-order components due to saturation effects.

---

# Repository Structure

```
JUAS2-NC-Dipole/
│
├── femm/                # FEMM Lua scripts
├── tools/               # Python case generator
├── scripts/             # Batch runners
├── materials/           # BH curves
├── runs/                # Generated simulation cases
├── post/                # Postprocessing tools
├── misc/
│   ├── femm_install/    # FEMM installer
│   └── references/      # Course material PDFs
└── docs/                # Case study documents
```

---

# Installation (Wine + FEMM)

If FEMM is not installed:

1. Install Wine (e.g. via Homebrew).
2. Run installer:

```
misc/femm_install/femm42bin_x64_21Apr2019.exe
```

3. Ensure `FEMM_EXE` points to:

```
~/.wine/drive_c/Program Files/FEMM42/bin/femm.exe
```

#### might need to add this:
```bash
export FEMM_EXE="$HOME/.wine/drive_c/Program Files/FEMM42/bin/femm.exe"
```

---

# TODO – Active Development

## Physics / Validation

* [ ] Verify GFR implementation
* [ ] Validate multipole normalization
* [ ] Cross-check multipole extraction vs literature
* [ ] Compare integrated vs central field definition
* [ ] Perform systematic saturation studies

## Geometry

* [ ] Refine mesh in air gap
* [ ] Implement true curved pole wedges (arc-based)
* [ ] Compare polyline vs arc pole tips

## Postprocessing

* [ ] Plot full 2D field maps per run
* [ ] Improve comparison visualization
* [ ] Add automatic report generation

---

# References

Milanese, A. (2022). *An Introduction to Magnets for Accelerators*. John Adams Institute Accelerator Course, Jan. 20, 2022. (See p. 81 for multipole formalism.)

Zickler, T. (2024). II.3 — Normal conducting magnets. In *Proceedings of the Joint Universities Accelerator School (JUAS) — Courses and exercises*. CERN Yellow Reports: School Proceedings. [https://doi.org/10.23730/CYRSP-2024-003.1001](https://doi.org/10.23730/CYRSP-2024-003.1001)

