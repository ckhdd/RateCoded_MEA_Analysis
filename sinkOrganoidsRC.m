clear all; 
warning ('off','all'); 
close all; 
clc;
dirProf = "/Users/SRDNM_Organoids_2DNS/"; %%% Set your Path
dirWorking = "Organoids/"; %%% Set your Working Path
dirIn = "Data/ParadigmRC/"; 
dirOut = "Data/ParadigmRC/"; 
filtLevel = "R";
subjSI = struct; 
% baseLen = 60000; 

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
            fileName = strcat('R',num2str(hdx),currSeries,'.mat');
            fileIn = strcat(dirProf,dirWorking,dirIn,filtLevel, ...
                '/','R',num2str(hdx),'/',writeCol,'/',fileName); 
            inVar = load(fileIn); inVar = inVar.outVar; 
            outVar = struct; subjData = [];
            chansList = fieldnames(inVar);
            for kdx=1:numel(chansList)
                currChan = string(chansList(kdx));
                subjData(:,kdx) = inVar.(currChan);
            end
            outDir = strcat(dirProf,dirWorking,dirOut,filtLevel,'S/');
            fileOut = strcat(outDir,fileName);
            [outVar.subjSI,outVar.Amats] = calcSinkIndex(subjData,500);
            save(fileOut,'outVar');
            clear subjSI subjData
        end
    end
end