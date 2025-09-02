function [idxBest, score, fval_norm] = evaluateParetoFront(fval, weights, ...
    globalCovMin, globalCovMax, costMin, costMax, gdopMin, gdopMax)
% fval: matriz Nx3 [GlobalCoverage, cost, GDOP95]
% weights: vector [w1, w2, w3], pesa los objetivos para scalarización final
% Los *_Min y *_Max definen los rangos de normalización de cada objetivo


    % Normalización al rango [0, 1] con tus valores de referencia
    GC_norm    = (fval(:,1) - globalCovMin) / (globalCovMax - globalCovMin);
    cost_norm  = (fval(:,2) - costMin) / (costMax - costMin);
    GDOP95_norm= (fval(:,3) - gdopMin) / (gdopMax - gdopMin);
    
    % Control de posibles valores fuera de [0,1] (por seguridad)
    GC_norm    = min(max(GC_norm, 0), 1);
    cost_norm  = min(max(cost_norm, 0), 1);
    GDOP95_norm= min(max(GDOP95_norm, 0), 1);

    % Si maximizas cobertura, invierte: todo es a minimizar
    GC_inv = 1 - GC_norm;
    
    % Vector final para scalarización
    fval_norm = [GC_norm, cost_norm, GDOP95_norm];
    fval_norm_mod = [GC_inv, cost_norm, GDOP95_norm];

    % Scalarización ponderada
    score = fval_norm_mod * weights(:);

    % Índice de la mejor solución (menor score)
    [~, idxBest] = min(score);
end
