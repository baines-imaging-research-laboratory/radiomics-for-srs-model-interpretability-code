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

vdSize_cm = [17.5 12];
dFontSize = 8;
sFont = "Arial";

hFig = figure;

hFig.Units = 'centimeter';
vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

tiledlayout(5,5, 'Padding', 'none', 'TileSpacing', 'compact');

vdFeaturesToPlot = [7 8 10 12 13];

vsFeaturesToPlotNames = [
    "GLDM Dependence Entropy"
    "Shape & Size Surface Volume Ratio"
    "First Order Kurtosis"
    "First Order 10^{ th} Percentile"
    "GLCM Informational Measure of Correlation 2"];

c1vdPlotYLimPerFeatures = {
    [-0.03 0.06]
    [-0.03 0.07]
    [-0.03 0.06]
    [-0.04 0.14]
    [-0.08 0.04]
    };

c1vdPlotYGridLines = {
    -0.02:0.02:0.06
    -0.02:0.02:0.06
    -0.02:0.02:0.06
    -0.04:0.04:0.12
    -0.08:0.04:0.04
};

vdPlotLims = [-0.08, 0.14];

for dFeaturePlotIndex=1:length(vdFeaturesToPlot)    
    dFeatureIndex = vdFeaturesToPlot(dFeaturePlotIndex);
    
    
    oFeatureValues = oRadiomicDataSet(:,oRadiomicDataSet.GetFeatureNames() == vsFeatureNamesToAnalyze(dFeatureIndex));
    vdFeatureValues = oFeatureValues.GetFeatures();
    
    [c1vdALEIntervalCentresPerFeature_Progression, c1vdAverageALEValuesPerFeature_Progression] = ...
            FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(vsExpCodePerLabel(1)), '01 Analysis', 'ALE Analysis.mat'),...
            'c1vdALEIntervalCentresPerFeature', 'c1vdAverageALEValuesPerFeature');
    
    for dLabelIndex=2:dNumLabels   
        
        nexttile;
        
        %%%plot(vdFeatureValues, c1vdPlotYLimPerFeatures{dFeaturePlotIndex}(1), '.k');
        hold on;
        
        [c1vdALEIntervalCentresPerFeature, c1vdAverageALEValuesPerFeature] = ...
            FileIOUtils.LoadMatFile(...
            fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory(vsExpCodePerLabel(dLabelIndex)), '01 Analysis', 'ALE Analysis.mat'),...
            'c1vdALEIntervalCentresPerFeature', 'c1vdAverageALEValuesPerFeature');
        
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
        hAxes.XGrid = 'on';
        hAxes.YGrid = 'on';
        
        if dLabelIndex ~= 2
            hAxes.YTickLabel = {};
        end
        
        if dLabelIndex == 4
            xlabel(vsFeaturesToPlotNames(dFeaturePlotIndex));
        end
            
        if dFeaturePlotIndex == 4
            hAxes.XTick = [20000, 35000, 50000];
            hAxes.XTickLabels = ["20000", "35000", "50000"];
        end
        
        if dFeaturePlotIndex == 3 && dLabelIndex == 2
            ylabel("Accumulated Local Effect on Model Predicted Probabilities");
        end
    end
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

