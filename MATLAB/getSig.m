function [t, y] = getSig(s)
%GETSIG  Return time and value vectors from anything Data Inspector / Simulink exports.
%   Accepts: struct with .time/.data (Data Inspector -> Workspace),
%            timeseries (.Time/.Data), Simulink.SimulationData.Signal (.Values),
%            or an Nx2 numeric matrix [t y].
if isnumeric(s)
    t = s(:,1); y = s(:,2);
elseif isa(s, 'timeseries')
    t = s.Time; y = s.Data;
elseif isobject(s) && isprop(s, 'Values')
    [t, y] = getSig(s.Values);
    return
elseif isstruct(s) && isfield(s, 'time') && isfield(s, 'data')
    t = s.time; y = s.data;
elseif isstruct(s) && isfield(s, 'Time') && isfield(s, 'Data')
    t = s.Time; y = s.Data;
else
    error('getSig:type', 'Unsupported signal type: %s', class(s));
end
t = double(t(:));
y = double(squeeze(y));
if isvector(y), y = y(:); end
end
