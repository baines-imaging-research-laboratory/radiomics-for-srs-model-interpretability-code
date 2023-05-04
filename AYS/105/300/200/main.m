Experiment.StartNewSection('Analysis');

vsExpCodePerLabel = [
    "AYS-105-300-001B"
    "AYS-105-300-101B"
    "AYS-105-300-102B"
    "AYS-105-300-103B"
    "AYS-105-300-104B"
    "AYS-105-300-105B"];

vsLabels = [
    "Progression"
    "Homogeneous"
    "Heterogeneous"
    "Cystic (Simple)"
    "Cystic (Complex)"
    "Necrosis"];
dNumLabels = length(vsLabels);

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

dNumFeatures = length(vsFeatureNamesToAnalyze);



m2dCorrelationToFirstLabelCoefficientPerFeaturePerLabel = zeros(dNumFeatures, dNumLabels-1);
m2dCorrelationToFirstLabelPValuePerFeaturePerLabel = zeros(dNumFeatures, dNumLabels-1);

for dFeatureIndex=1:dNumFeatures    
    hFig = figure();
    hold on;
    
    vdFirstLabelAverageALEValues = [];
    
    for dLabelIndex=1:dNumLabels    
        [c1vdALEIntervalCentresPerFeature, c1vdAverageALEValuesPerFeature] = ...
            FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(vsExpCodePerLabel(dLabelIndex)), '01 Analysis', 'ALE Analysis.mat'),...
            'c1vdALEIntervalCentresPerFeature', 'c1vdAverageALEValuesPerFeature');
        
        plot(c1vdALEIntervalCentresPerFeature{dFeatureIndex}, c1vdAverageALEValuesPerFeature{dFeatureIndex}, '-');
        
        if dLabelIndex == 1
            vdFirstLabelAverageALEValues = c1vdAverageALEValuesPerFeature{dFeatureIndex};
        else
            [dCoefficient, dPVal] = corr(vdFirstLabelAverageALEValues', c1vdAverageALEValuesPerFeature{dFeatureIndex}');
            
            m2dCorrelationToFirstLabelCoefficientPerFeaturePerLabel(dFeatureIndex, dLabelIndex-1) = dCoefficient;
            m2dCorrelationToFirstLabelPValuePerFeaturePerLabel(dFeatureIndex, dLabelIndex-1) = dPVal;
        end
    end
        
    oFeatureValues = oRadiomicDataSet(:,oRadiomicDataSet.GetFeatureNames() == vsFeatureNamesToAnalyze(dFeatureIndex));
    vdFeatureValues = oFeatureValues.GetFeatures();
    
    hAxes = gca;
    plot(vdFeatureValues, hAxes.YLim(1), '.k');
    
    title(vsFeatureNamesToAnalyze(dFeatureIndex),'Interpreter','none');
    
    legend(vsLabels, 'Location', 'eastoutside');
    
    savefig(hFig, fullfile(Experiment.GetResultsDirectory(), "ALE Comparison Plot (" + vsFeatureNamesToAnalyze(dFeatureIndex) + ").fig"));
    delete(hFig);
end

FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'ALE Correlations of Progression vs Appearances.mat'),...
    'm2dCorrelationToFirstLabelCoefficientPerFeaturePerLabel', m2dCorrelationToFirstLabelCoefficientPerFeaturePerLabel,...
    'm2dCorrelationToFirstLabelPValuePerFeaturePerLabel', m2dCorrelationToFirstLabelPValuePerFeaturePerLabel);





