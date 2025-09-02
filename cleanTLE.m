function cleanedFilename = cleanTLE(originalFile, maxAgeDays, maxNdot, maxNddot, usarPredefinido)
    if nargin < 2
        maxAgeDays = 2;
    end
    if nargin < 3
        maxNdot = 1e-3;   % umbral razonable para ndot
    end
    if nargin < 4
        maxNddot = 1e-2;  % umbral razonable para nddot
    end

    if ~isfile(originalFile)
        warning("Archivo '%s' no encontrado. No se pudo limpiar.", originalFile);
        cleanedFilename = "";
        return;
    end

    try
        lines = readlines(originalFile);
    catch
        warning("Error al leer el archivo '%s'.", originalFile);
        cleanedFilename = "";
        return;
    end

    lines = strip(lines);
    newLines = strings(0,1);
    totalSat = 0;
    keptSat = 0;

    for i = 1:3:length(lines) % Itera sobre las líneas de tres en tres, porque un satélite ocupa tres líneas (TLE: nombre, línea 1, línea 2)
        if i+2 > length(lines)
            continue;
        end

        try
            name = lines(i); % Lee nombre de Satelite
            l1 = lines(i+1); % Linea 1
            l2 = lines(i+2); % Linea 2

            % Epoch
            yy = str2double(extractBetween(l1, 19, 20)); % Extrae los dos dígitos del año de época desde la columna 19-20 de la línea 1 del TLE y los convierte a número
            dd = str2double(extractBetween(l1, 21, 32)); % Lo mismo con el dia
            yyyy = yy + (yy < 57)*2000 + (yy >= 57)*1900; % Se convierte año de 2 a 4 cifras
            epoch = datetime(yyyy, 1, 0) + days(dd);      % Crea fecha EPOCH

            % ndot y nddot
            ndot = str2double(extractBetween(l1, 34, 43)); % Extrae la razón de cambio del movimiento medio, ndot
            nddot_raw = extractBetween(l1, 45, 50); % Extrae el valor bruto de nddot (aceleración de movimiento medio). ejemplo: "-26959"
            nddot_exp = str2double("1e" + extractBetween(l1, 50, 51)); % Extrae el exponente del formato científico (por ejemplo, "+0")
            nddot = str2double("0." + nddot_raw) * nddot_exp; % Reconstruye el valor real de nddot combinando la mantisa como decimal y multiplicando por el exponente adecuado

            % Verificar umbrales
            if abs(ndot) > maxNdot || abs(nddot) > maxNddot
                continue;
            end
        catch
            continue;
        end

        totalSat = totalSat + 1;

        if usarPredefinido 
            if epoch >= datetime('11/07/2025', 'InputFormat', 'dd/MM/yyyy') - days(maxAgeDays) % CAMBIAR DATETIME POR DIA DE DESCARGA
                newLines(end+1,1) = name;
                newLines(end+1,1) = l1;
                newLines(end+1,1) = l2;
                keptSat = keptSat + 1;
            end
        else
            if epoch >= datetime("now") - days(maxAgeDays)
                newLines(end+1,1) = name;
                newLines(end+1,1) = l1;
                newLines(end+1,1) = l2;
                keptSat = keptSat + 1;
            end
        end
    end

    cleanedFilename = "cleaned_" + originalFile;

    if keptSat == 0
        warning("No se conservaron satélites en '%s'. Archivo generado vacío.", cleanedFilename);
        writelines("", cleanedFilename);
    else
        writelines(newLines, cleanedFilename);
    end

    fprintf("\n✅ Limpieza de TLE completada:\n");
    fprintf("  Archivo original: %s\n", originalFile);
    fprintf("  Total satélites procesados: %d\n", totalSat);
    fprintf("  Satélites válidos (≤ %d días): %d\n", maxAgeDays, keptSat);
    fprintf("  Archivo generado: %s\n\n", cleanedFilename);
end
