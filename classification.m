%% Matlab Initiation
clear all; 
warning('off', 'all'); 
close all; 
clc;

%% Set random seed for reproducibility
% rng(42);

%% Feature Map Loading
dirProf = "/Users/SRDNM_Organoids_2DNS/"; %%% Set your Path
dirWorking = "Organoids/Data/ParadigmRC"; %%% Set your Working Path
featIn = load(strcat(dirProf,dirWorking,'tblFeats.mat'));

tblFeats = featIn.tblFeats; 

%% Set up Cohorts Structure
cohorts = 2; %%% Change the cohorts index to label structure

% rowsInc = 2;
% colsInc = 123;

if (cohorts == 2)
    tblFeats.CohortNominal = repmat(...
        ["Control"; "Control"; "SCZ"; "SCZ"], [6 1]); %%% Change to match the number of data points
elseif (cohorts == 8)
    tblFeats.CohortNominal = repmat(...
        ["ControlA"; "ControlA"; "SCZA"; "SCZA";
        "ControlB"; "ControlB"; "SCZB"; "SCZB";
        "ControlC"; "ControlC"; "SCZC"; "SCZC";
        "ControlD"; "ControlD"; "SCZD"; "SCZD"
        ], [3 1]);
elseif (cohorts == 3)
    tblFeats.CohortNominal = repmat(...
        ["Control"; "Control"; "SCZ"; "SCZ"; "BPD"; "BPD"], [4 1]); %%% Change to match the number of data points
elseif (cohorts == 12)
    tblFeats.CohortNominal = repmat(...
        ["ControlA"; "ControlA"; "SCZA"; "SCZA"; "BPDA"; "BPDA";
        "ControlB"; "ControlB"; "SCZB"; "SCZB"; "BPDB"; "BPDB";
        "ControlC"; "ControlC"; "SCZC"; "SCZC"; "BPDC"; "BPDC";
        "ControlD"; "ControlD"; "SCZD"; "SCZD"; "BPDD"; "BPDD"
        ], [3 1]);
end

currFeats = tblFeats(:,4:end); % Extract Features by Eliminate the "Plate Number", "Plate_Row", "Plate_Column"

%% Feature Selection Using MRMR (Minimum Redundancy Maximum Relevance)
[priorPred, predPrior] = fscmrmr(currFeats, "CohortNominal");

