function [ a ] = optimize_linear_action( l, K, constrs, annot)
%OPTIMIZE_LINEAR Given the loss for all samples and all classes, and the
%annotation sequence, we find the best possible assignment

a = cell(length(l), 1);
for i = 1:length(l)
    % sequel of labels (here we can have background label in between)
    k = annot{i};
    T = size(l{i}, 2);
    % building the cost matrix
    C = l{i}(k, :);
    % filter the cost matrix with constraints: be carefule constraints
    % should be in format T x K, but C is in K x T...
    C_filter = filter_with_constraints(C, constrs{i});

    % Dynamic programming (mex file)
    % NB here we can in principle handle more than one action.
    [~, pathk, patht] = warp_with_jumps_differentthresh(C_filter, []);

    a{i} = full(sparse(patht, k(pathk), 1, T, K));
end

end
