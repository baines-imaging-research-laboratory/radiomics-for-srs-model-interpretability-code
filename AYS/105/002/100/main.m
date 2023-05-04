Experiment.StartNewSection('Analysis');

oDB = ExperimentManager.Load('DB-001');

[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
    sHPOCode, sObjFcnCodeForHPO,...
    sFeatureSelectorCode, ~] = ...
    ExperimentManager.LoadExperimentManifestCodesMatFile();

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);

dNumSamples = oRadiomicDataSet.GetNumberOfSamples();

viGroupIds = oRadiomicDataSet.GetGroupIds();
viSubGroupIds = oRadiomicDataSet.GetSubGroupIds();

vdTimeToProgressionPerSample_days = zeros(dNumSamples,1);
vdTimeToCensorPerSample_days = zeros(dNumSamples,1);

for dSampleIndex=1:dNumSamples
    oPatient = oDB.GetPatientByPrimaryId(viGroupIds(dSampleIndex));
    oBM = oPatient.GetBrainMetastasis(viSubGroupIds(dSampleIndex));
    
    if ~isempty(oBM.GetInFieldProgressionDate())
        vdTimeToProgressionPerSample_days(dSampleIndex) = days(oBM.GetInFieldProgressionDate() - oPatient.GetFirstSRSTreatmentDate());
    end
    
    vdTimeToCensorPerSample_days(dSampleIndex) = days(oPatient.GetDateOfDeath() - oPatient.GetFirstSRSTreatmentDate());    
end

FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'Time to Progression and Censor.mat'),...
    'vdTimeToProgressionPerSample_days', vdTimeToProgressionPerSample_days,...
    'vdTimeToCensorPerSample_days', vdTimeToCensorPerSample_days);



