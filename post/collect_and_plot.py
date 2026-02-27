#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

REPO_ROOT = Path(__file__).resolve().parents[1]
RUNS_DIR = REPO_ROOT / "runs"
OUT_DIR = REPO_ROOT / "post" / "out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

def load_case(case_dir: Path) -> dict:
    params = json.loads((case_dir / "params.json").read_text())
    out = case_dir / "out"
    data = {"case": case_dir.name, "params": params, "dir": case_dir}

    gap = out / "gap_By_scan.csv"
    if gap.exists():
        data["gap"] = pd.read_csv(gap)

    mp = out / "multipoles.csv"
    if mp.exists():
        data["multipoles"] = pd.read_csv(mp)

    bx = out / "Bx_profile.txt"
    if bx.exists():
        arr = np.loadtxt(bx)
        data["bx_profile"] = pd.DataFrame({"x_mm": arr[:,0], "Bx_T": arr[:,1]})

    mon = out / "monitor_points.csv"
    if mon.exists():
        data["monitors"] = pd.read_csv(mon)
    
    fieldd = out / "B_2d.txt"
    if fieldd.exists():
        arr = np.loadtxt(fieldd)
        data["field_2d"] = pd.DataFrame({"x_mm": arr[:,0], "y_mm": arr[:,1], "Bx_T": arr[:,2], "By_T": arr[:,3]})

    return data

def homogeneity_metric(gap_df: pd.DataFrame, x_good_mm: float = 40.0) -> float:
    # metric: max |dBmag/By0| over |x|<=x_good_mm
    df = gap_df.copy()
    df = df[np.abs(df["x_mm"]) <= x_good_mm]
    if len(df) == 0:
        return np.nan
    return float(np.max(np.abs(df["dBy_over_By0"])))

def plot_case(case: dict) -> dict:
    name = case["case"]
    out_case = OUT_DIR / name
    out_case.mkdir(exist_ok=True)

    metrics = {}
    gfr = 30.0
    s = 55.43

    if "gap" in case:
        df = case["gap"]
        metrics["homogeneity_max_abs_dByBy0_40mm"] = homogeneity_metric(df, 40.0)
        idx_1 = int(np.argmin(np.abs(df["x_mm"].values - gfr)))
        idx_2 = int(np.argmin(np.abs(df["x_mm"].values - (gfr+s/2))))
        
        plt.figure()
        plt.plot(df["x_mm"], df["By_T"], label="By")
        plt.axvline(x=gfr, color='r', linestyle='--', label='Good Field Region')
        plt.axvline(x=gfr+s/2, color='b', linestyle='--', label='Good Field Region+sagitta')
        y_val_1 = float(df["By_T"].iloc[idx_1])
        y_val_2 = float(df["By_T"].iloc[idx_2])
        if y_val_1 > 0:
            plt.text(gfr, y_val_1, f'{y_val_1:.2e}', color='r', ha='right')
        if y_val_2 > 0:
            plt.text(gfr+s/2, y_val_2, f'{y_val_2:.2e}', color='b', ha='right')
        plt.xlabel("x [mm]")
        plt.ylabel("By [T]")
        plt.legend()
        plt.title(f"{name}: By along gap scan")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "gap_By.png", dpi=160)
        plt.close()
        
        
        plt.figure()
        plt.plot(df["x_mm"], df["Bmag_T"], label="|B|") 
        plt.axvline(x=gfr, color='r', linestyle='--', label='Good Field Region')
        plt.axvline(x=gfr+s/2, color='b', linestyle='--', label='Good Field Region+sagitta')
        y_val_1 = float(df["Bmag_T"].iloc[idx_1])
        y_val_2 = float(df["Bmag_T"].iloc[idx_2])
        if y_val_1 > 0:
            plt.text(gfr, y_val_1, f'{y_val_1:.2e}', color='r', ha='right')
        if y_val_2 > 0:
            plt.text(gfr+s/2, y_val_2, f'{y_val_2:.2e}', color='b', ha='right')
        plt.xlabel("x [mm]")
        plt.ylabel("|B| [T]")
        plt.legend()
        plt.title(f"{name}: |B| along gap scan")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "gap_Bmag.png", dpi=160)
        plt.close()
        
        By_o_By0 = np.abs((df["By_T"]-df["By_T"][0])/df["By_T"][0])  # assuming By0 is the first point (x=0)

        plt.figure()
        plt.plot(df["x_mm"], np.log10(By_o_By0), label="|dBy/By0|")
        plt.axvline(x=gfr, color='r', linestyle='--', label='Good Field Region') 
        plt.axvline(x=gfr+s/2, color='b', linestyle='--', label='Good Field Region+sagitta')
        y_val_1 = float(By_o_By0.iloc[idx_1])
        y_val_2 = float(By_o_By0.iloc[idx_2])
        if y_val_1 > 0:
            plt.text(gfr, np.log10(y_val_1), f'{np.log10(y_val_1):.2e}', color='r', ha='right')
        if y_val_2 > 0:
            plt.text(gfr+s/2, np.log10(y_val_2), f'{np.log10(y_val_2):.2e}', color='b', ha='right')
        plt.xlabel("x [mm]")
        plt.ylabel(r"$\log_{10}(|dBy/By0|)$")
        plt.legend()
        plt.title(f"{name}: field homogeneity (dBy/By0)")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "gap_homogeneity_dBy_over_By0.png", dpi=160)
        plt.close()
        
        B_oB0 = np.abs((df["Bmag_T"]-df["Bmag_T"][0])/df["Bmag_T"][0])  # assuming By0 is the first point (x=0)
        
        plt.figure()
        plt.plot(df["x_mm"], np.log10(B_oB0), label="|dB/B0|")
        plt.axvline(x=gfr, color='r', linestyle='--', label='Good Field Region') 
        plt.axvline(x=gfr+s/2, color='b', linestyle='--', label='Good Field Region+sagitta')
        y_val_1 = float(B_oB0.iloc[idx_1])
        y_val_2 = float(B_oB0.iloc[idx_2])
        if y_val_1 > 0:
            plt.text(gfr, np.log10(y_val_1), f'{np.log10(y_val_1):.2e}', color='r', ha='right')
        if y_val_2 > 0:
            plt.text(gfr+s/2, np.log10(y_val_2), f'{np.log10(y_val_2):.2e}', color='b', ha='right')
        plt.xlabel("x [mm]")
        plt.ylabel(r"$\log_{10}(|dB/B0|)$")
        plt.title(f"{name}: field homogeneity (dB/B0)")
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "gap_homogeneity.png", dpi=160)
        plt.close()
        
        ##2dPlot of Bmag
        X = case["field_2d"]["x_mm"].values
        Y = case["field_2d"]["y_mm"].values
        Z = case["field_2d"]["Bx_T"].values**2 + case["field_2d"]["By_T"].values**2
        Z = np.sqrt(Z)
        plt.figure()
        plt.tricontourf(X, Y, Z, levels=50, cmap='rainbow')
        #put the maximum in the colormap
        plt.clim(0, np.max(Z))
        plt.colorbar(label='|B| [T]')
        plt.xlabel('x [mm]')
        plt.ylabel('y [mm]')
        plt.title(f'{name}: 2D field magnitude')
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "field_2d_Bmag.png", dpi=160)
        plt.close()
        

    if "multipoles" in case:
        mp = case["multipoles"]
        plt.figure()
        plt.semilogy(mp["n"], mp["rel_to_n1"])
        plt.xlabel("n")
        plt.ylabel("relative amplitude (to n=1)")
        plt.title(f"{name}: multipoles (Br Fourier)")
        plt.grid(True, which="both", alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "multipoles.png", dpi=160)
        plt.close()

    if "bx_profile" in case:
        bx = case["bx_profile"]
        plt.figure()
        plt.plot(bx["x_mm"], bx["Bx_T"])
        plt.xlabel("x [mm]")
        plt.ylabel("Bx [T]")
        plt.title(f"{name}: Bx profile (y=0)")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(out_case / "Bx_profile.png", dpi=160)
        plt.close()

    return metrics

