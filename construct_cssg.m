function cssg = construct_cssg(segments, length, delta_row, delta_col, tangent_dir, contour, char_filename)
    cssg = {}; 
    for i = 1 : size(segments, 2)
        l = ceil(0.1 * length(i));
        base = segments{i}(l : length(i) - l + 1, :);
        cross_section = find_opposite_pts(segments, i, base, delta_row, delta_col, tangent_dir, contour, char_filename);
        opps = [];
        temp = {};
        for j = 1 : size(cross_section, 2)
            if isempty(cross_section{j}) 
                continue
            else
                if ~sum(ismember(opps, cross_section{j}(3, 2)))
                    temp = [temp, cross_section(j)];
                    opps = [opps, cross_section{j}(3, 2)];
                end
            end
        end
        cssg{i} = temp;
    end
end

function cross_section = find_opposite_pts(segments, current_segment, base, delta_row, delta_col, tangent_dir, contour, char_filename)
    cross_section = {};
    [H, W] = size(contour);
    for i = 1 : size(base, 1)
        row = base(i, 1); % y
        col = base(i, 2); % x
%         disp([row, col])
        row_displacement = delta_row(row, col);
        col_displacement = delta_col(row, col);
%         disp([row_displacement, col_displacement])
        if col_displacement == 0
            linear = horzcat([1 : row - 1, row + 1 : H].', zeros(H - 1, 1) + col);
        else
            gradient = row_displacement / col_displacement;
            constant = row - (gradient * col);
            linear = [];
            for x = 1 : W
                if x == col
                    continue
                end
                y = floor((gradient * x) + constant);
%                 % Calibration
%                 if y > 1 && y < H - 1 && (y - floor(y)) < 0.2 && ~contour(floor(y), x) && contour(floor(y + 1), x)
%                     y = floor(y + 1);
%                 else 
%                     y = floor(y);
%                 end
                if gradient < 0
                    if y > H
                        continue
                    elseif y < 1
                        break
                    end
                else
                    if y > H
                        break
                    elseif y < 1
                        continue
                    end
                end
                linear = [linear; y, x];
            end
        end
        candidate = [];
        candidate_dist = [];
        ref = tangent_dir(row, col);
        for j = 1 : size(linear, 1)
            r = linear(j, 1);
            c = linear(j, 2);
            if contour(r, c) && abs(ref - tangent_dir(r, c)) <= 25
                candidate = [candidate; r, c];
                candidate_dist = [candidate_dist; euclidean_dist([r, c], [row, col])];
            end
        end
        [val, idx] = min(candidate_dist);
        % Estimated stroke width
        % from histogram, input = 8, base = 12

        if char_filename(1) == 'b'
            thr = 12;
        elseif char_filename(1) == 'g'
            thr = 10;
        else
            thr = 8;
        end
        if isempty(idx) || val > thr
            continue
        else
            opps = find(ismember(linear, [candidate(idx, 1), candidate(idx, 2)], 'rows'));
            for s = 1 : size(segments, 2)
                if sum(ismember(segments{s}, [linear(opps, 1), linear(opps, 2)], 'rows'))
                    opps_segment = s;
                end
            end
            cross_section{i} = [row, col; linear(opps, 1), linear(opps, 2); current_segment, opps_segment];
        end
    end
end
