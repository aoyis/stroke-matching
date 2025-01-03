function [corners, theta_set] = corner_detection(contour_set)
    corners = [];
    n = 1;
    theta_set = {};
    for i = 1 : size(contour_set, 2)
        d = 8;
        set = contour_set{i};
        sz = size(set, 1);
        theta = [];
        for idx = 1 : sz
            if idx <= d
                backward = sz - d + idx;
                A = [set(backward, 1) set(backward, 2)];
            else
                A = [set(idx - d, 1) set(idx - d, 2)];
            end
            B = [set(idx, 1) set(idx, 2)];
            if sz < idx + d
                forward = idx + d - sz;
                C = [set(forward, 1) set(forward, 2)];
            else
                C = [set(idx + d, 1) set(idx + d, 2)];
            end
            v1 = A - B;
            v2 = C - B;
            dist_BA = euclidean_dist(A, B);
            dist_BC = euclidean_dist(C, B);
            theta_inrad = acos(dot(v1, v2) / (dist_BA * dist_BC));
            theta_indeg = (theta_inrad * 180) / pi;
            theta = [theta; theta_inrad];
        end
        theta_set{n} = theta;
        n = n + 1;
        for j = 1 : sz
            target = theta(j, 1);
            flag = 0;
            if target >= 3 * pi / 4
                continue
            end
            for ref = 1 : 10
                back = j - ref;
                if back <= 0 
                    back = sz + back;
                end
                front = j + ref;
                if front > sz
                    front = front - sz;
                end
                if theta(front, 1) < target || theta(back, 1) <= target
                    flag = 1;
                    break
                end
            end
            if ~flag
                corners = [corners; set(j, 1), set(j, 2)];
            end
        end
    end
end