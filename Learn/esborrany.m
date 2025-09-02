%% LEO Constellation Optimization using GA (Visibility-Based)
clear; clc;

%% Parameters
minObservability = 0.90;
spacingInLatLon = 5;
sampleTime = 240;  % seconds
simDuration = minutes(128);

%% Load and filter land areas for European region
landareas = readgeotable("landareas.shp");
eurasia = landareas(landareas.Name == "Africa and Eurasia", :);

latlim = [35 70];    % Desde sur de España hasta Escandinavia
lonlim = [-10 40];   % Desde Portugal hasta Turquía

eurasia_europe = geoclip(eurasia.Shape, latlim, lonlim);  % Devuelve un geopolyshape recortado

spacingInLatLon = 5; % o menor para más resolución %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[gridlat, gridlon] = meshgrid(latlim(1):spacingInLatLon:latlim(2), ...
                              lonlim(1):spacingInLatLon:lonlim(2));
gridlat = gridlat(:);
gridlon = gridlon(:);

pts = geopointshape(gridlat, gridlon);
inregion = isinterior(eurasia_europe, pts);
gslat = gridlat(inregion);
gslon = gridlon(inregion);

% FIGURE DE MALLA
% figure
% geoplot(eurasia_europe, 'k')
% hold on
% geoscatter(gslat, gslon, 10, 'r', 'filled')
% title('Malla de estaciones terrestres sobre Europa')

lat_europe = latlim;    % Desde sur de España hasta Escandinavia
lon_europe = lonlim;   % Desde Portugal hasta Turquía

% numUEs_europe = 100;
%[latE, lonE] = generateGridUEs(lat_europe, lon_europe, numUEs_europe);
latE = gslat; lonE = gslon;

lat_global = [-60 60];   % Cobertura útil de LEO
lon_global = [-180 180];
numUEs_global = 10; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CAMBIAR %%%%%%%%%%%

[latG, lonG] = generateGridUEs(lat_global, lon_global, numUEs_global);

% Supón que tienes lat/lon de puertos en archivo
tblPorts = readtable("topPorts.csv");  
latP = tblPorts.Latitude;
lonP = tblPorts.Longitude;

%latUE = [latE; latG; latP];
%lonUE = [lonE; lonG; lonP];
latUE = latG; %%%%%%%%%%%%%% SOLO DE PRUEBAS %%%%%%%%%% BORRAR LUEGO %%%%%%
lonUE = lonG;

numUEs = numel(latUE);

%% Scenario and Targets
startTime = datetime(2023,9,2,12,0,0);
stopTime = startTime + simDuration;
mission.Scenario = satelliteScenario(startTime, stopTime, sampleTime);

mission.Targets = groundStation(mission.Scenario, latUE, lonUE, MinElevationAngle=30);

%% Optimization Variables

lb = [1, 1, 40, 0.5, 1, 1, 40, 0.5];    % [Pws Sws Iws Aws Pwd Swd Iwd Awd]
ub = [10, 20, 80, 1.2, 10, 20, 80, 1.2];
nvars = numel(lb);

%% GA Options
options = optimoptions('ga', ...
    'Display', 'iter', ...
    'PopulationSize', 20, ...
    'MaxGenerations', 20, ...            % Mas adelante cambiar a 30 o mas
    'UseParallel', true);

%% Fitness Function
fitnessFcn = @(x) constellationFitness(x, mission, minObservability);

%% Run GA
[x_opt, fval] = ga(fitnessFcn, nvars, [], [], [], [], lb, ub, @satelliteNonlinCon, options);

fprintf("\n✅ Optimización completada.\n");
fprintf("Walker Star: %dx%d @ %.1f°, %.1f Mm\n", round(x_opt(1)), round(x_opt(2)), x_opt(3), x_opt(4));
fprintf("Walker Delta: %dx%d @ %.1f°, %.1f Mm\n", round(x_opt(5)), round(x_opt(6)), x_opt(7), x_opt(8));
fprintf("Total Sats: %d\n", round(x_opt(1)*x_opt(2) + x_opt(5)*x_opt(6)));

