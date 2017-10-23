function f = compute_objective(X, z, GXTP)
% Computing the objective...


fSL = compute_f_SL(X, z, z, GXTP);

f   = fSL;

end