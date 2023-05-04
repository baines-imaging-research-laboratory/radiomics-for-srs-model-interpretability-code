Experiment.StartNewSection('Analysis');

sFeatureImportanceExpCode_Observer = "AYS-105-001-002";
sFeatureImportanceExpCode_Model = "AYS-105-001-004";

[c2stFeatureImportanceAnalysisPerObserverPerAppearance, vsFeatureNames] = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(sFeatureImportanceExpCode_Observer), '01 Analysis', 'Feature Importance Analysis.mat'),...
    'c2stFeatureImportanceAnalysisPerObserverPerAppearance', 'vsFeatureNames');

stFeatureImportanceAnalysisForModel = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(sFeatureImportanceExpCode_Model), '01 Analysis', 'Feature Importance Analysis.mat'),...
    'stFeatureImportanceAnalysis');

dObserverNumber = 6; % expert consensus

c2xOutput = cell(109,13);

% Headers
c2xOutput(2,:) = {'Rank', 'Score', 'Feature Name', 'Score', 'Feature Name', 'Score', 'Feature Name', 'Score', 'Feature Name', 'Score', 'Feature Name', 'Score', 'Feature Name'};
c2xOutput(1,:) = {'', 'Progression', '', 'Homogeneous', '', 'Heterogeneous', '', 'Cystic (Simple)', '', 'Cystic (Complex)', '', 'Necrosis', ''};

c2xOutput(3:end,1) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects((1:107)');

% progression model feature importance rankings
vdScores = stFeatureImportanceAnalysisForModel.vdNormalizedAverageImportanceScorePerFeature;
[vdSortedScores, vdSortIndices] = sort(vdScores,'descend');

c2xOutput(3:end,2) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vdSortedScores');
c2xOutput(3:end,3) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vsFeatureNames(vdSortIndices)');

% observer-replicating models
for dAppearanceIndex=1:5 % homo..necrosis
    vdScores = c2stFeatureImportanceAnalysisPerObserverPerAppearance{dObserverNumber,dAppearanceIndex}.vdNormalizedAverageImportanceScorePerFeature;
    [vdSortedScores, vdSortIndices] = sort(vdScores,'descend');
    
    c2xOutput(3:end,4+2*(dAppearanceIndex-1)) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vdSortedScores');
    c2xOutput(3:end,4+2*(dAppearanceIndex-1)+1) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vsFeatureNames(vdSortIndices)');
end

% write to disk
writecell(c2xOutput, fullfile(Experiment.GetResultsDirectory(), 'Feature Importance Rankings Per Model.xlsx'));



% Comparison of feature importance to progression model
c2xOutput = cell(109,13);

% Headers
c2xOutput(2,:) = {'Rank', 'Score', 'Feature Name', 'Rank', 'Score', 'Rank', 'Score', 'Rank', 'Score', 'Rank', 'Score', 'Rank', 'Score'};
c2xOutput(1,:) = {'', 'Progression', '', 'Homogeneous', '', 'Heterogeneous', '', 'Cystic (Simple)', '', 'Cystic (Complex)', '', 'Necrosis', ''};

c2xOutput(3:end,1) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects((1:107)');

% progression model feature importance rankings
vdScores = stFeatureImportanceAnalysisForModel.vdNormalizedAverageImportanceScorePerFeature;
[vdSortedScores, vdSortIndices] = sort(vdScores,'descend');

c2xOutput(3:end,2) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vdSortedScores');
c2xOutput(3:end,3) = CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vsFeatureNames(vdSortIndices)');

vsFeatureNamesSortedByProgressionImportance = vsFeatureNames(vdSortIndices)';

% observer-replicating models
for dAppearanceIndex=1:5 % homo..necrosis
    vdScores = c2stFeatureImportanceAnalysisPerObserverPerAppearance{dObserverNumber,dAppearanceIndex}.vdNormalizedAverageImportanceScorePerFeature;
    [vdSortedScores, vdSortIndices] = sort(vdScores,'descend');
    
    vsSortedFeatureNames = vsFeatureNames(vdSortIndices)';
    
    for dFeatureIndex=1:107
        dFeatureMatchIndex = find(vsSortedFeatureNames == vsFeatureNamesSortedByProgressionImportance(dFeatureIndex));
        
        c2xOutput{2+dFeatureIndex,4+2*(dAppearanceIndex-1)} = dFeatureMatchIndex;
        c2xOutput{2+dFeatureIndex,4+2*(dAppearanceIndex-1)+1} = vdSortedScores(dFeatureMatchIndex);
    end
end

% write to disk
writecell(c2xOutput, fullfile(Experiment.GetResultsDirectory(), 'Feature Importance Rankings Per Model Compared To Progression Model.xlsx'));