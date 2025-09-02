%% LEO Constellation Optimization using GA (Visibility-Based)
clear; clc;

%% Parameters
minObservability = 0.90;
spacingInLatLon = 5;
sampleTime = 240;  % seconds
simDuration = minutes(128);
minEle=30; % degrees

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

elev=zeros(size(latUE));
ue_info = [latUE, lonUE, elev];
%ue_info = [latUE,lonUE];

numUEs = numel(latUE);

%% Scenario and Targets
startTime = datetime(2023,9,2,12,0,0);
stopTime = startTime + simDuration;
mission.Scenario = satelliteScenario(startTime, stopTime, sampleTime);

timeVect = startTime:seconds(sampleTime):stopTime; % VECTOR TIME VECT   
mission.Targets = groundStation(mission.Scenario, latUE, lonUE, MinElevationAngle=minEle);

%% Optimization Variables

lb = [1, 1, 40, 0.5, 1, 1, 40, 0.5, 0]; % [Pws Sws Iws Aws Pwd Swd Iwd Awd Fwd]
ub = [10, 20, 80, 1.2, 10, 20, 80, 1.2, 9]; % Fwd UpperBound conservador (Fwd ≤ Pwd - 1)
nvars = numel(lb);

%% GA Options
options = optimoptions('ga', ...
    'Display', 'iter', ...
    'PopulationSize', 10, ...
    'MaxGenerations', 10, ...            % Mas adelante cambiar a 30 o mas
    'UseParallel', true);

%% Fitness Function
fitnessFcn = @(x) constellationFitness(x, minObservability, timeVect, ue_info, minEle);

%% Run GA
[x_opt, fval] = ga(fitnessFcn, nvars, [], [], [], [], lb, ub, @satelliteNonlinCon, options);

fprintf("\n✅ Optimización completada.\n");
fprintf("Walker Star: %dx%d @ %.1f°, %.1f Mm\n", round(x_opt(1)), round(x_opt(2)), x_opt(3), x_opt(4));
fprintf("Walker Delta: %dx%d @ %.1f°, %.1f Mm\n", round(x_opt(5)), round(x_opt(6)), x_opt(7), x_opt(8));
totalSats = round(x_opt(1)*x_opt(2) + x_opt(5)*x_opt(6));
fprintf("Total Sats: %d\n", totalSats);

