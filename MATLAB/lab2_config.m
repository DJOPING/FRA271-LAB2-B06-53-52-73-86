function c = lab2_config()
%LAB2_CONFIG  Shared constants for every FRA271 Lab 2 script.
%   Values marked TODO must be measured or read from a datasheet.

% --- ADC (STM32G474, 12-bit) ---
c.adc_bits = 12;
c.adc_max  = 2^c.adc_bits - 1;     % 4095
c.vref     = 3.3;                  % V

% --- Current sensor WCS1700 (PA1) ---
% I = (V - V0) / S ; calibrate with calib_linear.m and paste the result here
c.cur_V0   = 3.3/2;                % V at 0 A          TODO: measure
c.cur_S    = 0.022;                % V/A sensitivity   TODO: measure (~33 mV/A @5V, ratiometric)

% --- Load cell YZC-131A + INA125 (PA0) ---
% F = cell_gain * ADC + cell_offset  [N]
c.cell_gain   = 1.0e-3;            % N per ADC count   TODO: calibrate with known masses
c.cell_offset = 0;                 % N                 TODO
c.arm_L       = 0.110;             % m, shaft centre to load-cell contact   TODO: measure

% --- DC motor (Nidec 12 V geared) ---
c.dc_Vin = 12;                     % V

% --- Stepper ---
c.step_angle_deg = 1.8;            % TODO: check stepper datasheet

% --- BLDC A2212 13T 1000KV ---
c.bldc_poles      = 14;
c.bldc_pole_pairs = c.bldc_poles/2;   % 7
c.bldc_KV         = 1000;             % rpm/V

c.g = 9.81;
end
