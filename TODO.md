# TODO

This file collects **engineering + simulation + post-processing** tasks so the Lua stays readable.

## FEMM model / materials
- [ ] Replace `1010 Steel` with laminated electrical steel (e.g. **M1200-100A**):
  - [ ] Import or create BH curve in FEMM material library
  - [ ] Document provenance (datasheet / course material)
  - [ ] Decide on lamination modeling strategy (effective μ, stacking factor, etc.)
- [ ] Add a switch to export multiple scans (e.g. multiple y values, and also By at GFR boundary).
- [ ] Add optional pole-face shims / pole shaping parameters for field quality optimization.
- [ ] Add a parameter sweep mode (geometry cases) by iterating over parameter sets and writing one CSV per case.

## FEMM solution sanity checks (workflow)
(From the JUAS FEMM tutorial slides: check “physical reasonableness” and field quality.)
- [ ] Plot flux lines in FEMM post-processor and verify the topology is sensible (no weird leakage paths).
- [ ] Probe point values in the center and compare to expectation from analytical design.
- [ ] Analyse coil terminal properties (current, voltage, losses, etc.) in FEMM.
- [ ] Probe B-field in the yoke and check for saturation / high-B hot spots.
- [ ] (Optional) Plot field vectors as an additional sanity check.

## Field quality evaluation (post-processing)
(Also from the JUAS FEMM tutorial: field quality evaluation requires ΔB/B0 and should cover the operation range and GFR boundary.)

- [ ] Confirm the homogeneity definition used is consistent:
      ΔB/B0 = By(x,y)/By(0,0) - 1   (or use By at x=0 on the scan line).
- [ ] Compute and report:
  - [ ] max |ΔBy/By0| in the Good Field Region (GFR)
  - [ ] RMS(ΔBy/By0) in the GFR
  - [ ] “flat-top” width where |ΔBy/By0| < spec
- [ ] Evaluate field quality not only on midplane but also at **GFR boundary** (y = ±y_GFR, or in 2D: at the relevant edges).
- [ ] Evaluate field quality across the **full operation range** (Bmin..Bmax):
  - [ ] Run multiple excitation points (current scaling) and plot homogeneity vs. current
  - [ ] Track onset of saturation in steel vs. current

## Extra analysis (nice-to-have)
- [ ] Polynomial fit of By(x) in the GFR and extract multipole errors (normal components):
  - [ ] Fit By(x) ≈ B0 * (1 + b2 x^2 + b4 x^4 + ...)
  - [ ] Provide coefficients and compare between cases
- [ ] Integrated field:
  - [ ] (If a longitudinal model is available) compute ∫B·dl
  - [ ] In 2D-only, document assumptions (depth, end effects neglected)
- [ ] Automated report figures:
  - [ ] Export publication-ready PNG/PDF for By(x) and ΔBy/By0
  - [ ] Save derived metrics into a CSV/JSON summary for the design report

References: JUAS 2026 "Case study: FEMM tutorial" slides.
