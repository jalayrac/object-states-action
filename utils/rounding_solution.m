function [ a ] = rounding_solution( z, clips, constrs, ptrs_tracks, annot, K)
%ROUNDING Summary of this function goes here
%   Detailed explanation goes here

l = mat2cell(ones(size(z'))-2* z', K, clips);
a = optimize_linear(l, K, constrs, ptrs_tracks, annot);
a = cell2mat(a);

end
