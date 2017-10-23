function [ B1_action_state, B2_action_state ] = compute_B_matrices_joint_actionstate( clips_action, ...
    clips_state, T_action, T_state)
%COMPUTE_B_MATRICES_JOINT_ACTIONSTATE Summary of this function goes here
%   Detailed explanation goes here

T                   = numel(T_action);
T_action_cell       = mat2cell(T_action, clips_action, 1);
T_state_cell        = mat2cell(T_state,  clips_state,  1);

B1_action_state     = cell(numel(clips_action),1);
B2_action_state     = cell(numel(clips_action),1);

for i=1:numel(clips_action)
    % construct the time matrices with subplus part
    B1_clip = zeros(numel(T_action_cell{i}), numel(T_state_cell{i}));
    B2_clip = zeros(numel(T_action_cell{i}), numel(T_state_cell{i}));

    for t=1:numel(T_action_cell{i})
        for k=1:numel(T_state_cell{i})
            % state 1:
            B1_clip(t, k) = 1 / (2 * T) * subplus(T_state_cell{i}(k) - T_action_cell{i}(t));
            % state 2:
            B2_clip(t, k) = 1 / (2 * T) * subplus(T_action_cell{i}(t)   - T_state_cell{i}(k));
        end
    end
    B1_action_state{i} = B1_clip;
    B2_action_state{i} = B2_clip;
end

end
