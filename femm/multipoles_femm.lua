-- femm/multipoles_femm.lua
-- FEMM-safe multipole extraction from Br on circular arc around origin.
--
-- compute_multipoles_Br(case_index, nh, np, Rs_mm, out_csv)
-- case_index:
--   1 -> dipole 180deg (C-shape)   : theta in [0, PI]
--   2 -> dipole 90deg  (H-shape)   : theta in [0, PI/2]
--   3 -> quadrupole 45deg          : theta in [0, PI/4]
--
-- Output CSV: n,a_cos,b_sin,rel_to_n1
-- where Br(theta) ≈ sum_n [ a_n cos(n theta) + b_n sin(n theta) ]
--
-- Notes:
--   - No 'math' library usage (FEMM Lua sometimes lacks it)
--   - No nested functions/closures (FEMM Lua scope restrictions)

-- Robust PI
if PI == nil then
    if pi ~= nil then
        PI = pi
    else
        PI = 3.14159265358979323846
    end
end

-- -- Robust trig helpers (some FEMM builds have globals sin/cos/sqrt)
-- -- If your FEMM has math.* instead, you can swap these in one place.
-- local _sin = sin
-- local _cos = cos
-- local _sqrt = sqrt

function _cos(x)
  if cos then return cos(x) end
  if math and math.cos then return math.cos(x) end
  return 0
end

function _sin(x)
  if sin then return sin(x) end
  if math and math.sin then return math.sin(x) end
  return 0
end

function _sqrt(x)
  if sqrt then return sqrt(x) end
  if math and math.sqrt then return math.sqrt(x) end
  return 0
end


function compute_multipoles_Br(case_index, nh, np, Rs_mm, out_csv)

    local thmax = PI/2
    if case_index == 1 then thmax = PI end
    if case_index == 3 then thmax = PI/4 end

    if np == nil or np < 2 then
        print("ERROR: np must be >= 2")
        return
    end

    local dth = thmax / (np - 1)

    -- sample Br(theta)
    local Br = {}
    local th = {}

    local i = 1
    while i <= np do
        local theta = (i-1) * dth
        local x = Rs_mm * _cos(theta)
        local y = Rs_mm * _sin(theta)

        local A, bx, by = mo_getpointvalues(x, y)
        local br = bx * _cos(theta) + by * _sin(theta)

        th[i] = theta
        Br[i] = br
        i = i + 1
    end

    -- coefficients
    local a = {}
    local b = {}

    local n = 1
    while n <= nh do
        local s_cos = 0.0
        local s_sin = 0.0
        local nc = 0.0
        local ns = 0.0

        i = 1
        while i <= np do
            local w = 1.0
            if (i == 1) or (i == np) then w = 0.5 end

            local c = _cos(n * th[i])
            local s = _sin(n * th[i])

            s_cos = s_cos + w * Br[i] * c
            s_sin = s_sin + w * Br[i] * s

            nc = nc + w * c * c
            ns = ns + w * s * s

            i = i + 1
        end

        s_cos = s_cos * dth
        s_sin = s_sin * dth
        nc = nc * dth
        ns = ns * dth

        if nc == 0 then nc = 1e-30 end
        if ns == 0 then ns = 1e-30 end

        a[n] = s_cos / nc
        b[n] = s_sin / ns

        n = n + 1
    end

    local ref = _sqrt(a[1]*a[1] + b[1]*b[1])
    if ref == 0 then ref = 1e-30 end

    local f = openfile(out_csv, "w")
    write(f, "n,a_cos,b_sin,rel_to_n1\n")

    n = 1
    while n <= nh do
        local rel = _sqrt(a[n]*a[n] + b[n]*b[n]) / ref
        write(f, n .. "," .. a[n] .. "," .. b[n] .. "," .. rel .. "\n")
        n = n + 1
    end

    closefile(f)
    print("Wrote multipoles CSV: " .. out_csv)
end