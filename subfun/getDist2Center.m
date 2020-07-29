function xy = getDist2Center(xy)

    [~, R] = cart2pol(xy(:, 1), xy(:, 2));
    xy(:, 5) = R;

end
