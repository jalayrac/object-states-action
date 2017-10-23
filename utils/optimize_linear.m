function [ a ] = optimize_linear( l, K, constrs, ptrs_tracks, annot )
%OPTIMIZE_LINEAR Given the loss for all samples and all classes, and the
%annotation sequence, we find the best possible assignment

opts.alpha  = 0;

a = cell(length(l), 1);
for i = 1:length(l)
    % sequel of labels (here we can have background label in between)
    k = annot{i};
    % pointer of incoming tracks
    PTRS = ptrs_tracks{i};
    T = size(l{i}, 2);

    % building the cost matrix
    C = l{i}(k, :);

    % filter the cost matrix with constraints: be carefule constraints
    % should be in format T x K, but C is in K x T...
    C_filter = filter_with_constraints(C, constrs{i});

    % Dynamic programming (mex file)
    [~, pathk, patht] = dp_atleastoneordering_withtracks(C_filter, PTRS, opts.alpha);
    a{i} = full(sparse(patht, k(pathk), 1, T, K));
end

end
