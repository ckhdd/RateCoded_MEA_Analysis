clear all; 
warning ('off','all'); 
close all; clc;

dirProf = "/Users/SRDNM_Organoids_2DNS/"; %%% Set your Path
dirWorking = "Organoids/"; %%% Set your Working Path
dirIn = "Data/ParadigmRC/"; 
dirOut = "Data/ParadigmRC/"; 
filtLevel = "RS";

for hdx=2:3 %%% Change number of recording files
    for idx=1:2 %%% Change well row number
        switch idx
            case 1; writeCol='A';
            case 2; writeCol='B';
            case 3; writeCol='C';
            case 4; writeCol='D';
        end
        for jdx=1:6 %%% Change well column number
            writeRow = num2str(jdx); 
            currSeries = strcat(writeCol,writeRow);
            subjSI.(filtLevel).(strcat('r',num2str(hdx))).(...
                currSeries) = struct;
            fileName = strcat('R',num2str(hdx),currSeries,'.mat');
            fileIn = strcat(dirProf,dirWorking,dirIn,filtLevel, ...
                '/',fileName); 
            fileOut = strcat(dirProf,dirWorking,dirOut,filtLevel, ...
                'F/',fileName);
            inVar = load(fileIn); inVar = inVar.outVar.subjSI;

            outVar = struct; 
            currBin = inVar; currBin(currBin>0.7) = 1;
            currBin(currBin~=1) = 0;
            currDiv = inVar(:,2:end)-inVar(:,1:end-1);
            currDiv(currDiv==0) = 1e-10;
            currDivDiv = currDiv(:,2:end)-currDiv(:,1:end-1);
            currDivMob = sqrt(var(currDivDiv,[],2)./var(currDiv,[],2));
            
            valMean = mean(inVar,2); valStd = std(inVar,[],2);
            
            outVar.byChannel.autocorr = ...
                diag(corr(inVar(:,2:end)',inVar(:,1:end-1)'));                
            outVar.byChannel.cov = valStd./valMean; 
            outVar.byChannel.hjorthact = var(inVar,[],2);
            outVar.byChannel.hjorthmob = sqrt( ...
                var(currDiv,[],2)./outVar.byChannel.hjorthact);
            outVar.byChannel.hjorthcomp = currDivMob./...
                outVar.byChannel.hjorthmob;
            if (anynan(outVar.byChannel.hjorthcomp))
                outVar.byChannel.hjorthcomp(...
                    isnan(outVar.byChannel.hjorthcomp)) = 0;
            end
            outVar.byChannel.iqr = iqr(inVar,2);
            outVar.byChannel.kurtosis = kurtosis(inVar,[],2);
            outVar.byChannel.mad = mad(inVar,1,2);
            outVar.byChannel.mean = valMean;
            outVar.byChannel.median = median(inVar,2);
           
            outVar.byChannel.range = max(inVar,[],2)-min(inVar,[],2);
            outVar.byChannel.skewness = skewness(inVar,[],2);
            outVar.byChannel.std = valStd;
            outVar.byChannel.SIPct = (sum(currBin,2)./size(currBin,2));
            
            outVar.matrix.frobenius = sqrt(sum(abs(inVar).^2,'all'));
            outVar.matrix.mean = mean(inVar,'all');
            [~,~,outVar.matrix.normality,~] = kstest(inVar);
            [~,sing,~]=svd(inVar); 
            outVar.matrix.singuMax = max(diag(sing));
            outVar.matrix.singuMin = min(diag(sing));
            outVar.matrix.singuRatio = max(diag(sing))/min(diag(sing));
            meanBin = outVar.byChannel.mean;
            meanBin(meanBin>=0.7)=1; meanBin(meanBin~=1)=0;
            outVar.matrix.SinkChansPct = sum(meanBin)/size(meanBin,2);                
            outVar.matrix.SIPct = ...
                sum(currBin,'all')./numel(currBin);
            
            outVar.overall.dispAutocorr = abs(...
                max(outVar.byChannel.autocorr) - ...
                min(outVar.byChannel.autocorr));
            outVar.overall.dispHjorthact = abs(...
                max(outVar.byChannel.hjorthact) - ...
                min(outVar.byChannel.hjorthact));
            outVar.overall.dispHjorthmob = abs(...
                max(outVar.byChannel.hjorthmob) - ...
                min(outVar.byChannel.hjorthmob));
            outVar.overall.dispHjorthcomp = abs(...
                max(outVar.byChannel.hjorthcomp) - ...
                min(outVar.byChannel.hjorthcomp));
            outVar.overall.dispIqr = abs(...
                max(outVar.byChannel.iqr) - ...
                min(outVar.byChannel.iqr));
            outVar.overall.dispKurtosis = abs(...
                max(outVar.byChannel.kurtosis) - ...
                min(outVar.byChannel.kurtosis));
            outVar.overall.dispMad = abs(...
                max(outVar.byChannel.mad) - ...
                min(outVar.byChannel.mad));
            outVar.overall.dispMean = abs(...
                max(outVar.byChannel.mean) - ...
                min(outVar.byChannel.mean));
            outVar.overall.dispMedian = abs(...
                max(outVar.byChannel.median) - ...
                min(outVar.byChannel.median));
            outVar.overall.dispRange = abs(...
                max(outVar.byChannel.range) - ...
                min(outVar.byChannel.range));
            outVar.overall.dispSkewness = abs(...
                max(outVar.byChannel.skewness) - ...
                min(outVar.byChannel.skewness));
            outVar.overall.dispStd = abs(...
                max(outVar.byChannel.std) - ...
                min(outVar.byChannel.std));
            outVar.overall.dispSIPct = abs(...
                max(outVar.byChannel.SIPct) - ...
                min(outVar.byChannel.SIPct));
           
            outVar.overall.minAutocorr = ...
                min(outVar.byChannel.autocorr);
            outVar.overall.minHjorthact = ...
                min(outVar.byChannel.hjorthact);
            outVar.overall.minHjorthmob = ...
                min(outVar.byChannel.hjorthmob);
            outVar.overall.minHjorthcomp = ...
                min(outVar.byChannel.hjorthcomp);
            outVar.overall.minIqr = ...
                min(outVar.byChannel.iqr);
            outVar.overall.minKurtosis = ...
                min(outVar.byChannel.kurtosis);
            outVar.overall.minMad = ...
                min(outVar.byChannel.mad);
            outVar.overall.minMean = ...
                min(outVar.byChannel.mean);
            outVar.overall.minMedian = ...
                min(outVar.byChannel.median);
            outVar.overall.minRange = ...
                min(outVar.byChannel.range);
            outVar.overall.minSkewness = ...
                min(outVar.byChannel.skewness);
            outVar.overall.minStd = ...
                min(outVar.byChannel.std);
            outVar.overall.minSIPct = ...
                min(outVar.byChannel.SIPct);
           
            outVar.overall.maxAutocorr = ...
                max(outVar.byChannel.autocorr);
            outVar.overall.maxHjorthact = ...
                max(outVar.byChannel.hjorthact);
            outVar.overall.maxHjorthmob = ...
                max(outVar.byChannel.hjorthmob);
            outVar.overall.maxHjorthcomp = ...
                max(outVar.byChannel.hjorthcomp);
            outVar.overall.maxIqr = ...
                max(outVar.byChannel.iqr);
            outVar.overall.maxKurtosis = ...
                max(outVar.byChannel.kurtosis);
            outVar.overall.maxMad = ...
                max(outVar.byChannel.mad);
            outVar.overall.maxMean = ...
                max(outVar.byChannel.mean);
            outVar.overall.maxMedian = ...
                max(outVar.byChannel.median);
            outVar.overall.maxRange = ...
                max(outVar.byChannel.range);
            outVar.overall.maxSkewness = ...
                max(outVar.byChannel.skewness);
            outVar.overall.maxStd = ...
                max(outVar.byChannel.std);
            outVar.overall.maxSIPct = ...
                max(outVar.byChannel.SIPct);
            save(fileOut,'outVar');
        end
    end
end