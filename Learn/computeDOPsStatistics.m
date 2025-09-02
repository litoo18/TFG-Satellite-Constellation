function [stats, DOP95] = computeDOPsStatistics(allDOPs,selectedDOP)

    meanValue = mean(allDOPs(:,:,selectedDOP),1); % Mean value for each UE in all TS
    minValue = min(meanValue); % Min value out of all UEs


    dopVals = squeeze(allDOPs(:,:,selectedDOP)); % [timeStamps x numUEs]

    meanPerUE = mean(dopVals,1);   % Media de GDOP para cada UE
    maxPerUE  = max(dopVals,[],1); % Máximo de GDOP para cada UE
    minPerUE  = min(dopVals,[],1); % Mínimo de GDOP para cada UE

    stats.meanPerUE      = meanPerUE;
    stats.maxPerUE       = maxPerUE;
    stats.minPerUE       = minPerUE;
    stats.globalMean     = mean(meanPerUE);   % Media global (todos usuarios)
    stats.globalMax      = max(maxPerUE);     % El peor caso posible
    stats.percentile95   = prctile(meanPerUE,95);
    DOP95                = stats.percentile95;
end