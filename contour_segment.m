function [segments, length] = contour_segment(corners, contour_set)
    segments = {};
    length = [];
    x = 1;
    n = 1;
    for i = 1 : size(contour_set, 2)
    %for i = 1
        set = contour_set{i};
        sz = size(contour_set{i}, 1);
        m = 1;
        % Start of a set
        Sg = [corners(n, 1), corners(n, 2)];
        s = find(ismember(set, [corners(n, 1), corners(n, 2)], 'rows'));
        while m <= sz
            idx = s + m;
            if idx > sz
                idx = idx - sz;
            end
            Sg = [Sg; set(idx, 1), set(idx, 2)];
            if ismember([set(idx, 1), set(idx, 2)], corners, 'rows')
                segments{x} = Sg;
                length(x) = L(Sg);
                x = x + 1;
                Sg = [set(idx, 1), set(idx, 2)];
                n = n + 1;
            end
            m = m + 1;
        end
    end
end

function k = L(Sg)
    k = size(Sg, 1);
end