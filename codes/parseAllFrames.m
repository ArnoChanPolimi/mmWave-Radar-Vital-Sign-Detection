function frames = parseAllFrames(rawBuf)
    rawBuf = uint8(rawBuf(:));
    bufLen = numel(rawBuf);
    magic  = uint8([2 1 4 3 6 5 8 7]).';

    frames = struct('frameNumber',{},'R',{},'x',{},'y',{},'z',{});
    idx = 1;

    while idx + 8 <= bufLen
        % 在当前位置之后找 magic
        found = [];
        for i = idx : (bufLen-7)
            if all(rawBuf(i:i+7) == magic)
                found = i;
                break;
            end
        end
        if isempty(found)
            break;                     % 没有更多帧了
        end
        startIdx = found;
        idx = startIdx + 8;

        % 读 header（8 个 uint32）
        if idx + 8*4 - 1 > bufLen
            break;
        end
        headerWords = typecast(rawBuf(idx:idx+8*4-1), 'uint32');
        frameNumber    = double(headerWords(4));
        totalPacketLen = double(headerWords(2));
        numDetectedObj = double(headerWords(6));
        numTLVs        = double(headerWords(7));
        idx = idx + 8*4;
        frameEnd = min(bufLen, startIdx + totalPacketLen - 1);

        % 遍历 TLV，找 type==1（点云）
        detPayload = [];
        for t = 1:numTLVs
            if idx + 8 - 1 > frameEnd, break; end
            tlvHead  = typecast(rawBuf(idx:idx+7), 'uint32');
            tlvType  = double(tlvHead(1));
            tlvLen   = double(tlvHead(2));
            idx = idx + 8;
            if idx + tlvLen - 1 > frameEnd, break; end
            if tlvType == 1
                detPayload = rawBuf(idx:idx+tlvLen-1);
            end
            idx = idx + tlvLen;
        end

        if ~isempty(detPayload) && numDetectedObj > 0
            % 按 float32 解析 x,y,z,v
            pts      = typecast(detPayload, 'single');
            nFloats  = numel(pts);
            floatsPerObj = floor(nFloats / numDetectedObj);  % 应该是 4
            useFloats = floatsPerObj * numDetectedObj;
            pts      = pts(1:useFloats);
            ptsMat   = reshape(pts, floatsPerObj, []).';
            x = double(ptsMat(:,1));
            y = double(ptsMat(:,2));
            z = double(ptsMat(:,3));
            R = sqrt(x.^2 + y.^2 + z.^2);

            k = numel(frames)+1;
            frames(k).frameNumber = frameNumber;
            frames(k).R = R;
            frames(k).x = x;
            frames(k).y = y;
            frames(k).z = z;
        end

        % 跳到这一帧末尾的下一个字节，继续找下一帧
        idx = frameEnd + 1;
    end
end