predImps = string([currFeats.Properties.VariableNames(1:end-1)]');
predOut = [predImps(priorPred') priorPred' predPrior(priorPred)'];
predOut = predOut(1:floor(length(predOut)), :);
bar(str2double(predOut(:,3)));
xlabel("Predictor");
ylabel("Estimated Confidence");
set(gca, 'xtick', 1:length(predOut));
xticklabels(strrep(predOut(:,1), "_", "/_"));
xtickangle(45);

% Select the best 3 features
selectedFeatures = predOut(1:3, 1);
currFeats = currFeats(:, [selectedFeatures; "CohortNominal"]);

%% Define number of trials
numTrials = 20;    %%% Change the number of trials
bestLoss = Inf;
bestSVMModel = [];
bestCVSVMModel = [];
bestY_pred = [];
bestScores = [];

for trial = 1:numTrials
    %% SVM with Kernel
    X = currFeats{:, 1:end-1}; % Features
    Y = currFeats.CohortNominal; % Labels

    % Convert Y to categorical
    Y = categorical(Y);

    % Train the SVM model with kernel
    SVMModel = fitcsvm(X, Y, 'Standardize',true, 'KernelFunction', 'polynomial', 'OptimizeHyperparameters', 'auto','KernelScale','auto','HyperparameterOptimizationOptions',struct('MaxObjectiveEvaluations',200,'UseParallel',true));
    % SVMModel = fitcecoc(X, Y, 'OptimizeHyperparameters', 'auto');
    % SVMModel = fitPosterior(SVMModel); % Fit posterior probabilities

    % Cross-validation
    CVSVMModel = crossval(SVMModel);
    loss = kfoldLoss(CVSVMModel);
    disp(['Trial ', num2str(trial), ' cross-validated loss: ', num2str(loss)]);

    if loss < bestLoss
        bestLoss = loss;
        bestSVMModel = SVMModel;
        bestCVSVMModel = CVSVMModel;
        bestY_pred = kfoldPredict(CVSVMModel);

        % Create a meshgrid for the 3 selected features
        [x1Grid, x2Grid, x3Grid] = meshgrid(linspace(min(X(:,1)), max(X(:,1)), 50), ...
                                            linspace(min(X(:,2)), max(X(:,2)), 50), ...
                                            linspace(min(X(:,3)), max(X(:,3)), 50));
        xGrid = [x1Grid(:), x2Grid(:), x3Grid(:)];

        % Predict scores over grid
        [~, scores] = predict(SVMModel, xGrid);
        bestScores = scores;
    end
end

disp(['Best cross-validated loss: ', num2str(bestLoss)]);

%% Confusion Matrix
figure;
cm = confusionchart(Y, bestY_pred);
cm.Title = 'Confusion Matrix';
% cm.RowSummary = 'row-normalized';
set(gca, 'FontName', 'Arial', 'FontSize', 14);

%% 3D Visualization and Decision Boundary
X = currFeats{:, 1:end-1}; % Features

% Plot 3D scatter plot
figure;
gscatter3(X(:,1), X(:,2), X(:,3), Y);
xlabel(selectedFeatures(1), 'Interpreter', 'latex');
ylabel(selectedFeatures(2), 'Interpreter', 'latex');
zlabel(selectedFeatures(3), 'Interpreter', 'latex');

% Optimize axis scales for clear visualization
xlim([min(X(:,1)) max(X(:,1))]);
ylim([min(X(:,2)) max(X(:,2))]);
zlim([min(X(:,3)) max(X(:,3))]);

% Apply scientific font and color style
set(gca, 'FontName', 'Arial', 'FontSize', 14, 'LineWidth', 1.5, 'Box', 'on', 'GridLineStyle', '--');
set(gca, 'XColor','k', 'YColor', 'k', 'ZColor', 'k', 'Color', 'none');
set(gcf, 'Color', 'w');

alpha(0.6); % Set transparency

% Reshape scores to match the grid dimensions
scoresGrid = reshape(bestScores(:,2), size(x1Grid));

% Plot the decision boundary as an isosurface
hold on;
colors = lines(numel(categories(Y)));
p = patch(isosurface(x1Grid, x2Grid, x3Grid, scoresGrid, 0.2),'FaceAlpha', 0.25);
p.FaceColor = colors(1,:);
p.EdgeColor = 'none';
p.LineStyle = '--';
isonormals(x1Grid, x2Grid, x3Grid, scoresGrid, p);



% Enhance plot appearance for publication
xlabel(selectedFeatures(1), 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel(selectedFeatures(2), 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
zlabel(selectedFeatures(3), 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
title('Control vs SCZ in 2D Neurons Baseline', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% title('Control vs SCZ vs BPD in Organoids Baseline', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% title('Control vs SCZ in 2D Neurons After Electrical Stimulus', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% title('Control vs SCZ vs BPD in Organoids After Electrical Stimulus', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
grid on;
legend(categories(Y), 'Location', 'best', 'FontName', 'Arial', 'FontSize', 12);

view(3); % Set the view to 3D
camlight; lighting phong; % Add lighting for better visual effect

function gscatter3(x, y, z, g)
    % for 3D scatter plot with grouping variable
    groups = unique(g);
    hold on;
    colors = lines(length(groups));
    markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};
    for i = 1:length(groups)
        idx = g == groups(i);
        scatter3(x(idx), y(idx), z(idx), 100, colors(i,:), markers{i}, 'filled', 'MarkerEdgeColor', 'k');
    end
    hold off;
end

%% Uncomment for Muticlass Classification on Organoids Data
% %% MATLAB Initiation
% clear all;
% warning('off', 'all');
% close all;
% clc;
% 
% %% Set random seed for reproducibility
% rng default;
% 
% %% Feature Map Loading
% dirProf = "/Users/chengkai/Downloads/SarmaPipeline/";
% dirWorking = "Organoids/Data/ParadigmRC/";
% featIn = load(strcat(dirProf,dirWorking,'tblFeats.mat'));
% 
% tblFeats = featIn.tblFeats;
% 
% %% Set up Cohorts Structure
% cohorts = 3;
% 
% if (cohorts == 2)
%     tblFeats.CohortNominal = repmat(...
%         ["Control"; "Control"; "SCZ"; "SCZ"], [6 1]);
% elseif (cohorts == 8)
%     tblFeats.CohortNominal = repmat(...
%         ["ControlA"; "ControlA"; "SCZA"; "SCZA";
%         "ControlB"; "ControlB"; "SCZB"; "SCZB";
%         "ControlC"; "ControlC"; "SCZC"; "SCZC";
%         "ControlD"; "ControlD"; "SCZD"; "SCZD"], [3 1]);
% elseif (cohorts == 3)
%     tblFeats.CohortNominal = repmat(...
%         ["Control"; "Control"; "SCZ"; "SCZ"; "BPD"; "BPD"], [12 1]);
% elseif (cohorts == 12)
%     tblFeats.CohortNominal = repmat(...
%         ["ControlA"; "ControlA"; "SCZA"; "SCZA"; "BPDA"; "BPDA";
%         "ControlB"; "ControlB"; "SCZB"; "SCZB"; "BPDB"; "BPDB";
%         "ControlC"; "ControlC"; "SCZC"; "SCZC"; "BPDC"; "BPDC";
%         "ControlD"; "ControlD"; "SCZD"; "SCZD"; "BPDD"; "BPDD"], [3 1]);
% end
% 
% currFeats = tblFeats(:,4:end); % Extract Features by Eliminate the "Plate Number", "Plate_Row", "Plate_Column"
% 
% %% Feature Selection Using MRMR (Minimum Redundancy Maximum Relevance)
% [priorPred, predPrior] = fscmrmr(currFeats, "CohortNominal");
% 
% predImps = string([currFeats.Properties.VariableNames(1:end-1)]');
% predOut = [predImps(priorPred') priorPred' predPrior(priorPred)'];
% predOut = predOut(1:floor(length(predOut)), :);
% bar(str2double(predOut(:,3)));
% xlabel("Predictor");
% ylabel("Estimated Confidence");
% set(gca, 'xtick', 1:length(predOut));
% xticklabels(strrep(predOut(:,1), "_", "/_"));
% xtickangle(45);
% 
% % Select the best 3 features
% selectedFeatures = predOut(1:3, 1);
% currFeats = currFeats(:, [selectedFeatures; "CohortNominal"]);
% 
% %% Define number of trials
% numTrials = 10; 
% bestLoss = Inf;
% bestModel = [];
% bestY_pred = [];
% bestScores = [];
% 
% for trial = 1:numTrials
%     %% Train the model using fitcauto
%     X = currFeats{:, 1:end-1}; % Features 24 x 3
%     Y = currFeats.CohortNominal; % Labels 24 x 1
% 
%     % Convert Y to categorical
%     Y = categorical(Y);
% 
%     % Train the model with automatic hyperparameter optimization
%     options = statset('UseParallel',true);
%     t = templateSVM('Standardize',true,'KernelFunction','polynomial');
%     SVMModel = fitcecoc(X, Y, 'Learners',t,'OptimizeHyperparameters', 'auto','Options',options,'HyperparameterOptimizationOptions',struct('MaxObjectiveEvaluations',200));
%     % cv = cvpartition(Y, 'KFold', 5);
%     % options = struct("Optimizer","asha", "UseParallel",true, "MaxObjectiveEvaluations", 500, "CVPartition", cv);
% 
%     % [model, Results] = fitcauto(X, Y, 'Learners', 'all', "OptimizeHyperparameters", "all", "ClassNames", ["Control", "SCZ", "BPD"], "HyperparameterOptimizationOptions", options);
% 
% 
%     % Cross-validation
%     CVSVMModel = crossval(SVMModel);
%     loss = kfoldLoss(CVSVMModel);
%     disp(['Trial ', num2str(trial), ' cross-validated loss: ', num2str(loss)]);
% 
%     % Store the best model
%     if loss < bestLoss
%         bestLoss = loss;
%         bestSVMModel = SVMModel;
%         bestCVSVMModel = CVSVMModel;
%         bestY_pred = kfoldPredict(CVSVMModel);       
% 
%     end
% end
% 
% disp(['Best cross-validated loss: ', num2str(bestLoss)]);
% 
% %% Confusion Matrix
% figure;
% cm = confusionchart(Y, bestY_pred);
% cm.Title = 'Confusion Matrix';
% set(gca, 'FontName', 'Arial', 'FontSize', 14);
% 
% %% 3D Visualization and Decision Boundary
% X = currFeats{:, 1:end-1}; % Features
% 
% % Plot 3D scatter plot
% figure;
% gscatter3(X(:,1), X(:,2), X(:,3), Y);
% xlabel(currFeats.Properties.VariableNames{1}, 'Interpreter', 'latex');
% ylabel(currFeats.Properties.VariableNames{2}, 'Interpreter', 'latex');
% zlabel(currFeats.Properties.VariableNames{3}, 'Interpreter', 'latex');
% 
% xlim([min(X(:,1)) max(X(:,1))]);
% ylim([min(X(:,2)) max(X(:,2))]);
% zlim([min(X(:,3)) max(X(:,3))]);
% 
% set(gca, 'FontName', 'Arial', 'FontSize', 14, 'LineWidth', 1.5, 'Box', 'on', 'GridLineStyle', '--');
% set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', 'Color', 'none');
% set(gcf, 'Color', 'w');
% 
% 
% xlabel(currFeats.Properties.VariableNames{1}, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
% ylabel(currFeats.Properties.VariableNames{2}, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
% zlabel(currFeats.Properties.VariableNames{3}, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
% % title('Control vs SCZ in 2D Neurons Baseline', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% % title('Control vs SCZ vs BPD in Organoids Baseline', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% % title('Control vs SCZ in 2D Neurons After Electrical Stimulus', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% title('Control vs SCZ vs BPD in Organoids After Electrical Stimulus', 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
% grid on;
% 
% alpha(0.6);
% 
% view(3);
% camlight; 
% lighting phong;
% 
% % Generate grid points over the feature space
% [x1Grid, x2Grid, x3Grid] = meshgrid(linspace(min(X(:,1)), max(X(:,1)), 50), ...
%                                     linspace(min(X(:,2)), max(X(:,2)), 50), ...
%                                     linspace(min(X(:,3)), max(X(:,3)), 50));
% xGrid = [x1Grid(:), x2Grid(:), x3Grid(:)];
% 
% % Predict the labels of the grid points
% [~, scores] = predict(bestSVMModel, xGrid);
% 
% % Reshape scores into the size of the grid
% scores = reshape(scores, [size(x1Grid,1), size(x2Grid,2), size(x3Grid,3), size(scores,2)]);
% 
% % Plot decision boundaries
% hold on;
% colors = lines(numel(categories(Y)));
% for i = 1:numel(categories(Y))
%     fv = isosurface(x1Grid, x2Grid, x3Grid, scores(:,:,:,i), -0.2);
%     if ~isempty(fv.vertices)
%         p = patch(fv, 'FaceColor', colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.25);
%         isonormals(x1Grid, x2Grid, x3Grid, scores(:,:,:,i), p);
%     end
% end
% 
% legend({'Control', 'SCZ', 'BPD'}, 'Location', 'best', 'FontName', 'Arial', 'FontSize', 12);
% hold off;
% 
% function gscatter3(x, y, z, g)
%     % groups = unique(g);
%     groups = {'Control', 'SCZ', 'BPD'};
%     hold on;
%     colors = lines(length(groups));
%     markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};
%     for i = 1:length(groups)
%         idx = g == groups(i);
%         % disp("plotting", groups(i))
%         scatter3(x(idx), y(idx), z(idx), 100, colors(i,:), markers{i}, 'filled', 'MarkerEdgeColor', 'k');
%     end
%     hold off;
% end

