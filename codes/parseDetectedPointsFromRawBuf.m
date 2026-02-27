function [R, detObj] = parseDetectedPointsFromRawBuf(rawBuf, rangeRes)
% 解析 xwr68xx_mmw_demo UART 数据，返回第一帧的检测点距离
% rawBuf : uint8 列向量（比如你保存的 rawBuf）
% rangeRes : 距离分辨率 (m)，对 profile_2d_bpm.cfg 是 0.044 m
%
% 输出：
%   R      : [N×1] 每个检测目标的距离 (m)
%   detObj : 结构体，包含 rangeIdx / dopplerIdx / x / y / z 等

if nargin < 2
    rangeRes = 0.044;   % 来自 profile_2d_bpm.cfg 的注释
end

rawBuf = uint8(rawBuf(:));      % 确保是列向量
bufLen = numel(rawBuf);

% ---- 1. 找 magic word（帧起始） ----
magic = uint8([2 1 4 3 6 5 8 7]).';
startIdx = [];

for i = 1:(bufLen - numel(magic) + 1)
    if all(rawBuf(i:i+7) == magic)
        startIdx = i;
        break;
    end
end

if isempty(startIdx)
    error('在 rawBuf 中找不到 magic word，数据有问题');
end

idx = startIdx + 8;   % 跳过 magic

% ---- 2. 读 frame header（8 个 uint32）----
% 结构如下（TI mmw_demo UART 输出）：
% uint16 magicWord[4];      % 8 字节
% uint32 version;           % 1
% uint32 totalPacketLen;    % 2
% uint32 platform;          % 3
% uint32 frameNumber;       % 4
% uint32 timeCpuCycles;     % 5
% uint32 numDetectedObj;    % 6
% uint32 numTLVs;           % 7
% uint32 subFrameNumber;    % 8

if idx + 8*4 - 1 > bufLen
    error('buffer 长度不足，header 不完整');
end

headerWords = typecast(rawBuf(idx:idx+8*4-1), 'uint32');
version        = headerWords(1);
totalPacketLen = double(headerWords(2));
% platform     = headerWords(3);
frameNumber    = double(headerWords(4));
% timeCpuCycles= headerWords(5);
numDetectedObj = double(headerWords(6));
numTLVs        = double(headerWords(7));
subFrameNumber = double(headerWords(8));

idx = idx + 8*4;   % 跳过 8 个 uint32，而不是 9 个
frameEnd = min(bufLen, startIdx + totalPacketLen - 1);


% ---- 3. 遍历 TLV，找到 type==1 (DETECTED_POINTS) ----
detPayload = [];
tlvTypes = [];

for tlvIdx = 1:numTLVs
    if idx + 8 - 1 > frameEnd
        break;
    end
    tlvHead  = typecast(rawBuf(idx:idx+7), 'uint32');
    tlvType  = double(tlvHead(1));
    tlvLen   = double(tlvHead(2));
    idx = idx + 8;

    if idx + tlvLen - 1 > frameEnd
        break;
    end
    tlvTypes(end+1) = tlvType; %#ok<AGROW>

    if tlvType == 1   % DETECTED_POINTS
        detPayload = rawBuf(idx:idx+tlvLen-1);
    end

    idx = idx + tlvLen;
end

fprintf('这一帧里的 TLV types = [%s]\n', sprintf('%d ', tlvTypes));

if isempty(detPayload) || numDetectedObj == 0
    warning('这一帧没有检测到目标或没有 DETECTED_POINTS TLV');
    R = [];
    detObj = struct('rangeIdx',[],'dopplerIdx',[],'peakVal',[],...
                    'x',[],'y',[],'z',[]);
    return;
end

% ---- 4. 按 float32 解析 DETECTED_POINTS（x,y,z,v） ----
% 对于 mmw demo: type=1 的 payload = numDetectedObj * 4 个 float32
pts = typecast(detPayload, 'single');   % 按 float32 展开
nFloats = numel(pts);

if numDetectedObj == 0
    warning('header 里 numDetectedObj=0');
    R = [];
    detObj = struct('rangeIdx',[],'dopplerIdx',[],'peakVal',[],...
                    'x',[],'y',[],'z',[]);
    return;
end

floatsPerObj = floor(nFloats / numDetectedObj);   % 正常应为 4

if mod(nFloats, numDetectedObj) ~= 0
    warning('payload float 个数和 numDetectedObj 对不上：总 float=%d, 每点取 %d 个，多出来的会被丢弃。',...
        nFloats, floatsPerObj);
end

useFloats = floatsPerObj * numDetectedObj;
pts       = pts(1:useFloats);
ptsMat    = reshape(pts, floatsPerObj, []).';     % [N x floatsPerObj]

nObj = size(ptsMat,1);

% 约定: 第1列 x, 第2列 y, 第3列 z, 第4列 v
x = double(ptsMat(:,1));
y = double(ptsMat(:,2));
z = double(ptsMat(:,3));
v = [];
if floatsPerObj >= 4
    v = double(ptsMat(:,4));
end

% ---- 5. 距离换算 ----
R = sqrt(x.^2 + y.^2 + z.^2);   % 米

detObj = struct();
detObj.x          = x;
detObj.y          = y;
detObj.z          = z;
detObj.v          = v;
detObj.rangeIdx   = [];   % 这里已不用 rangeIdx
detObj.dopplerIdx = [];
detObj.peakVal    = [];
