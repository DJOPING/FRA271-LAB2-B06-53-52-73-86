%% Lab 2.1 — FFT of the speed signal, low-pass filter design and Bode plot
% 1) FFT of logged motor speed at several PWM frequencies
% 2) Design a low-pass filter for the speed measurement
% 3) Bode plot of the filter, and before/after in time and frequency
%
% NOTE for the discussion: the board streams to Simulink at the model's
% fixed step (Fs below), usually far below the PWM frequency. PWM ripple
% above Fs/2 cannot appear directly; it aliases or is averaged by the motor's
% inductance and inertia. Most of what you see is encoder quantisation noise,
% the commutator / gear ripple (proportional to speed) and mechanical vibration.
clear; close all; clc
USE_DEMO = true;

%% INPUT — one speed log per PWM frequency (Data Inspector -> Workspace)
% runs(k).sig = exported variable (struct with .time/.data, timeseries or [t y])
% runs(k).f_pwm = PWM frequency used (Hz)
runs = struct('sig', {}, 'f_pwm', {});
fc   = 5;          % Hz, LPF cutoff — choose from the FFT (below the noise, above the dynamics)
order = 2;         % Butterworth order if Signal Processing Toolbox is available
tSkip = 1;         % s, drop the start-up transient

if USE_DEMO
    Fs = 500; t = (0:1/Fs:10)';
    for fp = [100 1000 20000]
        rip = 0.4*sin(2*pi*24*t) + 0.15*sin(2*pi*48*t);                   % gear/commutator
        alias = 0.3*(fp < Fs)*sin(2*pi*mod(fp, Fs)*t);                    % only when PWM < Fs
        w = 6*(1 - exp(-t/0.15)) + rip + alias + 0.25*randn(size(t));     % encoder noise
        runs(end+1) = struct('sig', [t w], 'f_pwm', fp); %#ok<SAGROW>
    end
    disp('*** DEMO DATA — not real measurements ***')
end
if isempty(runs), error('Fill in runs (see INPUT section).'); end

%% FFT of each run
f1 = figure('Name', 'FFT of speed', 'Position', [100 100 900 300*numel(runs)]);
tl = tiledlayout(numel(runs), 1, 'TileSpacing', 'compact');
for k = 1:numel(runs)
    [t, y] = getSig(runs(k).sig);
    Fs = 1/median(diff(t));
    y = y(t >= t(1) + tSkip);
    [fr, A] = singleSidedFFT(y - mean(y), Fs);
    nexttile; plot(fr, A, 'LineWidth', 1); grid on; hold on
    xline(fc, 'r--', sprintf('f_c = %g Hz', fc));
    [pk, ip] = maxk(A(2:end), 3); fpk = fr(ip+1);
    plot(fpk, pk, 'rv', 'MarkerFaceColor', 'r')
    title(sprintf('PWM %g Hz  (Fs = %.0f Hz) — peaks at %s Hz', runs(k).f_pwm, Fs, mat2str(round(fpk', 1))))
    ylabel('|W(f)| (rad/s)')
end
xlabel(tl, 'Frequency (Hz)')
saveFig(f1, 'dc_fft_speed');

%% Filter design (uses run 1's sample rate)
[t, y] = getSig(runs(1).sig);
Fs = 1/median(diff(t));
hasSPT = exist('butter', 'file') == 2;
if hasSPT
    [b, a] = butter(order, fc/(Fs/2));
    fname = sprintf('Butterworth order %d', order);
else
    % 1st-order IIR (exponential smoothing), exact discretisation of 1/(tau s + 1)
    alpha = exp(-2*pi*fc/Fs);
    b = 1 - alpha; a = [1 -alpha];
    fname = '1st-order IIR';
end
yf  = filter(b, a, y);                       % causal (real-time) — has phase lag
if hasSPT, yff = filtfilt(b, a, y); else, yff = []; end   % zero-phase (offline only)

%% Bode plot of the discrete filter
fb = logspace(-1, log10(Fs/2), 500);
z  = exp(1j*2*pi*fb/Fs);
H  = polyval(b(end:-1:1), 1./z) ./ polyval(a(end:-1:1), 1./z);
f2 = figure('Name', 'Bode');
subplot(2,1,1); semilogx(fb, 20*log10(abs(H)), 'LineWidth', 1.5); grid on
yline(-3, 'r--', '-3 dB'); xline(fc, 'r--'); ylabel('Magnitude (dB)')
title(sprintf('%s, f_c = %g Hz, Fs = %.0f Hz', fname, fc, Fs))
subplot(2,1,2); semilogx(fb, unwrap(angle(H))*180/pi, 'LineWidth', 1.5); grid on
xline(fc, 'r--'); ylabel('Phase (deg)'); xlabel('Frequency (Hz)')
saveFig(f2, 'dc_lpf_bode');

%% Before / after
f3 = figure('Name', 'Filtered speed', 'Position', [100 100 900 600]);
subplot(2,1,1); plot(t, y, 'Color', [0.7 0.7 0.7]); hold on
plot(t, yf, 'b', 'LineWidth', 1.5);
if ~isempty(yff), plot(t, yff, 'r--', 'LineWidth', 1.2); end
grid on; xlabel('Time (s)'); ylabel('Speed (rad/s)')
leg = {'raw', 'filtered (causal)'};
if ~isempty(yff), leg{end+1} = 'filtfilt (zero-phase)'; end
legend(leg)
title('Time domain')
k0 = t >= t(1) + tSkip;
[fr, A]  = singleSidedFFT(y(k0)  - mean(y(k0)),  Fs);
[~,  Af] = singleSidedFFT(yf(k0) - mean(yf(k0)), Fs);
subplot(2,1,2); plot(fr, A, 'Color', [0.6 0.6 0.6]); hold on; plot(fr, Af, 'b', 'LineWidth', 1.2)
xline(fc, 'r--'); grid on; xlabel('Frequency (Hz)'); ylabel('|W(f)|'); legend('raw', 'filtered')
title('Frequency domain')
saveFig(f3, 'dc_lpf_before_after');

fprintf('Std of steady speed: raw %.4f, filtered %.4f rad/s (%.0f %% lower)\n', ...
    std(y(k0)), std(yf(k0)), 100*(1 - std(yf(k0))/std(y(k0))));
fprintf('Group delay of the causal filter at DC ~ %.1f ms\n', 1e3*groupDelayDC(b, a)/Fs);

%% local functions
function [f, A] = singleSidedFFT(x, Fs)
x = x(:); N = numel(x);
X = fft(x .* hann_(N)) / sum(hann_(N));
A = 2*abs(X(1:floor(N/2)+1)); A(1) = A(1)/2;
f = (0:floor(N/2))' * Fs/N;
end

function w = hann_(N)
w = 0.5 - 0.5*cos(2*pi*(0:N-1)'/(N-1));
end

function gd = groupDelayDC(b, a)
% d(phase)/d(omega) at omega = 0, in samples
nb = 0:numel(b)-1; na = 0:numel(a)-1;
gd = sum(nb.*b)/sum(b) - sum(na.*a)/sum(a);
end
