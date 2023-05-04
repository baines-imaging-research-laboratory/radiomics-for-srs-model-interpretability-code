Experiment.StartNewSection('Analysis');

[vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days] = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-105-002-100'), '01 Analysis', 'Time to Progression and Censor.mat'),...
    'vdTimeToProgressionPerSample_days', 'vdTimeToCensorPerSample_days');


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
    
    [vdRPAGroupPerSample, hFig] = ExecuteRPAModelAndPerformKMAnalysis(vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample, vbReceived21GySRSPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days);
    
    m2dRPAGroupPerSamplePerObserver(:,dObserverIndex) = vdRPAGroupPerSample;
    
    savefig(hFig, fullfile(Experiment.GetResultsDirectory(), "Observer " + string(dObserverIndex) + " KM Plot.fig"));
    delete(hFig);

    ExportDataForSASAnalysis(vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, vdRPAGroupPerSample, dObserverIndex);
end

FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'RPA Groups Per Observer.mat'),...
    'm2dRPAGroupPerSamplePerObserver', m2dRPAGroupPerSamplePerObserver);




function [vdRPAGroupPerSample, hFig] = ExecuteRPAModelAndPerformKMAnalysis(vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample, vbReceived21GySRSPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days)
    vdRPAGroupPerSample = RodriguesHazardFunctionRPA(vbReceived21GySRSPerSample, vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample);

    hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days);
end

function vdRPAGroupPerSample = RodriguesHazardFunctionRPA(vbReceived21GySRSPerSample, vbIsHomogeneousOrHeterogeneousPerSample, vbIsHeterogeneousOrNecrosisPerSample)
    vdRPAGroupPerSample = zeros(size(vbReceived21GySRSPerSample));
    
    vdRPAGroupPerSample(vbReceived21GySRSPerSample & vbIsHomogeneousOrHeterogeneousPerSample) = 1;
    vdRPAGroupPerSample(vbReceived21GySRSPerSample & ~vbIsHomogeneousOrHeterogeneousPerSample) = 2;
    vdRPAGroupPerSample(~vbReceived21GySRSPerSample & ~vbIsHeterogeneousOrNecrosisPerSample) = 3;
    vdRPAGroupPerSample(~vbReceived21GySRSPerSample & vbIsHeterogeneousOrNecrosisPerSample) = 4;
end

function hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days)

hFig = figure();
hold('on');

vsColourPerGroup = ["k", "r", "g", "b"];

for dGroup = 1:4
    vdTimeToProgression = vdTimeToProgressionPerSample_days(vdRPAGroupPerSample == dGroup);
    vdTimeToCensor = vdTimeToCensorPerSample_days(vdRPAGroupPerSample == dGroup);
    
    vdTimeToCensor(vdTimeToProgression ~= 0) = [];
    vdTimeToProgression(vdTimeToProgression == 0) = [];
    
    [v_f,v_x] = ecdf([vdTimeToCensor; vdTimeToProgression], 'censoring', [true(size(vdTimeToCensor)); false(size(vdTimeToProgression))]);
    
    stairs([(v_x*12/365);20],100*[v_f;v_f(end)], 'Color', vsColourPerGroup(dGroup));
end

xlabel('Time to Progression (months)');
ylabel('Progressive Disease (%)');

xlim([-0.1, 20.1]);
ylim([-0.1, 60.1]);

xticks(0:3:18);
yticks(0:5:60);

grid('on');
title('Time to Progression per BM');

legend(["RPA 1" "RPA 2" "RPA 3" "RPA 4"], 'Location', 'northwest');

end


function ExportDataForSASAnalysis(vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, vdRPAGroupPerSample, dObserverIndex)

c1chHeaders = {'Group', 'Time to Event (days)', 'Event is Censor'};

vdTimeToEvent_days = vdTimeToCensorPerSample_days;
vdTimeToEvent_days(vdTimeToProgressionPerSample_days ~= 0) = vdTimeToProgressionPerSample_days(vdTimeToProgressionPerSample_days ~= 0);

vbCensored = vdTimeToProgressionPerSample_days == 0;


c1xData = [...
    CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vdRPAGroupPerSample),...
    CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vdTimeToEvent_days),...
    CellArrayUtils.MatrixOfObjects2CellArrayOfObjects(vbCensored)];
 
writecell(...
    [c1chHeaders; c1xData],...
    fullfile(Experiment.GetResultsDirectory(), "SAS Analysis Export (Obs " + string(dObserverIndex) + ").xlsx"),...
    'Sheet', 'Survival and Progression');

end