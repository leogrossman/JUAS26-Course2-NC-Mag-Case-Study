function write_gap_scan_csv(csv_name, scan_y, scan_xmin, scan_xmax, scan_N)
    local f = openfile(csv_name, "w")
    write(f, "x_mm,y_mm,Bx_T,By_T,Bmag_T,dBy_over_By0\n")

    local A0, bx0, by0 = mo_getpointvalues(0, scan_y)
    if by0 == 0 then by0 = 1e-30 end

    local i = 0
    while i < scan_N do
        local x = scan_xmin + (scan_xmax - scan_xmin) * i / (scan_N - 1)
        local y = scan_y
        local A, bx, by = mo_getpointvalues(x, y)
        local bmag = sqrt(bx*bx + by*by)
        local dby  = (by/by0) - 1
        write(f, x..","..y..","..bx..","..by..","..bmag..","..dby.."\n")
        i = i + 1
    end
    closefile(f)
end
