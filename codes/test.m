%% TEST %%
% 拍频信号示例
fs = 10000;       % 采样频率（Hz）
t = 0:1/fs:2;   % 时间序列（0.5秒）

f1 = 440;         % 第一个频率（Hz）
f2 = 442;         % 第二个频率（Hz），略有差异，形成拍频

% 生成两个正弦波并叠加
x1 = sin(2*pi*f1*t);
x2 = sin(2*pi*f2*t);
beat = x1 + x2;

% 绘图
figure;
plot(t, beat);
xlabel('时间 (s)');
ylabel('幅度');
title(['拍频信号：f_1 = ' num2str(f1) ' Hz, f_2 = ' num2str(f2) ' Hz']);
grid on;

% 计算拍频频率
f_beat = abs(f1 - f2);
disp(['拍频频率为：' num2str(f_beat) ' Hz']);
