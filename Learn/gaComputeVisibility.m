function [GlobalCoverage, MinimumCoverage, perUserVis, satECEF, elevMatrix] = gaComputeVisibility(cHybrid, ue_lla,timeVect,minElevationAngle)
        numUEs = length(ue_lla); 
        numTS = numel(timeVect);
        numSats = size(cHybrid,1);

        % Creacion de Matrices
        % visibilityMatrix = zeros(numUEs, numTS); 
        visMatrix = zeros(numSats,numUEs,numTS);
        azMatrix = zeros(numSats,numUEs,numTS);
        elevMatrix = zeros(numSats,numUEs,numTS);

        % timeVect -> vector (datetime o segundos) de tus instantes de propagación
        % cHybrid(i,:) -> [a, e, i, RAAN, argp, trueAnomaly] de cada satélite
        
        satECEF = zeros(3, numTS, numSats); % [3 x tiempo x sats]
        
        for k = 1:numSats
            a    = cHybrid(k,1); % (semi-eje mayor)
            e    = cHybrid(k,2); % (excentricidad) 
            incl = cHybrid(k,3); % (inclinación)
            RAAN = cHybrid(k,4); % (Right Ascension of the Ascending Node)
            argp = cHybrid(k,5); % (argumento del periapsis)
            nu   = cHybrid(k,6); % 
            % (anomalía verdadera): ángulo que indica la posición actual del 
            % satélite en su órbita en relación con el periapsis, es decir, 
            % cuánto ha avanzado alrededor de la órbita desde el periapsis.

        
            % Propagación de SATELITES en modo SGP4 (recomendado para LEO)
            [pos,~] = propagateOrbit(timeVect, a, e, incl, RAAN, argp, nu, ...
                             OutputCoordinateFrame="fixed-frame"); % Posición ECEF de cada satélite para cada instante de tiempo
            % Guarda en el arreglo completo PropModel="sgp4",
            satECEF(:,:,k) = pos;
        end

        % Cálculo del ángulo de elevación con respecto a cada ground station
        for t = 1:numTS
            for k = 1:numSats
                pos_sat = satECEF(:,t,k)'; % [x y z] en ECEF, metros
                for j = 1:numUEs
                    % gsLat(j), gsLon(j), gsAlt(j): coords de la estación
                    [az, elev, vis] = lookangles(ue_lla(j,:), pos_sat, minElevationAngle); % gsLat(j), gsLon(j), gsAlt(j)
                    elevMatrix(k, j, t) = elev; % Guarda elevación
                    azMatrix(k, j, t) = az; % Guarda azimuth
                    visMatrix(k, j, t) = vis; % Guarda visibilidad
                end
            end
        end
        % --- elevMatrix, azMatrix y visMatrix (sats x users x tiempos) ---
        
        % Para cada GS y TS, Condición conjunta: elevación suficiente + visibilidad real
        validCoverage = (elevMatrix >= minElevationAngle) & (visMatrix == 1); % (sats x users x tiempos)
        
        % Luego, aplicas el "any" sobre los satélites
        visibilityMatrix = squeeze(any(validCoverage, 1)); % (users x tiempos)
        
        % Paso 2: Calcula el porcentaje de tiempo cubierto por cada GS
        perUserVis = mean(visibilityMatrix, 2); % (users x 1): % del tiempo cubierta cada GS
        
        GlobalCoverage = mean(perUserVis); % Porcentaje medio de cobertura de todos los UEs
        MinimumCoverage = min(perUserVis); % Porcentaje de Cobertura del peor UE.

end