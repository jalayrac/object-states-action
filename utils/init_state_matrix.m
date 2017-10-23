function Z = init_state_matrix(X, GXTP, clips_state, constrs_state, annot_state, ptrs_tracks, params_state)

fprintf('Generating state intialisation by optimizing g(Y) for %d iterations\n', params_state.niter_init);
[M, ~] = size(X);
[~, K_state] = size(constrs_state{1});
Z = zeros(M, K_state);
n_initpoint = 5;
for k=1:n_initpoint
    fake_grad          = rand(K_state, M)-0.5;
    fake_grad_per_clip = mat2cell(fake_grad, K_state, clips_state); 
    Z_fwr = optimize_linear(fake_grad_per_clip, K_state, constrs_state, ptrs_tracks, annot_state);
    Z_fwr = cell2mat(Z_fwr);
    Z = Z + 1 ./ n_initpoint * Z_fwr;
end
tic;
for i = 1:params_state.niter_init  
    if toc > 5
        fprintf('   iteration %d out of %d\n', i, params_state.niter);
        tic;
    end
    % Gradient computation
    grad = compute_gradient(X, Z, GXTP);
    grad_per_clip = mat2cell(grad, K_state, clips_state);    

    % FW linear oracle
    Z_fwr = optimize_linear(grad_per_clip, K_state, constrs_state, ptrs_tracks, annot_state);
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

