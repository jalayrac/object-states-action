function [ GXTP ] = compute_GXTP( X, lambda )

[N, d] = size(X);

XTP = bsxfun(@plus, X, -mean(X, 1))';

G = XTP * X + N * lambda * eye(d);
GXTP = G \ XTP;

end
