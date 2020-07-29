function [X] = getX(nDots, matrixSize)
    % Gives random position to the dots in x and y
    X  =  rand(nDots, 1) * matrixSize - matrixSize / 2;
end
