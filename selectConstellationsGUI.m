function [constellationNames, usePredefined, nConstellations] = selectConstellationsGUI()
    % GUI para seleccionar múltiples constelaciones y un único modo predefinido/actual

    % Lista completa de constelaciones disponibles
    constellationList = {
        'Iridium', 'OneWeb', 'Kuiper', 'Starlink', ...
        'Qianfan', 'Hulianwang', 'Orbcomm', 'Globalstar'
    };

    % Inicialización de salidas
    constellationNames = {};
    usePredefined = false;
    nConstellations = 0;

    % Centrado de ventana
    screenSize = get(0, 'ScreenSize');
    figWidth = 400;
    figHeight = 280;
    figX = (screenSize(3) - figWidth) / 2;
    figY = (screenSize(4) - figHeight) / 2;

    % Crear interfaz
    fig = uifigure( ...
        'Name', 'Selecciona Constelaciones Satelitales', ...
        'Position', [figX figY figWidth figHeight]);

    % Lista de selección múltiple
    lb = uilistbox(fig, ...
        'Items', constellationList, ...
        'Multiselect', 'on', ...
        'Position', [50 100 300 140]);

    % Checkbox único para "usar predefinido"
    cb = uicheckbox(fig, ...
        'Text', 'Usar archivos predefinidos (*.tle)', ...
        'Position', [50 70 300 22]);

    % Botón aceptar
    btn = uibutton(fig, ...
        'Text', 'Aceptar', ...
        'Position', [150 20 100 30], ...
        'ButtonPushedFcn', @(btn,event) confirmar());

    % Esperar a que el usuario interactúe
    uiwait(fig);

    function confirmar()
        constellationNames = lb.Value;
        nConstellations = numel(constellationNames);
        usePredefined = cb.Value;

        if nConstellations == 0
            uialert(fig, 'Selecciona al menos una constelación.', 'Error');
            return;
        end

        uiresume(fig);
        delete(fig);
    end
end
