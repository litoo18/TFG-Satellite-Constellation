function summary = summarizeTLEcompact(filename)
    lines = readlines(filename);
    lines = strip(lines);

    inclinations = [];
    eccentricities = [];
    meanMotions = [];
    epochs = [];

    % Tomar el nombre del primer satélite como nombre de constelación
    constellationName = strtrim(lines(1));

    for i = 1:3:length(lines)
        if i+2 > length(lines), break; end
        l1 = lines(i+1);
        l2 = lines(i+2);

        % Epoch
        yy = str2double(extractBetween(l1, 19, 20));
        dd = str2double(extractBetween(l1, 21, 32));
        yyyy = yy + (yy < 57)*2000 + (yy >= 57)*1900;
        epochs(end+1) = datenum(datetime(yyyy, 1, 0) + days(dd));

        % Orbital elements
        inclinations(end+1) = str2double(extractBetween(l2, 9, 16));
        eccStr = extractBetween(l2, 27, 33);
        eccentricities(end+1) = str2double("0." + eccStr);
        mm = str2double(extractBetween(l2, 53, 63));
        meanMotions(end+1) = mm;
    end

    % Cálculos
    periods = 1440 ./ meanMotions;  % min
    heights = ((398600.4418 * (periods .* 60).^2) / (4*pi^2)).^(1/3) - 6371; % km

    % Resultado
    summary.Constellation          = constellationName;
    summary.NumSatellites          = numel(inclinations);
    summary.Inclination_mean       = mean(inclinations);
    summary.Eccentricity_mean      = mean(eccentricities);
    summary.OrbitalPeriod_mean_min = mean(periods);
    summary.Altitude_mean_km       = mean(heights);
    summary.Epoch_mean             = datetime(mean(epochs), 'ConvertFrom', 'datenum');
end
