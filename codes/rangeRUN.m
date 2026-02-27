clear; clc;
load uart_raw_frame.mat

[R, detObj] = parseDetectedPointsFromRawBuf(rawBuf);   % 不传 rangeRes 也行

fprintf('这一帧检测到 %d 个目标。\n', numel(R));

if isempty(R)
    disp('没有目标。');
else
    disp('每个目标的距离 R (m)：');
    disp(R.');

    % 散点图
    figure;
    stem(R, 'filled');
    xlabel('目标索引');
    ylabel('距离 R (m)');
    title('这一帧检测到的目标距离');
    grid on;

    % 距离直方图
    figure;
    histogram(R, 0:0.2:10);     % 你关心 0~10 m 的范围
    xlabel('距离 (m)');
    ylabel('目标数');
    title('目标距离分布');
    grid on;
end
