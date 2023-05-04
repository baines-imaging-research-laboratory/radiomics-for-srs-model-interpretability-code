Experiment.StartNewSection('Analysis');

chExpReferenceCode = 'AYS-105-300-101';

[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);

vsFeatureNamesToAnalyze = [
    "original_glrlm_GrayLevelNonUniformity"
    "original_ngtdm_Contrast"
    "original_glcm_Idn"
    "original_glszm_ZoneEntropy"
    "original_glcm_InverseVariance"
    "original_glszm_ZonePercentage"
    "original_gldm_DependenceEntropy"
    "original_shape_SurfaceVolumeRatio"
    "original_glrlm_GrayLevelNonUniformityNormalized"
    "original_firstorder_Kurtosis"
    "original_glcm_Correlation"
    "original_firstorder_10Percentile"
    "original_glcm_Imc2"
    "original_glcm_ClusterShade"
    "original_ngtdm_Busyness"
    "original_glszm_LargeAreaLowGrayLevelEmphasis"
    "original_shape_Flatness"
];

dNumBootstrapReps = 250;
dNumFeatures = length(vsFeatureNamesToAnalyze);

c2vdALEValuesPerBootstrapPerFeature = cell(dNumBootstrapReps, dNumFeatures);
c1vdALEIntervalCentresPerFeature = {};

for dBootstrapRepIndex=1:dNumBootstrapReps
    chFilename = ['Iteration ', StringUtils.num2str_PadWithZeros(dBootstrapRepIndex, length(num2str(dNumBootstrapReps))), ' Results.mat'];
    
    if dBootstrapRepIndex == 1
        [c1vdALEValuePerIntervalPerFeature,c1vdALEIntervalCentresPerFeature] = FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(chExpReferenceCode), '01 ALE Analysis', chFilename),...
            'c1ALEValuePerIntervalPerFeature', 'c1vdIntervalCentresPerFeature');
    else
        c1vdALEValuePerIntervalPerFeature = FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(chExpReferenceCode), '01 ALE Analysis', chFilename),...
            'c1ALEValuePerIntervalPerFeature');
    end
    
    for dFeatureIndex=1:dNumFeatures
        if ~isempty(c1vdALEValuePerIntervalPerFeature{dFeatureIndex})
            c2vdALEValuesPerBootstrapPerFeature{dBootstrapRepIndex,dFeatureIndex} = c1vdALEValuePerIntervalPerFeature{dFeatureIndex};
        end
    end
end


c1vdAverageALEValuesPerFeature = cell(dNumFeatures,1);
c1m2dALEValues95CIPerFeature = cell(dNumFeatures,1);

for dFeatureIndex=1:dNumFeatures    
    m2dALEValuesPerBootstrap = zeros(dNumBootstrapReps,length(c1vdALEIntervalCentresPerFeature{dFeatureIndex}));    
    vbRemoveRow = false(dNumBootstrapReps,1);
    
    for dBootstrapRepIndex=1:dNumBootstrapReps
        if isempty(c2vdALEValuesPerBootstrapPerFeature{dBootstrapRepIndex,dFeatureIndex})
            vbRemoveRow(dBootstrapRepIndex) = true;
        else
            m2dALEValuesPerBootstrap(dBootstrapRepIndex,:) = c2vdALEValuesPerBootstrapPerFeature{dBootstrapRepIndex,dFeatureIndex};
        end
    end
    
    m2dALEValuesPerBootstrap = m2dALEValuesPerBootstrap(~vbRemoveRow,:); % some bootstraps may not have used a feature due to correlation filter
    
    hFig = figure();
    hold on;
    
    vdAverageALEValues = mean(m2dALEValuesPerBootstrap);
    
    plot(c1vdALEIntervalCentresPerFeature{dFeatureIndex}, vdAverageALEValues,'-k');
    
    m2d95CIPerALEValue = zeros(2,length(vdAverageALEValues));
    
    for dPointIndex=1:length(vdAverageALEValues)
        vdSorted = sort(m2dALEValuesPerBootstrap(:,dPointIndex),'ascend');
        m2d95CIPerALEValue(1,dPointIndex) = vdSorted(round(0.05*size(m2dALEValuesPerBootstrap,1)));
        m2d95CIPerALEValue(2,dPointIndex) = vdSorted(round(0.95*size(m2dALEValuesPerBootstrap,1)));
    end
    
    plot(c1vdALEIntervalCentresPerFeature{dFeatureIndex}, m2d95CIPerALEValue(1,:),'-r');
    plot(c1vdALEIntervalCentresPerFeature{dFeatureIndex}, m2d95CIPerALEValue(2,:),'-r');
    
    oFeatureValues = oRadiomicDataSet(:,oRadiomicDataSet.GetFeatureNames() == vsFeatureNamesToAnalyze(dFeatureIndex));
    vdFeatureValues = oFeatureValues.GetFeatures();
    
    hAxes = gca;
    plot(vdFeatureValues, hAxes.YLim(1), '.k');
    
    title(vsFeatureNamesToAnalyze(dFeatureIndex),'Interpreter','none');
    
    savefig(hFig, fullfile(Experiment.GetResultsDirectory(), "ALE Plot (" + vsFeatureNamesToAnalyze(dFeatureIndex) + ").fig"));
    delete(hFig);
    
    % aggregate results for saving
    c1vdAverageALEValuesPerFeature{dFeatureIndex} = vdAverageALEValues;
    c1m2dALEValues95CIPerFeature{dFeatureIndex} = m2d95CIPerALEValue;
end

FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'ALE Analysis.mat'),...
    'vsFeatureNames', vsFeatureNamesToAnalyze,...
    'c1vdALEIntervalCentresPerFeature', c1vdALEIntervalCentresPerFeature,...
    'c1vdAverageALEValuesPerFeature', c1vdAverageALEValuesPerFeature,...
    'c1m2dALEValues95CIPerFeature', c1m2dALEValues95CIPerFeature);




