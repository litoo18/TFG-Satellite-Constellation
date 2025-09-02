function results = gaCheckResults(x, minObs, timeVect, ue_lla, ue_xyz, minEle)

    % Parámetros orbitales fijos
    e = 0; w = 0; % Eccentricity & Argument of perigee

    % Walker Star
    Pws = round(x(1));      Sws = round(x(2));
    Iws = x(3);             Aws = alt2radius(x(4));
    % Walker Delta
    Pwd = round(x(5));      Swd = round(x(6));
    Iwd = x(7);             Awd = alt2radius(x(8));
    Fwd = round(x(9));      % Phasing (índice entero entre 0 y Pwd)

    % Guardar Variables
    results.x.Pws = Pws; results.x.Sws = Sws;
    results.x.Iws = Iws; results.x.Aws = Aws;
    results.x.Pwd = Pwd; results.x.Swd = Swd;
    results.x.Iwd = Iwd; results.x.Awd = Awd;
    results.x.Fwd = Fwd;

    % Crear constelación híbrida
    [cHybrid,numSats] = gaCreateSatellites(e, w, Pws, Sws, Iws, Aws, Pwd, Swd, Iwd, Awd, Fwd);

    % Calcular visibilidad geométrica por elevación
    [GlobalCoverage,MinCoverage,perUserVis,satECEF,elevMatrix] = gaComputeVisibility(cHybrid, ue_lla,timeVect,minEle);

%%  COMPUTE GDOP
    allDOPs = computeDOPs(satECEF,ue_xyz, ue_lla, elevMatrix);
    selectedDOP = 5; % 1HDOP, 2VDOP, 3PDOP, 4TDOP, 5GDOP
    [DOPstats, DOP95] = computeDOPsStatistics(allDOPs, selectedDOP); % Según selected DOP
    ThGDOP = 6;                % Threshold realista GDOP

%%  COMPUTE COSTS
    ThN = 350; % Threshold Satellites
    cost = satCostFunction(numSats, ThN);

    results.numSats = numSats;
    results.GlobalCoverage = GlobalCoverage;
    results.GDOPmax = DOPstats.globalMax;
    results.GDOP95 = DOP95;
    results.cost = cost;
    results.DOPstats = DOPstats;
    
end