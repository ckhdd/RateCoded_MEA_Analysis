function A = calcAMX(numCh,approx,dataIn,AMXset,AMXcnt)
    A = []; b = []; H = zeros(numCh*(approx-1),numCh*numCh); 
    segStart = AMXset(AMXcnt)+1; segEnd = AMXset(AMXcnt+1)-1; 
    b = reshape(dataIn(segStart:segEnd,1:numCh)',numCh*(segEnd-segStart+1),1);
    row=1;
    for idx = segStart-1:segEnd-1
        E = [dataIn(idx,1:numCh)];
        for jdx = 1:numCh 
           if jdx == 1
               H(row,:) = [E(1,1:numCh) zeros(1,(numCh*numCh) - numCh)];
           elseif jdx==numCh
               H(row,:)= [zeros(1,(numCh*numCh)-numCh) E(1,1:numCh)];
           else
               H(row,:)= [H(jdx,1:(jdx-1)*numCh) E(1,1:numCh) ...
                   zeros(1,(numCh*numCh)-jdx*numCh)];
           end
           row = row + 1;
        end
    end
    if (size(dataIn,2)>approx)
        Atemp= pinv(H)*b; 
    else
        H = sparse(H);
        Atemp = H\b;
    end
    A = reshape(Atemp,size(dataIn,2),size(dataIn,2))';
end