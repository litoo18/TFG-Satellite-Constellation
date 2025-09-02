function [singleFile, tleGlobalFile] = loadConstellationTLE(name, usePredefined, tleGlobalFile)
    % name: nombre de constelación (ej: "Starlink")
    % usePredefined: true -> copia fichero local usePredefined_Starlink.tle
    % tleGlobalFile: opcional, nombre del fichero combinado de salida

    if nargin < 3 || isempty(tleGlobalFile)
        tleGlobalFile = "allConstellations.tle";
        if exist(tleGlobalFile, 'file')
            delete(tleGlobalFile);
        end
    end

    % 1. URLs disponibles
    urls = struct( ...
        'Iridium', 'https://celestrak.org/NORAD/elements/gp.php?GROUP=iridium&FORMAT=tle', ...
        'OneWeb',  'https://celestrak.org/NORAD/elements/gp.php?GROUP=oneweb&FORMAT=tle', ...
        'Kuiper',  'https://celestrak.org/NORAD/elements/gp.php?GROUP=kuiper&FORMAT=tle', ...
        'Starlink','https://celestrak.org/NORAD/elements/gp.php?GROUP=starlink&FORMAT=tle', ...
        'Qianfan', 'https://celestrak.org/NORAD/elements/gp.php?GROUP=qianfan&FORMAT=tle', ...
        'Hulianwang', 'https://celestrak.org/NORAD/elements/gp.php?GROUP=hulianwang&FORMAT=tle', ...
        'Orbcomm','https://celestrak.org/NORAD/elements/gp.php?GROUP=orbcomm&FORMAT=tle', ...
        'Globalstar','https://celestrak.org/NORAD/elements/gp.php?GROUP=globalstar&FORMAT=tle' ...
    );

    % 2. Fichero destino
    singleFile = name + ".tle";

    if usePredefined
        % Buscar archivo predefinido en carpeta tle_data/
        localFile = fullfile("tle_data", "usePredefined_" + name + ".tle");
        if ~isfile(localFile)
            error("Archivo predefinido %s no encontrado.", localFile);
        end
        copyfile(localFile, singleFile);
    else
        % Descargar si no es predefinido
        if isfield(urls, name)
            url = urls.(name);
            websave(singleFile, url);
        else
            error("Constelación %s no válida.", name);
        end
    end

    % 3. Añadir contenido al archivo global
    appendToGlobalTLE(singleFile, tleGlobalFile);
end


function appendToGlobalTLE(srcFile, globalFile)
    if ~isfile(srcFile)
        warning("Archivo %s no encontrado, no se añadió.", srcFile);
        return;
    end
    data = fileread(srcFile);
    fid = fopen(globalFile, 'a');
    if fid == -1
        error("No se pudo abrir %s para escribir.", globalFile);
    end
    fprintf(fid, '%s', data);  % No añadas \n extra aquí
    % Añadir salto de línea solo si el contenido no termina ya con uno
    if ~endsWith(data, newline)
        fprintf(fid, '\n');
    end
    fclose(fid);
end