def main():
    cases = []
    for p in sorted(RUNS_DIR.glob("case_*")):
        if (p/"params.json").exists():
            cases.append(load_case(p))

    if not cases:
        raise SystemExit(f"No cases found in {RUNS_DIR}. Run: python3 tools/make_cases.py --make --run")

    rows = []
    for c in cases:
        metrics = plot_case(c)
        params = c["params"]
        row = {
            "case": c["case"],
            "MODEL_FRACTION": params.get("MODEL_FRACTION"),
            "I_amp": params.get("I_amp"),
            "dent_pole_h": params.get("dent_pole_h"),
            "dent_pole_w": params.get("dent_pole_w"),
            "dl_int": params.get("dl_int"),
            "dl_ext": params.get("dl_ext"),
            **metrics,
        }
        rows.append(row)

    summary = pd.DataFrame(rows).sort_values(by="case")
    summary_path = OUT_DIR / "summary.csv"
    summary.to_csv(summary_path, index=False)
    print(f"Wrote {summary_path}")

    # Comparison plot: homogeneity vs dent parameters
    if "homogeneity_max_abs_dByBy0_40mm" in summary.columns:
        plt.figure()
        plt.plot(summary["dent_pole_h"], summary["homogeneity_max_abs_dByBy0_40mm"], marker="o", linestyle="None")
        plt.xlabel("dent_pole_h")
        plt.ylabel("max |dBy/By0| (|x|<=40mm)")
        plt.title("Homogeneity vs dent_pole_h")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(OUT_DIR / "compare_homogeneity_vs_dent_pole_h.png", dpi=180)
        plt.close()

        plt.figure()
        plt.plot(summary["dent_pole_w"], summary["homogeneity_max_abs_dByBy0_40mm"], marker="o", linestyle="None")
        plt.xlabel("dent_pole_w")
        plt.ylabel("max |dBy/By0| (|x|<=40mm)")
        plt.title("Homogeneity vs dent_pole_w")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(OUT_DIR / "compare_homogeneity_vs_dent_pole_w.png", dpi=180)
        plt.close()

    print("Postprocessing done. See post/out/")

if __name__ == "__main__":
    main()
