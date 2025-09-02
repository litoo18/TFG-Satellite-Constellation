function [idxBest, score, scoreMin2Max] = gaEvaluateParetoFront(fval, weights, ...
    globalCovMin, globalCovMax, costMin, costMax, gdopMin, gdopMax)
% fval: matriz Nx3 [GlobalCoverage, cost, GDOP95]
% weights: vector [w1, w2, w3], pesa los objetivos para scalarización final
% Los *_Min y *_Max definen los rangos de normalización de cada objetivo

    % Filtra: marca como NaN las filas fuera de rango
    mask_inrange = ...
        (fval(:,1) >= globalCovMin & fval(:,1) <= globalCovMax) & ...
        (fval(:,2) >= costMin     & fval(:,2) <= costMax)      & ...
        (fval(:,3) >= gdopMin     & fval(:,3) <= gdopMax);

    fval_filtered = fval;
    fval_filtered(~mask_inrange, :) = NaN;

    % Normalización al rango [0, 1] sobre valores filtrados
    GC_norm    = (fval_filtered(:,1) - globalCovMin) / (globalCovMax - globalCovMin);
    cost_norm  = (fval_filtered(:,2) - costMin) / (costMax - costMin);
    GDOP95_norm= (fval_filtered(:,3) - gdopMin) / (gdopMax - gdopMin);

    GC_norm    = min(max(GC_norm, 0), 1);
    cost_norm  = min(max(cost_norm, 0), 1);
    GDOP95_norm= min(max(GDOP95_norm, 0), 1);

    % Si maximizas cobertura, invierte: todo es a minimizar
    % GC_inv = 1 - GC_norm;
    GC_inv = GC_norm;
    fval_norm = [GC_norm, cost_norm, GDOP95_norm];
    fval_norm_mod = [GC_inv, cost_norm, GDOP95_norm];

    % Scalarización ponderada
    score = fval_norm_mod * weights(:);

    % Asigna NaN en score a las filas no válidas
    score(~mask_inrange) = NaN;

    % Índice de la mejor solución (menor score, ignorando NaNs)
    if all(isnan(score))
        idxBest = [];
    else
        [~, idxBest] = min(score);
    end

    % % Ordena score respecto a la 1a columna (de menor a mayor)
    % [~, idxSort] = sort(score(:,1));
    % scoreMin2Max = score(idxSort, :);
    % scoreMin2Max(:,4) = idxSort(:);

    % Filtra los valores de score que no son NaN
    validMask    = ~isnan(score);
    validScores  = score(validMask);
    validIndices = find(validMask); % índices originales
    
    % Ordena los scores válidos y los índices asociados
    [sortedScores, sortIdx] = sort(validScores);
    sortedIndices = validIndices(sortIdx);
    
    % Crea la matriz: columna 1 = score ordenado, columna 2 = índice original
    scoreMin2Max = [sortedScores, sortedIndices];

end