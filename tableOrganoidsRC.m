clear all; 
warning ('off','all'); 
close all; 
clc;
dirProf = "/Users/SRDNM_Organoids_2DNS/"; %%% Set your Path
dirWorking = "Organoids/"; %%% Set your Working Path
dirIn = "Data/ParadigmRC/"; 
dirOut = "Data/ParadigmRC/"; 
filtLevel = "RSF";

tblFeats = table; fieldList = []; chanRay = string(num2str([1:16]'));
chanRay = strrep(chanRay,' ','');

for hdx=2:3
    for idx=1:2
        switch idx
            case 1; writeCol='A';
            case 2; writeCol='B';
            case 3; writeCol='C';
            case 4; writeCol='D';
        end
        for jdx=1:6
            writeRow = num2str(jdx);
            currSeries = strcat(writeCol,writeRow);
            tblRow = [hdx;idx;jdx];
            if (hdx==2 && idx==1 && jdx==2) %%% Change hdx 1 or 2
                fieldList = ["Plate";"Plate_Row";"Plate_Column"];
            end
            subjSI.(filtLevel).(strcat('r',num2str(hdx))).(...
                currSeries) = struct;
            fileName = strcat('R',num2str(hdx),currSeries,'.mat');
            fileIn = strcat(dirProf,dirWorking,dirIn,filtLevel, ...
                '/',fileName); 
            inVar = load(fileIn); inVar = inVar.outVar; 
            measList = fields(inVar.byChannel);
            for kdx=1:numel(measList)
                currMeas = string(measList(kdx));
                tblRow = [tblRow;inVar.byChannel.(currMeas)];
                if (hdx==2 && idx==1 && jdx==2) %%% Change hdx 1 or 2
                    fieldList = [fieldList;strcat(currMeas,'_',chanRay)];
                end
            end
            matrixList = fieldnames(inVar.matrix);
            for kdx=1:numel(matrixList)
                currMatrix = string(matrixList(kdx));
                tblRow = [tblRow;inVar.matrix.(currMatrix)];
                if (hdx==2 && idx==1 && jdx==2) %%% Change hdx 1 or 2
                    fieldList = [fieldList;currMatrix];
                end
            end
            overallList = fieldnames(inVar.overall);
            for kdx=1:numel(overallList)
                currVer = string(overallList(kdx));
                tblRow = [tblRow;inVar.overall.(currVer)];
                if (hdx==2 && idx==1 && jdx==2) %%% Change hdx 1 or 2
                    fieldList = [fieldList;currVer];
                end
            end
            tblFeats = [tblFeats;array2table(tblRow')];
        end
    end
end
tblFeats.Properties.VariableNames = fieldList';
save(strcat(dirProf,dirWorking,dirOut,"tblFeats.mat"),'tblFeats');