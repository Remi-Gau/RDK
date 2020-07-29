function xy = getDistToCenter(xy)

    [~, R] = cart2pol(xy(:, 1), xy(:, 2));
    xy(:, 5) = R;

end
