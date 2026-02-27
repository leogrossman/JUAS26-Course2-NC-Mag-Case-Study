-- auto-generated: case_params.lua
units    = "millimeters"
depth_mm = 100.0

I_amp   = 521.33
N_turns = 24

MAT_AIR   = "Air"
MAT_CU    = "Copper"
MAT_STEEL = "Cold rolled low carbon strip steel"  -- default; can be overridden by USE_M1200

-- Model / geometry options
GEOM_MODE = "H_SHAPE"              -- currently: H_SHAPE
MODEL_FRACTION = "quarter" -- "quarter" or "half"

-- Optional nonlinear steel from BH curve (M1200-100A)
USE_M1200 = 0
BH_DAT_PATH = "../../materials/M1200-100A_45.dat"
STEEL_LAM_FILL = 0.98

-- Mesh
mesh_air_far = 10
mesh_steel   = 2.0
mesh_cu      = 3.0
mesh_gap     = 2.0

USE_A0_OUTER = 1

-- H-shape geometry (match tutorial repo defaults)
h_ap_mm   = 50.0    -- full aperture height
w_pole_mm = 151.29  -- pole width
w_leg_mm  = 75.26   -- yoke/leg width
c_h_mm    = 51.0     -- conductor height
c_w_mm    = 75.0     -- conductor width
dx_mm     = 4.0      -- insulation margin

-- Shaping knobs (the "wedges")
dent_pole_h = 0.24444444444444446
dent_pole_w = 0.15555555555555556
dl_int      = 0.20555555555555555
dl_ext      = 0.41666666666666663

-- Airbox
x_air = 350.0
y_air = 250.0

-- Output
out_dir = "out"
csv_gap_scan   = out_dir .. "/gap_By_scan.csv"
txt_Bx_profile = out_dir .. "/Bx_profile.txt"
txt_B_2d       = out_dir .. "/B_2d.txt"
csv_multipoles = out_dir .. "/multipoles.csv"
csv_monitors   = out_dir .. "/monitor_points.csv"

-- Gap scan
scan_y    = 12.5
scan_xmin = 0.0
scan_xmax = 75.645
scan_N    = 401

-- Bx profile scan
bx_scan_y    = 0.0
bx_scan_xmin = 0.0
bx_scan_xmax = 60.0
bx_scan_N    = 401

-- Multipoles
multipoles_case_index = 2
multipoles_nh = 15
multipoles_np = 200
multipoles_Rs_mm = 20.0

-- Monitor points: { {"name", x_mm, y_mm}, ... }
monitor_points = {
    {"gap_center", 0.0, 12.5},
    {"yoke_hotspot", 192.27499999999998, 90.13}
}
