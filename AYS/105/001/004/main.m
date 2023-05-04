Experiment.StartNewSection('Analysis');

sExpCode = "EXP-105-200-002";

dNumBootstraps = 250;

% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);



[vdAverageImportanceScorePerFeature, vdNormalizedAverageImportanceScorePerFeature, vdAverageImportanceRankingPerFeature, vdNormalizedAverageImportanceRankingPerFeature] =...
    CalculateFeatureImportanceForExperiment(sExpCode, dNumBootstraps, oRadiomicDataSet);

stFeatureImportanceAnalysis = struct(...
    'vdAverageImportanceScorePerFeature', vdAverageImportanceScorePerFeature,...
    'vdNormalizedAverageImportanceScorePerFeature', vdNormalizedAverageImportanceScorePerFeature,...
    'vdAverageImportanceRankingPerFeature', vdAverageImportanceRankingPerFeature,...
    'vdNormalizedAverageImportanceRankingPerFeature', vdNormalizedAverageImportanceRankingPerFeature);
    
FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'Feature Importance Analysis.mat'),...
    'stFeatureImportanceAnalysis', stFeatureImportanceAnalysis,...
    'vsFeatureNames', oRadiomicDataSet.GetFeatureNames());


function [vdAverageImportanceScorePerFeature, vdNormalizedAverageImportanceScorePerFeature, vdAverageImportanceRankingPerFeature, vdNormalizedAverageImportanceRankingPerFeature] = CalculateFeatureImportanceForExperiment(sExpCode, dNumBootstraps, oRadiomicDataSet)

sResultsDirectory = ExperimentManager.GetPathToExperimentAssetResultsDirectory(sExpCode);

dTotalNumFeatures = oRadiomicDataSet.GetNumberOfFeatures();
vsFeatureNames = oRadiomicDataSet.GetFeatureNames();

m2dFeatureRankingScorePerBootstrapPerFeature = nan(dNumBootstraps, dTotalNumFeatures);
m2dFeatureRankPerBootstrapPerFeature = nan(dNumBootstraps, dTotalNumFeatures);

for dBootstrapIndex=1:dNumBootstraps
    % load artifacts from experiment
    [vbRadiomicFeatureMask, vdFeatureImportanceScores] = FileIOUtils.LoadMatFile(...
        fullfile(sResultsDirectory, "02 Bootstrapped Iterations", "Iteration " + string(StringUtils.num2str_PadWithZeros(dBootstrapIndex,3)) + " Results.mat"),...
        'vbRadiomicFeatureMask', 'vdFeatureImportanceScores');

    % get data set
    oBootstrapDataSet = oRadiomicDataSet(:, vbRadiomicFeatureMask);
    vsBootstrapFeatureNames = oBootstrapDataSet.GetFeatureNames();

    % calculate feature ranking scores
    vdFeatureRankings = zeros(size(vdFeatureImportanceScores));
    [~, vdSortIndices] = sort(vdFeatureImportanceScores, 'descend');
    
    for dFeatureIndex=1:length(vdFeatureImportanceScores)
        vdFeatureRankings(vdSortIndices(dFeatureIndex)) = dFeatureIndex;
    end
    
    vdNormalizedFeatureImportance = (vdFeatureImportanceScores - min(vdFeatureImportanceScores)) / (max(vdFeatureImportanceScores) - min(vdFeatureImportanceScores));
    
    if any(isnan(vdNormalizedFeatureImportance))
        disp('!');
        vdNormalizedFeatureImportance(isnan(vdNormalizedFeatureImportance)) = 0;
    end
    
    for dBoostrapFeatureIndex=1:oBootstrapDataSet.GetNumberOfFeatures()
        m2dFeatureRankingScorePerBootstrapPerFeature(dBootstrapIndex, vsFeatureNames==vsBootstrapFeatureNames(dBoostrapFeatureIndex)) = vdNormalizedFeatureImportance(dBoostrapFeatureIndex);
        m2dFeatureRankPerBootstrapPerFeature(dBootstrapIndex, vsFeatureNames==vsBootstrapFeatureNames(dBoostrapFeatureIndex)) = vdFeatureRankings(dBoostrapFeatureIndex);
    end
    
    m2dFeatureRankingScorePerBootstrapPerFeature(dBootstrapIndex,isnan(m2dFeatureRankingScorePerBootstrapPerFeature(dBootstrapIndex,:))) = min(m2dFeatureRankingScorePerBootstrapPerFeature(dBootstrapIndex,~isnan(m2dFeatureRankingScorePerBootstrapPerFeature(dBootstrapIndex,:))));
    m2dFeatureRankPerBootstrapPerFeature(dBootstrapIndex,isnan(m2dFeatureRankPerBootstrapPerFeature(dBootstrapIndex,:))) = max(m2dFeatureRankPerBootstrapPerFeature(dBootstrapIndex,~isnan(m2dFeatureRankPerBootstrapPerFeature(dBootstrapIndex,:))));
    
end

vdAverageImportanceScorePerFeature = mean(m2dFeatureRankingScorePerBootstrapPerFeature);
vdAverageImportanceRankingPerFeature = mean(m2dFeatureRankPerBootstrapPerFeature);

vdNormalizedAverageImportanceScorePerFeature = (vdAverageImportanceScorePerFeature - min(vdAverageImportanceScorePerFeature)) / (max(vdAverageImportanceScorePerFeature) - min(vdAverageImportanceScorePerFeature));
vdNormalizedAverageImportanceRankingPerFeature = (vdAverageImportanceRankingPerFeature - min(vdAverageImportanceRankingPerFeature)) / (max(vdAverageImportanceRankingPerFeature) - min(vdAverageImportanceRankingPerFeature));

end