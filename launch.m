addpath('./utils')

action = 'put_wheel';

lambda_state = 0.0001;
lambda_action = 0.01;
seed = 370;
niter = 600;

% For the close_fridge and open_fridge action we do less iterations as it is a bit slower.w
if strcmp(action, 'close_fridge') | strcmp(action, 'open_fridge')
    niter = 300;
end

alpha = 0.5;
beta = 1;

exp_launcher(action, lambda_state, lambda_action, seed, niter, alpha, beta)
