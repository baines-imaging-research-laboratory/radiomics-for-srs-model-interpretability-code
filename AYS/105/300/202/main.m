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

vdSize_cm = [17.5 19.1];
dFontSize = 8;
sFont = "Arial";

hFig = figure;

hFig.Units = 'centimeter';
vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

tiledlayout(8,5, 'Padding', 'none', 'TileSpacing', 'compact');

vdFeaturesToPlot = [1 2 3 4 5 6 9 11];

vsFeaturesToPlotNames = [
    "GLRLM Gray-Level Non-Uniformity"
    "NGTDM Contrast"
    "GLCM Inverse Difference Normalized"
    "GLSZM Zone Entropy"
    "GLCM Inverse Variance"
    "GLSZM Zone Percentage"    
    "GLRLM Gray-Level Non-Uniformity Normalized"    
    "GLCM Correlation"
    ];

c1vdPlotYLimPerFeatures = {
    [-0.02 0.065]
    [-0.06 0.02]
    [-0.01 0.08]
    [-0.015 0.06]
    [-0.02 0.05]
    [-0.065 0.035]
    [-0.02 0.04]
    [-0.045 0.09]
    };

c1vdPlotYGridLines = {
    -0.02:0.02:0.06
    -0.06:0.02:0.02
     0.00:0.02:0.08
     0:0.02:0.06
     -0.02:0.02:0.04
     -0.06:0.02:0.02
     -0.02:0.02:0.04
     -0.03:0.03:0.09
};

c1vdPlotXGridLines = {
    2000:3000:8000
    0.1:0.1:0.5
    0.85:0.05:0.95
    5:1:7
    0.1:0.1:0.4
    0.1:0.1:0.5
    0.01:0.03:1.03
    0.5:0.1:0.9
};


for dFeaturePlotIndex=1:length(vdFeaturesToPlot)    
    dFeatureIndex = vdFeaturesToPlot(dFeaturePlotIndex);
    
    
    oFeatureValues = oRadiomicDataSet(:,oRadiomicDataSet.GetFeatureNames() == vsFeatureNamesToAnalyze(dFeatureIndex));
    vdFeatureValues = oFeatureValues.GetFeatures();
    
    vdMin = zeros(6,1);
    vdMax = zeros(6,1);
    
    [c1vdALEIntervalCentresPerFeature_Progression, c1vdAverageALEValuesPerFeature_Progression] = ...
            FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(vsExpCodePerLabel(1)), '01 Analysis', 'ALE Analysis.mat'),...
            'c1vdALEIntervalCentresPerFeature', 'c1vdAverageALEValuesPerFeature');
    
    vdMin(1) = min(c1vdAverageALEValuesPerFeature_Progression{dFeatureIndex});
    vdMax(1) = max(c1vdAverageALEValuesPerFeature_Progression{dFeatureIndex});
        
    for dLabelIndex=2:dNumLabels   
        
        nexttile;
        
        %%%plot(vdFeatureValues, c1vdPlotYLimPerFeatures{dFeaturePlotIndex}(1), '.k');
        hold on;
        
        [c1vdALEIntervalCentresPerFeature, c1vdAverageALEValuesPerFeature] = ...
            FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(vsExpCodePerLabel(dLabelIndex)), '01 Analysis', 'ALE Analysis.mat'),...
            'c1vdALEIntervalCentresPerFeature', 'c1vdAverageALEValuesPerFeature');
        
        vdMin(dLabelIndex) = min(c1vdAverageALEValuesPerFeature{dFeatureIndex});
        vdMax(dLabelIndex) = max(c1vdAverageALEValuesPerFeature{dFeatureIndex});
        
         plot(...
            [min(vdFeatureValues), c1vdALEIntervalCentresPerFeature{dFeatureIndex}, max(vdFeatureValues)],...
            [c1vdAverageALEValuesPerFeature_Progression{dFeatureIndex}(1), c1vdAverageALEValuesPerFeature_Progression{dFeatureIndex}, c1vdAverageALEValuesPerFeature_Progression{dFeatureIndex}(end)],...
            '-k', 'LineWidth', 0.5);
        plot(...
            [min(vdFeatureValues), c1vdALEIntervalCentresPerFeature{dFeatureIndex}, max(vdFeatureValues)],...
            [c1vdAverageALEValuesPerFeature{dFeatureIndex}(1), c1vdAverageALEValuesPerFeature{dFeatureIndex}, c1vdAverageALEValuesPerFeature{dFeatureIndex}(end)],...
            '-k', 'LineWidth', 1.5);
        
        ylim(c1vdPlotYLimPerFeatures{dFeaturePlotIndex});              
        xlim([min(vdFeatureValues) max(vdFeatureValues)]);
        
        hAxes = gca;
        
        hAxes.YTick = c1vdPlotYGridLines{dFeaturePlotIndex};
        hAxes.XTick = c1vdPlotXGridLines{dFeaturePlotIndex};
        
        hAxes.XGrid = 'on';
        hAxes.YGrid = 'on';
        
        if dLabelIndex ~= 2
            hAxes.YTickLabel = {};
        end
        
        if dLabelIndex == 4
            xlabel(vsFeaturesToPlotNames(dFeaturePlotIndex));
        end
                    
        if dFeaturePlotIndex == 4 && dLabelIndex == 2
            ylabel("Accumulated Local Effect on Model Predicted Probabilities");
        end
    end
    
    disp([min(vdMin) max(vdMax)]);
end

saveas(hFig, fullfile(Experiment.GetResultsDirectory(), 'ALE Plot Comparison.svg'));
savefig(hFig, fullfile(Experiment.GetResultsDirectory(), 'ALE Plot Comparison.fig'));

delete(hFig);


hFig = figure;

hold on;

plot(...
    [1 0],...
    [0 1],...
    '-k', 'LineWidth', 1.5);
plot(...
    [0 1],...
    [1 0],...
    '-k', 'LineWidth', 0.5);

legend("Appearance Experiments", "Post-SRS Progression Experiment   ", 'Location', 'southoutside');

saveas(hFig, fullfile(Experiment.GetResultsDirectory(), 'ALE Plot Comparison Legend.svg'));
savefig(hFig, fullfile(Experiment.GetResultsDirectory(), 'ALE Plot Comparison Legend.fig'));

delete(hFig);

