function [xy] = dotsROut(xy, matrixSize)
    rOut  = xy(:, 5) > matrixSize / 2;
    % If there are we reset them at a diametrically opposite position
    if any(rOut)
        %             xy(r_out,1:2) = xy(r_out,1:2) * -1;

        X = getX(sum(rOut), matrixSize);
        Y = getY(sum(rOut), matrixSize, X);

        xy(rOut, 1) =  X;
        xy(rOut, 2) =  Y;

    end
end
