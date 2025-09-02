 function [factor1,factor2] = findClosestFactors(n)
 % This function finds the two factors of n that are closest to each other
 % Initialize the factors from 1 and n
factor1 = 1;
factor2 = n;
 % Loop through possible factors up to the square root of n
 for i = round(sqrt(n)):-1:1
 if mod(n,i) == 0  % If i is a factor
        factor1 = i;
        factor2 = n/i;
 break % Exit the loop as you find the closest factors
 end
 end
 end