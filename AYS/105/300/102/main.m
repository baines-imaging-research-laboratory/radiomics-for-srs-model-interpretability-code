Experiment.StartNewSection('ALE Analysis');

% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);
m2dAllFeatures = oRadiomicDataSet.GetFeatures();
vsAllFeatureNames = oRadiomicDataSet.GetFeatureNames();

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
    
dNumberOfFeatures = length(vsFeatureNamesToAnalyze);
dNumBootstrapReps = 250;

dNumALEIntervals = 25;


oManager = Experiment.GetLoopIterationManager(dNumBootstrapReps, 'AvoidIterationRecomputationIfResumed', false); % "+ 1" for the train and test on full data set iteration needed for AUC_0.632

parfor dBootstrapRepIndex=1:dNumBootstrapReps    
    oManager.PerLoopIndexSetup(dBootstrapRepIndex);    

    chFilename = ['Iteration ', StringUtils.num2str_PadWithZeros(dBootstrapRepIndex, length(num2str(dNumBootstrapReps))), ' Results.mat'];       
       
    [oTrainedClassifier, oTestingSet] = FileIOUtils.LoadMatFile(...
        fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-105-200-102A'), '02 Bootstrapped Iterations', chFilename),...
        'oTrainedClassifier', 'oTestingSet');
            
    c1vdIntervalCentresPerFeature = cell(dNumberOfFeatures,1);
    c1ALEValuePerIntervalPerFeature = cell(dNumberOfFeatures,1);
    c1vdIntervalPerSamplePerFeature = cell(dNumberOfFeatures,1);
    c1vdPredictionDifferencePerSamplePerFeature = cell(dNumberOfFeatures,1);
    
    for dFeatureIndex=1:dNumberOfFeatures    
        [vdIntervalCentres, vdALEValuePerInterval, vdIntervalPerSample, vdPredictionDifferencePerSample] = AccumulatedLocalEffectsCalculator.CalculateALE(oRadiomicDataSet, vsFeatureNamesToAnalyze(dFeatureIndex), oTrainedClassifier, dNumALEIntervals);
        
        c1vdIntervalCentresPerFeature{dFeatureIndex} = vdIntervalCentres;
        c1ALEValuePerIntervalPerFeature{dFeatureIndex} = vdALEValuePerInterval;
        c1vdIntervalPerSamplePerFeature{dFeatureIndex} = vdIntervalPerSample;
        c1vdPredictionDifferencePerSamplePerFeature{dFeatureIndex} = vdPredictionDifferencePerSample;
    end
    
    % Save artifacts to disk
    FileIOUtils.SaveMatFile(...
        fullfile(Experiment.GetResultsDirectory(), chFilename),...
        'c1vdIntervalCentresPerFeature', c1vdIntervalCentresPerFeature,...
        'c1ALEValuePerIntervalPerFeature', c1ALEValuePerIntervalPerFeature,...
        'c1vdIntervalPerSamplePerFeature', c1vdIntervalPerSamplePerFeature,...
        'c1vdPredictionDifferencePerSamplePerFeature', c1vdPredictionDifferencePerSamplePerFeature);  
    
    % par manager clean-up
    oManager.PerLoopIndexTeardown();
end

oManager.PostLoopTeardown();

