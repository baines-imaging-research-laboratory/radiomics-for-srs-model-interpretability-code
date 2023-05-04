Experiment.StartNewSection('Analysis');

[vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days] = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-105-002-100'), '01 Analysis', 'Time to Progression and Censor.mat'),...
    'vdTimeToProgressionPerSample_days', 'vdTimeToCensorPerSample_days');

vdRankSumPValuePerObserver = [0.007 0.02 0.03 0.003 0.005 0.009];

% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oClinicalDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsClinicalFeatureValueCodes,...
    sLabelsCode);

oDoseAndFractionationFeatureValues = oClinicalDataSet(:, oClinicalDataSet.GetFeatureNames() == "Dose And Fractionation");
vdDoseAndFractionationFeatureValues = oDoseAndFractionationFeatureValues.GetFeatures();
vbReceived21GySRSPerSample = (vdDoseAndFractionationFeatureValues == SRSTreatmentParameters.e21in1.GetFeatureValuesCategoryNumber());

vsHomogeneousOrHeterogeneousLabelCodePerObserver = ["506" "516" "526" "536" "546" "556"];
vsHeterogeneousOrNecrosisLabelCodePerObserver = ["507" "517" "527" "537" "547" "557"];

dNumObservers = length(vsHomogeneousOrHeterogeneousLabelCodePerObserver);

m2dRPAGroupPerSamplePerObserver = zeros(oClinicalDataSet.GetNumberOfSamples(), dNumObservers);

for dObserverIndex=1:dNumObservers
    oHomogeneousOrHeterogeneousLBL = ExperimentManager.Load("LBL-" + vsHomogeneousOrHeterogeneousLabelCodePerObserver(dObserverIndex));
    oHomogeneousOrHeterogeneousLabelledFeatureValues = oHomogeneousOrHeterogeneousLBL.GetLabelledFeatureValues();
    vbIsHomogeneousOrHeterogeneousPerSample = oHomogeneousOrHeterogeneousLabelledFeatureValues.GetLabels() == oHomogeneousOrHeterogeneousLabelledFeatureValues.GetPositiveLabel();
    
    oHeterogeneousOrNecrosisLBL = ExperimentManager.Load("LBL-" + vsHeterogeneousOrNecrosisLabelCodePerObserver(dObserverIndex));
    oHeterogeneousOrNecrosisLabelledFeatureValues = oHeterogeneousOrNecrosisLBL.GetLabelledFeatureValues();
    vbIsHeterogeneousOrNecrosisPerSample = oHeterogeneousOrNecrosisLabelledFeatureValues.GetLabels() == oHeterogeneousOrNecrosisLabelledFeatureValues.GetPositiveLabel();
    
    [vdRPAGroupPerSample, hFig] = ExecuteRPAModelAndPerformKMAnalysis(vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample, vbReceived21GySRSPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, vdRankSumPValuePerObserver(dObserverIndex));
    
    m2dRPAGroupPerSamplePerObserver(:,dObserverIndex) = vdRPAGroupPerSample;
    
    savefig(hFig, fullfile(Experiment.GetResultsDirectory(), "Observer " + string(dObserverIndex) + " KM Plot.fig"));
    saveas(hFig, fullfile(Experiment.GetResultsDirectory(), "Observer " + string(dObserverIndex) + " KM Plot.svg"));
    delete(hFig);
end




function [vdRPAGroupPerSample, hFig] = ExecuteRPAModelAndPerformKMAnalysis(vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample, vbReceived21GySRSPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, dRankSumPValue)
    vdRPAGroupPerSample = RodriguesHazardFunctionRPA(vbReceived21GySRSPerSample, vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample);

    hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, dRankSumPValue);
end

function vdRPAGroupPerSample = RodriguesHazardFunctionRPA(vbReceived21GySRSPerSample, vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample)
    vdRPAGroupPerSample = zeros(size(vbReceived21GySRSPerSample));
    
    vdRPAGroupPerSample(vbReceived21GySRSPerSample & vbIsHomogeneousOrHeterogeneousPerSample) = 1;
    vdRPAGroupPerSample(vbReceived21GySRSPerSample & ~vbIsHomogeneousOrHeterogeneousPerSample) = 2;
    vdRPAGroupPerSample(~vbReceived21GySRSPerSample & ~vbIsHeterogeneousOrNecrosisPerSample) = 3;
    vdRPAGroupPerSample(~vbReceived21GySRSPerSample & vbIsHeterogeneousOrNecrosisPerSample) = 4;
