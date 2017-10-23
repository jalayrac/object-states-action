function FW_optim( X_action, X_state, T_action, T_state,...
                   Z_GT, Y_GT, clips_action, clips_state, ...
                   constrs_action, constrs_state, ptrs_tracks,...
                   annot_action, annot_state, lambda, mu,...
                   params_action, params_state, params)

%{
This codes contains the optimizer based on Frank-Wolfe for the joint
action state problem.

Args:
  X_action        : action design matrix of size [T, d]
  X_state         : track-state design matrix of size [M, d]
  Z_GT            : GT action matrix of size [T, A] (used for evaluation).
  Y_GT            : GT state matrix of size [M, S] (used for evaluation).
  clips_action    : table of size n which contains length of the different chunk
                    of actions. This is used when we need to separate the blocks
                    for the FW oracle.
  clips_state     : same but for track instead.
  ptrs_tracks     : cell containing pointers of incoming tracks for each clips.
  constrs_action: action (not really used for this project)
  constrs_state   : cell containing the constraints obtained from either in house
                     technique or from semi supervison (not really used for this project)
  lambda          : regularization parameter for action
  mu              : regularization parameter
  params_action   : parameters specific for actions:

  params_state    : parameters specific for states:

  params          : parameters for the optimization and the joint method:
         params.niter: number of iterations of the FW procedure.
         params.alpha: factor in front of f(Z) (higher more
                          action condidence)
         params.beta : factor in front of g(Y) (higher more state
                          confidence)
         params.eta  : power factor in the
%}

% Computing the B matrices (used to define the joint distorsion d)
[ B1_action_state, B2_action_state ] = compute_B_matrices_joint_actionstate(...
                                clips_action, clips_state,...
                                T_action, T_state );

fprintf('Starting FW optimization for joint action-state problem...\n');

alpha = params.alpha;
beta  = params.beta;

% State processing.
[M,       ~] = size(X_state);
[~, K_state] = size(constrs_state{1});

% Action procesing.
[N,       ~] = size(X_action);
[~, K_action] = size(constrs_action{1});

% pre-computing heavy stuff
fprintf('Precomputing big matrices state (can take time)...');
GXTP_state = compute_GXTP(X_state, mu);
fprintf('done \n');

fprintf('Precomputing big matrix action (can take time)...');
GXTP_action = compute_GXTP(X_action, lambda);
fprintf('done \n');


% Initialization
fprintf('**********************************\n');
fprintf('   JOINT DIFFRAC INITIALISATION   \n');
fprintf('**********************************\n');

% Init for action.
Z = init_action_matrix(X_action, GXTP_action, clips_action,...
    constrs_action, annot_action, params_action);

% Init for states.
Y = init_state_matrix(X_state, GXTP_state, clips_state,...
    constrs_state, annot_state, ptrs_tracks, params_state);

% initial objective at the init point
i = 1;

% Rebuilding the implicit classifiers
% For States.
W_state = GXTP_state * Y;
b_state = ones(1, M) * (Y - X_state * W_state) / M;
g = 1/M*norm(Y-X_state*W_state-repmat(b_state,M,1),'fro').^2 + mu*norm(W_state,'fro').^2;



% For actions.
W_action = GXTP_action * Z;
b_action = ones(1, N) * (Z - X_action * W_action) / N;
f = 1/N*norm(Z-X_action*W_action-repmat(b_action,N,1),'fro').^2 + lambda*norm(W_action,'fro').^2;

% Joint cost rounding.
[Z_jcr, Y_jcr] = joint_costclassifier_rounding(X_action*W_action+ones(N,1)*b_action, ...
                                               X_state*W_state+ones(M,1)*b_state, ...
                                               K_action, K_state,...
                                               ptrs_tracks, ...
                                               T_action, T_state, ...
                                               clips_action, clips_state, ...
                                               alpha, beta, ...
                                               B1_action_state, B2_action_state);

pr_jcr_all_state = evaluate_solution(Z_jcr, clips_action, Z_GT);
pr_jcr_all_action = evaluate_solution(Y_jcr, clips_state, Y_GT);

last_state_pr_jcr  = mean(pr_jcr_all_state(:));
last_action_pr_jcr = mean(pr_jcr_all_action);

% The performance are based on the best objectives.
best_obj_pr_jcr_st = last_state_pr_jcr;
best_obj_pr_jcr_act = last_action_pr_jcr;

fprintf('init pr_jcr for state : %5.3f\n', best_obj_pr_jcr_st);
fprintf('init pr_jcr for action: %5.3f\n', best_obj_pr_jcr_act);

fprintf('**********************************\n');
fprintf('         FW OPTIMIZATION          \n');
fprintf('**********************************\n');


dYZ = compute_distorsion_nonconvex_vectorized(Z, Y, ...
                                              B1_action_state, B2_action_state, ...
                                              clips_action, clips_state);

