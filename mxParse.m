function [M,N,totalMx,mxSet] = mxParse(data,approx)
    mxn = size(data);
    M = mxn(1); N = mxn(2); 
    totalMx = floor(M/approx); mxSet(1,1) = 1;
    for idx=1:totalMx; mxSet(1,idx+1)=(idx*approx)+1;end
end