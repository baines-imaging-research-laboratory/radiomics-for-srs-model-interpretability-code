Experiment.StartNewSection('Analysis');

m2dAppearanceScorePerSamplePerObserver = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-003-003-001'), '01 Process XML', 'Observer Study Appearance Scores.mat'),...
    'm2dAppearanceScorePerSamplePerObserver');

dNumObservers = 3; % only experts
dNumSamples = size(m2dAppearanceScorePerSamplePerObserver,1);

m2dExportMatrix = zeros(dNumObservers*dNumSamples,3); % columns: sample id, observer id, score

dInsertIndex = 1;

for dObserverIndex=1:dNumObservers
    for dSampleIndex=1:dNumSamples
        m2dExportMatrix(dInsertIndex,1) = dSampleIndex;
        m2dExportMatrix(dInsertIndex,2) = dObserverIndex;
        m2dExportMatrix(dInsertIndex,3) = m2dAppearanceScorePerSamplePerObserver(dSampleIndex,dObserverIndex);
        
        dInsertIndex = dInsertIndex + 1;
    end
end
    
vsHeaders = ["s", "r", "y"];

writematrix(vsHeaders, fullfile(Experiment.GetResultsDirectory(), 'SAS Export.xlsx'), 'Range', 'A1');
writematrix(m2dExportMatrix, fullfile(Experiment.GetResultsDirectory(), 'SAS Export.xlsx'), 'Range', 'A2');
