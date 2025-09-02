function analyzeTLEorbits(tleFile, nSats, durationSec, stepSec)
    % Leer datos TLE
    sats = tleread(tleFile);

    % Asegurarse de que se seleccionen nSats satélites
    if nSats > numel(sats)
        error("El archivo TLE contiene menos de %d satélites", nSats);
    end
    sats = sats(1:nSats);

    % Crear vector de tiempo como datetime en UTC
    startTime = sats(1).Epoch;  % Epoch del primer satélite
    tVec = startTime + seconds(0:stepSec:durationSec);  % Vector de datetime

    % Recorrer los satélites y propagar sus órbitas
    figure;
    hold on;
    for i = 1:nSats
        sat = sats(i);

        % Propagar órbita con modelo numérico en el marco ECI
        state = propagateOrbit(tVec, sat, ...
             "CoordinateFrame", "eci", ...
             "PropModel", "numerical");


        % Extraer posición para graficar (x, y, z)
        pos = state.Position;

        % Graficar la órbita del satélite
        plot3(pos(1, :), pos(2, :), pos(3, :), 'DisplayName', sat.Name);
    end

    % Ajustes de la gráfica
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    zlabel('Z [m]');
    legend;
    title('Trayectorias de los satélites propagadas');
    axis equal;
    hold off;
end
