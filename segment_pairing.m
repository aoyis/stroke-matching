function strokes = segment_pairing(segments, cssg, length)
    strokes = {};
    for i = 1 : size(cssg, 2)
        for j = 1 : size(cssg{i}, 2)
            if length(i) > length(cssg{i}{j}(3, 2))
                strokes = [strokes, segments(i)];
                break
            elseif length(i) == length(cssg{i}{j}(3, 2)) && i < cssg{i}{j}(3, 2)
                strokes = [strokes, segments(i)];
            end
        end
    end
end