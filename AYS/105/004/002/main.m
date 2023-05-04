Experiment.StartNewSection('Analysis');

sExpCode = "EXP-105-201-002";

[vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days] = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-105-002-100'), '01 Analysis', 'Time to Progression and Censor.mat'),...
    'vdTimeToProgressionPerSample_days', 'vdTimeToCensorPerSample_days');


% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);



[m2dROCXAndCI, m2dROCYAndCI, vdAUCAndCI, vdMCRAndCI, vdFPRAndCI, vdFNRAndCI, dPointIndexForOptThres, dAUC_0Point632PlusPerBootstrap, vbPredictedLabelPerSample, dMCRForPredictedLabels, dFPRForPredictedLabels, dFNRForPredictedLabels,...
    vdRPAGroupPerSample, vdPointIndexPerRPAGroupCutPoint] =...
    CalculateAverageROCErrorMetricsAndPredictedLabels(sExpCode, oRadiomicDataSet);

hFig = PerformKMAnalysis(vdRPAGroupPerSample, vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days);

savefig(hFig, fullfile(Experiment.GetResultsDirectory(), "KM Plot.fig"));
delete(hFig);

FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'RPA Groups.mat'),...
    'm2dRPAGroupPerSample', vdRPAGroupPerSample);

ExportDataForSASAnalysis(vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, vdRPAGroupPerSample);







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


function [m2dROCXAndCI, m2dROCYAndCI, vdAUCAndCI, vdMCRAndCI, vdFPRAndCI, vdFNRAndCI, dPointIndexForOptThres, dAUC_0Point632PlusPerBootstrap, vbPredictedLabelPerSample, dMCRForPredictedLabels, dFPRForPredictedLabels, dFNRForPredictedLabels, vdRPAGroupPerSample, vdPointIndexPerRPAGroupCutPoint] = CalculateAverageROCErrorMetricsAndPredictedLabels(sExpCode, oReferenceDataSet)

viGroupIdPerSample = oReferenceDataSet.GetGroupIds();
viSubGroupIdPerSample = oReferenceDataSet.GetSubGroupIds();

dNumSamples = oReferenceDataSet.GetNumberOfSamples();



sExpResultsPath = ExperimentManager.GetPathToExperimentAssetResultsDirectory(sExpCode);

[c1oGuessResultsPerPartition, c1oOOBGuessResultsPerPartition] = FileIOUtils.LoadMatFile(fullfile(sExpResultsPath, "02 Bootstrapped Iterations ", "Partitions & Guess Results.mat"), "c1oGuessResultsPerPartition", "c1oOOBSamplesGuessResultsPerPartition");
vdAUC_0Point632PlusPerBootstrap = FileIOUtils.LoadMatFile(fullfile(sExpResultsPath, "03 Performance", "AUC Metrics.mat"), "vdAUC_0Point632PlusPerBootstrap");

dAUC_0Point632PlusPerBootstrap = mean(vdAUC_0Point632PlusPerBootstrap);

dNumBootstraps = length(c1oGuessResultsPerPartition);

c1vdConfidencesPerBootstrap = cell(dNumBootstraps,1);
c1vdTrueLabelsPerBootstrap = cell(dNumBootstraps,1);

c1vdOOBConfidencesPerBootstrap = cell(dNumBootstraps,1);
c1vdOOBTrueLabelsPerBootstrap = cell(dNumBootstraps,1);

dPosLabel = c1oGuessResultsPerPartition{1}.GetPositiveLabel();

for dBootstrapIndex=1:dNumBootstraps
    oGuessResult = c1oGuessResultsPerPartition{dBootstrapIndex};
    
    c1vdConfidencesPerBootstrap{dBootstrapIndex} = oGuessResult.GetPositiveLabelConfidences();
    c1vdTrueLabelsPerBootstrap{dBootstrapIndex} = oGuessResult.GetLabels();
    
    oOOBGuessResult = c1oOOBGuessResultsPerPartition{dBootstrapIndex};
    
    c1vdOOBConfidencesPerBootstrap{dBootstrapIndex} = oOOBGuessResult.GetPositiveLabelConfidences();
    c1vdOOBTrueLabelsPerBootstrap{dBootstrapIndex} = oOOBGuessResult.GetLabels();
end