h  = alpha * f + (1 - alpha) * g + beta * dYZ;

% Joint cost classifier rounding is a bit slow do it not too often
freq_jcr = 25;
best_h_jcr = 100000000;
best_h_ccr = 100000000;


% Cost classifier rounding.
Y_ccr = rounding_solution(X_state*W_state+ones(M,1)*b_state, clips_state, ...
                          constrs_state, ptrs_tracks, annot_state, K_state);
Z_ccr = rounding_solution_action(X_action*W_action+ones(N,1)*b_action, ...
        clips_action, constrs_action, annot_action, K_action);
g_ccr = compute_objective(X_state, Y_ccr, GXTP_state);
f_ccr = compute_objective(X_action, Z_ccr, GXTP_action);
dYZ_ccr = compute_distorsion_nonconvex_vectorized(Z_ccr, Y_ccr, ...
                B1_action_state, B2_action_state, clips_action, clips_state);
h_ccr = alpha * f_ccr + (1 - alpha) * g_ccr + beta * dYZ_ccr;

if h_ccr <= best_h_ccr
  best_h_ccr = h_ccr;
  W_state_best_ccr = W_state;
  b_state_best_ccr = b_state;
  W_action_best_ccr = W_action;
  b_action_best_ccr = b_action;
end

for i = 2:params.niter
    % Frank Wolfe update
    % gradient of f with respect to Z
    grad_f_action        = alpha * compute_gradient(X_action, Z, GXTP_action);
    grad_f_pervid_action = mat2cell(grad_f_action, K_action, clips_action);

    % gradient of g with respect to Y
    grad_g_state          = (1 - alpha) * compute_gradient(X_state, Y, GXTP_state);
    grad_g_pervid_state   = mat2cell(grad_g_state, K_state, clips_state);


    % gradients of d with respect to Y and Z
    [grad_dist_perclip_action, grad_dist_perclip_state] = ...
        compute_distorsion_gradient_nonconvex_vectorized(Z, Y, ...
         B1_action_state, B2_action_state,...
         clips_action, clips_state);

    % Multiply the gradient of the distorsion by beta
    grad_dist_perclip_action = cellfun(@(x) x*beta, ...
                                       grad_dist_perclip_action, ...
                                       'UniformOutput', false);
    grad_dist_perclip_state  = cellfun(@(x) x*beta, ...
                                       grad_dist_perclip_state, ...
                                      'UniformOutput', false);

    % Sum the gradients.
    grad_pervid_action = cellfun(@plus, grad_f_pervid_action, ...
                                 grad_dist_perclip_action, ...
                                 'UniformOutput', false);
    grad_pervid_state  = cellfun(@plus, grad_g_pervid_state, ...
                                 grad_dist_perclip_state, ...
                                 'UniformOutput', false);

    % FW linear oracle for Y and Z
    Y_fwr = optimize_linear(grad_pervid_state, K_state, constrs_state, ...
                            ptrs_tracks, annot_state);

    Y_fwr = cell2mat(Y_fwr);
    Z_fwr = optimize_linear_action(grad_pervid_action, K_action, ...
                                   constrs_action, annot_action);
    Z_fwr = cell2mat(Z_fwr);

    % Get matrix form gradients to compute gap
    grad_state  = cell2mat(grad_pervid_state);
    grad_action = cell2mat(grad_pervid_action);

    % Duality gap.
    d_state  = trace(grad_state*(Y-Y_fwr));
    d_action = trace(grad_action*(Z-Z_fwr));
    d_total  = d_state+d_action;

    % Do the linesearch.
    Dy = Y_fwr - Y;
    Dz = Z_fwr - Z;
    f_dir   =   compute_objective(X_action, Dz, GXTP_action);
    g_dir   =   compute_objective(X_state,  Dy, GXTP_state);
    dYZ_dir =   compute_distorsion_nonconvex_vectorized(Dz, Dy, ...
           B1_action_state, B2_action_state, clips_action, clips_state);
    h_dir   = alpha   *  f_dir + (1-alpha) * g_dir + beta   * dYZ_dir;
    gamma   =  d_total / (2*h_dir);
    assert(gamma>=-eps);
    gamma   = max(min(gamma, 1), 0);

    % Update the variables.
    Z = (1 - gamma) * Z + gamma * Z_fwr;
    Y = (1 - gamma) * Y + gamma * Y_fwr;

    % From now, optimization is finished, we only evaluate the current model.

    % Rebuilding the implicit classifiers.
    W_state = GXTP_state * Y;
    b_state = ones(1, M) * (Y - X_state * W_state) / M;
    W_action = GXTP_action * Z;
    b_action = ones(1, N) * (Z - X_action * W_action) / N;

    % Compute objective value.
    f   = 1/N*norm(Z-X_action*W_action-repmat(b_action,N,1),'fro').^2 + ...
          lambda*norm(W_action,'fro').^2;
    g   = 1/M*norm(Y-X_state*W_state-repmat(b_state,M,1),'fro').^2 + ...
          mu*norm(W_state,'fro').^2;
    dYZ = compute_distorsion_nonconvex_vectorized(Z, Y, ...
          B1_action_state, B2_action_state, ...
          clips_action, clips_state);

    h   = alpha * f + (1 - alpha) * g + beta * dYZ;

    % Cost classifier rounding.
    Y_ccr = rounding_solution(X_state*W_state+ones(M,1)*b_state, clips_state, ...
                              constrs_state, ptrs_tracks, annot_state, K_state);
    Z_ccr = rounding_solution_action(X_action*W_action+ones(N,1)*b_action, ...
            clips_action, constrs_action, annot_action, K_action);
    g_ccr = compute_objective(X_state, Y_ccr, GXTP_state);
    f_ccr = compute_objective(X_action, Z_ccr, GXTP_action);
    dYZ_ccr = compute_distorsion_nonconvex_vectorized(Z_ccr, Y_ccr, ...
                    B1_action_state, B2_action_state, clips_action, clips_state);
    h_ccr = alpha * f_ccr + (1 - alpha) * g_ccr + beta * dYZ_ccr;

    if h_ccr <= best_h_ccr
      best_h_ccr = h_ccr;
      W_state_best_ccr = W_state;
      b_state_best_ccr = b_state;
      W_action_best_ccr = W_action;
      b_action_best_ccr = b_action;
    end

    if mod(i, freq_jcr)==0
        fprintf('Doing joint cost rounding (might take time)...\n');
        [Z_jcr, Y_jcr] =  joint_costclassifier_rounding( X_action*W_action+ones(N,1)*b_action, X_state*W_state+ones(M,1)*b_state, K_action, K_state,...
                            ptrs_tracks, T_action, T_state, clips_action, clips_state, alpha, beta, B1_action_state, B2_action_state);
        % evaluate
        pr_jcr_action = evaluate_solution(Z_jcr, clips_action, Z_GT);
        pr_jcr_state = evaluate_solution(Y_jcr, clips_state, Y_GT);

        g_jcr   = compute_objective(X_state, Y_jcr, GXTP_state);
        f_jcr   = compute_objective(X_action, Z_jcr, GXTP_action);
        dYZ_jcr = compute_distorsion_nonconvex_vectorized(Z_jcr, Y_jcr, ...
                       B1_action_state, B2_action_state, clips_action, clips_state);
        h_jcr   = alpha * f_jcr + (1-alpha) * g_jcr + beta * dYZ_jcr;

        last_action_pr_jcr  = mean(pr_jcr_action);
        last_state_pr_jcr = mean(pr_jcr_state(:));

        if h_jcr <= best_h_jcr
            best_h_jcr = h_jcr;
            best_obj_pr_jcr_st = last_state_pr_jcr;
            best_obj_pr_jcr_act = last_action_pr_jcr;
        end
    else
      % printing the scores (might print more things if needed)
      fprintf('iter=%3i ',       i);
      fprintf('hobj=%-+5.3e ',   h);
      fprintf('dgap=%-+5.3e ',   d_total);
      fprintf('\n');
    end
