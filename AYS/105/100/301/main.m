Experiment.StartNewSection('Analysis');




% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);
vbIsPositiveForProgression = oRadiomicDataSet.GetLabels() == oRadiomicDataSet.GetPositiveLabel();

sExpCodeRadiomicsModel = "EXP-105-200-002";
vdAverageConfidencePerSample_Progression = GetAverageConfidencePerSample(sExpCodeRadiomicsModel, oRadiomicDataSet);

vdGroupPerSample = zeros(123,1);

for dCode=1:5
    sLabelsCode = "LBL-55"+string(dCode);
    oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
        vsRadiomicFeatureValueCodes,...
        sLabelsCode);
    vbIsPositive = oRadiomicDataSet.GetLabels() == 1;
    vdGroupPerSample(vbIsPositive) = dCode;
end

vbKeepSample = vdGroupPerSample ~= 0;


% 5-way comparison ANOVA plot
vdSize_cm = [13.1 6.4+0.78];

% - make plot to find out size of boxes to allow for ploting of opaque boxes
hFig = figure();

hFig.Units = 'centimeter';
vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

boxplot(vdAverageConfidencePerSample_Progression(vbKeepSample), vdGroupPerSample(vbKeepSample), 'Colors', 'k');
hAnovaAxes = gca;

m2dXDataPerBoxPlotPerPoint = zeros(5,5);
m2dYDataPerBoxPlotPerPoint = zeros(5,5);

for dBoxPlotIndex=1:5
    m2dXDataPerBoxPlotPerPoint(dBoxPlotIndex,:) = hAnovaAxes.Children(1).Children(10+dBoxPlotIndex).XData;
    m2dYDataPerBoxPlotPerPoint(dBoxPlotIndex,:) = hAnovaAxes.Children(1).Children(10+dBoxPlotIndex).YData;
end

delete(hFig);

% - plot the figure
hFig = figure();

hFig.Units = 'centimeter';
vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

hAnovaAxes = axes;
hAnovaAxes.YGrid = 'on';
hold('on');

for dBoxPlotIndex=1:5
    patch(m2dXDataPerBoxPlotPerPoint(dBoxPlotIndex,1:4),m2dYDataPerBoxPlotPerPoint(dBoxPlotIndex,1:4),[1 1 1]);
end

hAnovaBoxPlot = boxplot(vdAverageConfidencePerSample_Progression(vbKeepSample), vdGroupPerSample(vbKeepSample), 'Colors', 'k');

ylim([0,0.8]);
hAnovaAxes.Children(1).Children(1).MarkerEdgeColor = 'k';
hAnovaAxes.Children(1).Children(2).MarkerEdgeColor = 'k';
hAnovaAxes.Children(1).Children(3).MarkerEdgeColor = 'k';
hAnovaAxes.Children(1).Children(4).MarkerEdgeColor = 'k';
hAnovaAxes.Children(1).Children(5).MarkerEdgeColor = 'k';

hAnovaAxes.Children(1).Children(26).LineStyle = '-';
hAnovaAxes.Children(1).Children(27).LineStyle = '-';
hAnovaAxes.Children(1).Children(28).LineStyle = '-';
hAnovaAxes.Children(1).Children(29).LineStyle = '-';
hAnovaAxes.Children(1).Children(30).LineStyle = '-';
hAnovaAxes.Children(1).Children(31).LineStyle = '-';
hAnovaAxes.Children(1).Children(32).LineStyle = '-';
hAnovaAxes.Children(1).Children(33).LineStyle = '-';
hAnovaAxes.Children(1).Children(34).LineStyle = '-';
hAnovaAxes.Children(1).Children(35).LineStyle = '-';

xticklabels(["Homogeneous", "Heterogenous", "Cystic (Simple)", "Cystic (Complex)", "Necrosis"]);
hAnovaAxes.FontName = "Arial";
hAnovaAxes.FontSize = 8;
ylabel("Predicted Probability of Progression");

hAnovaAxes.YAxis.MinorTickValues = 0.05:0.1:0.75;
hAnovaAxes.YMinorGrid = 'on';

savefig(hFig, fullfile(Experiment.GetResultsDirectory(), '5-way Qualitative Appearance Boxplot.fig'));
saveas(hFig, fullfile(Experiment.GetResultsDirectory(), '5-way Qualitative Appearance Boxplot.svg'));

delete(hFig);



% 2-way rank-sum comparison between hetergeneous + and -

% - get sizes of box plot
vdSize_cm = [5.8 6.4+0.78];

hFig = figure();

hFig.Units = 'centimeter';
vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

boxplot(vdAverageConfidencePerSample_Progression(vdGroupPerSample == 2), vbIsPositiveForProgression(vdGroupPerSample == 2), 'Colors', 'k', 'Widths', 0.45);
hRankSumAxes = gca;

