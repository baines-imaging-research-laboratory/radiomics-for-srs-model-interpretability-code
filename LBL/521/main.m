Experiment.StartNewSection(ExperimentManager.chExperimentAssetsSectionName);

sLBLCode = "LBL-521";

m2dAppearanceScorePerSamplePerObserver = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-003-003-001'), '01 Process XML', 'Observer Study Appearance Scores.mat'),...
    'm2dAppearanceScorePerSamplePerObserver');

dObserver = 3;
vdAppearanceScorePerSample = m2dAppearanceScorePerSamplePerObserver(:,dObserver);

dAppearanceScore = BrainMetastasisAppearanceScore.homogeneous.GetFeatureValuesCategoryNumber();
viLabels = uint8(vdAppearanceScorePerSample == dAppearanceScore);

oSS = ExperimentManager.Load("SS-001");
[vdPatientIdsPerSample, vdBrainMetastasisNumberPerSample] = oSS.GetPatientIdAndBrainMetastasisNumberPerSample();

vsFeatureNames = "Dummy Variable";

dNumSamples = length(vdPatientIdsPerSample);
m2dFeatures = zeros(dNumSamples, 1);

viGroupIds = uint8(vdPatientIdsPerSample);
viSubGroupIds = uint8(vdBrainMetastasisNumberPerSample);

vsUserDefinedSampleStrings = string(vdPatientIdsPerSample) + "-" + string(vdBrainMetastasisNumberPerSample);

oRecord = CustomFeatureExtractionRecord(sLBLCode, "Homogeneous BM Appearance for Observer " + string(dObserver), m2dFeatures);

oLabelledFeatureValues = LabelledFeatureValuesByValue(...
    m2dFeatures, viGroupIds, viSubGroupIds, vsUserDefinedSampleStrings, vsFeatureNames',...
    viLabels, uint8(1), uint8(0),...
    'FeatureExtractionRecord', oRecord);

disp("Num +: " + string(sum(viLabels==1)));
disp("Num -: " + string(sum(viLabels==0)));

oLBL = Labels(sLBLCode);

oLBL.SaveLabelledFeatureValuesAsMat(oLabelledFeatureValues);
oLBL.Save();