end

function hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, dRankSumPValue)

vdSize_cm = [17.5/2 6]; % width height
dFontSize = 8;
chFont = 'Arial';

hFig = figure();

hFig.Units = 'centimeters';

vdPosition = hFig.Position;
vdPosition(3:4) = vdSize_cm;
hFig.Position = vdPosition;

hFig.Units = 'pixels';


hold('on');

vdXTicks = 0:3:18;

m2dNumberAtRiskPerRPAGroupPerTick = zeros(4, length(vdXTicks));

vsLineStylePerGroup = ["-." "-" "-." "-"];
vdLineThickness = [1.1 1 2 2];

c1hKMPlots = cell(4,1);

for dGroup = 1:4
    vdTimeToProgression = vdTimeToProgressionPerSample_days(vdRPAGroupPerSample == dGroup);
    vdTimeToCensor = vdTimeToCensorPerSample_days(vdRPAGroupPerSample == dGroup);
    
    vdTimeToCensor(vdTimeToProgression ~= 0) = [];
    vdTimeToProgression(vdTimeToProgression == 0) = [];
    
    [v_f,v_x] = ecdf([vdTimeToCensor; vdTimeToProgression], 'censoring', [true(size(vdTimeToCensor)); false(size(vdTimeToProgression))]);
    
    c1hKMPlots{dGroup} = stairs([(v_x*12/365);18],100*[v_f;v_f(end)], 'LineWidth', vdLineThickness(dGroup), 'LineStyle', vsLineStylePerGroup(dGroup), 'Color', 'k');
    
    vdTimeToEvent_months = [vdTimeToCensor; vdTimeToProgression]*12/365;
    
    for dTickIndex=1:length(vdXTicks)
        m2dNumberAtRiskPerRPAGroupPerTick(dGroup,dTickIndex) = sum(vdTimeToEvent_months >= vdXTicks(dTickIndex));
    end
end

hAxes = gca;

hAxes.FontName = 'Arial';
hAxes.FontSize = 8;

xlabel('Time to Progression (months)');
ylabel('Progressive Disease (%)');

xlim([0, 18]);
ylim([0, 60]);

hAxes.YAxis.MinorTickValues = 5:10:55;

xticks(vdXTicks);
yticks(0:10:60);

grid('on');
hAxes.YMinorGrid = 'on';
hAxes.YMinorTick = 'on';

hAxes.Units = 'points';
hAxes.Position = [35 70 200 95];

vdTextYPositionsPerGroup = [-18 -23 -28 -33];

hAxes.Clipping = 'off';

for dGroupIndex=1:4
    line(hAxes, [-1 -2.6], [vdTextYPositionsPerGroup(dGroupIndex) vdTextYPositionsPerGroup(dGroupIndex)],...
        'LineWidth', vdLineThickness(dGroupIndex), 'LineStyle', vsLineStylePerGroup(dGroupIndex), 'Color', 'k');
    
    for dXTickIndex=1:length(vdXTicks)
        text(vdXTicks(dXTickIndex), vdTextYPositionsPerGroup(dGroupIndex), string(m2dNumberAtRiskPerRPAGroupPerTick(dGroupIndex, dXTickIndex)),...
            'FontName', 'Arial', 'FontSize', 8, 'HorizontalAlignment', 'center');
    end
end

text(hAxes, 9, -40, "Brain Metastases at Risk", 'FontName', 'Arial', 'FontSize', 8.8, 'HorizontalAlignment', 'center');

hAxes.YLabel.Position = [-1.4, 27.5, -1];

if dRankSumPValue < 0.0001
    sPValueString = "p < 0.0001";
else
    sPValueString = "p = " + string(round(dRankSumPValue, 4));
end


text(hAxes, 0.75, 52.5, sPValueString, 'FontName', 'Arial', 'FontSize', 8.8, 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

end


