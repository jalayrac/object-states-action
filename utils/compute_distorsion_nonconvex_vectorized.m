function [ dist ] = compute_distorsion_nonconvex_vectorized( Z, Y, B1_action_state, B2_action_state, clips_action, clips_state )
%COMPUTE_DISTORSION_NONCONVEX_VECTORIZED Summary of this function goes here
%   Detailed explanation goes here

dist = 0;

n_clip = numel(clips_action);
Z_cell = mat2cell(Z, clips_action, 1);
Y_cell = mat2cell(Y, clips_state,  2);

for i =1:n_clip
    dist = dist + Z_cell{i}' * (B1_action_state{i} * Y_cell{i}(:, 1)  +  B2_action_state{i} * Y_cell{i}(:, 2)) ;
end

end