% Use perfcurve and non-OOB samples to calculate AUC
[m2dROCXAndCI, m2dROCYAndCI, vdT, vdAUCAndCI] = perfcurve(c1vdTrueLabelsPerBootstrap, c1vdConfidencesPerBootstrap, dPosLabel, 'TVals', 0:0.001:1);

% Use perfcurve and OOB samples to find optimal threshold (upper
% left)
[m2dOOBX, m2dOOBY, vdOOBT, ~] = perfcurve(c1vdOOBTrueLabelsPerBootstrap, c1vdOOBConfidencesPerBootstrap, dPosLabel, 'TVals', 0:0.001:1);

vdUpperLeftDist = ((m2dOOBX(:,1)).^2) + ((1-m2dOOBY(:,1)).^2);
[~,dMinIndex] = min(vdUpperLeftDist);
dOptThres = vdOOBT(dMinIndex);

% find the corresponding closest point on the non-OOB ROC for the
% same threshold
[~,dPointIndexForOptThres] = min(abs(dOptThres - vdT(:,1)));

% get FPR, FNR and MCR from ROC
vdFPRAndCI = m2dROCXAndCI(dPointIndexForOptThres,:); % since ROC
vdTPRAndCI = m2dROCYAndCI(dPointIndexForOptThres,:); % since ROC

vdFNRAndCI = 1-vdTPRAndCI; % by defn
vdTNRAndCI = 1-vdFPRAndCI; % by defn

vdFNRAndCI([2,3]) = vdFNRAndCI([3,2]); % CIs are backwards
vdTNRAndCI([2,3]) = vdTNRAndCI([3,2]); % CIs are backwards




% predicted label per sample
% average confidences of a sample across bootstraps in which it was in the
% testing set. Use the average ROC curve and operating point (from OOB
% samples) to classify the sample.

vbPredictedLabelPerSample = false(dNumSamples,1);
vbGroundTruthLabelPerSample = false(dNumSamples,1);

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
            
            vbGroundTruthLabelPerSample(dSampleIndex) = vbGuessResultIsPositivePerSample(dGuessResultSampleIndex);
        end
    end
    
    dAverageConfidence = mean(vdConfidencesPerBootstrap(~isnan(vdConfidencesPerBootstrap)));
    vdAverageConfidencePerSample(dSampleIndex) = dAverageConfidence;
    
    vbPredictedLabelPerSample(dSampleIndex)  = dAverageConfidence >= dOptThres;
end

dNumPositives = sum(vbGroundTruthLabelPerSample);
dNumNegatives = sum(~vbGroundTruthLabelPerSample);

% get realized MCR, FPR, and FNR when label was predicted for each sample
dMCRForPredictedLabels = sum(vbGroundTruthLabelPerSample ~= vbPredictedLabelPerSample) / dNumSamples;
dFPRForPredictedLabels = sum(vbPredictedLabelPerSample(~vbGroundTruthLabelPerSample)) / sum(~vbGroundTruthLabelPerSample);
dFNRForPredictedLabels = sum(~vbPredictedLabelPerSample(vbGroundTruthLabelPerSample)) / sum(vbGroundTruthLabelPerSample);

% get MCR for average ROC (needed num positives and negatives)
vdFPAndCI = vdFPRAndCI * dNumNegatives; % by defn
vdFNAndCI = vdFNRAndCI * dNumPositives; % by defn

vdMCRAndCI = (vdFPAndCI + vdFNAndCI) ./ (dNumPositives + dNumNegatives);


% RPA groups

% sub-analysis on BMs predicted to not progress to find optimal threshold
% to split this BMs using OOB samples
viValidGroupIds = viGroupIdPerSample(~vbPredictedLabelPerSample);
viValidSubGroupIds = viSubGroupIdPerSample(~vbPredictedLabelPerSample);

c1vdOOBConfidencesPerBootstrap1 = cell(dNumBootstraps,1);
c1vdOOBTrueLabelsPerBootstrap1 = cell(dNumBootstraps,1);

for dBootstrapIndex=1:dNumBootstraps    
    oOOBGuessResult = c1oOOBGuessResultsPerPartition{dBootstrapIndex};
    oOOBGuessResult = ApplySampleMask(oOOBGuessResult, viValidGroupIds, viValidSubGroupIds);
    
    c1vdOOBConfidencesPerBootstrap1{dBootstrapIndex} = oOOBGuessResult.GetPositiveLabelConfidences();
    c1vdOOBTrueLabelsPerBootstrap1{dBootstrapIndex} = oOOBGuessResult.GetLabels();