m2dXDataPerBoxPlotPerPoint = zeros(2,5);
m2dYDataPerBoxPlotPerPoint = zeros(2,5);

for dBoxPlotIndex=1:2
    m2dXDataPerBoxPlotPerPoint(dBoxPlotIndex,:) = hRankSumAxes.Children(1).Children(4+dBoxPlotIndex).XData;
    m2dYDataPerBoxPlotPerPoint(dBoxPlotIndex,:) = hRankSumAxes.Children(1).Children(4+dBoxPlotIndex).YData;
end

delete(hFig);


% plot actual boxplot
hFig = figure();

hFig.Units = 'centimeter';
vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

hRankSumAxes = axes;
hRankSumAxes.YGrid = 'on';
hold on;

for dBoxPlotIndex=1:2
    patch(m2dXDataPerBoxPlotPerPoint(dBoxPlotIndex,1:4),m2dYDataPerBoxPlotPerPoint(dBoxPlotIndex,1:4),[1 1 1]);
end

boxplot(vdAverageConfidencePerSample_Progression(vdGroupPerSample == 2), vbIsPositiveForProgression(vdGroupPerSample == 2), 'Colors', 'k', 'Widths', 0.45);

ylim([0,0.8]);
hRankSumAxes.Children(1).Children(1).MarkerEdgeColor = 'k';
hRankSumAxes.Children(1).Children(2).MarkerEdgeColor = 'k';

hRankSumAxes.Children(1).Children(11).LineStyle = '-';
hRankSumAxes.Children(1).Children(12).LineStyle = '-';
hRankSumAxes.Children(1).Children(13).LineStyle = '-';
hRankSumAxes.Children(1).Children(14).LineStyle = '-';

xticklabels(["No Progression", "Progression"]);
hRankSumAxes.FontName = "Arial";
hRankSumAxes.FontSize = 8;
ylabel("Predicted Probability of Progression");

hRankSumAxes.YAxis.MinorTickValues = 0.05:0.1:0.75;
hRankSumAxes.YMinorGrid = 'on';

hRankSumAxes.XAxis.TickLength = 2.5*hRankSumAxes.XAxis.TickLength;
hRankSumAxes.YAxis.TickLength = 2.5*hRankSumAxes.YAxis.TickLength;

savefig(hFig, fullfile(Experiment.GetResultsDirectory(), '2-way Heterogeneous Boxplot.fig'));
saveas(hFig, fullfile(Experiment.GetResultsDirectory(), '2-way Heterogeneous Boxplot.svg'));

delete(hFig);


function vdAverageConfidencePerSample = GetAverageConfidencePerSample(sExpCode, oReferenceDataSet)

viGroupIdPerSample = oReferenceDataSet.GetGroupIds();
viSubGroupIdPerSample = oReferenceDataSet.GetSubGroupIds();
dNumSamples = oReferenceDataSet.GetNumberOfSamples();

sExpResultsPath = ExperimentManager.GetPathToExperimentAssetResultsDirectory(sExpCode);
[c1oGuessResultsPerPartition, c1oOOBGuessResultsPerPartition] = FileIOUtils.LoadMatFile(fullfile(sExpResultsPath, "02 Bootstrapped Iterations ", "Partitions & Guess Results.mat"), "c1oGuessResultsPerPartition", "c1oOOBSamplesGuessResultsPerPartition");

dNumBootstraps = length(c1oGuessResultsPerPartition);

vdAverageConfidencePerSample = zeros(dNumSamples,1);

for dSampleIndex=1:dNumSamples
    vdConfidencesPerBootstrap = nan(dNumBootstraps,1);
    
    iGroupId = viGroupIdPerSample(dSampleIndex);
    iSubGroupId = viSubGroupIdPerSample(dSampleIndex);
    
    for dBootstrapIndex=1:dNumBootstraps
        oGuessResult = c1oGuessResultsPerPartition{dBootstrapIndex};
        
        vdPositiveConfidencesPerSample = oGuessResult.GetPositiveLabelConfidences();
        vbGuessResultIsPositivePerSample = oGuessResult.GetLabels() == oGuessResult.GetPositiveLabel();
        
        viGuessResultGroupIdsPerSample = oGuessResult.GetGroupIds();
        viGuessResultSubGroupIdsPerSample = oGuessResult.GetSubGroupIds();
        
        dGuessResultSampleIndex = find(viGuessResultGroupIdsPerSample == iGroupId & viGuessResultSubGroupIdsPerSample == iSubGroupId);
        
        if ~isempty(dGuessResultSampleIndex)
            vdConfidencesPerBootstrap(dBootstrapIndex) = vdPositiveConfidencesPerSample(dGuessResultSampleIndex);
        end
    end
    
    dAverageConfidence = mean(vdConfidencesPerBootstrap(~isnan(vdConfidencesPerBootstrap)));
    vdAverageConfidencePerSample(dSampleIndex) = dAverageConfidence;
end

end