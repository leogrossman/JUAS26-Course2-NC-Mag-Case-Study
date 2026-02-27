-- multipoles_femm.lua (FEMM-compatible Lua)
-- Multipole extraction from Br(theta) sampled on an arc.
-- case_index: 1 dipole 180°, 2 dipole 90° (H-shape quarter model), 3 quadrupole 45°.

function _linspace(a, b, n, i)
    return a + (b - a) * i / (n - 1)
end

function compute_multipoles_Br(case_index, nh, np, Rs_mm, out_csv)
    local thmax, ihmin, ihstep, ihfund
    if case_index == 1 then
        thmax = pi
        ihmin = 1
        ihstep = 1
        ihfund = 1
    elseif case_index == 2 then
        thmax = pi/2
        ihmin = 1
        ihstep = 2
        ihfund = 1
    elseif case_index == 3 then
        thmax = pi/4
        ihmin = 2
        ihstep = 4
        ihfund = 2
    else
        -- default to dipole 90°
        thmax = pi/2
        ihmin = 1
        ihstep = 2
        ihfund = 1
    end

    local Cre = {}
    local Cim = {}
    local n
    for n=1,nh do
        Cre[n] = 0.0
        Cim[n] = 0.0
    end

    local i
    for i=0,np-1 do
        local th = _linspace(0, thmax, np, i)
        local w = 1.0
        if (i == 0) or (i == np-1) then w = 0.5 end

        local x = Rs_mm * cos(th)
        local y = Rs_mm * sin(th)

        local A, bx, by = mo_getpointvalues(x, y)
        local br = bx*cos(th) + by*sin(th)

        for n=1,nh do
            local c = cos(n*th)
            local s = sin(n*th)
            Cre[n] = Cre[n] + w * br * c
            Cim[n] = Cim[n] + w * br * s
        end
    end

    local dth = thmax / (np - 1)
    for n=1,nh do
        Cre[n] = Cre[n] * dth
        Cim[n] = Cim[n] * dth
    end

    local fund_mag = sqrt(Cre[ihfund]*Cre[ihfund] + Cim[ihfund]*Cim[ihfund])
    if fund_mag == 0 then fund_mag = 1e-30 end

    local f = openfile(out_csv, "w")
    write(f, "n,ReCn,ImCn,|Cn|,Cn_over_fund\n")
    for n=ihmin,nh,ihstep do
        local mag = sqrt(Cre[n]*Cre[n] + Cim[n]*Cim[n])
        local ratio = mag / fund_mag
        write(f, n..","..Cre[n]..","..Cim[n]..","..mag..","..ratio.."\n")
    end
    closefile(f)
end
