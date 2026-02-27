-- build_and_solve.lua
-- Parameter-driven JUAS2 NC dipole model builder + solver + exports.
--
-- Supports:
--   * Geometry mode: "H_SHAPE" (JUAS/tutorial-style parameterization)
--   * Model fraction:
--       - "quarter": x>=0, y>=0 (symmetry at x=0 and y=0)
--       - "half"   : full x, y>=0 (symmetry at y=0)  [DEFAULT + recommended]
--   * Steel material:
--       - built-in "1010 Steel" (MAT_STEEL)
--       - optional nonlinear laminated steel from BH curve (M1200-100A) .dat
--   * Exports per case (in out_dir):
--       - gap_By_scan.csv       (By along horizontal scan in aperture)
--       - Bx_profile.txt        (x  Bx, tutorial-compatible)
--       - multipoles.csv        (Br Fourier multipoles from circular sampling)
--       - monitor_points.csv    (field at user-defined points)
--
-- Assumes: dofile("case_params.lua") already executed in the case folder.

-- ==========================
-- FEMM Lua compatibility utils
-- ==========================

function list_len(t)
    local n = 0
    while t[n+1] do n = n + 1 end
    return n
end

function list_push(t, v)
    t[list_len(t) + 1] = v
end

function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function split_ws(line)
    -- whitespace split without gmatch/pattern iterators
    local t = {}
    local i = 1
    while true do
        local s, e = string.find(line, "%S+", i)
        if s == nil then break end
        list_push(t, string.sub(line, s, e))
        i = e + 1
    end
    return t
end

function ensure_dir(path)
    if mkdir then mkdir(path) end
end

function add_rect(x1, y1, x2, y2, open_bottom)
    mi_addnode(x1, y1) mi_addnode(x2, y1) mi_addnode(x2, y2) mi_addnode(x1, y2)
    if open_bottom ~= 1 then mi_addsegment(x1, y1, x2, y1) end
    mi_addsegment(x2, y1, x2, y2)
    mi_addsegment(x2, y2, x1, y2)
    mi_addsegment(x1, y2, x1, y1)
end

function set_A0_on_segment_at(x, y)
    mi_selectsegment(x, y)
    mi_setsegmentprop("A0", 0, 1, 0, 0)
    mi_clearselected()
end

-- ==========================
-- Steel from BH curve (.dat)
-- ==========================
function add_steel_from_bh_dat(mat_name, dat_path, lam_fill)
    -- Create material container
    -- mi_addmaterial(name, mux, muy, Hc, J, Cduct, Lam_d, Phi_hmax, lam_fill, lam_type)
    mi_addmaterial(mat_name, 1, 1, 0, 0, 0, 0, 0, lam_fill, 0)

    local f = openfile(dat_path, "r")
    if f == nil then
        print("ERROR: Could not open BH curve file: " .. dat_path)
        return
    end

    while true do
        local line = read(f)
        if line == nil then break end
        line = trim(line)
        if line ~= "" then
            local parts = split_ws(line)
            if parts[1] and parts[2] then
                local B = tonumber(parts[1])
                local H = tonumber(parts[2])
                if B ~= nil and H ~= nil then
                    mi_addbhpoint(mat_name, B, H)
                end
            end
        end
    end

    closefile(f)
end

-- ==========================
-- Export helpers
-- ==========================
function write_Bx_profile_txt(out_txt, y_mm, xmin, xmax, N)
    local f = openfile(out_txt, "w")
    local i = 0
    while i < N do
        local x = xmin + (xmax - xmin) * i / (N - 1)
        local A, bx, by = mo_getpointvalues(x, y_mm)
        write(f, x .. " " .. bx .. "\n")
        i = i + 1
    end
    closefile(f)
end

function write_monitor_points_csv(out_csv, pts)
    local f = openfile(out_csv, "w")
    write(f, "name,x_mm,y_mm,Bx_T,By_T,Bmag_T\n")
    local i = 1
    while pts[i] do
        local name = pts[i][1]
        local x = pts[i][2]
        local y = pts[i][3]
        local A, bx, by = mo_getpointvalues(x, y)
        local bmag = sqrt(bx*bx + by*by)
        write(f, name .. "," .. x .. "," .. y .. "," .. bx .. "," .. by .. "," .. bmag .. "\n")
        i = i + 1
    end
    closefile(f)
