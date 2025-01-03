clc; clear; close all;
addpath("./utils/");
addpath("./matfile")

%% Preprocessing
path="image/";
filename= "b_zuo.png";
% Input data
image = double(imread(path + filename)) / 255;
% Binarization
im_R = image(:, :, 1);
im_G = image(:, :, 2);
im_B = image(:, :, 3);
grayscale = 0.299 * im_R + 0.587 * im_G + 0.114 * im_B;
% Thresholding 
image = grayscale > (160 / 255);
% Inverting
image = double(bitxor(image, 1));
figure; imshow(image);

%% Contour Tracing 
load("lookup.mat");
[contour, contour_idx] = contour_extract(image, category);
[directed_graph, contour_set] = contour_tracing(contour, contour_idx, direction);
figure; imshow(contour);

%% Corner detection
[corners, ~] = corner_detection(contour_set);
figure; imshow(visualize(corners, contour, 'R', 1));

%% CSSG
[segments, length] = contour_segment(corners, contour_set);
BW = logical(contour);
% Plug-ins
Orientations = skeleton_orientation(BW,5); %5x5 box tangent_dir
Onormal = Orientations+90; %easier to view normals
Onr = sind(Onormal); %vv
Onc = cosd(Onormal); %uu
[r,c] = find(BW);    %row/cols
idx = find(BW);      %Linear indices into Onr/Onc
figure; imshow(BW,[]);
% Overlay normals to verify
hold on
quiver(c,r,-Onc(idx),Onr(idx));

% Suppress noise segments.
cssg = construct_cssg(segments, length, Onr, -Onc, Orientations, contour, char(filename));
figure; imshow(contour);
for i = 1 : size(cssg, 2)
    for j = 1 : size(cssg{i}, 2)
        if isempty(cssg{i}{j})
            continue
        else
            target = cssg{i}{j};
            hold on;
            line([target(1, 2), target(2, 2)], [target(1, 1), target(2, 1)], 'LineWidth', 3)
        end
    end
end

%% Segments pairing and extraction
strokes = segment_pairing(segments, cssg, length); 
im_strokes = zeros(size(image));
for i = 1 : size(strokes, 2)
    for j = 1 : size(strokes{i}, 1)
        im_strokes(strokes{i}(j, 1), strokes{i}(j, 2)) = 1;
    end
end
figure; imshow(im_strokes);

%% Stroke Matching
load("zuo.mat");
load("b_zuo.mat");
n = size(strokes, 2);
[H, W] = size(image);
[b_H, b_W] = size(b_image);
features = zeros(n, 12);
b_features = zeros(n, 12);
im = zeros(H, W);
b_im = zeros(b_H, b_W);
for i = 1 : n
    for j = 1 : size(strokes{i}, 1)
        im(strokes{i}(j, 1), strokes{i}(j, 2)) = 1;
    end
    for j = 1 : size(strokes{i}, 1)
        b_im(strokes{i}(j, 1), strokes{i}(j, 2)) = 1;
    end
end
figure; imshow(im);
figure; imshow(b_im);
xy_coord = zeros(n, 6);
b_xy_coord = zeros(n, 6);
for i = 1 : n
    midpt = floor((1 + size(strokes{i}, 1)) / 2);
    b_midpt = floor((1 + size(strokes{i}, 1)) / 2);
    % Normalized to base image
    xy_coord(i, 1 : 6) = [strokes{i}(1, 1), strokes{i}(1, 2), ...
                        strokes{i}(midpt, 1), strokes{i}(midpt, 2), ...
                        strokes{i}(end, 1), strokes{i}(end, 2)];
    b_xy_coord(i, 1 : 6) = [strokes{i}(1, 1), strokes{i}(1, 2), ...
                        strokes{i}(b_midpt, 1), strokes{i}(b_midpt, 2), ...
                        strokes{i}(end, 1), strokes{i}(end, 2)];
end

%% Normalized Location
features(:, 1 : 6) = xy_coord ./ [H, W, H, W, H, W];
b_features(:, 1 : 6) = b_xy_coord ./ [b_H, b_W, b_H, b_W, b_H, b_W];

%% Ratio
total = sum(im, "all");
b_total = sum(b_im, "all");
for i = 1 : n
    features(i, 7) = size(strokes{i}, 1) / total;
    b_features(i, 7) = size(strokes{i}, 1) / b_total;
end

%% Direction
for i = 1 : n
    [~, features(i, 8)] = find_dir([xy_coord(i, 1), xy_coord(i, 2)], [xy_coord(i, 3), xy_coord(i, 4)], im);
    [~, features(i, 9)] = find_dir([xy_coord(i, 3), xy_coord(i, 4)], [xy_coord(i, 5), xy_coord(i, 6)], b_im);
    [~, b_features(i, 8)] = find_dir([b_xy_coord(i, 1), b_xy_coord(i, 2)], [b_xy_coord(i, 3), b_xy_coord(i, 4)], im);
    [~, b_features(i, 9)] = find_dir([b_xy_coord(i, 3), b_xy_coord(i, 4)], [b_xy_coord(i, 5), b_xy_coord(i, 6)], b_im);
end

%% Weighted contour
rd = [(H + W) / 12, (H + W) / 8, (H + W) / 4];
pos = [1, 3, 5];
weights = [1, 0.7, 0.3];
for i = 1 : n
    for j = 1 : 3
        for r = 1 : H
            for c = 1 : W
                if euclidean_dist([r, c], [xy_coord(i, pos(j)), xy_coord(i, pos(j)+ 1)]) <= rd(j)
                    features(i, j + 9) = features(i, j + 9) + weights(j) * image(r, c);
                end
            end
        end
        % Normalize
        features(i, j + 9) = features(i, j + 9) / (sum(image, 'all') * weights(j));
        for r = 1 : b_H
            for c = 1 : b_W
                if euclidean_dist([r, c], [b_xy_coord(i, pos(j)), b_xy_coord(i, pos(j) + 1)]) <= rd(j)
                    b_features(i, j + 9) = b_features(i, j + 9) + weights(j) * b_image(r, c);
                end
            end
        end
        % Normalize
        b_features(i, j + 9) = b_features(i, j + 9) / (sum(b_image, 'all') * weights(j));
    end
end

%% MSE
match = [1 : n; zeros(1, n)];
for i = 1 : n
    mn = inf;
    for j = 1 : n
        % MSE
        mse = sum((b_features(i, :) - features(j, :)) .^ 2) / 12;
        if mse < mn
            mn = mse;
            match(2, i) = j;
        end
    end
end

%% Visualize result
result = zeros(max(H, b_H), max(W, b_W), 3);
for i = 1 : n
    for j = 1 : size(strokes{i}, 1)
        result(strokes{i}(j, 1), strokes{i}(j, 2), 1) = 255;
        result(strokes{i}(j, 1), strokes{i}(j, 2), 2) = 255;
        result(strokes{i}(j, 1), strokes{i}(j, 2), 3) = 255;
    end
    for k = 1 : size(b_strokes{i}, 1)
        result(b_strokes{i}(k, 1), b_strokes{i}(k, 2), 1) = 255;
        result(b_strokes{i}(k, 1), b_strokes{i}(k, 2), 2) = 0;
        result(b_strokes{i}(k, 1), b_strokes{i}(k, 2), 3) = 0;
    end
end
figure; imshow(result);