function [grad_dist_perclip_action, grad_dist_perclip_state] = ...
            compute_distorsion_gradient_nonconvex_vectorized(Z, Y, B1_action_state, B2_action_state,...
            clips_action, clips_state)
        

% NB : B1 and B2 have already the 1/(2T) normalization factor (but not he
% beta one though)

n_clip = numel(clips_action);
grad_dist_perclip_action = cell(1, n_clip);
grad_dist_perclip_state  = cell(1, n_clip);

Z_cell = mat2cell(Z, clips_action, 1);
Y_cell = mat2cell(Y, clips_state,  2);

for i=1:n_clip
    Z_clip = Z_cell{i};
    Y_clip = Y_cell{i};    
    grad_dist_perclip_state{i}        = zeros(size(Y_clip));
    grad_dist_perclip_action{i}       = zeros(size(Z_clip));
        
    grad_dist_perclip_action{i}       =  (B1_action_state{i} * Y_clip(:,1) + B2_action_state{i} * Y_clip(:,2));       
    grad_dist_perclip_state{i}(:, 1)  =  (B1_action_state{i}' * Z_clip); 
    grad_dist_perclip_state{i}(:, 2)  =  (B2_action_state{i}' * Z_clip); 
    
    % transpose the matrix
    grad_dist_perclip_state{i}       = grad_dist_perclip_state{i}';    
    grad_dist_perclip_action{i}       = grad_dist_perclip_action{i}';
end
  
end
                                