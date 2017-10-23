function exp_launcher(action, lambda_state, lambda_action, seed, niter, alpha, beta)

% Get the parameters.
params.action     = action;
params.seed       = seed;
params.niter      = niter;   % Number of iterations joint FW.

% Set the hyperparameters.
params.alpha      = alpha; % Weight on the state diffrac cost function.
params.beta       = beta;  % Weight on the distorsion function.

%% Parameters for action.
params_action                 = params;
params_action.initmode        = 'optim'; % Init. with action only optim.
params_action.niter_init      = 30; % Number of such iterations.
params_action.lambda          = lambda_action;  % Regularizer.

% Parameters for states.
params_state                 = params;
params_state.initmode        = 'optim'; % Init. with state only optim.
params_state.niter_init      = 30; % Number of such iterations.
params_state.lambda          = lambda_state; % Regularizer.

% Set the random generator for reproducibility.
rng(params_state.seed);

% Load data for states and action.
load(sprintf('./data/features_%s.mat', action));

% Optimization.
FW_optim(X_action, X_state, T_action, T_state, Z_GT, Y_GT, ...
         clips_action, clips_state, constrs_action, constrs_state, ...
         ptrs_tracks, annot_action, annot_state, ...
         params_action.lambda, params_state.lambda,...
         params_action, params_state, params);

end
