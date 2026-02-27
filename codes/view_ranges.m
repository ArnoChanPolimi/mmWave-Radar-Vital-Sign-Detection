% view_ranges.m
% 从 uart_raw_frame.mat 解析所有帧，并画出目标距离

clear; clc;

% 1) 读采集好的原始字节流
load uart_raw_frame.mat   % 里面应该有 rawBuf

% 2) 解析所有帧
frames = parseAllFrames(rawBuf);

fprintf('总共解析到 %d 帧。\n', numel(frames));

if isempty(frames)
    error('没有解析到任何帧，请检查 rawBuf / 采集是否成功。');
end

% 3) 画某几帧的距离分布（比如第 1 帧和最后一帧）
figure;
stem(frames(1).R, 'filled');
xlabel('目标索引');
ylabel('距离 R (m)');
title('第 1 帧检测到的目标距离');
grid on;

if numel(frames) > 1
    figure;
    stem(frames(end).R, 'filled');
    xlabel('目标索引');
    ylabel('距离 R (m)');
    title(sprintf('第 %d 帧检测到的目标距离', frames(end).frameNumber));
    grid on;
end

% 4) 也可以画“时间-距离”的简单示意：每帧取最小距离作为代表
nF = numel(frames);
minR = zeros(nF,1);
for k = 1:nF
    if isempty(frames(k).R)
        minR(k) = NaN;
    else
        minR(k) = min(frames(k).R);
    end
end

figure;
plot(1:nF, minR, '-o');
xlabel('帧号索引');
ylabel('每帧最近目标距离 (m)');
title('随时间变化的最近目标距离');
grid on;
