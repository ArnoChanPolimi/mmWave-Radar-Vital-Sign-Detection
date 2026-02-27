function [rangeAxis, rangeProfile] = parseRangeProfile(rawBuf, rangeRes, numRangeBins)
% 从 rawBuf 中解析出第 1 帧的 RANGE_PROFILE TLV
% rawBuf:  uint8 列向量
% rangeRes: 距离分辨率 (m)，比如 0.044
% numRangeBins: 距离 bin 数，比如 256

if nargin < 2
    rangeRes = 0.044;     % 来自 cfg 注释
end
if nargin < 3
    numRangeBins = 256;   % 来自 cfg：Num ADC Samples
end

magic = uint8([2 1 4 3 6 5 8 7]).';   % 帧头 magic word
bufLen = numel(rawBuf);

%--- 1. 找到第一个 magic word 位置
startIdx = [];
for i = 1:(bufLen - numel(magic) + 1)
    if all(rawBuf(i:i+7) == magic)
        startIdx = i;
        break;
    end
end
if isempty(startIdx)
    error('在 rawBuf 里找不到 magic word，数据有问题');
end

idx = startIdx + 8;  % 跳过 magic

%--- 2. 读 frame header（9 个 uint32）
if idx + 9*4 - 1 > bufLen
    error('buffer 太短，header 不完整');
end
headerWords = typecast(rawBuf(idx:idx+9*4-1), 'uint32');
version         = headerWords(1);
totalPacketLen  = headerWords(2);
numTLVs         = headerWords(8);

% 你可以 disp(version/numTLVs 看看
% fprintf('version=0x%08X, numTLVs=%d, totalLen=%d\n',version,numTLVs,totalPacketLen);

idx = idx + 9*4;  % 跳过 header

%--- 3. 依次遍历 TLV，找到 type==2 的 RANGE_PROFILE
rangeProfile = [];
for t = 1:numTLVs
    if idx + 8 - 1 > bufLen
        break;
    end
    tlvHead = typecast(rawBuf(idx:idx+7), 'uint32');
    tlvType = tlvHead(1);
    tlvLen  = tlvHead(2);
    idx = idx + 8;  % 到 payload 起始位置
    
    if idx + tlvLen - 1 > bufLen
        break;
    end
    tlvPayload = rawBuf(idx:idx+tlvLen-1);
    idx = idx + tlvLen;
    
    if tlvType == 2   % RANGE_PROFILE
        % payload 是 numRangeBins 个 uint16
        vals = typecast(tlvPayload, 'uint16');
        rangeProfile = double(vals(1:numRangeBins));
        break;
    end
end

if isempty(rangeProfile)
    error('这一帧里没有 RANGE_PROFILE TLV（type=2），检查 guiMonitor / cfg');
end

%--- 4. 距离轴（米）
rangeAxis = (0:numRangeBins-1).' * rangeRes;
end
