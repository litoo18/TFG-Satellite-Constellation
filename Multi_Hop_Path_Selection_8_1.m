%% Multi-Hop Path Selection Through Large Satellite Constellation

    init();

%% Add large constellation
% Paso 1: interfaz
[nombres, usarPredefinido, num] = selectConstellationsGUI();

% Paso 2: cargar cada constelación
for i = 1:num
    name = nombres{i};
    if isfile("allConstellations.tle") 
        [archivo, archivoGlobal] = loadConstellationTLE(name, usarPredefinido,archivoGlobal);
    else
    [archivo, archivoGlobal] = loadConstellationTLE(name, usarPredefinido);
    end
    fprintf("Constelación %s cargada en %s y añadida a %s\n", name, archivo, archivoGlobal);
    cleanedFile = cleanTLE(archivo, 30, 5e-4, 5e-3, usarPredefinido); % % Limpiar por fecha (ejemplo 15 días bien, con 2 dias mas preciso) {5e-4, 5e-3} UMBRALES PARA CONSTELACIÓN LEO
    summary = summarizeTLEcompact(cleanedFile); % FUNCION PARA DAR INFORMACION DE ARCHIVO TLE LIMPIO
    disp(summary)
end

%%            % Distancia mínima entre satélite 20 y 38: 6245.2 m

% Determine the indices of the range when the satellite are closer than the 
% target of 200 km. Then, use a for loop to find the times when this relative 
% distance is less than a target of 200 km.

% You can use the Mapping Toolbox™ 3-D Coordinate and Vector Transfomations
% to transform coordinates and vector components between global and local systems.



%% === Análisis preliminar con propagación numérica ===
%analyzeTLEorbits(cleanedFile, 3, 3600, 60);  % 3 satélites, 1h, paso 60s

%% CREATE SCENARIO

startTime = summary.Epoch_mean;           % Epoch_mean UTC
stopTime = startTime + hours(3);           
sampleTime = 60;                           % Seconds
sc = satelliteScenario(startTime,stopTime,sampleTime,"AutoSimulate",false) %Autosimulate false to calculate first connection.
%sc = satelliteScenario(startTime,stopTime,sampleTime)

%% Usar el archivo TLE limpio
if isfile(cleanedFile)
    satellites_info = tleread(cleanedFile);
    timeVect = startTime:seconds(sampleTime):stopTime;
    [r,v] = propagateOrbit(timeVect,satellites_info, 'PropModel','sgp4'); % OutputCoordinateFrame="fixed-frame" para ECEF
    for k = 1:numel(satellites_info) %Guardar vectores r y v en struct.
        satellites_info(k).r = r(:,:,k);  
        satellites_info(k).v = v(:,:,k);
    end
    [~, nTimes, nSats] = size(r);
    fprintf("Se calcularon posiciones y velocidades de %d satélites en %d timestamps\n", nSats, nTimes);

    minDist = zeros(nSats); globaldMin=Inf;
    for i = 1:nSats-1
        for j = i+1:nSats
            delta = satellites_info(i).r - satellites_info(j).r;   % 3×nTimes
            dInst = sqrt(sum(delta.^2, 1));                        % 1×nTimes
            dMin = min(dInst);
            minDist(i,j) = dMin;
            minDist(j,i) = dMin;  % matriz simétrica
            % fprintf("Distancia mínima entre satélite %d y %d: %.1f m\n", i, j, dMin);
            if dMin<=globaldMin
                globaldMin = dMin;
                satmin1 = i;
                satmin2 = j;
                %fprintf("Distancia mínima entre satélite %d y %d: %.1f m\n", i, j, dMin);
            end
        end
    end
    fprintf("Distancia mínima entre satélite %d y %d: %.1f m\n", satmin1, satmin2, globaldMin);

    satellites = loadSatellitesFromTLEfile(sc, cleanedFile);
    numSatellitesLoaded = numel(satellites);
    fprintf("Se cargaron %d satélites desde %s\n", numSatellitesLoaded, cleanedFile);
else
    error("El archivo %s no existe.", cleanedFile);
end

fprintf("Iniciando Satellite Viewer\n");
%v = satelliteScenarioViewer(sc,"ShowDetails",false);
v = satelliteScenarioViewer(sc);
sc.AutoSimulate = true;

%% Esconder Labels

for idxSat=1:numel(satellites)
    satellites(idxSat).ShowLabel=0;
    fprintf('%d ', idxSat); fprintf(' ');
end; fprintf('\n');

%% Mostrar Labels

for idxSat=1:numel(satellites)
    satellites(idxSat).ShowLabel=1;
    fprintf('%d ', idxSat); fprintf(' ');
end; fprintf('\n');


%% FUTURE APLICATIONS:

% Analyze NTN Coverage and Capacity for LEO Mega-Constellation
% Calculate Latency and Doppler in a Satellite Scenario
% Multi-Hop Path Selection Through Large Satellite Constellation
% Interference from Satellite Constellation on Communications Link

% NB-IoT NTN Link Budget Analysis

 