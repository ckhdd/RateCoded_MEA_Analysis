%% Matlab Setting
clear all; 
warning ('off','all'); 
close all; 
clc;

%% Analysis Selection
% Data_Selected = "2D Baseline"; %%% Uncomment for 2D Neurons Baseline Data Analysis
% Data_Selected = "2D After Stimulus"; %%% Uncomment for 2D Neurons After Stimulus Data Analysis
Data_Selected = "3D Baseline"; %%% Uncomment for 3D Organoids Baseline Data Analysis
% Data_Selected = "3D After Stimulus"; %%% Uncomment for 3D Organoids After Stimulus Data Analysis


%% File Path Setting
switch Data_Selected
    case '2D Baseline'
        filePrefix = "2D neuron 1min sponta rec";  
        fileSuffix = " data+SpikeData.csv";     
    case '2D After Stimulus'
        filePrefix = "2D neuron sim 10 pulses 0 afterstm1to5sec data";
        fileSuffix = "+SpikeData.csv";

    case '3D Baseline'
        filePrefix = "Organoids 1min sponta rec"; 
        fileSuffix = " data+SpikeData.csv"; 
    case '3D After Stimulus'
        filePrefix = "Organoid sim 10 pulses data analysis"; 
        fileSuffix = " after stim+SpikeData.csv";
end 


dirProf = "/Users/SRDNM_Organoids_2DNS/"; %%% Set your Path
dirWorking = "Organoids/Data/ParadigmRC/R/"; %%% Set your Working Path
headersFixed = ["Well","Treatment","Conc(M)", ...
    "TOI(min)","Channel in well","Channel","Selected","Time_of_day", ...
    "Within_session_time","Within_session_time(ms)", ...
    "Within_trace_time(ms)","Cluster_id","Trace","Pre(ms)","Post(ms)", ...
    "Interspike_interval(ms)","ConcFinal(M)"];
headersRemove = ["Treatment","Conc(M)","TOI(min)","Channel","Selected", ...
    "Time_of_day","Within_session_time","Within_trace_time(ms)", ...
    "Cluster_id","Trace","Pre(ms)","Post(ms)","ConcFinal(M)"];
headersVar = strcat("y",string(num2str((0:70)')),"(uv)");
headersSort = {'Well','Channel in well','Within_session_time(ms)'};
headersSortDir = {'ascend','ascend','ascend'};

%% MEA Recording Parameters
recTime = 60;  %%% change recording duration (sec)
recFreq = 20000; %%% change sampling frequency
ratecode = 200;
basePts = recFreq*recTime*1000;


%% Data Loading and Preprocessing
for hdx=1:3 %%% Change number of recording files
recNum = num2str(hdx);
rec.filename = strcat(filePrefix,recNum,fileSuffix);
rec.opts = detectImportOptions(rec.filename);
rec.data = readtable(rec.filename,rec.opts);
rec.data.Properties.VariableNames(1:17) = headersFixed;
rec.data.Properties.VariableNames(18:88) = headersVar;
rec.data(:,headersRemove) = [];
rec.data = sortrows(rec.data,headersSort,headersSortDir);

for idx=1:4 %%% Change well row number
    switch idx
        case 1; writeCol='A';
        case 2; writeCol='B';
        case 3; writeCol='C';
        case 4; writeCol='D';
    end
    for jdx=1:6 %%% Change well column number
        writeRow = num2str(jdx); currSeries = strcat(writeCol,writeRow);
        for kdx=1:16 %%% 16 Channels
            if (kdx<10)
                writeChan = strcat('w0',num2str(kdx));
            else
                writeChan = strcat('w',num2str(kdx));
            end
            currRows = ( ...
                strcmp(rec.data.("Well"),strcat(writeCol,writeRow)) ...
                & rec.data.("Channel in well") == kdx);
            currData = table2array(rec.data(currRows,[3 5:end]));
            clear currRows 
            downTime = zeros(basePts/recFreq,1);
            for ldx=1:size(currData,1)
                disp(strcat(num2str(hdx),",",num2str(idx),",",num2str(jdx),",",num2str(kdx),",",num2str(ldx)));
                [~,maxdx] = max(currData(ldx,2:end));
                currPt = currData(ldx)+maxdx/20;
                binTime = max(floor(currPt),1);
                downTime(binTime) = downTime(binTime)+1;
            end 
            rec.(currSeries).(writeChan) = movmean(downTime,ratecode);
        end
    end
end

for idx=1:2 %%% Change well row number
    switch idx
        case 1; writeCol='A';
        case 2; writeCol='B';
        case 3; writeCol='C';
        case 4; writeCol='D';
    end
    dirOut = strcat('R',recNum,'/',writeCol,'/');
    for jdx=1:6 %%% Change well column number
        writeRow = num2str(jdx); currSeries = strcat(writeCol,writeRow);
        outVar = rec.(currSeries); 
        outVarName = strcat("R",recNum,currSeries);
        mkdir(strcat(dirProf,dirWorking,dirOut));
        outPath = strcat(dirProf,dirWorking,dirOut,outVarName);
        save(outPath,"outVar");
        clear outVar;
    end
end
end