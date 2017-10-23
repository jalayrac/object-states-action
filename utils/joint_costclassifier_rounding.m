function [ a_action, a_state ] = joint_costclassifier_rounding( wTx_action, wTx_state,...
    K_action, K_state, ptrs_tracks, T_action, T_state, clips_action, ...
    clips_state, alpha, beta, B1_action_state, B2_action_state)
%ROUNDING_SOLUTION_JOINT Summary of this function goes here
%   Detailed explanation goes here

T = numel(T_action);
M = numel(T_state);

T_action_cell       = mat2cell(T_action, clips_action, 1);
T_state_cell        = mat2cell(T_state,  clips_state,  1);

% careful with the constants!
cost_action_classif = mat2cell(     alpha   / (2 * T) * ( ones(size(wTx_action'))-2* wTx_action' ), K_action, clips_action);
cost_state_classif  = mat2cell( (1 - alpha) / (2 * M) * ( ones(size(wTx_state'))-2* wTx_state'   ), K_state,  clips_state);

% double check your gradient with the new formula

% loop over each clip to get the best solution for each clip
a_action = cell(numel(clips_action),  1);
a_state  = cell(numel(clips_state), 1);

for i=1:numel(clips_action)
    T_clip    = numel(T_action_cell{i});
    M_clip    = numel(T_state_cell{i});

    best_val  = 100000;
    % BRUTE FORCE SEARCH ON T
    for t = 1:T_clip
        cur_Z    = zeros(T_clip, 1);
        cur_Z(t) = 1;

        cur_val = cost_action_classif{i} * cur_Z;

        dist_linearCost1 = beta * ( cur_Z' * B1_action_state{i} );
        dist_linearCost2 = beta * ( cur_Z' * B2_action_state{i} );
        dist_linearCost  = [dist_linearCost1; dist_linearCost2];

        final_linearCost = cost_state_classif{i} + dist_linearCost;
        [~, pathk, patht] = dp_atleastoneordering_withtracks(final_linearCost, ptrs_tracks{i}, 0);


        k = 1:2;
        cur_Y    = full(sparse(patht, k(pathk), 1, M_clip, 2));

        cur_val = cur_val  + trace(final_linearCost * cur_Y);

        if cur_val < best_val
            a_action{i} = cur_Z;
            a_state{i}  = cur_Y;
            best_val    = cur_val;
        end
    end
end

a_action = cell2mat(a_action);
a_state = cell2mat(a_state);
end