end

function mirror_poly_x0(pts)
    -- mirror nodes
    local n = list_len(pts)
    local i = 1
    while i <= n do
        mi_addnode(-pts[i].x, pts[i].y)
        i = i + 1
    end
    -- mirror segments
    i = 1
    while i < n do
        mi_addsegment(-pts[i].x, pts[i].y, -pts[i+1].x, pts[i+1].y)
        i = i + 1
    end
end

-- ==========================
-- Start model
-- ==========================
newdocument(0)
mi_probdef(0, units, "planar", 1e-8, depth_mm, 30)

-- Materials
mi_getmaterial(MAT_AIR)
mi_getmaterial(MAT_CU)

local STEEL_NAME = MAT_STEEL
if USE_M1200 == 1 then
    STEEL_NAME = "M1200-100A"
    add_steel_from_bh_dat(STEEL_NAME, BH_DAT_PATH, STEEL_LAM_FILL)
else
    mi_getmaterial(MAT_STEEL)
end

-- Circuits
mi_addcircprop("CoilR",  I_amp, 1)
mi_addcircprop("CoilL", -I_amp, 1)
mi_addcircprop("SeriesCoil", I_amp, 1)

-- Output
ensure_dir(out_dir)

-- ==========================
-- Geometry: H-shape (quarter polygon + mirror for half)
-- ==========================
local half_h = h_ap_mm/2
local new_w2 = w_pole_mm/2 + dent_pole_w * w_pole_mm/2
local new_half_h = half_h + dent_pole_h * h_ap_mm/2
if dent_pole_h < 0 then new_half_h = half_h end

local dli = dl_int * w_leg_mm
local dle = dl_ext * w_leg_mm

-- Quarter-face polygon points (x>=0,y>=0)
local pts = {
    {x = 0,                                    y = half_h},
    {x = w_pole_mm/2,                          y = half_h},
    {x = new_w2,                               y = new_half_h},
    {x = new_w2,                               y = half_h + c_h_mm + dx_mm},
    {x = new_w2 + c_w_mm + dx_mm,              y = half_h + c_h_mm + dx_mm},
    {x = new_w2 + c_w_mm + dx_mm,              y = 0},
    {x = new_w2 + c_w_mm + dx_mm + w_leg_mm,   y = 0},
    {x = new_w2 + c_w_mm + dx_mm + w_leg_mm,   y = half_h + c_h_mm + dx_mm + w_leg_mm*(1-dl_ext)},
    {x = new_w2 + c_w_mm + dx_mm + w_leg_mm*(1-dl_ext), y = half_h + c_h_mm + dx_mm + w_leg_mm},
    {x = dli,                                   y = half_h + c_h_mm + dx_mm + w_leg_mm},
    {x = 0,                                     y = half_h + c_h_mm + dx_mm + w_leg_mm*(1-dl_int)},
    {x = 0,                                     y = half_h}
}

-- draw quarter polygon
local npts = list_len(pts)
local i = 1
while i <= npts do
    mi_addnode(pts[i].x, pts[i].y)
    i = i + 1
end
i = 1
while i < npts do
    mi_addsegment(pts[i].x, pts[i].y, pts[i+1].x, pts[i+1].y)
    i = i + 1
end

if MODEL_FRACTION == "half" then
    mirror_poly_x0(pts)
end

-- Outer airbox
add_rect(-x_air, 0, x_air, y_air, 0)
if USE_A0_OUTER == 1 then
    mi_addboundprop("A0", 0,0,0,0,0,0,0,0,0)
    set_A0_on_segment_at( x_air, y_air/2)
    set_A0_on_segment_at( 0,    y_air)
    set_A0_on_segment_at(-x_air, y_air/2)
end

-- Conductor rectangle in quarter window
local cond = {
    {x = new_w2 + dx_mm/2,          y = half_h + dx_mm/2},
    {x = new_w2 + dx_mm/2,          y = half_h + c_h_mm + dx_mm/2},
    {x = new_w2 + dx_mm/2 + c_w_mm, y = half_h + c_h_mm + dx_mm/2},
    {x = new_w2 + dx_mm/2 + c_w_mm, y = half_h + dx_mm/2},
    {x = new_w2 + dx_mm/2,          y = half_h + dx_mm/2}
}

