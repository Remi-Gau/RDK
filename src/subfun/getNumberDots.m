function nDots = getNumberDots(dotWidth, matrixSize, dotDensity, ppd)
    % Number of dots : surface of the RDK disc / surface of one dot * density of dots
    % matrix_size
    nDots = ceil(pi * (matrixSize / 2 / ppd)^2 / (pi * (dotWidth / 2)^2) * dotDensity);
    if nDots < 10
        nDots = 10;
    end
end
