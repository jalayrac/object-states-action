function Z = init_action_matrix(X, GXTP, clips_action, constrs_action, annot_action, params_action)


[N, ~] = size(X);
[~, K_action] = size(constrs_action{1});
fprintf('Generating state intialisation by optimizing f(Z) for %d iterations\n', params_action.niter_init);
Z = zeros(N, K_action);
n_initpoint = 5;
for k=1:n_initpoint
    fake_grad_action   = rand(K_action, N)-0.5;
    fake_grad_action_per_clip = mat2cell(fake_grad_action, K_action, clips_action);
    Z_fwr              = optimize_linear_action(fake_grad_action_per_clip, K_action, constrs_action,...
                            annot_action);
    Z_fwr              = cell2mat(Z_fwr);
    Z = Z + 1 ./ n_initpoint * Z_fwr;
end

tic;
for i = 1:params_action.niter_init
    if toc > 5
        fprintf('   iteration %d out of %d\n', i, params_action.niter);
        tic;
    end
    % Gradient computation
    grad = compute_gradient(X, Z, GXTP);
    grad_per_clip = mat2cell(grad, K_action, clips_action);

    % FW linear oracle
    Z_fwr = optimize_linear_action(grad_per_clip, K_action, constrs_action, annot_action);
    Z_fwr = cell2mat(Z_fwr);

    % Duality gap
    d = trace(grad*(Z-Z_fwr));

    % Optimal line search to get the step-size
    gamma_n = d;
    gamma_d = 2 * compute_f_SL(X, Z_fwr-Z, Z_fwr-Z, GXTP);
    gamma   = gamma_n / gamma_d;
    gamma   = max(min(gamma, 1), 0);

    % updating z
    Z = (1-gamma) * Z + gamma * Z_fwr;
end
fprintf('done!\n');



end