%% Fitness Function Definition
function penalty = constellationFitness(x, minObs, timeVect, ue_info, minElevationAngle)
    
    % --- Inicialización ---
    % Definir parámetros orbitales fijos
    e = 0;      % Eccentricity
    w = 0;      % Argument of perigee

    % Round integer parameters
    % Walker Star
    Pws = round(x(1));      Sws = round(x(2));
    Iws = x(3);             Aws = alt2radius(x(4));
    % Walker Delta
    Pwd = round(x(5));      Swd = round(x(6));
    Iwd = x(7);             Awd = alt2radius(x(8));
    Fwd = round(x(9));      % Phasing (índice entero entre 0 y Pwd)
    
    try
        % Crear constelación híbrida
        % --- Generar satélites Walker Star ---
        satCount = 0;
        el_star = zeros(Pws*Sws, 6);  % [a e i RAAN w TA]
        Mws = pi / Sws;               % Intervalo de fase entre planos
        
        for j = 0:Pws-1
            RAAN_ws = mod(rad2deg(pi/Pws * j), 360);
            for k = 0:Sws-1
                Mwsjk = mod(rad2deg(2*pi/Sws*(j) + Mws*k), 360);
                satCount = satCount + 1;
                el_star(satCount,:) = [Aws, e, Iws, RAAN_ws, w, mod(Mwsjk,360)];
            end
        end

        % --- Generar satélites Walker Delta ---
        satCount = 0;
        el_delta = zeros(Pwd*Swd, 6); % [a e i RAAN w TA]
        Nwd = Pwd*Swd;
        
        for j = 0:Pwd-1
            RAAN_wd = mod(360/Pwd * j, 360);      % Ωwdj
            for k = 0:Swd-1
                phase_shift = 2*pi*Nwd*Fwd*j/Pwd;
                Mwdjk = mod(rad2deg(phase_shift/Nwd + 2*pi*k/Swd), 360);  % Mwdjk (anomalía media ~ TA si órbita circular)
                satCount = satCount + 1;
                el_delta(satCount,:) = [Awd, e, Iwd, RAAN_wd, w, mod(Mwdjk,360)];
            end
        end

        % Combinar ambas constelaciones
        el_all = [el_star; el_delta];  % Matriz N x 6 de elementos orbitales

        % Calcular visibilidad geométrica por elevación
        numUEs = length(ue_info); 
        numTS = numel(timeVect);
        visMatrix = zeros(numUEs, numTS); 
        
        % timeVect -> vector (datetime o segundos) de tus instantes de propagación
        % el_all(i,:) -> [a, e, i, RAAN, argp, trueAnomaly] de cada satélite
        
        positions = zeros(3, numTS, size(el_all,1)); % [3 x tiempo x sats]
        
        for k = 1:size(el_all,1)
            a    = el_all(k,1);
            e    = el_all(k,2);
            incl = el_all(k,3);
            RAAN = el_all(k,4);
            argp = el_all(k,5);
            nu   = el_all(k,6);
        
            % Propagación de SATELITES en modo SGP4 (recomendado para LEO)
            [pos,~] = propagateOrbit(timeVect, a, e, incl, RAAN, argp, nu, ...
                             OutputCoordinateFrame="fixed-frame"); % Posición ECEF de cada satélite para cada instante de tiempo
            % Guarda en el arreglo completo PropModel="sgp4",
            positions(:,:,k) = pos;
        end

        % Cálculo del ángulo de elevación con respecto a cada ground station
        for t = 1:numTS
            for k = 1:size(el_all,1)
                pos_sat = positions(:,t,k)'; % [x y z] en ECEF, metros
                for j = 1:numUEs
                    % gsLat(j), gsLon(j), gsAlt(j): coords de la estación
                    [elev, ~, ~] = lookangles(ue_info(j,:), pos_sat); % gsLat(j), gsLon(j), gsAlt(j)
                    elevMatrix(k, j, t) = elev; % Guarda elevación
                end
            end
        end
        % --- Una vez tienes elevMatrix (sats x users x tiempos) ---
        
        % minElevationAngle = 10; % o el que estimes adecuado, puedes
        % parametrizarlo también, ENTRADO COMO PARAMETROOO
        
        % Paso 1: Para cada ground station y timestamp, verifica si al menos un satélite supera el umbral
        % visMatrix(j,t) == 1 si GS j está cubierta por >=1 satélite en el timestamp t
        visMatrix = squeeze(any(elevMatrix >= minElevationAngle, 1)); % (users x tiempos)
        
        % Paso 2: Calcula el porcentaje de tiempo cubierto por cada GS
        perUserVis = mean(visMatrix, 2); % (users x 1): % del tiempo cubierta cada GS
        
        % Paso 3: Penalización según cumplimiento de minObs
        if any(perUserVis < minObs)
            % Penalizar si alguna GS tiene menos del mínimo requerido.
            penalty = 1e6 + sum((minObs - perUserVis(perUserVis < minObs)).^2)*1e3; % Penalty scaled nonlinearly based on the amount of violation ((minObs - vis)^2) is elegant and smooth.
        else
            % Penalización mínima: simplemente el número total de satélites usados
            penalty = Pws*Sws + Pwd*Swd;
        end

        %% Eliminar satélites creados en este paso
        
        clear el_all;
        clear el_star;
        clear el_delta;

        catch ME
            penalty = 1e7;
            rethrow(ME) % Para depuración: muestra el error original
    end
end

function [c, ceq] = satelliteNonlinCon(x)
    % Restricción: mínimo total de satélites
    Pws = round(x(1)); Sws = round(x(2));
    Pwd = round(x(5)); Swd = round(x(6));
    Fwd = round(x(9)); % Phasing

    totalSats = Pws*Sws + Pwd*Swd;
    minSats = 30;

    % Restricción desigualdad: c(x) ≤ 0
    c(1) = minSats - totalSats;     % totalSats ≥ minSats
    c(2) = Fwd - (Pwd - 1);         % Fwd ≤ Pwd - 1

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
    r = (alt + 6.378137) * 1e6;
end


