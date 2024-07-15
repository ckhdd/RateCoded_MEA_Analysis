function conSig = reconSig(A,numAMX,dataIn,AMXset,numCh,wdx)
    conSig=[];
    for idx=1:numAMX
        segStart = AMXset(idx); segEnd = AMXset(idx+1)-1;
        conSig(segStart,1:numCh)= [dataIn(segStart,1:numCh)];
        for jdx = (segStart+1):segEnd
            for kdx = 1:numCh
                conSig(jdx,kdx) = A(kdx,:,idx)*transpose(conSig(jdx-1,:));
            end
        end
    end
end