%% Fitness Function Definition
function penalty = constellationFitness(x, mission, minObs)

    % Round integer parameters
    Pws = round(x(1));      Sws = round(x(2));
    Iws = x(3);             Aws = x(4);
    Pwd = round(x(5));      Swd = round(x(6));
    Iwd = x(7);             Awd = x(8);
    
    try
        % Crear constelación híbrida
        star = walkerStar(mission.Scenario, alt2radius(Aws), Iws, Pws*Sws, Pws, 0);
        delta = walkerDelta(mission.Scenario, alt2radius(Awd), Iwd, Pwd*Swd, Pwd, 0);
        sat = [star; delta];
        
        % Calcular visibilidad geométrica por elevación
        numUEs = numel(mission.Scenario.GroundStations);
        numTS = numel(mission.Scenario.SimulationTime);
        visMatrix = zeros(numUEs, numTS);

       for i = 1:numUEs
            [~, el] = aer(mission.Scenario.GroundStations(i), mission.Scenario.Satellites); % PROBAR ADAPTACION CON mission.Targets(i) y mission.Satellites(i) 
            elIdx = el >= mission.Scenario.GroundStations(i).MinElevationAngle;
            visMatrix(i,:) = any(elIdx, 1);
        end

        perUserVis = mean(visMatrix, 2);
        meanVis = mean(perUserVis)

        % Penalización si algún UE no cumple
        if any(vis < minObs)
            penalty = 1e6 + sum((minObs - vis(vis < minObs)).^2)*1e3;
        else
            penalty = Pws*Sws + Pwd*Swd;  % Mínimo total de satélites
        end

        % Eliminar satélites creados en este paso
        delete(mission.Scenario.Satellites);
        delete(sat);
    catch
        penalty = 1e7;  % Penalización fuerte en errores
    end
end

function [c, ceq] = satelliteNonlinCon(x)
    % Restricción: mínimo total de satélites
    Pws = round(x(1)); Sws = round(x(2));
    Pwd = round(x(5)); Swd = round(x(6));
    totalSats = Pws*Sws + Pwd*Swd;

    minSats = 30;
    
    % Restricción desigualdad: c(x) ≤ 0
    c = minSats - totalSats;   % --> queremos totalSats ≥ minSats ⇒ minSats - totalSats ≤ 0
    ceq = [];  % No hay restricciones de igualdad
end


%% Helper Functions

function [latCoord, lonCoord] = generateGridUEs(latRange, lonRange, numUEs)
    % Encuentra los factores más cercanos
    [latSpacing, lonSpacing] = findClosestFactors(numUEs);

    % Crea la malla regular
    latPts = linspace(latRange(1), latRange(2), latSpacing);
    lonPts = linspace(lonRange(1), lonRange(2), lonSpacing);
    [latMesh, lonMesh] = meshgrid(latPts, lonPts);
    latCoord = latMesh(:);
    lonCoord = lonMesh(:);

    % Normaliza longitudes a [-180, 180)
    lonCoord = mod(lonCoord + 180, 360) - 180;

    % Elimina duplicados usando tolerancia
    coords = round([latCoord lonCoord]*1e6)/1e6; % redondeo para tolerancia ~1e-6 deg
    [coordsUnique, ia] = unique(coords, 'rows');

    if size(coordsUnique,1) < size(coords,1)
        warning("⚠️ Se detectaron y eliminaron %d puntos duplicados (por redondeo geográfico).", size(coords,1) - size(coordsUnique,1));
    end

    latCoord = coordsUnique(:,1);
    lonCoord = coordsUnique(:,2);
    fprintf("   Se añaden %d Usuarios\n", numel(latCoord));

end

% Altitude to radius conversion
function r = alt2radius(alt)
    r = (alt + 6378.137) * 1e3;
end


