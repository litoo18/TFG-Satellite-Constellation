function [ue, rx] = generateUEs(sc)
% GENERATEUES Crea usuarios en Europa y principales puertos globales

    % --- Europa (rectángulo simple) ---
    latEU = [35 70];    
    lonEU = [-10 30];
    nUE_EU = 30;
    [latS, lonS] = generateGrid(latEU, lonEU, nUE_EU);

    % --- Puertos globales (coordenadas representativas simplificadas) ---
    portLat = [35.6, 22.3, 31.2, -34.6, 35.1, 1.3, 51.3, 35.6, -6.9, 43.2];  % 10 grandes puertos
    portLon = [139.8, 114.2, 121.5, 18.4, 129.0, 103.9, 0.1, 139.8, 146.9, -3.7];
    
    % Combinar todo
    latAll = [latS; portLat(:)];
    lonAll = [lonS; portLon(:)];

    ue = groundStation(sc, latAll, lonAll);
    [ue.MinElevationAngle] = deal(20); % elevación mínima

    rxCfg = struct;
    rxCfg.MaxGByT = -5;
    rxCfg.SystemLoss = 0;
    rxCfg.PreReceiverLoss = 0;

    rx = receiver(ue, ...
        Antenna=arrayConfig(Size=[1 1]), ...
        SystemLoss=rxCfg.SystemLoss, ...
        PreReceiverLoss=rxCfg.PreReceiverLoss, ...
        GainToNoiseTemperatureRatio=rxCfg.MaxGByT);
end

function [latGrid, lonGrid] = generateGrid(latLim, lonLim, nPts)
    [rows, cols] = findClosestFactors(nPts);
    latPts = linspace(latLim(1), latLim(2), rows);
    lonPts = linspace(lonLim(1), lonLim(2), cols);
    [LAT, LON] = meshgrid(latPts, lonPts);
    latGrid = LAT(:);
    lonGrid = LON(:);
end
