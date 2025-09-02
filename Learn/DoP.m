function[HDOP, VDOP, PDOP, TDOP, GDOP] = DoP(H, sta_lat, sta_long)

epsilon = 1e-6; % Umbral de tolerancia
validRows = vecnorm(H, 2, 2) > epsilon;  % Devuelve un vector lógico
numValid = sum(validRows);

if (numValid<4) % CONDICIÓN NECESARIA, PONER NaN o VALOR ALTO 100
    HDOP = 1000;
    VDOP = 1000;
    PDOP = 1000;
    TDOP = 1000;
    GDOP = 1000;
else
    landa=deg2rad(sta_long);
    phi=deg2rad(sta_lat);

    R=[-sin(phi)*cos(landa) -sin(phi)*sin(landa) cos(phi) 0
    -sin(landa) cos(landa) 0 0
    -cos(phi)*cos(landa) -cos(phi)*sin(landa) -sin(phi) 0
    0 0 0 1];

    R(abs(R) < 1e-12) = 0;
    
    Qprev = ((H')*H);
    Q = pinv(Qprev);  % O mejor aún, usa chol o svd
    Qprima = R * Q * R';

    qnn = Qprima(1,1);
    qee = Qprima(2,2);
    qdd = Qprima(3,3);
    qctct = Qprima(4,4);

    % % Evita valores negativos numéricamente inestables, NO ME HA HECHO FALTA
    % qnn1 = max(qnn, 0);
    % qee1 = max(qee, 0);
    % qdd1 = max(qdd, 0);
    % qctct1 = max(qctct, 0);
    
    HDOP = sqrt(qnn+qee);
    VDOP = sqrt(qdd);
    PDOP = sqrt(qnn+qee+qdd);
    TDOP = sqrt(qctct);
    GDOP = sqrt((PDOP)^2+(TDOP)^2);
end

end