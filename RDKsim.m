% Simulates a RDK and estimates the density of the dots over a desired number of frames

clear;
close all;
clc;

% ANIMATIONS DETAILS
% number of animation frames in loop
nframes = 100000;
log_ndots = zeros(1, nframes);

% SCREEN DETAILS
% Pixel per degree on a 39 cm wide screen seen at a 60 cm distance
ppd =  53;
% Frame per seconds on a "normal" screen
fps = 60;

matrix_size = 800;

cfg = config();

% DOTS DETAILS
% dots per degree^2
dot_density = cfg.dot_density;
% max dot speed (deg/sec)
dot_speed   = cfg.dot_speed;
% width of dot (deg)
dot_w = cfg.dot_w;
% fraction of dots to kill each frame (limited lifetime)
fraction_kill = cfg.fraction_kill;
% Amount of coherence
coherence = cfg.coherence;
% 0 gives right, 90 gives down, 180 gives left and 270 up.
angle_motion = cfg.angle_motion;
% decompose angle of motion into horizontal and vertical vector
hor_vector = cos(pi * angle_motion / 180);
vert_vector = sin(pi * angle_motion / 180);

aperture_width = cfg.aperture_width;

% Initialise the other variables

% To collect dots density
B = zeros(matrix_size);

% report the iteration number
report = ceil(nframes / 10);

% Radius of the RDK
r = matrix_size / 2;

% dot speed (pixels/frame)
pfs  =  dot_speed * ppd / fps;

% dot size (pixels)
s  =  dot_w * ppd;

% Number of dots : surface of the RDK disc * density of dots
nDots  =  getNumberDots(dot_w, matrix_size, dot_density, ppd);

% Decide which dots are signal dots (1) and those are noise dots (0)
dot_nature  =  rand(nDots, 1) < coherence;

%% initialize dots
% Dot positions and speed matrix : colunm 1 to 5 gives respectively
% x position, y position, x speed, y speed, and distance of the point the RDK center
xy = zeros(nDots, 5);

[X] = getX(nDots, matrix_size);
[Y] = getY(nDots, matrix_size, X);

xy(:, 1) =  X;
xy(:, 2) =  Y;
clear X Y;

% Gives a pre determinded horizontal and vertical speed to the signal dots
xy(dot_nature, 3:4) = ...
    repmat([hor_vector vert_vector], [sum(dot_nature), 1]) * pfs;

% Gives a random horizontal and vertical speed to the other ones
xy(~dot_nature, 3:4) =  randn(sum(~dot_nature), 2) * pfs;

% calculate distance from matrix center for each dot
[~, R] =  cart2pol(xy(:, 1), xy(:, 2));
xy(:, 5) =  R;

aperture_x  = [-400 -400 + aperture_width];

for i = 1:nframes
    if mod(i, report) == 0 % To know how far in the loop we are
        disp(i);
    end

    % Finds if there is dots to reposition because out of the RDK
    xy = dotsROut(xy, matrix_size);

    % Kill some dots and ressed them at random position
    xy = dotsReseed(nDots, fraction_kill, matrix_size, xy);

    % calculate distance from matrix center for each dot
    [~, R] =  cart2pol(xy(:, 1), xy(:, 2));
    xy(:, 5) =  R;

    % find the dots that are within the aread and only pass those to be
    % plotted
    r_in  = xy(:, 5) <= matrix_size / 2;

    xy_matrix =  xy(r_in, 1:2);

    % convert to pixel
    xy_matrix = floor(xy_matrix + matrix_size / 2 + 1);

    % update matrix that keeps track of dots density
    ind = sub2ind(size(B), xy_matrix(:, 2), xy_matrix(:, 1));
    B(ind) = B(ind) + 1;

    % Move the dots
    xy(:, 1:2) =  xy(:, 1:2) + xy(:, 3:4);

    % track numbe of dots on screen
    log_ndots(i) = numel(ind);

end

subplot (311);
[X, Y] = meshgrid(1:matrix_size, 1:matrix_size);
mesh(X, Y, B);
title('dot density');

subplot (312);
imagesc(B);
axis square;
title('dot density');

subplot (313);
plot(log_ndots);
title('dots per frame');
