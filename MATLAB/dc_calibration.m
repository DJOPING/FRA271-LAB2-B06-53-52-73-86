%% Lab 2.1 — Signal Conditioning: WCS1700 current sensor and load cell
% Converts raw ADC counts from MotorXploer.slx into amperes and newtons.
% Fill in the INPUT section with steady-state averages (see steadyMean.m),
% run, then paste the printed numbers into lab2_config.m.
clear; close all; clc
c = lab2_config();
USE_DEMO = true;   % set false once you have real readings

%% INPUT 1 — current sensor
% Multimeter reading in series with the motor (A) vs mean ADC on PA1.
% Include 0 A (motor off) and several duty cycles / loads. Repeat each >= 3 times.
I_meter   = [];    % A
adc_cur   = [];    % counts

%% INPUT 2 — load cell
% Known masses hung / pressed on the load cell (kg) vs mean ADC on PA0.
mass_kg   = [];    % kg
adc_cell  = [];    % counts

if USE_DEMO
    rng(1);
    I_meter  = repmat([0 0.25 0.5 0.75 1.0 1.5], 1, 3);
    adc_cur  = (c.cur_V0 + 0.022*I_meter)/c.vref*c.adc_max + randn(size(I_meter))*3;
    mass_kg  = repmat([0 0.05 0.1 0.2 0.3 0.5], 1, 3);
    adc_cell = 120 + mass_kg*c.g/1.2e-3 + randn(size(mass_kg))*5;
    disp('*** DEMO DATA — not real measurements ***')
end

%% Current: ADC -> V -> A
V_cur = adc_cur / c.adc_max * c.vref;
[p, R2] = linfit(I_meter, V_cur);          % V = S*I + V0
S = p(1); V0 = p(2);
fprintf('Current sensor: S = %.4f V/A (%.1f mV/A), V0 = %.4f V, R^2 = %.4f\n', S, S*1e3, V0, R2);
fprintf('  -> paste:  c.cur_V0 = %.4f;  c.cur_S = %.5f;\n', V0, S);

f1 = figure('Name', 'Current calibration');
plot(I_meter, V_cur, 'o'); hold on
xi = linspace(min(I_meter), max(I_meter), 50);
plot(xi, S*xi + V0, '-', 'LineWidth', 1.5); grid on
xlabel('Current from multimeter (A)'); ylabel('Sensor output (V)')
title(sprintf('WCS1700: V = %.4f I + %.4f  (R^2 = %.4f)', S, V0, R2))
legend('measured', 'linear fit', 'Location', 'northwest')
saveFig(f1, 'dc_cal_current');

%% Load cell: ADC -> N
F_true = mass_kg * c.g;
[q, R2c] = linfit(adc_cell, F_true);       % F = gain*ADC + offset
fprintf('Load cell: gain = %.4e N/count, offset = %.4f N, R^2 = %.4f\n', q(1), q(2), R2c);
fprintf('  -> paste:  c.cell_gain = %.4e;  c.cell_offset = %.4f;\n', q(1), q(2));

f2 = figure('Name', 'Load cell calibration');
plot(adc_cell, F_true, 'o'); hold on
xa = linspace(min(adc_cell), max(adc_cell), 50);
plot(xa, q(1)*xa + q(2), '-', 'LineWidth', 1.5); grid on
xlabel('ADC (counts)'); ylabel('Force (N)')
title(sprintf('Load cell: F = %.3e ADC + %.3f  (R^2 = %.4f)', q(1), q(2), R2c))
legend('measured', 'linear fit', 'Location', 'northwest')
saveFig(f2, 'dc_cal_loadcell');
