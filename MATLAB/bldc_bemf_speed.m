%% Lab 2.3 — BLDC: speed from BEMF frequency, phase shift and phase order
% Electrical frequency f_e (Hz, read with the scope's vertical cursors as 1/period)
%   mechanical rpm = 60 * f_e / pole_pairs   (A2212: 14 poles -> 7 pole pairs)
% Phase shift between phases = 360 * dt / T_e  (ideal 120 deg)
clear; close all; clc
c = lab2_config();
USE_DEMO = true;

%% INPUT 1 — speed test (one row per set speed; repeat >= 3 times per set speed)
rpm_set = [];     % speed set in MC Workbench Motor Pilot (rpm)
T_e_ms  = [];     % BEMF period from the scope (ms) — same length as rpm_set

%% INPUT 2 — phase shift (from one screenshot per direction)
% Time from the rising zero-crossing of phase A to that of B and C (ms), and the period.
dir_label = ["CW"; "CCW"];
dtAB_ms   = [];   % per direction
dtAC_ms   = [];
Tph_ms    = [];

if USE_DEMO
    rng(4);
    rpm_set = repmat([1000 1500 2000 2500 3000], 1, 3);
    T_e_ms  = 1e3 ./ (rpm_set*c.bldc_pole_pairs/60) .* (1 + 0.02*randn(size(rpm_set)) - 0.01);
    Tph_ms  = [8.57; 8.57];
    dtAB_ms = [Tph_ms(1)/3; 2*Tph_ms(2)/3] + 0.1*randn(2,1);
    dtAC_ms = [2*Tph_ms(1)/3; Tph_ms(2)/3] + 0.1*randn(2,1);
    disp('*** DEMO DATA — not real measurements ***')
end

%% Speed from BEMF frequency
f_e     = 1e3 ./ T_e_ms;
rpm_bemf = 60 * f_e / c.bldc_pole_pairs;
err_pct = 100 * (rpm_bemf - rpm_set) ./ rpm_set;

[g, setv] = findgroups(rpm_set(:));
mu  = splitapply(@mean, rpm_bemf(:), g);
sd  = splitapply(@std,  rpm_bemf(:), g);
fe  = splitapply(@mean, f_e(:), g);
tbl = table(setv, fe, mu, sd, 100*(mu - setv)./setv, ...
    'VariableNames', {'rpm_set','f_e_Hz','rpm_from_BEMF','SD','error_pct'});
disp(tbl)

[p, R2] = linfit(fe, setv);
fprintf('Fit rpm_set = %.3f * f_e %+.1f (R^2 = %.4f); theory slope 60/p = %.3f -> implied pole pairs %.2f\n', ...
    p(1), p(2), R2, 60/c.bldc_pole_pairs, 60/p(1));

f1 = figure('Name', 'BLDC speed', 'Position', [100 100 1000 400]);
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile; errorbar(setv, mu, sd, 'o', 'LineWidth', 1.2); hold on
lim = [0 max(setv)*1.1]; plot(lim, lim, 'k--'); grid on
xlabel('Set speed (rpm)'); ylabel('Speed from BEMF (rpm)'); title('BEMF-derived vs set speed')
legend('measured (mean ± SD)', 'ideal y = x', 'Location', 'northwest')
nexttile; plot(fe, setv, 'o'); hold on
fi = linspace(0, max(fe)*1.1, 50); plot(fi, 60*fi/c.bldc_pole_pairs, 'k--'); grid on
xlabel('BEMF electrical frequency f_e (Hz)'); ylabel('Speed (rpm)')
title(sprintf('rpm = 60 f_e / %d', c.bldc_pole_pairs))
saveFig(f1, 'bldc_speed_bemf');

%% Phase shift and order
if ~isempty(dtAB_ms)
    phAB = 360 * dtAB_ms ./ Tph_ms;
    phAC = 360 * dtAC_ms ./ Tph_ms;
    order = strings(size(phAB));
    for k = 1:numel(phAB)
        if phAB(k) < phAC(k), order(k) = "A -> B -> C"; else, order(k) = "A -> C -> B"; end
    end
    disp(table(dir_label(1:numel(phAB)), phAB, phAC, order, ...
        'VariableNames', {'direction','A_to_B_deg','A_to_C_deg','sequence'}))
    fprintf('Ideal: 120 deg and 240 deg; reversing direction swaps B and C.\n');
end

%% Ideal trapezoidal BEMF sketch (for the theory section)
th = linspace(0, 720, 1441);
trap = @(x) interp1([0 30 150 210 330 360], [0 1 1 -1 -1 0], mod(x, 360));
f2 = figure('Name', 'Ideal trapezoidal BEMF');
plot(th, trap(th), th, trap(th - 120), th, trap(th - 240), 'LineWidth', 1.5); grid on
xlabel('Electrical angle (deg)'); ylabel('Normalised BEMF'); xlim([0 720])
xticks(0:60:720); legend('Phase A', 'Phase B', 'Phase C')
title('Ideal trapezoidal BEMF — 6 commutation steps per electrical cycle')
saveFig(f2, 'bldc_ideal_bemf');
