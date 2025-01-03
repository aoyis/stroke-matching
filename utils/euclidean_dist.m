function dist = euclidean_dist(A, B)
    dist = sqrt((A(1, 2) - B(1, 2)) ^ 2 + (A(1, 1) - B(1, 1)) ^ 2);
end