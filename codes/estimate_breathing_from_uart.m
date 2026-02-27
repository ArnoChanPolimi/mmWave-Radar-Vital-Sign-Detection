%% 1. 载入 UART 原始帧数据（你已经用 IWR6843ISK_outputdata 采过）
clear; clc;

load uart_raw_frame.mat   % 里边有 rawBuf, cfgPort, dataPort
fprintf('rawBuf 长度 = %d 字节\n', numel(rawBuf));

%% 2. 解析 rawBuf -> frames 结构体（需要有 parseAllFrames.m）
frames = parseAllFrames(rawBuf);

numFrames = numel(frames);
fprintf('解析出 %d 帧数据\n', numFrames);

% === 重要：帧周期（秒） ===
% 在 cfg 里 frameCfg 最后一个参数。你现在 profile_2d_bpm.cfg 里是 "frameCfg 0 1 32 0 100 1 0"
% 第5个参数=100 ms -> 0.1 s
framePeriod = 0.1;  % 如果你后来改了 cfg，这里同步改

t = (0:numFrames-1).' * framePeriod;   % 时间轴

%% 3. 为每一帧选一个“代表人体”的距离
R_rep = nan(numFrames,1);

for k = 1:numFrames
    Rk = frames(k).R;   % 这一帧所有目标的距离（m）
    if isempty(Rk)
        continue;
    end

    % 只保留一个合理的人体距离范围（根据你的场景调整）
    % 比如你在教室里，人 ~0.3~3 米
    Rk_sel = Rk(Rk > 0.3 & Rk < 3.0);

    if isempty(Rk_sel)
        continue;
    end

    % 用中位数作为本帧“人体距离代表值”，抗一下噪点
    R_rep(k) = median(Rk_sel);
end

%% 4. 简单插值填补 NaN（如果有些帧没检测到目标）
valid = ~isnan(R_rep);
if sum(valid) < 5
    error('有效帧太少，几乎没有检测到人体目标，换个位置 / cfg 再采一次。');
end

R_rep_filled = R_rep;
R_rep_filled(~valid) = interp1(t(valid), R_rep(valid), t(~valid), 'linear', 'extrap');

%% 5. 去掉直流 + 去趋势（只看起伏）
R_dc_removed = R_rep_filled - mean(R_rep_filled);
R_detrend = detrend(R_dc_removed);  % 去掉慢漂移

%% 6. 设计一个呼吸频段的带通滤波器（比如 0.1~0.5 Hz）
fs = 1/framePeriod;  % 采样频率
f_low  = 0.1;        % 下限，Hz   ~ 6 BPM
f_high = 0.5;        % 上限，Hz   ~30 BPM

% 二阶 Butterworth 带通
[b,a] = butter(2, [f_low, f_high]/(fs/2), 'bandpass');
R_bp = filtfilt(b, a, R_detrend);

%% 7. 频谱分析，找呼吸频率峰
Nfft = 2^nextpow2(numFrames);
F = (0:Nfft-1).' * (fs/Nfft);   % 频率轴
R_fft = fft(R_bp, Nfft);
P = abs(R_fft).^2;              % 能量谱

% 只看 0.05~1 Hz 区间（更宽一点）
f_min = 0.05; f_max = 1.0;
idx_band = (F >= f_min) & (F <= f_max);

[~, idx_pk] = max(P(idx_band));
f_br = F(idx_band);
f_br = f_br(idx_pk);            % 呼吸频率（Hz）

BR_bpm = f_br * 60;             % 转成 次/分钟

fprintf('估计呼吸频率 BR ≈ %.2f Hz (≈ %.1f 次/分钟)\n', f_br, BR_bpm);

%% 8. 画图看看结果

figure;
subplot(3,1,1);
plot(t, R_rep_filled, '-o');
xlabel('时间 (s)'); ylabel('代表距离 R_{rep} (m)');
title('每帧代表人体的距离（原始）');
grid on;

subplot(3,1,2);
plot(t, R_bp);
xlabel('时间 (s)'); ylabel('带通信号 (m)');
title('带通后（0.1~0.5 Hz）的距离起伏');
grid on;

subplot(3,1,3);
plot(F(idx_band), P(idx_band));
xlabel('频率 (Hz)'); ylabel('谱能量');
title(sprintf('距离起伏的功率谱，BR ≈ %.1f 次/分钟', BR_bpm));
grid on;