local nc = list_len(cond)
i = 1
while i <= nc do
    mi_addnode(cond[i].x, cond[i].y)
    i = i + 1
end
i = 1
while i < nc do
    mi_addsegment(cond[i].x, cond[i].y, cond[i+1].x, cond[i+1].y)
    i = i + 1
end

-- Mirror conductor for half model
if MODEL_FRACTION == "half" then
    i = 1
    while i <= nc do
        mi_addnode(-cond[i].x, cond[i].y)
        i = i + 1
    end
    i = 1
    while i < nc do
        mi_addsegment(-cond[i].x, cond[i].y, -cond[i+1].x, cond[i+1].y)
        i = i + 1
    end
end

-- ==========================
-- Block labels (IMPORTANT: one per region)
-- ==========================

-- Outer air
mi_addblocklabel(0, y_air-30)
mi_selectlabel(0, y_air-30)
mi_setblockprop(MAT_AIR, 1, mesh_air_far, "", 0, 10, 0)
mi_clearselected()

-- Aperture air (inside gap)
mi_addblocklabel(0, half_h/2)
mi_selectlabel(0, half_h/2)
mi_setblockprop(MAT_AIR, 1, mesh_gap, "", 0, 4, 0)
mi_clearselected()

-- Steel yoke (place label safely inside yoke)
local local_yx = (new_w2 + c_w_mm + dx_mm) + w_leg_mm*0.5
local local_yy = half_h + (c_h_mm + dx_mm + w_leg_mm)*0.5
mi_addblocklabel(local_yx, local_yy)
mi_selectlabel(local_yx, local_yy)
mi_setblockprop(STEEL_NAME, 1, mesh_steel, "", 0, 1, 0)
mi_clearselected()

if MODEL_FRACTION == "half" then
    mi_addblocklabel(-local_yx, local_yy)
    mi_selectlabel(-local_yx, local_yy)
    mi_setblockprop(STEEL_NAME, 1, mesh_steel, "", 0, 1, 0)
    mi_clearselected()
end

-- Conductor(s)
local cx = new_w2 + dx_mm/2 + c_w_mm/2
local cy = half_h + c_h_mm/2

mi_addblocklabel(cx, cy)
mi_selectlabel(cx, cy)
if MODEL_FRACTION == "quarter" then
    mi_setblockprop(MAT_CU, 1, mesh_cu, "SeriesCoil", 0, 2, N_turns)
else
    mi_setblockprop(MAT_CU, 1, mesh_cu, "CoilR", 0, 3, N_turns)
end
mi_clearselected()

if MODEL_FRACTION == "half" then
    mi_addblocklabel(-cx, cy)
    mi_selectlabel(-cx, cy)
    mi_setblockprop(MAT_CU, 1, mesh_cu, "CoilL", 0, 3, N_turns)
    mi_clearselected()
end

-- ==========================
-- Solve
-- ==========================
mi_zoomnatural()
mi_saveas(out_dir .. "/model.fem")
mi_createmesh()
mi_analyze()
mi_loadsolution()

-- ==========================
-- Exports
-- ==========================

-- Gap scan CSV
dofile("../../femm/post_gap_scan.lua")
write_gap_scan_csv(csv_gap_scan, scan_y, scan_xmin, scan_xmax, scan_N)

-- Bx profile txt
write_Bx_profile_txt(txt_Bx_profile, bx_scan_y, bx_scan_xmin, bx_scan_xmax, bx_scan_N)

-- Multipoles CSV
dofile("../../femm/multipoles_femm.lua")
compute_multipoles_Br(multipoles_case_index, multipoles_nh, multipoles_np, multipoles_Rs_mm, csv_multipoles)

-- Monitor points CSV
write_monitor_points_csv(csv_monitors, monitor_points)

print("Done. Outputs in: " .. out_dir)

-- Auto-close
mi_close()
if quit then quit() end
if closefemm then closefemm() end