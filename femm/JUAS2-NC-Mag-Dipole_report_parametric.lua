-- JUAS2-NC-Mag-Dipole_report_parametric.lua
-- Upper-half H-magnet: y >= 0, symmetry at y=0 (Neumann natural).
-- Report-aligned dimensions (see README/TODO for traceability).
-- Coil windows are OPEN to y=0 so the yoke does NOT wrap under the coils.
-- Central beam gap is modeled as a separate aperture (configurable).
-- Opposite current in left coil.
-- Exports CSV scan across the central gap midline.

-- ============================================================
-- USER PARAMETERS (case-study knobs)
-- ============================================================

-- Units / model
units    = "millimeters"
depth_mm = 100.0

-- Excitation (report)
I_amp   = 521.33
N_turns = 24

-- Materials (use 1010 Steel for now; laminated steel is a TODO in TODO.md)
MAT_AIR   = "Air"
MAT_CU    = "Copper"
MAT_STEEL = "1010 Steel"

-- Mesh controls (mm)
mesh_air_far = 25
mesh_steel   = 10
mesh_air_win = 8
mesh_cu      = 3
mesh_gap     = 1.5

-- Outer air padding (mm)
pad_x = 250.0
pad_y = 250.0

-- Outer boundary condition A=0 on top/side of airbox (NOT on symmetry line y=0)
USE_A0_OUTER = 1

-- Geometry modeling switch:
-- 1: central aperture is a distinct air region (recommended: matches "aperture near x=0")
-- 0: connect bottom air (central + windows) into one region under one "roof" segment
SEPARATE_CENTRAL_APERTURE = 1

-- ============================================================
-- GEOMETRY (report sketch aligned defaults)
-- ============================================================

-- Outer yoke boundary (steel) [report sketch]
x_yoke = 226.72
y_yoke = 195.12

-- Central beam gap aperture (air)
gap_half_height = 25.0

-- IMPORTANT:
-- Ensure the aperture does not overlap the window inner wall at x_win_L.
-- Default ties gap_half_width to x_win_L to guarantee non-overlap.
gap_half_width  = 77.6

-- Coil windows (air holes), OPEN to y=0
x_win_L   = 77.6
x_win_R   = 131.1
y_win_bot = 0.0
y_win_top = 99.5

-- Copper base (right) - rectangle inside window before clearance
x_cu_L_base = 79.6
x_cu_R_base = 129.1

-- Clearance (mm) between copper and window
gap_x = 2.0
gap_y = 5.0

-- Derived copper bounds
x_cu_L = x_cu_L_base + gap_x
x_cu_R = x_cu_R_base - gap_x
y_cu_B = y_win_bot + gap_y
y_cu_T = y_win_top - gap_y

-- Outer airbox extents
x_air = x_yoke + pad_x
y_air = y_yoke + pad_y

-- ============================================================
-- SCAN SETUP (gap scan CSV)
-- ============================================================
scan_y    = gap_half_height * 0.5
scan_xmin = -gap_half_width
scan_xmax =  gap_half_width
scan_N    = 401
csv_name  = "gap_By_scan.csv"

-- ============================================================
-- Helper functions
-- ============================================================
function add_rect(x1, y1, x2, y2, open_bottom)
    -- Adds rectangle boundary segments.
    -- If open_bottom==1, does NOT add segment from (x1,y1)->(x2,y1).
    mi_addnode(x1, y1) mi_addnode(x2, y1) mi_addnode(x2, y2) mi_addnode(x1, y2)
    if open_bottom ~= 1 then
        mi_addsegment(x1, y1, x2, y1)
    end
    mi_addsegment(x2, y1, x2, y2)
    mi_addsegment(x2, y2, x1, y2)
    mi_addsegment(x1, y2, x1, y1)
end

function set_A0_on_segment_at(x, y)
    mi_selectsegment(x, y)
    mi_setsegmentprop("A0", 0, 1, 0, 0)
    mi_clearselected()
end

-- ============================================================
-- New model
-- ============================================================
newdocument(0)
mi_probdef(0, units, "planar", 1e-8, depth_mm, 30)

mi_getmaterial(MAT_AIR)
mi_getmaterial(MAT_CU)
mi_getmaterial(MAT_STEEL)

mi_addcircprop("CoilR",  I_amp, 1)
mi_addcircprop("CoilL", -I_amp, 1)

-- ============================================================
-- Outer airbox boundary (y>=0); bottom y=0: symmetry -> natural Neumann (no BC)
-- ============================================================
add_rect(-x_air, 0, x_air, y_air, 0)

if USE_A0_OUTER == 1 then
    mi_addboundprop("A0", 0,0,0,0,0,0,0,0,0)
    -- Apply A0 only to TOP and SIDES, not to y=0
    set_A0_on_segment_at( x_air, y_air/2)
    set_A0_on_segment_at( 0,    y_air)
    set_A0_on_segment_at(-x_air, y_air/2)
end

-- ============================================================
-- Yoke outer boundary (steel)
-- ============================================================
add_rect(-x_yoke, 0, x_yoke, y_yoke, 0)

-- ============================================================
-- Coil window holes (air) OPEN to y=0 so no steel under coils
-- Right window: x in [x_win_L..x_win_R], y in [0..y_win_top]
-- ============================================================

-- Right window nodes
mi_addnode( x_win_L, y_win_bot)
mi_addnode( x_win_R, y_win_bot)
mi_addnode( x_win_R, y_win_top)
mi_addnode( x_win_L, y_win_top)

-- Window OPEN at y=0: do NOT add bottom segment at y=0
mi_addsegment( x_win_R, y_win_bot, x_win_R, y_win_top)  -- outer wall
mi_addsegment( x_win_R, y_win_top, x_win_L, y_win_top)  -- top wall

