function [Y] = getY(nDots, matrixSize)
    % Determine corresponding Y coordinate:
    %     temp  = ((matrix_size/2)^2 - X.^2 ).^0.5;
    %     Y  =  rand(nDots,1).*temp*2-temp;

    Y  =  rand(nDots, 1) * matrixSize - matrixSize / 2;
end
