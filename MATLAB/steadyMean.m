function [m, sd] = steadyMean(sig, tStart, tEnd)
%STEADYMEAN  Mean and standard deviation of a logged signal over [tStart, tEnd] seconds.
%   Use it to turn one Data Inspector run into one steady-state table point.
%   Example: [w, w_sd] = steadyMean(speed, 3, 8);
[t, y] = getSig(sig);
if nargin < 2 || isempty(tStart), tStart = t(1); end
if nargin < 3 || isempty(tEnd),   tEnd   = t(end); end
k = t >= tStart & t <= tEnd;
if ~any(k), error('steadyMean:window', 'No samples in [%g, %g] s', tStart, tEnd); end
m  = mean(y(k));
sd = std(y(k));
end
