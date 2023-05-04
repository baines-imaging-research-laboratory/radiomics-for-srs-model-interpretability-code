Experiment.StartNewSection('Analysis');

% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);

vsObserverCodes = ["101","102","103","104","105","106"]; % Observer 1, 2, 3, 4, 5, Expert Consensus
vsAppearanceCodes = ["001","002","003","004","005","006","007"]; % homogeneous, heterogeneous, cystic simple, cystic complex, necrosis, homogeneous/hetergeneous, heterogeneous/necrosis

dNumObservers = length(vsObserverCodes);
dNumAppearances = length(vsAppearanceCodes);

dNumSamples = oRadiomicDataSet.GetNumberOfSamples();

c2stErrorMetricsPerObserverPerAppearance = cell(dNumObservers, dNumAppearances);

m3bPredictedLabelPerSamplePerObserverPerAppearance = zeros(dNumSamples, dNumObservers, dNumAppearances);

for dObserverIndex=1:dNumObservers
    disp("---");
    disp(dObserverIndex);
    disp("---");
    
    for dAppearanceIndex=1:dNumAppearances
        disp(dAppearanceIndex);
        sExpCode = "EXP-105-"+vsObserverCodes(dObserverIndex)+"-"+vsAppearanceCodes(dAppearanceIndex);
        
        [m2dROCXAndCI, m2dROCYAndCI, vdAUCAndCI, vdMCRAndCI, vdFPRAndCI, vdFNRAndCI, dOptimalROCThreshold, dPointIndexForOptimalROCIndex, dAUC_0Point632Plus,...
            vdAverageConfidencePerSample, vbPredictedLabelPerSample, dMCRForPredictedLabels, dFPRForPredictedLabels, dFNRForPredictedLabels] =...
            CalculateAverageROCErrorMetricsAndPredictedLabels(sExpCode,oRadiomicDataSet);
        
        c2stErrorMetricsPerObserverPerAppearance{dObserverIndex, dAppearanceIndex} = struct(...
            'm2dROCXAndCI', m2dROCXAndCI, 'm2dROCYAndCI', m2dROCYAndCI, 'vdAUCAndCI', vdAUCAndCI, 'dAUC_0Point632Plus', dAUC_0Point632Plus,...
            'vdMCRAndCI', vdMCRAndCI, 'vdFPRAndCI', vdFPRAndCI, 'vdFNRAndCI', vdFNRAndCI, 'dOptimalROCThreshold', dOptimalROCThreshold, 'dPointIndexForOptimalROCIndex', dPointIndexForOptimalROCIndex,...
            'vdAverageConfidencePerSample', vdAverageConfidencePerSample,...
            'dMCRForPredictedLabels', dMCRForPredictedLabels, 'dFPRForPredictedLabels', dFPRForPredictedLabels, 'dFNRForPredictedLabels', dFNRForPredictedLabels);
        m3bPredictedLabelPerSamplePerObserverPerAppearance(:, dObserverIndex, dAppearanceIndex) = vbPredictedLabelPerSample;
    end
end
   
FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'Error Metrics and Predicted Labels.mat'),...
    'c2stErrorMetricsPerObserverPerAppearance', c2stErrorMetricsPerObserverPerAppearance,...
    'm3bPredictedLabelPerSamplePerObserverPerAppearance', m3bPredictedLabelPerSamplePerObserverPerAppearance);




function [m2dROCXAndCI, m2dROCYAndCI, vdAUCAndCI, vdMCRAndCI, vdFPRAndCI, vdFNRAndCI, dOptThres, dPointIndexForOptThres, dAUC_0Point632PlusPerBootstrap, vdAverageConfidencePerSample, vbPredictedLabelPerSample, dMCRForPredictedLabels, dFPRForPredictedLabels, dFNRForPredictedLabels] = CalculateAverageROCErrorMetricsAndPredictedLabels(sExpCode, oReferenceDataSet)



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

end



