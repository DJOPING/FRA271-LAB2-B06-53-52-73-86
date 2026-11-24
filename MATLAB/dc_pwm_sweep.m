%% Lab 2.1 — Effect of PWM frequency and duty cycle on speed, current and efficiency
% Also used for the H-bridge comparison: run once per mode
% (Sign-Magnitude, Locked Anti-Phase) and set MODE accordingly.
clear; close all; clc
c = lab2_config();
USE_DEMO = true;
MODE = 'Sign-Magnitude';   % or 'Locked Anti-Phase' (label only, for titles/files)

%% INPUT — rows = PWM frequencies, columns = duty cycles
% Fill each cell with a steady-state mean (steadyMean.m). Average the 3 repeats first,
% or put the SD in *_sd to draw error bars.
f_pwm  = [];          % Hz, e.g. [100 1000 5000 20000]
duty   = [];          % %, e.g. 0:10:100
w      = [];          % rad/s   size numel(f_pwm) x numel(duty)
I      = [];          % A
tau_L  = [];          % N·m load torque (same arm load for every point), [] = no-load
w_sd = []; I_sd = [];

if USE_DEMO
    f_pwm = [100 1000 5000 20000]; duty = 0:10:100;
    [D, F] = meshgrid(duty/100, f_pwm);
    dead = 0.08 + 0.04*log10(F/100);              % larger deadband at high f (driver switching)
    w = max(0, 7.6*(D - dead)./(1 - dead));
    I = 0.12 + 0.35*D + 0.05*log10(F/100).*D;
    tau_L = 0.05;
    w = w + randn(size(w))*0.05; I = I + randn(size(I))*0.01;
    disp('*** DEMO DATA — not real measurements ***')
end

nF = numel(f_pwm);
Pin  = c.dc_Vin * I;                       % supply-side estimate; for sign-magnitude
                                           % the averaged supply current is ~duty*I_motor
if strcmpi(MODE, 'Sign-Magnitude'), Pin = Pin .* (duty/100); end
if isempty(tau_L)
    eta = nan(size(w));
else
    eta = 100 * tau_L .* w ./ Pin;
    eta(Pin <= 0 | w <= 0) = NaN;
end

f1 = figure('Name', ['PWM sweep — ' MODE], 'Position', [100 100 1200 380]);
tl = tiledlayout(1, 3, 'TileSpacing', 'compact');
quant = {w*60/(2*pi), I, eta}; ylab = {'Speed (rpm)', 'Current (A)', 'Efficiency (%)'};
sds = {w_sd*60/(2*pi), I_sd, []};
for q = 1:3
    nexttile; hold on; grid on
    for k = 1:nF
        lbl = sprintf('%g Hz', f_pwm(k));
        if ~isempty(sds{q})
            errorbar(duty, quant{q}(k,:), sds{q}(k,:), '-o', 'DisplayName', lbl);
        else
            plot(duty, quant{q}(k,:), '-o', 'DisplayName', lbl);
        end
    end
    xlabel('Duty cycle (%)'); ylabel(ylab{q}); title([ylab{q} ' vs duty'])
end
legend('Location', 'best'); title(tl, MODE)
saveFig(f1, ['dc_pwm_sweep_' regexprep(lower(MODE), '\W', '_')]);

% Speed linearity and dead zone per frequency
fprintf('%s\n%10s %12s %12s %10s\n', MODE, 'f (Hz)', 'slope', 'deadband %', 'R^2');
for k = 1:nF
    m = w(k,:) > 0.05*max(w(k,:));
    [p, R2] = linfit(duty(m), w(k,m));
    fprintf('%10g %12.4f %12.1f %10.4f\n', f_pwm(k), p(1), -p(2)/p(1), R2);
end

f2 = figure('Name', ['Speed map — ' MODE]);
imagesc(duty, 1:nF, w*60/(2*pi)); axis xy; colorbar
set(gca, 'YTick', 1:nF, 'YTickLabel', string(f_pwm))
xlabel('Duty cycle (%)'); ylabel('PWM frequency (Hz)'); title(['Speed (rpm) — ' MODE])
saveFig(f2, ['dc_pwm_map_' regexprep(lower(MODE), '\W', '_')]);
