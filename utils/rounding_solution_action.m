function [ a ] = rounding_solution_action( z, clips, constrs, annot, K )
%ROUNDING Summary of this function goes here
%   Detailed explanation goes here

l = mat2cell(ones(size(z'))-2* z', K, clips);
a = optimize_linear_action(l, K, constrs, annot);
a = cell2mat(a);

end
