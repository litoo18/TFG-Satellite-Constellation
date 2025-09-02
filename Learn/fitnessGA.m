function score = fitnessGA(satParams, ue, rx, sc, sampleTime)
% FITNESSGA Evalúa la cobertura de una configuración satelital sobre UEs
%   satParams: vector de variables [alt1, inc1, RAAN1, ..., altN, incN, RAANN]
%   ue, rx: estaciones base y receptores (de generateUEs)
%   sc: escenario satelital (satelliteScenario)
%   sampleTime: resolución temporal en segundos
%
%   score: porcentaje de UEs cubiertos durante el 80% del tiempo o más

%% 1. Preparar
delete(satellite(sc)); % Borra satélites previos

nSat = length(satParams) / 3;
altitudes = satParams(1:3:end);     % km
inclinations = satParams(2:3:end);  % deg
RAANs = satParams(3:3:end);         % deg

%% 2. Añadir satélites al escenario
sats = satellite.empty;
for i = 1:nSat
    sats(i) = satellite(sc, ...
        semiMajorAxis = 6371e3 + altitudes(i)*1e3, ...
        eccentricity = 0, ...
        inclination = inclinations(i), ...
        rightAscensionOfAscendingNode = RAANs(i), ...
        argumentOfPeriapsis = 0, ...
        trueAnomaly = 0, ...
        Name = "Sat" + i);
    
    transmitter(sats(i), ...
        Frequency = 2e9, ...
        Power = 20, ...
        SystemLoss = 0, ...
        BitRate = 10, ...
        Antenna = arrayConfig(Size=[1 1]));
end

%% 3. Calcular accesos
accesses = access(sats, rx);
updateResults(accesses); % Espera a que calcule

%% 4. Métrica: porcentaje de UEs cubiertos el 80% del tiempo
nUE = numel(rx);
coverageRatio = zeros(1, nUE);

for i = 1:nUE
    ueAccess = accesses(:, i);
    totalCovered = false(size(sc.SimulationTime));

    for j = 1:numel(ueAccess)
        intervals = accessIntervals(ueAccess(j));
        if isempty(intervals)
            continue
        end

        for k = 1:height(intervals)
            t1 = seconds(intervals.StartTime(k) - sc.StartTime);
            t2 = seconds(intervals.StopTime(k) - sc.StartTime);
            idx1 = max(1, round(t1/sampleTime) + 1);
            idx2 = min(length(totalCovered), round(t2/sampleTime) + 1);
            totalCovered(idx1:idx2) = true;
        end
    end

    coverageRatio(i) = mean(totalCovered);
end

%% 5. Score: proporción de UEs con cobertura >= 80%
score = sum(coverageRatio >= 0.8) / nUE;

% Opcional: penalización por exceso de satélites o altitudes bajas
penalty = 0.01 * sum(altitudes < 500);  % Penaliza órbitas demasiado bajas
score = score - penalty;

% Negar para minimizar en GA (si usas ga() de MATLAB, busca máximo → -score)
score = -score;
end