-- Inner window wall stops at y=gap_half_height so bottom air handling is controlled
mi_addnode( x_win_L, gap_half_height)
mi_addsegment( x_win_L, y_win_top, x_win_L, gap_half_height)

-- Left window (mirror)
mi_addnode(-x_win_L, y_win_bot)
mi_addnode(-x_win_R, y_win_bot)
mi_addnode(-x_win_R, y_win_top)
mi_addnode(-x_win_L, y_win_top)

-- Window OPEN at y=0: do NOT add bottom segment at y=0
mi_addsegment(-x_win_R, y_win_bot, -x_win_R, y_win_top) -- outer wall
mi_addsegment(-x_win_R, y_win_top, -x_win_L, y_win_top) -- top wall

-- Inner window wall stops at y=gap_half_height
mi_addnode(-x_win_L, gap_half_height)
mi_addsegment(-x_win_L, y_win_top, -x_win_L, gap_half_height)

-- ============================================================
-- Central beam gap aperture handling
-- ============================================================

if SEPARATE_CENTRAL_APERTURE == 1 then
    -- Distinct central aperture (air):
    -- vertical walls at x=±gap_half_width, y in [0..gap_half_height]
    -- roof at y=gap_half_height from -gap_half_width..+gap_half_width

    -- Right wall
    mi_addnode( gap_half_width, 0)
    mi_addnode( gap_half_width, gap_half_height)
    mi_addsegment( gap_half_width, 0, gap_half_width, gap_half_height)

    -- Left wall
    mi_addnode(-gap_half_width, 0)
    mi_addnode(-gap_half_width, gap_half_height)
    mi_addsegment(-gap_half_width, 0, -gap_half_width, gap_half_height)

    -- Roof
    mi_addsegment(-gap_half_width, gap_half_height, gap_half_width, gap_half_height)
else
    -- Legacy: connect bottom air (central + windows) into one region below a roof segment
    mi_addsegment(-x_win_L, gap_half_height,  x_win_L, gap_half_height)
end

-- ============================================================
-- Copper coils (rectangles inside windows, with clearance)
-- ============================================================

-- Right copper
add_rect( x_cu_L, y_cu_B,  x_cu_R, y_cu_T, 0)

-- Left copper (mirror)
add_rect(-x_cu_R, y_cu_B, -x_cu_L, y_cu_T, 0)

-- ============================================================
-- Block labels
-- ============================================================

-- Outer air
mi_addblocklabel(0, y_air-30)
mi_selectlabel(0, y_air-30)
mi_setblockprop(MAT_AIR, 1, mesh_air_far, "", 0, 10, 0)
mi_clearselected()

-- Steel yoke
mi_addblocklabel(0, y_yoke-10)
mi_selectlabel(0, y_yoke-10)
mi_setblockprop(MAT_STEEL, 1, mesh_steel, "", 0, 1, 0)
mi_clearselected()

-- Central aperture air (fine mesh)
mi_addblocklabel(0, gap_half_height*0.5)
mi_selectlabel(0, gap_half_height*0.5)
mi_setblockprop(MAT_AIR, 1, mesh_gap, "", 0, 4, 0)
mi_clearselected()

-- Window air ABOVE the gap roof (separate region) - improves mesh control
x_win_air_R = (x_win_L + x_cu_L)*0.5
y_win_air_R = (gap_half_height + y_win_top)*0.5
mi_addblocklabel( x_win_air_R, y_win_air_R)
mi_selectlabel( x_win_air_R, y_win_air_R)
mi_setblockprop(MAT_AIR, 1, mesh_air_win, "", 0, 2, 0)
mi_clearselected()

mi_addblocklabel(-x_win_air_R, y_win_air_R)
mi_selectlabel(-x_win_air_R, y_win_air_R)
mi_setblockprop(MAT_AIR, 1, mesh_air_win, "", 0, 2, 0)
mi_clearselected()

-- Copper right
x_cu_mid_R = (x_cu_L + x_cu_R)*0.5
y_cu_mid   = (y_cu_B + y_cu_T)*0.5
mi_addblocklabel(x_cu_mid_R, y_cu_mid)
mi_selectlabel(x_cu_mid_R, y_cu_mid)
mi_setblockprop(MAT_CU, 1, mesh_cu, "CoilR", 0, 3, N_turns)
mi_clearselected()

-- Copper left
mi_addblocklabel(-x_cu_mid_R, y_cu_mid)
mi_selectlabel(-x_cu_mid_R, y_cu_mid)
mi_setblockprop(MAT_CU, 1, mesh_cu, "CoilL", 0, 3, N_turns)
mi_clearselected()

-- ============================================================
-- Solve
-- ============================================================
mi_zoomnatural()
mi_saveas("dipole_half_report_parametric.fem")
mi_createmesh()
mi_analyze()
mi_loadsolution()

-- ============================================================
-- Post: export scan CSV
-- ============================================================
f = openfile(csv_name, "w")
write(f, "x_mm,y_mm,Bx_T,By_T,Bmag_T,dBy_over_By0\n")

A0, bx0, by0 = mo_getpointvalues(0, scan_y)
if by0 == 0 then by0 = 1e-30 end

i = 0
while i < scan_N do
    x = scan_xmin + (scan_xmax - scan_xmin) * i / (scan_N - 1)
    y = scan_y
    A, bx, by = mo_getpointvalues(x, y)
    bmag = sqrt(bx*bx + by*by)
    dby  = (by/by0) - 1
    write(f, x..","..y..","..bx..","..by..","..bmag..","..dby.."\n")
    i = i + 1
end

closefile(f)
print("Wrote scan CSV: "..csv_name)
print("Scan y="..scan_y.." mm, x=["..scan_xmin..","..scan_xmax.."] mm, N="..scan_N)
