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

[dKWAnovaPValue,~,stMulticompare] = kruskalwallis(vdAverageConfidencePerSample_Progression(vbKeepSample), vdGroupPerSample(vbKeepSample));

disp("Kruskal-Wallis ANOVA p: " + string(dKWAnovaPValue));

disp("Adhoc pair-wise comparisons")

for dAppearanceIndex1=1:5
    for dAppearanceIndex2=dAppearanceIndex1+1:5
        disp(string(dAppearanceIndex1) + " vs " + string(dAppearanceIndex2) + ": " +string(ranksum(vdAverageConfidencePerSample_Progression(vdGroupPerSample==dAppearanceIndex1), vdAverageConfidencePerSample_Progression(vdGroupPerSample==dAppearanceIndex2))));
    end
end

disp("Rank-sum comparisons between + and - for each appearance");
for dAppearanceIndex=1:5
    disp(string(dAppearanceIndex) + ": " + string(ranksum(vdAverageConfidencePerSample_Progression(vdGroupPerSample==dAppearanceIndex & vbIsPositiveForProgression), vdAverageConfidencePerSample_Progression(vdGroupPerSample==dAppearanceIndex & ~vbIsPositiveForProgression))));    
end

disp("Comparisons to heterogeneous +");
for dAppearanceIndex=1:5
    if dAppearanceIndex ~= 2
        disp(string(dAppearanceIndex) + ": " + string(ranksum(vdAverageConfidencePerSample_Progression(vdGroupPerSample==dAppearanceIndex), vdAverageConfidencePerSample_Progression(vdGroupPerSample==2 & vbIsPositiveForProgression))));    
    end
end

disp("Comparisons to heterogeneous -");
for dAppearanceIndex=1:5
    if dAppearanceIndex ~= 2
        disp(string(dAppearanceIndex) + ": " + string(ranksum(vdAverageConfidencePerSample_Progression(vdGroupPerSample==dAppearanceIndex), vdAverageConfidencePerSample_Progression(vdGroupPerSample==2 & ~vbIsPositiveForProgression))));    
    end
end



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