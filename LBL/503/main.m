Experiment.StartNewSection(ExperimentManager.chExperimentAssetsSectionName);

oFeatureValues = ExperimentManager.Load("FV-500-200").GetFeatureValues();
vdAppearance = oFeatureValues.GetFeatures();
viLabels = uint8(vdAppearance == BrainMetastasisAppearanceScore.cysticSimple.GetFeatureValuesCategoryNumber()); 

oSS = ExperimentManager.Load("SS-001");

vsFeatureNames = "Dummy Variable";

[vdPatientIdsPerSample, vdBrainMetastasisNumberPerSample] = oSS.GetPatientIdAndBrainMetastasisNumberPerSample();

dNumSamples = length(vdPatientIdsPerSample);

m2dFeatures = zeros(dNumSamples, 1);

viGroupIds = uint8(vdPatientIdsPerSample);
viSubGroupIds = uint8(vdBrainMetastasisNumberPerSample);

vsUserDefinedSampleStrings = string(vdPatientIdsPerSample) + "-" + string(vdBrainMetastasisNumberPerSample);


oRecord = CustomFeatureExtractionRecord("LBL-503", "Cystic Simple BM Appearance from FV-500-200", m2dFeatures);

oLabelledFeatureValues = LabelledFeatureValuesByValue(...
    m2dFeatures, viGroupIds, viSubGroupIds, vsUserDefinedSampleStrings, vsFeatureNames',...
    viLabels, uint8(1), uint8(0),...
    'FeatureExtractionRecord', oRecord);

disp("Num +: " + string(sum(viLabels==1)));
disp("Num -: " + string(sum(viLabels==0)));

oLBL = Labels("LBL-503");

oLBL.SaveLabelledFeatureValuesAsMat(oLabelledFeatureValues);
oLBL.Save();