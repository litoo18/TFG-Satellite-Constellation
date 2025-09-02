function mission = gaCreateScenario(startTime, stopTime, sampleTime, minEle, ue_lla, results)

    latUE = ue_lla(:,1); lonUE = ue_lla(:,2);
    mission.Scenario = satelliteScenario(startTime, stopTime, sampleTime);
    mission.sc = satelliteScenarioViewer(mission.Scenario);
    mission.Targets = groundStation(mission.Scenario, latUE, lonUE, MinElevationAngle=minEle);

    % WalkerStar Phasing
    Fws=results.x.Pws-1;
    %Fws=1;

    %% rxConfig
    rxConfig = struct;
    rxConfig.MaxGByT = -5;        % Maximum gain-to-noise-temperature in dB/K
    rxConfig.SystemLoss = 0;      % Receiver system loss in dB
    rxConfig.PreReceiverLoss = 0; % Pre-receiver loss in dB
    rxConfig.RequiredEbNo = 11;   % Required bit energy to noise power spectral density ratio in dB
    
    % Add the receiver antenna to the ground stations
    isotropic = arrayConfig(Size=[1 1]);
    rx = receiver(mission.Targets,Antenna=isotropic, ...
        SystemLoss=rxConfig.SystemLoss, ...
        PreReceiverLoss=rxConfig.PreReceiverLoss, ...
        GainToNoiseTemperatureRatio=rxConfig.MaxGByT);

    % Create constellations
    mission.Constellation.WalkerDelta = walkerDelta(mission.Scenario,results.x.Awd,...
     results.x.Iwd,results.x.Swd*results.x.Pwd,results.x.Pwd,results.x.Fwd,Name="wD");
    
    mission.Constellation.WalkerStar = walkerStar(mission.Scenario,results.x.Aws,...
        results.x.Iws,results.x.Sws*results.x.Pws,results.x.Pws,Fws,Name="wS"); % Mws used here


end