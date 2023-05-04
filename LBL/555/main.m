Experiment.StartNewSection(ExperimentManager.chExperimentAssetsSectionName);

sLBLCode = "LBL-555";

m2dAppearanceScorePerSamplePerObserver = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-003-003-001'), '01 Process XML', 'Observer Study Appearance Scores.mat'),...
    'm2dAppearanceScorePerSamplePerObserver');

vdObservers = 1:3;
m2dAppearanceScorePerSamplePerObserver = m2dAppearanceScorePerSamplePerObserver(:,vdObservers);

dAppearanceScore = BrainMetastasisAppearanceScore.necrosis.GetFeatureValuesCategoryNumber();
viLabels = uint8(sum(m2dAppearanceScorePerSamplePerObserver == dAppearanceScore,2) >=2 );

oSS = ExperimentManager.Load("SS-001");
[vdPatientIdsPerSample, vdBrainMetastasisNumberPerSample] = oSS.GetPatientIdAndBrainMetastasisNumberPerSample();

vsFeatureNames = "Dummy Variable";

dNumSamples = length(vdPatientIdsPerSample);
m2dFeatures = zeros(dNumSamples, 1);

viGroupIds = uint8(vdPatientIdsPerSample);
viSubGroupIds = uint8(vdBrainMetastasisNumberPerSample);

vsUserDefinedSampleStrings = string(vdPatientIdsPerSample) + "-" + string(vdBrainMetastasisNumberPerSample);

oRecord = CustomFeatureExtractionRecord(sLBLCode, "Necrosis BM Appearance for Expert Consensus", m2dFeatures);

oLabelledFeatureValues = LabelledFeatureValuesByValue(...
    m2dFeatures, viGroupIds, viSubGroupIds, vsUserDefinedSampleStrings, vsFeatureNames',...
    viLabels, uint8(1), uint8(0),...
    'FeatureExtractionRecord', oRecord);

disp("Num +: " + string(sum(viLabels==1)));
disp("Num -: " + string(sum(viLabels==0)));

oLBL = Labels(sLBLCode);

oLBL.SaveLabelledFeatureValuesAsMat(oLabelledFeatureValues);
oLBL.Save();