end

[m2dOOBX1, m2dOOBY1, vdOOBT1, ~] = perfcurve(c1vdOOBTrueLabelsPerBootstrap1, c1vdOOBConfidencesPerBootstrap1, dPosLabel, 'TVals', 0:0.001:1);

vdUpperLeftDist1 = ((m2dOOBX1(:,1)).^2) + ((1-m2dOOBY1(:,1)).^2);
[~,dMinIndex1] = min(vdUpperLeftDist1);
dOptThres1 = vdOOBT1(dMinIndex1);

% sub-analysis on BMs predicted to progress to find optimal threshold
% to split this BMs using OOB samples
viValidGroupIds = viGroupIdPerSample(vbPredictedLabelPerSample);
viValidSubGroupIds = viSubGroupIdPerSample(vbPredictedLabelPerSample);

c1vdOOBConfidencesPerBootstrap3 = cell(dNumBootstraps,1);
c1vdOOBTrueLabelsPerBootstrap3 = cell(dNumBootstraps,1);

for dBootstrapIndex=1:dNumBootstraps    
    oOOBGuessResult = c1oOOBGuessResultsPerPartition{dBootstrapIndex};
    oOOBGuessResult = ApplySampleMask(oOOBGuessResult, viValidGroupIds, viValidSubGroupIds);
    
    c1vdOOBConfidencesPerBootstrap3{dBootstrapIndex} = oOOBGuessResult.GetPositiveLabelConfidences();
    c1vdOOBTrueLabelsPerBootstrap3{dBootstrapIndex} = oOOBGuessResult.GetLabels();
end

[m2dOOBX3, m2dOOBY3, vdOOBT3, ~] = perfcurve(c1vdOOBTrueLabelsPerBootstrap3, c1vdOOBConfidencesPerBootstrap3, dPosLabel, 'TVals', 0:0.001:1);

vdUpperLeftDist3 = ((m2dOOBX3(:,1)).^2) + ((1-m2dOOBY3(:,1)).^2);
[~,dMinIndex3] = min(vdUpperLeftDist3);
dOptThres3 = vdOOBT3(dMinIndex3);

% now have three thresholds:
% "2", the original optimal threshold from all BMs
% "1", the optimal threshold for BMs predicted to not progress based on 2
% "3", the optimal threshold for BMs predicted to progress based on 2
% together they are used to stratify BMs into 4 RPA groups
[~,dPointIndexForOptThres1] = min(abs(dOptThres1 - vdT(:,1)));
[~,dPointIndexForOptThres2] = min(abs(dOptThres - vdT(:,1)));
[~,dPointIndexForOptThres3] = min(abs(dOptThres3 - vdT(:,1)));

vdRPAGroupPerSample = zeros(dNumSamples,1);

vdRPAGroupPerSample(vdAverageConfidencePerSample < dOptThres1) = 1;
vdRPAGroupPerSample(vdAverageConfidencePerSample >= dOptThres1 & vdAverageConfidencePerSample < dOptThres) = 2;
vdRPAGroupPerSample(vdAverageConfidencePerSample >= dOptThres & vdAverageConfidencePerSample < dOptThres3) = 3;
vdRPAGroupPerSample(vdAverageConfidencePerSample >= dOptThres3) = 4;

vdPointIndexPerRPAGroupCutPoint = [dPointIndexForOptThres1 dPointIndexForOptThres2 dPointIndexForOptThres3];

end

function oGuessResult = ApplySampleMask(oGuessResult, viValidGroupIds, viValidSubGroupIds)
    viGroupIds = oGuessResult.GetGroupIds();
    viSubGroupIds = oGuessResult.GetSubGroupIds();

    vbInclude = false(size(viGroupIds));
    
    for dSampleIndex=1:length(viGroupIds)
        if any(viGroupIds(dSampleIndex) == viValidGroupIds & viSubGroupIds(dSampleIndex) == viValidSubGroupIds)
            vbInclude(dSampleIndex) = true;
        end
    end
    
    oGuessResult = oGuessResult(vbInclude);
end

function ExportDataForSASAnalysis(vdTimeToProgressionPerSample_days, vdTimeToCensorPerSample_days, vdRPAGroupPerSample)

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
    fullfile(Experiment.GetResultsDirectory(), 'SAS Analysis Export.xlsx'),...
    'Sheet', 'Survival and Progression');

end