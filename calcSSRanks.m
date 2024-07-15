function [SSIRank, SSISort, row_ranks, col_ranks] = calcSSRanks(A,approx)
    numCh = size(A,1);
    A_Abs = abs(A);
    A_Abs(1:numCh+1:end) = 0; % set diagonals to zero

    %% Compute row and column sums 
    sum_A_Row = sum(A_Abs,2)';
    sum_A_Col = sum(A_Abs,1);

    %% Identify sources/sinks
    % Rank channels from lowest (1) to highest (nCh) based on row sum
    % Rank the channels from highest (1) to lowest (nCh) based on col sum
    % Sum the two ranks => Sinks = high rank sum ; Sources = low rank sum   
    [~, sort_ch_r] = sort(sum_A_Row,'descend'); 
    [~, row_ranks] = sort(sort_ch_r); % rearrange sorted ch back to 1:nCh 
    row_ranks = row_ranks./numCh;

    [~, sort_ch_c] = sort(sum_A_Col,'descend');
    [~, col_ranks] = sort(sort_ch_c); % rearrange sorted ch back to 1:nCh 
    col_ranks = col_ranks./numCh;
    SSIRank = sqrt(2) - sqrt((1-row_ranks).^2+(1/numCh-col_ranks).^2);
    % SinkRank = SinkRank./max(SinkRank);
    % SSIRank = zeros(1,numCh);
    % for idx=1:numCh
    %     for jdx=1:numCh
    %         SSIRank(idx) = SSIRank(idx) + SinkRank(jdx)*abs(A(idx,jdx));
    %     end
    % end
    % SSIRank = SSIRank./max(SSIRank);
    [~, SSISort] = sort(SSIRank);
    
end