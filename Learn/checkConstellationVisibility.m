    function [meanVisibility, perUserVisibility, passed] = checkConstellationVisibility(sc, constellation, groundStations, minObservability)
% Verifica si la constelación cumple con un nivel mínimo de visibilidad
% usando análisis de acceso real.
%
% Inputs:
%   sc                - satelliteScenario ya creado y simulado
%   constellation     - vector de objetos Satellite ya añadidos al escenario
%   groundStations    - vector de objetos GroundStation
%   minObservability  - umbral mínimo (0-1) de visibilidad media por UE
%
% Outputs:
%   meanVisibility     - visibilidad promedio de todos los UEs
%   perUserVisibility  - vector con visibilidad media por UE
%   passed             - true si se cumple el mínimo para todos los UEs
    sc.AutoSimulate = false;
    numUEs = numel(groundStations);
    perUserVisibility = zeros(numUEs,1);

    % Analizar accesos reales por cada UE
    for i = 1:numUEs
        acc = access(constellation, groundStations(i));
        status = accessStatus(acc); % matriz: [sat x time]
        systemAccess = any(status,1); % al menos 1 sat visible en cada instante
        perUserVisibility(i) = mean(systemAccess);
    end

    % Calcular promedio global
    meanVisibility = mean(perUserVisibility);
    passed = all(perUserVisibility >= minObservability);

    % Mostrar resultados
    if passed
        fprintf("✅ La constelación CUMPLE con minObservability = %.2f\n", minObservability);
    else
        fprintf("❌ La constelación NO cumple. Mínimo observado: %.2f\n", min(perUserVisibility));
        fprintf("❌ Mean visibility: %.2f\n", meanVisibility);

    end

    sc.AutoSimulate = true;
end
