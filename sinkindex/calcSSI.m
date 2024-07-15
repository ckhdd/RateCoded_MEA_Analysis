function [SSIRank, SSISort, SSIdx, RankR, RankC, meanAMX] = ...
    calcSSI(A,numCh,approx)
    % configuration settings to determine based on input
    numWnd = size(A,3); % No. of windows
    
    % calculate a mean A matrix for all windows
    meanAMX = zeros(numCh,numCh);
    for idx = 1:numCh
        for jdx = 1:numCh
            outliers = isoutlier(squeeze(abs(A(idx,jdx,:))) ...
                ,"percentiles",[0.01,98.20]);
            vals = abs(A(idx,jdx,find(~outliers)));
            meanAMX(idx,jdx) = mean(vals);
        end
    end

    % Identify overall source/sink order
    [SSIdx,SSISort,RankR,RankC] = calcSSRanks(meanAMX,approx);

    SSIRank = nan(numCh,numWnd); % source-sink rank least to most
    for idx = 1:numWnd % for each window
        % Identify sources/sinks 
        [SSIRank(:,idx),~,~,~] = calcSSRanks(squeeze(A(:,:,idx)),approx);
    end
end