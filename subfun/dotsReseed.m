function xy = dotsReseed(nDots, fractionKill, matrixSize, xy)
rReseed = rand(nDots,1) < fractionKill;
if any(rReseed)
    X = getX(sum(rReseed), matrixSize);
    Y = getY(sum(rReseed), matrixSize, X);
    
    xy(rReseed,1) =  X;
    xy(rReseed,2) =  Y;
    
end
end