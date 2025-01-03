function [directed_graph, contour_set] = contour_tracing(contour, contour_idx, direction)
    % size of input image
    [H, W] = size(contour_idx);    
    % Initialize directed graph
    directed_graph = NaN(H, W);

    % For loop to trace the contour
    for i = 1 : size(contour_idx, 1)
        for j = 1 : size(contour_idx, 2)
            if isnan(contour_idx(i, j))
                continue
            end
            directed_graph(i, j) = direction(contour_idx(i, j) + 1);
        end
    end
    % Group the contours in cell
    contour_set = {};
    freeman_code = [0, 1; -1, 1; -1, 0; -1, -1; 0, -1; 1, -1; 1, 0; 1, 1];
    ref = contour;
    n = 1;
    while 1
        % Look for the first pixel
        [row_idx, col_idx] = find(ref, 1, 'first');
        if isempty([row_idx, col_idx])
            break
        end
        set = [];
        while ref(row_idx, col_idx)
            set = [set; row_idx, col_idx];
            ref(row_idx, col_idx) = 0;
            next_pos = directed_graph(row_idx, col_idx) + 1;
            row_idx = row_idx + freeman_code(next_pos, 1);
            col_idx = col_idx + freeman_code(next_pos, 2);
        end
        contour_set{n} = set;
        n = n + 1;
    end
end