clear; clc;
%% ===== 用户参数 =====
cfgPort   = "COM10";      % 用户口（CLI 配置） -> Enhanced
dataPort  = "COM9";       % 数据口（雷达数据） -> Standard

cfgFile   = "profile_2d_bpm.cfg";   % 这里改成你自己的 .cfg 文件名
captureTime = 2;        % 采集时长（秒），先来 0.2 s 试一下

%% ===== 打开串口 =====
% 确保没有其它程序占用串口：Uniflash / mmWave Studio 必须关掉

% 打开 CLI 口（115200）
cliBaud = 115200;
fprintf("打开 CLI 串口 %s @ %d...\n", cfgPort, cliBaud);
cli = serialport(cfgPort, cliBaud, "Timeout", 10);
configureTerminator(cli,"LF");
flush(cli);

% 打开数据口（921600）
dataBaud = 921600;
fprintf("打开 DATA 串口 %s @ %d...\n", dataPort, dataBaud);
data = serialport(dataPort, dataBaud, "Timeout", 5);
flush(data);

%% ===== 发送 cfg 文件到雷达 =====
fprintf("发送配置文件 %s 到雷达...\n", cfgFile);

% 先停一下传感器，防止之前在跑
writeline(cli, "sensorStop");
pause(0.1);

% 读取一下 CLI 返回的信息，看看有没有 Error
pause(0.5);
while cli.BytesAvailable > 0
    resp = fgetl(cli);
    if isempty(resp), break; end
    fprintf("CLI返回: %s\n", strtrim(resp));
end


fid = fopen(cfgFile, "r");
if fid < 0
    error("打不开配置文件 %s（请确认文件名和路径）", cfgFile);
end

while ~feof(fid)
    line = strtrim(fgetl(fid));
    if isempty(line) || startsWith(line, "%") || startsWith(line,"#")
        continue;   % 跳过空行和注释
    end
    writeline(cli, line);
    pause(0.05);    % 给雷达一点处理时间
end
fclose(fid);

fprintf("配置发送完毕，启动传感器...\n");
writeline(cli, "sensorStart");
pause(0.1);

%% ===== 从数据口抓一段原始数据 =====
fprintf("开始采集数据 %.3f s...\n", captureTime);

tStart = tic;
% rawBuf = uint8([]);
rawBuf = zeros(0,1,"uint8");   % 一个 0 行 1 列的 uint8 列向量
%%

while toc(tStart) < captureTime
    n = data.NumBytesAvailable;
    if n > 0
        % rawBuf = [rawBuf; read(data, n, "uint8")]; %#ok<AGROW>
        chunk  = read(data, n, "uint8");   % 1×n
        rawBuf = [rawBuf; chunk(:)];       % 转成 n×1 列向量再往下拼
    end
    pause(0.01);
end

fprintf("采集结束，共读取 %d 字节。\n", numel(rawBuf));

%% ===== 保存到文件，后面慢慢分析 =====
outBin = "uart_raw_frame.bin";
fid = fopen(outBin, "wb");
fwrite(fid, rawBuf, "uint8");
fclose(fid);

save("uart_raw_frame.mat","rawBuf","cfgPort","dataPort","cfgFile");

fprintf("已保存到 %s 和 uart_raw_frame.mat\n", outBin);

%% ===== 简单画一下字节值，看下是不是有东西 =====
figure; 
plot(double(rawBuf(1:min(2000,end))));
xlabel("样本索引");
ylabel("字节值");
title("从数据口读到的原始字节（前 2000 个）");
grid on;
