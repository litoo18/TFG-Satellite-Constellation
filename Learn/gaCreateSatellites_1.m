function [cHybrid, numSats] = gaCreateSatellites_1(e, w, Pws, Sws, Iws, Aws, Pwd, Swd, Iwd, Awd, Fwd)

        % --- Generar satélites Walker Star ---
        satCount = 0;
        el_star = zeros(Pws*Sws, 6);  % [a e i RAAN w TA]
        Mws = pi / Sws;               % Intervalo de fase entre planos
        
        for j = 0:Pws-1               % Para todos los planos desde 0
            RAAN_ws = mod(rad2deg(pi/Pws * j), 360); 
            for k = 0:Sws-1
                Mwsjk = mod(rad2deg(2*(pi/Sws)*(j) + Mws*k), 360);
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
        cHybrid = [el_star; el_delta];  % Matriz N x 6 de elementos orbitales
        numSats = size(cHybrid,1);
end