end

[Z_jcr, Y_jcr] =  joint_costclassifier_rounding( X_action*W_action_best_ccr+ones(N,1)*b_action_best_ccr, ...
                                                 X_state*W_state_best_ccr+ones(M,1)*b_state_best_ccr, ...
                                                 K_action, K_state, ptrs_tracks, ...
                                                 T_action, T_state, clips_action, ...
                                                 clips_state, alpha, beta, ...
                                                 B1_action_state, B2_action_state);

pr_jcr_action = evaluate_solution(Z_jcr, clips_action, Z_GT);
pr_jcr_state = evaluate_solution(Y_jcr, clips_state, Y_GT);
last_state_pr_jcr  = mean(pr_jcr_state(:));
last_action_pr_jcr = mean(pr_jcr_action);

g_jcr      = compute_objective(X_state, Y_jcr, GXTP_state);
f_jcr      = compute_objective(X_action, Z_jcr, GXTP_action);
dYZ_jcr    = compute_distorsion_nonconvex_vectorized(Z_jcr, Y_jcr, ...
               B1_action_state, B2_action_state, clips_action, clips_state);
h_jcr      = alpha * f_jcr + (1-alpha) * g_jcr + beta * dYZ_jcr;

if h_jcr <= best_h_jcr
    best_h_jcr = h_jcr;
    best_obj_pr_jcr_st = last_state_pr_jcr;
    best_obj_pr_jcr_act = last_action_pr_jcr;
end

% printing the scores (might print more things if needed)
fprintf('Optimization finished: ')
fprintf('precision for state = %5.2f, ',  best_obj_pr_jcr_st);
fprintf('precision for action = %5.2f.', best_obj_pr_jcr_act);
fprintf('\n');

end
