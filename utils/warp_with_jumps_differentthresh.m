function [y, pathk, patht] = warp_with_jumps_differentthresh(C, thresh)

[m, n] = size(C);

if isempty(thresh)
    mm = min(C(:));
else
    mm = thresh;
end

C = C - mm;

C_z = zeros(2*m + 1, n);
C_z(2:2:end, :) = C;

C_z = cat(2, C_z, zeros(2*m+1, 1));

%[D, path, dp] = warping_jump_mex_corrected(C_z);
[~, ~, y]     = warping_jump_mex_corrected(C_z);

y(1:2:end, :) = [];
y(:, end) = []; 

[pathk, patht] = find(y);

end
