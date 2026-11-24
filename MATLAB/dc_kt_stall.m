%% Lab 2.1 — Torque constant Kt and stall torque
% tau = F * L (load-cell force x arm length). Kt is the slope of tau vs I.
% Run dc_calibration.m first so lab2_config.m holds real calibration values.
clear; close all; clc
c = lab2_config();
USE_DEMO = true;

%% INPUT — Kt sweep
% Each row = one load level: mean ADC of load cell and current sensor.
% Repeat the whole sweep 3 times; stack every trial in the same arrays
% and give its trial number in `trial`.
adc_cell = [];   % counts (PA0)
adc_cur  = [];   % counts (PA1)
trial    = [];   % 1,2,3...

%% INPUT — stall (shaft locked at 100 % duty), one row per repeat
adc_cell_stall = [];
adc_cur_stall  = [];

if USE_DEMO
    rng(2); Kt0 = 0.18; I0 = 0.12;
    I = repmat(linspace(0.15, 1.9, 8), 1, 3); trial = kron(1:3, ones(1, 8));
    tau = Kt0*(I - I0) + randn(size(I))*0.004;
    adc_cur  = (c.cur_V0 + c.cur_S*I)/c.vref*c.adc_max;
    adc_cell = (tau/c.arm_L - c.cell_offset)/c.cell_gain;
    Ist = 2.0 + randn(1,3)*0.03; tst = Kt0*(Ist - I0) + randn(1,3)*0.005;
    adc_cur_stall  = (c.cur_V0 + c.cur_S*Ist)/c.vref*c.adc_max;
    adc_cell_stall = (tst/c.arm_L - c.cell_offset)/c.cell_gain;
    disp('*** DEMO DATA — not real measurements ***')
end

%% Convert to physical units
toI   = @(a) (a/c.adc_max*c.vref - c.cur_V0) / c.cur_S;
toTau = @(a) (c.cell_gain*a + c.cell_offset) * c.arm_L;
I   = toI(adc_cur);    tau = toTau(adc_cell);

%% Kt fit (with intercept: friction / no-load current shifts the line)
[p, R2] = linfit(I, tau);
Kt = p(1); I_friction = -p(2)/p(1);
% Kt per trial -> repeatability
tr = unique(trial); Kt_tr = zeros(size(tr));
for k = 1:numel(tr)
    m = trial == tr(k); pk = linfit(I(m), tau(m)); Kt_tr(k) = pk(1);
end
fprintf('Kt = %.4f Nm/A (R^2 = %.4f); per trial: %s; mean +- SD = %.4f +- %.4f\n', ...
    Kt, R2, mat2str(Kt_tr, 4), mean(Kt_tr), std(Kt_tr));
fprintf('Friction-equivalent current (tau = 0): %.3f A\n', I_friction);

%% Stall torque
I_st = toI(adc_cur_stall); tau_st = toTau(adc_cell_stall);
fprintf('Stall: tau_st = %.4f +- %.4f Nm, I_st = %.3f +- %.3f A\n', ...
    mean(tau_st), std(tau_st), mean(I_st), std(I_st));
fprintf('Check: Kt*(I_st - I_friction) = %.4f Nm\n', Kt*(mean(I_st) - I_friction));

%% Plot
f = figure('Name', 'Kt'); hold on
mk = 'osd^v><';
for k = 1:numel(tr)
    m = trial == tr(k);
    plot(I(m), tau(m), mk(mod(k-1, numel(mk))+1), 'MarkerSize', 7);
end
xi = linspace(0, max([I(:); I_st(:)]), 50);
plot(xi, Kt*xi + p(2), 'k-', 'LineWidth', 1.5)
plot(I_st, tau_st, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'y')
grid on; xlabel('Current I (A)'); ylabel('Torque \tau (N·m)')
title(sprintf('\\tau = %.4f I %+.4f   (K_t = %.4f N·m/A, R^2 = %.3f)', Kt, p(2), Kt, R2))
legend([arrayfun(@(k) sprintf('trial %d', k), tr, 'UniformOutput', false), {'fit', 'stall'}], ...
    'Location', 'northwest')
saveFig(f, 'dc_kt');

save(fullfile(fileparts(mfilename('fullpath')), 'dc_kt_result.mat'), ...
    'Kt', 'I_friction', 'tau_st', 'I_st');
