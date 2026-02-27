-- auto-generated: case_params.lua

units    = "millimeters"
depth_mm = 100.0

I_amp   = 420
N_turns = 24

MAT_AIR   = "Air"
MAT_CU    = "Copper"
MAT_STEEL = "1010 Steel"

-- Geometry / model options
GEOM_MODE = "H_SHAPE"
MODEL_FRACTION = "quarter"  -- "quarter" or "half"

-- Nonlinear steel option (M1200-100A)
USE_M1200 = 0
BH_DAT_PATH = "../../materials/M1200-100A_45.dat"
STEEL_LAM_FILL = 0.98

-- Mesh settings
mesh_air_far = 25
mesh_steel   = 10
mesh_air_win = 8
mesh_cu      = 3
mesh_gap     = 1.5

USE_A0_OUTER = 1

-- H-shape geometry (identical to tutorial repo)
h_ap_mm   = 50.0
w_pole_mm = 151.29
w_leg_mm  = 75.26
c_h_mm    = 51.0
c_w_mm    = 75.0
dx_mm     = 4.25

dent_pole_h = 0.3
dent_pole_w = 0.2
dl_int      = 0.25
dl_ext      = 0.5

-- Airbox
x_air = 350.0
y_air = 250.0

-- Output
out_dir = "out"
csv_gap_scan   = out_dir .. "/gap_By_scan.csv"
csv_multipoles = out_dir .. "/multipoles.csv"
txt_Bx_profile = out_dir .. "/Bx_profile.txt"
csv_monitors   = out_dir .. "/monitor_points.csv"

-- Gap scan
scan_y    = 0.001
scan_xmin = 0.0
scan_xmax = 75.645
scan_N    = 401

-- Bx profile
bx_scan_y    = 0.0
bx_scan_xmin = 0.0
bx_scan_xmax = 60.0
bx_scan_N    = 401

-- Multipoles
multipoles_case_index = 2
multipoles_nh = 15
multipoles_np = 200
multipoles_Rs_mm = 20.0

-- Monitor points
monitor_points = {
    {"gap_center", 0.0, 0.001},
    {"yoke_hotspot", 192.52499999999998, 90.255}
}
