function [contour, contour_idx] = contour_extract(image, category)
    % size of input image
    [H, W] = size(image);
    % Initialize empty contour images
    contour = zeros(H, W);
    contour_idx = NaN(H, W);
    % Initialize weight kernel
    kernel = [ 8,  4,   2;
              16,  0,   1;
              32, 64, 128];
    % Padded image
    image_og = padarray(image, [1 1], 0, 'both');

    % For loop to extract contour
    for i = 2 : (H + 1)
        for j = 2 : (W + 1)
            % If background pixel, continue
            if ~image_og(i, j)
                continue
            end
            % Extract sliding window
            sliding_window = capture(i, j, image_og);
            idx = sum(kernel .* sliding_window, 'all');
            [image_og, contour, contour_idx] = determine_pt(i, j, idx, kernel, category, image_og, contour, contour_idx);
        end
    end
end

function [image_og, contour, contour_idx] = determine_pt(i, j, idx, kernel, category, image_og, contour, contour_idx)
    % If background pixel, return 
    if image_og(i, j) == 0
        return
    % Else if no index, calculate
    elseif isnan(idx)
        sliding_window = capture(i, j, image_og);
        idx = sum(kernel .* sliding_window, 'all');
    end
    % Determine category
    % Interior point
    if category(idx + 1) == 1
        % do nothing
    % Noise point
    elseif category(idx + 1) == 2
        image_og(i, j) = 0;
        [image_og, contour, contour_idx] = determine_pt(i-1, j-1, contour_idx(i-1, j-1), kernel, category, image_og, contour, contour_idx);
        [image_og, contour, contour_idx] = determine_pt(i-1, j, contour_idx(i-1, j), kernel, category, image_og, contour, contour_idx);
        [image_og, contour, contour_idx] = determine_pt(i-1, j+1, contour_idx(i-1, j+1), kernel, category, image_og, contour, contour_idx);
        [image_og, contour, contour_idx] = determine_pt(i, j-1, contour_idx(i, j-1), kernel, category, image_og, contour, contour_idx);
    % Contour point
    elseif category(idx + 1) == 3
        contour(i-1, j-1) = 1;
        contour_idx(i-1, j-1) = idx;
    end
end

function sliding_window = capture(i, j, image)
    sliding_window = image((i-1):(i+1), (j-1):(j+1));
end