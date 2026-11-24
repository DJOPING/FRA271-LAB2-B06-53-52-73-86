%% Lab 2.1 — Motor characteristic curves (speed, current, power, efficiency vs torque)
% Linear DC motor model from two measured points per voltage:
%   no-load (w_NL, i_NL) and stall (tau_ST, i_ST)
%   w(tau) = w_NL (1 - tau/tau_ST)
%   i(tau) = i_NL + (i_ST - i_NL) tau/tau_ST
%   P_out  = tau w ,  P_in = V i ,  eta = P_out / P_in
clear; close all; clc
c = lab2_config();
USE_DEMO = true;

%% INPUT — one row per supply level (12 V at 100 % duty, then lower duties)
% V_eff = effective motor voltage = duty * Vin (sign-magnitude)
duty   = [];   % 0..1
w_NL   = [];   % rad/s, no-load speed (encoder)
i_NL   = [];   % A, no-load current
tau_ST = [];   % N·m, stall torque (from dc_kt_stall)
i_ST   = [];   % A, stall current

%% Optional: measured loaded points to overlay at 100 % duty
tau_meas = []; w_meas = []; i_meas = [];

if USE_DEMO
    duty   = [1.0 0.8 0.6 0.4];
    w_NL   = 7.6*duty - 0.3;          % geared output ~70 rpm at 12 V
    i_NL   = 0.12 + 0.03*duty;
    tau_ST = 0.33*duty;
    i_ST   = 2.0*duty;
    tau_meas = [0 0.05 0.1 0.15 0.2 0.25];
    w_meas = w_NL(1)*(1 - tau_meas/tau_ST(1)) + randn(1,6)*0.1;
    i_meas = i_NL(1) + (i_ST(1)-i_NL(1))*tau_meas/tau_ST(1) + randn(1,6)*0.03;
    disp('*** DEMO DATA — not real measurements ***')
end

V = duty * c.dc_Vin;
N = numel(duty);
cols = lines(N);
f = figure('Name', 'Motor characteristic', 'Position', [100 100 1000 700]);
tl = tiledlayout(2, 2, 'TileSpacing', 'compact');
ax = gobjects(4,1); for k = 1:4, ax(k) = nexttile(tl); hold(ax(k), 'on'); grid(ax(k), 'on'); end

summary = table();
for n = 1:N
    tau = linspace(0, tau_ST(n), 200);
    w   = w_NL(n) * (1 - tau/tau_ST(n));
    i   = i_NL(n) + (i_ST(n) - i_NL(n)) * tau/tau_ST(n);
    P   = tau .* w;
    eta = P ./ (V(n) * i);
    lbl = sprintf('%.0f%% (%.1f V)', duty(n)*100, V(n));
    plot(ax(1), tau, w*60/(2*pi), 'Color', cols(n,:), 'LineWidth', 1.5, 'DisplayName', lbl);
    plot(ax(2), tau, i,   'Color', cols(n,:), 'LineWidth', 1.5, 'DisplayName', lbl);
    plot(ax(3), tau, P,   'Color', cols(n,:), 'LineWidth', 1.5, 'DisplayName', lbl);
    plot(ax(4), tau, eta*100, 'Color', cols(n,:), 'LineWidth', 1.5, 'DisplayName', lbl);
    [Pmax, kP] = max(P); [etaMax, kE] = max(eta);
    summary = [summary; table(duty(n)*100, V(n), w_NL(n)*60/(2*pi), tau_ST(n), ...
        Pmax, tau(kP), etaMax*100, tau(kE), w(kE)*60/(2*pi), i(kE), ...
        'VariableNames', {'Duty_pct','V','NoLoad_rpm','Stall_Nm','Pmax_W','tau_at_Pmax', ...
        'EtaMax_pct','tau_at_EtaMax','rpm_at_EtaMax','I_at_EtaMax'})]; %#ok<AGROW>
end
if ~isempty(tau_meas)
    plot(ax(1), tau_meas, w_meas*60/(2*pi), 'ko', 'DisplayName', 'measured 100%');
    plot(ax(2), tau_meas, i_meas, 'ko', 'DisplayName', 'measured 100%');
end
ylabel(ax(1), 'Speed (rpm)');      title(ax(1), 'Speed vs Torque')
ylabel(ax(2), 'Current (A)');      title(ax(2), 'Current vs Torque')
ylabel(ax(3), 'Output power (W)'); title(ax(3), 'Power vs Torque')
ylabel(ax(4), 'Efficiency (%)');   title(ax(4), 'Efficiency vs Torque')
for k = 1:4, xlabel(ax(k), 'Torque (N·m)'); end
legend(ax(1), 'Location', 'northeast')
saveFig(f, 'dc_characteristic');

disp(summary)
fprintf(['At %.0f V: max efficiency %.1f %% at tau = %.3f N·m, %.1f rpm, %.2f A ' ...
    '(max power at tau = %.3f N·m ~ tau_ST/2)\n'], V(1), summary.EtaMax_pct(1), ...
    summary.tau_at_EtaMax(1), summary.rpm_at_EtaMax(1), summary.I_at_EtaMax(1), summary.tau_at_Pmax(1));
