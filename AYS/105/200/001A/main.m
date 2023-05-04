Experiment.StartNewSection('Loading Experiment Assets');

% load experiment asset codes
[sSSCode, vsClinicalFeatureValueCodes, vsRadiomicFeatureValueCodes, sLabelsCode, ~, sModelCode, ...
sHPOCode, sObjFcnCodeForHPO,...
sFeatureSelectorCode, ~] = ...
ExperimentManager.LoadExperimentManifestCodesMatFile();

% load experiment assets
oClinicalDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsClinicalFeatureValueCodes,...
    sLabelsCode);

oRadiomicDataSet = ExperimentManager.GetLabelledFeatureValues(...
    vsRadiomicFeatureValueCodes,...
    sLabelsCode);

% - apply sample selection
oSS = ExperimentManager.Load(sSSCode);

oClinicalDataSet = oSS.ApplySampleSelectionToFeatureValues(oClinicalDataSet);
oRadiomicDataSet = oSS.ApplySampleSelectionToFeatureValues(oRadiomicDataSet);

if isempty(oRadiomicDataSet)
    oReferenceDataset = oClinicalDataSet;
else
    oReferenceDataset = oRadiomicDataSet;
end
    
oOFN = ExperimentManager.Load(sObjFcnCodeForHPO); % OOB Samples AUC
oFS = ExperimentManager.Load(sFeatureSelectorCode); % Correlation Filter
oHPO = ExperimentManager.Load(sHPOCode); % Custom Bayesian HPO
oMDL = ExperimentManager.Load(sModelCode); % Random decision forest


% set up boot-strapped partitions
dNumBootstrapReps = 250;

Experiment.EndCurrentSection();


% Compute bootstrap iterations
Experiment.StartNewSection('Bootstrapped Iterations');

oManager = Experiment.GetLoopIterationManager(dNumBootstrapReps, 'AvoidIterationRecomputationIfResumed', true); % "+ 1" for the train and test on full data set iteration needed for AUC_0.632

for dBootstrapRepIndex=1:dNumBootstrapReps    
    disp(dBootstrapRepIndex);
    
    if oManager.IterationWasPreviouslyComputed(dBootstrapRepIndex)
        continue; % don't recomputed it!
    end
    
    oManager.PerLoopIndexSetup(dBootstrapRepIndex);
          
    chFilename = ['Iteration ', StringUtils.num2str_PadWithZeros(dBootstrapRepIndex, length(num2str(dNumBootstrapReps))), ' Results.mat'];       
       
    [oClassifier, stBootstrappedPartitions] = FileIOUtils.LoadMatFile(...
        fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('EXP-105-200-002'), '02 Bootstrapped Iterations', chFilename),...
        'oConstructedClassifier', 'stBootstrappedPartitions');
        
    % Declare variables (this avoids warnings)
    oRadiomicTuningAndTrainingSet = [];
    oRadiomicTestingSet = [];
    
    oClinicalTuningAndTrainingSet = [];
    oClinicalTestingSet = [];
    
    oTuningSet = [];
    oTrainingSet = [];
    oTestingSet = [];    
    
    % Get radiomic data
    if ~isempty(oRadiomicDataSet)
        oRadiomicTuningAndTrainingSet = oRadiomicDataSet(stBootstrappedPartitions.TrainingIndices,:);
        oRadiomicTestingSet = oRadiomicDataSet(stBootstrappedPartitions.TestingIndices,:);
        
        % Correlation filter
        oFeatureFilter = oFS.CreateFeatureSelector();
        oFeatureFilter.SelectFeatures(oRadiomicTuningAndTrainingSet, 'JournalingOn', false);
        vbRadiomicFeatureMask = oFeatureFilter.GetFeatureMask();
        
        oRadiomicTuningAndTrainingSet = oRadiomicTuningAndTrainingSet(:, vbRadiomicFeatureMask);
        oRadiomicTestingSet = oRadiomicTestingSet(:, vbRadiomicFeatureMask);
    else
        vbRadiomicFeatureMask = [];
    end
        
    % Get clinical data
    if ~isempty(oClinicalDataSet)
        oClinicalTuningAndTrainingSet = oClinicalDataSet(stBootstrappedPartitions.TrainingIndices,:);
        oClinicalTestingSet = oClinicalDataSet(stBootstrappedPartitions.TestingIndices,:);
    end
    
    % Combine radiomic and clinical data into one data set
    if ~isempty(oClinicalDataSet) && ~isempty(oRadiomicDataSet)
        oTuningSet = [oRadiomicTuningAndTrainingSet, oClinicalTuningAndTrainingSet];
        oTrainingSet = [oRadiomicTuningAndTrainingSet, oClinicalTuningAndTrainingSet];
        oTestingSet = [oRadiomicTestingSet, oClinicalTestingSet];
    elseif ~isempty(oClinicalDataSet)
        oTuningSet = oClinicalTuningAndTrainingSet;
        oTrainingSet = oClinicalTuningAndTrainingSet;
        oTestingSet = oClinicalTestingSet;
    elseif ~isempty(oRadiomicDataSet)
        oTuningSet = oRadiomicTuningAndTrainingSet;
        oTrainingSet = oRadiomicTuningAndTrainingSet;
        oTestingSet = oRadiomicTestingSet;
    end
        
    % Train and evaluate classifier
    oRNG = RandomNumberGenerator();
    
    oRNG.PreLoopSetup(1);
    oRNG.PerLoopIndexSetup(1);
    
    oTrainedClassifier = oClassifier.Train(oTrainingSet, 'JournalingOn', false);
        
    oRNG.PerLoopIndexTeardown;
    oRNG.PostLoopTeardown;
    
    % Save artifacts to disk
    FileIOUtils.SaveMatFile(...
        fullfile(Experiment.GetResultsDirectory(), chFilename),...
        'oTrainedClassifier', oTrainedClassifier,...
        'oTestingSet', oTestingSet,...
        '-v7', '-nocompression');          
    
    % par manager clean-up
    oManager.PerLoopIndexTeardown();
end

oManager.PostLoopTeardown();

