function [p, R2, yhat] = linfit(x, y, throughOrigin)
%LINFIT  Least-squares line y = p(1)*x + p(2) and its R^2.
%   throughOrigin = true forces p(2) = 0 (e.g. tau = Kt*I).
if nargin < 3, throughOrigin = false; end
x = x(:); y = y(:);
if throughOrigin
    p = [x \ y, 0];
else
    p = polyfit(x, y, 1);
end
yhat = p(1)*x + p(2);
R2 = 1 - sum((y - yhat).^2) / sum((y - mean(y)).^2);
end
