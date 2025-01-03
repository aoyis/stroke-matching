function [theta_inrad, theta_indeg] = find_dir(p, q, ref_img)
    if p(1) < q(1)
        vertex = p;
        dir_pt = q;
    elseif q(1) < p(1)
        vertex = q;
        dir_pt = p;
    else    
        theta_inrad = 0;
        theta_indeg = 0;
        return 
    end
    ref_pt = [min(p(1), q(1)), size(ref_img, 2)];
    v1 = ref_pt - vertex;
    v2 = dir_pt - vertex;
    dist_RV = euclidean_dist(ref_pt, vertex);
    dist_VD = euclidean_dist(dir_pt, vertex);
    theta_inrad = acos(dot(v1, v2) / (dist_RV * dist_VD));
    theta_indeg = (theta_inrad * 180) / pi;
end