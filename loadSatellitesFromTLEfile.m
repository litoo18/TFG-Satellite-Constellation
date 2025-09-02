function sats = loadSatellitesFromTLEfile(sc, tleFile)
    sats = [];
    lines = readlines(tleFile);
    lines = strip(lines);

    for i = 1:3:length(lines)
        if i+2 > length(lines)
            break
        end

        name = lines(i);
        l1 = lines(i+1);
        l2 = lines(i+2);

        tempFile = "temp_single_sat.tle";
        writelines([name; l1; l2], tempFile);

        try
            s = satellite(sc, tempFile);
            sats = [sats, s];  % concatenar satélites válidos
        catch
            warning("Satélite '%s' no se pudo agregar (posible decay o datos inválidos).", name);
        end

        delete(tempFile); % limpiar archivo temporal
    end
end
