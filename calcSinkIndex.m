function [sinkIndices,ABase] = calcSinkIndex(data,wnd)
    A = [];
    % determine the number of A matrices for our approximation
    [~, numCh, numAMX, AMXset] = mxParse(data,wnd);
    % estimate the A matrices on the signal
    for idx=1:numAMX
        A(:,:,idx) = calcAMX(numCh,wnd,data,AMXset,idx);        
    end
    ABase = A; A = [];
    % verify our estimated A can reconstruct the signal
    conSig = reconSig(ABase,numAMX,data,AMXset,numCh);
    conDim = size(conSig,1);
    conErrSum = round(max(sum(abs(conSig-data(1:conDim,:)))',[],'all') ...
        /size(conSig,1),3);
    conErrMax = round(max(abs(conSig-data(1:conDim,:)),[],'all'),3);
   % if (max(conErrSum) > 0.01)
   %     disp(strcat("recon error,",num2str(max(conErrSum))));
   %  disp(strcat(num2str(conErrMax),'-',num2str(conErrSum)));
   %      if (max(conErrSum)<9e4)
   %          figure; 
   %          for idx=1:16
   %              subplot(4,4,idx); 
   %              plot(data(:,idx));hold on;plot(conSig(:,idx));
   %              pause(1)
   %          end
   %          disp(num2str(wnd));
   %      end
   %      sinkIndices = NaN;
   %      return;
   % end
    for idx=1:numAMX
        A(:,:,idx) = calcAMX(numCh,wnd,conSig,AMXset,idx);
    end
    ARecon = A;
    % calculate the Source-Sink Index for our A matrices
    [sinkIndices, ~, ~, ~, ~, ~] = calcSSI(A,numCh,wnd);
end