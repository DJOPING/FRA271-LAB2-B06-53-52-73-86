%% Lab 2.2 — Stepper: frequency vs speed per drive mode, loss step, acceleration
% Theory: w [rev/s] = f_step * (step_angle/360) / microstep
%   microstep = 1 (full), 2 (half), 4, 8, 16, 32  (DRV8825 via M0..M2)
% Loss step = measured speed falls below theory (missed steps / stall).
clear; close all; clc
c = lab2_config();
USE_DEMO = true;
LOSS_TOL = 0.05;      % 5 % below theory counts as losing steps

%% DRV8825 mode table (M2 M1 M0) — for reference in the report
modes = table([1 2 4 8 16 32]', ["Full";"Half";"1/4";"1/8";"1/16";"1/32"], ...
    ["000";"001";"010";"011";"100";"101"], 'VariableNames', {'microstep','name','M2M1M0'});
disp(modes)

%% INPUT 1 — frequency sweep, one struct per mode
% sweep(k).microstep = 1,2,4...
% sweep(k).f         = step frequency (Hz) vector
% sweep(k).w         = measured speed from encoder (rad/s), averaged over repeats
% sweep(k).w_sd      = optional SD for error bars
sweep = struct('microstep', {}, 'f', {}, 'w', {}, 'w_sd', {});

%% INPUT 2 — acceleration test
% For each linear ramp rate (Hz/s), the step frequency where loss step started.
accel_rate  = [];   % Hz/s
f_loss_acc  = [];   % Hz
f_loss_sd   = [];   % Hz (optional)

if USE_DEMO
    rng(3);
    for ms = [1 2 4 8 16]
        f = linspace(50, 2500*ms/2, 25);
        wth = 2*pi * f * (c.step_angle_deg/360) / ms;
        fcrit = 900*ms^0.8;                                     % made-up pull-out frequency
        w = wth .* (1 - 0.9*(f > fcrit)) .* (1 + randn(size(f))*0.005);
        sweep(end+1) = struct('microstep', ms, 'f', f, 'w', w, 'w_sd', []); %#ok<SAGROW>
    end
    accel_rate = [100 250 500 1000 2000 4000];
    f_loss_acc = 1800 ./ (1 + accel_rate/1500) + randn(1,6)*20;
    disp('*** DEMO DATA — not real measurements ***')
end

%% Frequency vs speed
f1 = figure('Name', 'Stepper f vs speed', 'Position', [100 100 1000 420]);
tl = tiledlayout(1, 2, 'TileSpacing', 'compact');
ax1 = nexttile; hold on; grid on; ax2 = nexttile; hold on; grid on
cols = lines(numel(sweep));
res = table();
for k = 1:numel(sweep)
    s = sweep(k);
    wth = 2*pi * s.f * (c.step_angle_deg/360) / s.microstep;
    rpm = s.w*60/(2*pi); rpm_th = wth*60/(2*pi);
    lbl = sprintf('1/%d', s.microstep); if s.microstep == 1, lbl = 'Full'; elseif s.microstep == 2, lbl = 'Half'; end
    if isempty(s.w_sd)
        plot(ax1, s.f, rpm, 'o', 'Color', cols(k,:), 'DisplayName', [lbl ' measured']);
    else
        errorbar(ax1, s.f, rpm, s.w_sd*60/(2*pi), 'o', 'Color', cols(k,:), 'DisplayName', [lbl ' measured']);
    end
    plot(ax1, s.f, rpm_th, '-', 'Color', cols(k,:), 'HandleVisibility', 'off');
    ratio = s.w ./ wth;
    plot(ax2, s.f, ratio*100, '-o', 'Color', cols(k,:), 'DisplayName', lbl);
    kLoss = find(ratio < 1 - LOSS_TOL, 1);
    if isempty(kLoss), fLoss = NaN; else, fLoss = s.f(kLoss); end
    good = ratio >= 1 - LOSS_TOL;
    if nnz(good) >= 2, p = linfit(s.f(good), rpm(good)); slope = p(1); else, slope = NaN; end
    res = [res; table(string(lbl), slope, 60*(c.step_angle_deg/360)/s.microstep, fLoss, ...
        fLoss*60*(c.step_angle_deg/360)/s.microstep, ...
        'VariableNames', {'mode','slope_rpm_per_Hz','theory_rpm_per_Hz','f_loss_Hz','rpm_at_loss'})]; %#ok<AGROW>
end
xlabel(ax1, 'Step frequency (Hz)'); ylabel(ax1, 'Speed (rpm)'); title(ax1, 'Measured (markers) vs theory (lines)')
legend(ax1, 'Location', 'northwest')
yline(ax2, 100*(1-LOSS_TOL), 'r--', 'loss-step threshold');
xlabel(ax2, 'Step frequency (Hz)'); ylabel(ax2, 'Measured / theory (%)'); title(ax2, 'Step tracking')
legend(ax2, 'Location', 'southwest')
saveFig(f1, 'stepper_freq_speed');
disp(res)

%% Acceleration vs loss-step frequency
if ~isempty(accel_rate)
    f2 = figure('Name', 'Acceleration');
    if isempty(f_loss_sd)
        semilogx(accel_rate, f_loss_acc, '-o', 'LineWidth', 1.5);
    else
        errorbar(accel_rate, f_loss_acc, f_loss_sd, '-o', 'LineWidth', 1.5); set(gca, 'XScale', 'log');
    end
    grid on; xlabel('Ramp rate (Hz/s)'); ylabel('Frequency where loss step starts (Hz)')
    title('Higher acceleration -> loss step at lower frequency (inertia torque J\alpha)')
    saveFig(f2, 'stepper_accel_loss');
end
