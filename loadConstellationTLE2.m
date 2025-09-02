function constellation = loadConstellationTLE2()
    % OUTPUT: nombre del archivo TLE descargado (ej: 'Starlink.tle')

    % Eliminar TLEs antiguos excepto el predefinido
    files = dir("*.tle");
    for k = 1:length(files)
        if ~strcmp(files(k).name, "leoSatelliteConstellation.tle")
            delete(files(k).name);
        end
    end

    % URLs disponibles
    urls = struct( ...
        'Iridium', 'https://celestrak.org/NORAD/elements/gp.php?GROUP=iridium&FORMAT=tle', ...
        'OneWeb',  'https://celestrak.org/NORAD/elements/gp.php?GROUP=oneweb&FORMAT=tle', ...
        'Kuiper',  'https://celestrak.org/NORAD/elements/gp.php?GROUP=kuiper&FORMAT=tle', ...
        'Starlink','https://celestrak.org/NORAD/elements/gp.php?GROUP=starlink&FORMAT=tle' ...
    );

    % Variable para guardar el nombre seleccionado
    selectedName = "";

    % Crear GUI
    fig = uifigure('Name', 'Selecciona Constelación Satelital', 'Position', [500 500 300 150]);

    dd = uidropdown(fig, ...
        'Items', {'Iridium', 'OneWeb', 'Kuiper', 'Starlink'}, ...
        'Position', [75 80 150 22], ...
        'Value', 'Iridium');

    btn = uibutton(fig, 'push', ...
        'Text', 'Cargar Constelación', ...
        'Position', [75 40 150 30], ...
        'ButtonPushedFcn', @(btn, event) downloadAndSet(dd, urls));

    % Esperar a que el usuario interactúe
    uiwait(fig);

    % Devolver nombre final
    constellation = selectedName + ".tle";

    % Función anidada que modifica la variable externa
    function downloadAndSet(dd, urls)
        selectedConstellation = dd.Value;
        selectedName = selectedConstellation;  % guarda antes de cerrar
        url = urls.(selectedConstellation);
        fileName = selectedName + ".tle";
        try
            websave(fileName, url);
            sc = satelliteScenario;
            sat = satellite(sc, fileName);
            numSatellites = numel(sat);
            msg = sprintf('Se han cargado %d satélites de %s.', numSatellites, selectedName);
            uialert(fig, msg, 'Éxito');
            pause(1);
            uiresume(fig);
            close(fig);
        catch ME
            uialert(fig, ['Error al cargar el TLE: ' ME.message], 'Error');
        end
    end
end
