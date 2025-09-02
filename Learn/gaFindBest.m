function [idxBest, valueBest, listBest] = gaFindBest(fval)
    % Encuentra el mínimo valor de la primera columna y su índice
    [minObs, idxObs] = min(fval(:,1));

    % Suma de cada fila
    sumRows = sum(fval, 2);
    idxSum = (1:size(fval,1))';
    sumRows = [sumRows, idxSum];
    % Filtra sumRows para solo valores menores o iguales a 1
    listBest = sumRows(sumRows(:,1) <= 1, :);

    % Encuentra el índice y valor mínimo de las sumas
    [valueBest, idxBest] = min(sumRows);

    % Ordena fval respecto a la 1a columna (de menor a mayor)
    [~, idxSort] = sort(fval(:,1));
    fval_minObs = fval(idxSort, :);
    fval_minObs(:,4) = idxSort(:);
end