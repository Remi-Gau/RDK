function a = convPolAngle(a)
    % a = rem(a,2*pi);
    a = a / pi * 180;
    a(a < 0) = 360 + a(a < 0);
end
