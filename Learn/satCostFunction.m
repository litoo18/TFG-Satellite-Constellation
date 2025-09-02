function cost = satCostFunction(N, ThN)
    if N <= ThN
        cost = exp(0.001*N + 1);
    else
        cost = exp(0.007*N) - (exp(0.007*ThN) - exp(0.001*ThN + 1));
    end
end