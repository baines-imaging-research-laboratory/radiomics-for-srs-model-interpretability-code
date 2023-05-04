Experiment.StartNewSection('Analysis');

m2dAppearanceScorePerSamplePerObserver = FileIOUtils.LoadMatFile(...
    fullfile(ExperimentManager.GetPathToExperimentAssetResultsDirectory('AYS-003-003-001'), '01 Process XML', 'Observer Study Appearance Scores.mat'),...
    'm2dAppearanceScorePerSamplePerObserver');

dNumAppearances = 5;
dNumObservers = 5;

m2dConfusionMatrix = nan(dNumAppearances*dNumObservers);
m2dAgreementRateMatrix = nan(dNumObservers);

m3dConfusionMatrixPerComparison = zeros(5,5,10);
dConfusionMatrixIndex = 1;

for dObserver1Index=1:dNumObservers
    for dObserver2Index=dObserver1Index:dNumObservers
        
        m2dAppearanceConfusionMatrix = zeros(dNumAppearances);
        
        for dSampleIndex=1:size(m2dAppearanceScorePerSamplePerObserver,1)
            m2dAppearanceConfusionMatrix(m2dAppearanceScorePerSamplePerObserver(dSampleIndex,dObserver1Index), m2dAppearanceScorePerSamplePerObserver(dSampleIndex,dObserver2Index)) = ...
                m2dAppearanceConfusionMatrix(m2dAppearanceScorePerSamplePerObserver(dSampleIndex,dObserver1Index), m2dAppearanceScorePerSamplePerObserver(dSampleIndex,dObserver2Index)) + 1;
        end
        
        if dObserver1Index~=dObserver2Index
            m3dConfusionMatrixPerComparison(:,:,dConfusionMatrixIndex) = m2dAppearanceConfusionMatrix;
            dConfusionMatrixIndex = dConfusionMatrixIndex + 1;
        end
        
        m2dConfusionMatrix((dObserver1Index-1)*dNumAppearances+(1:5), (dObserver2Index-1)*dNumAppearances+(1:5)) = m2dAppearanceConfusionMatrix;
        
        m2dAgreementRateMatrix(dObserver2Index,dObserver1Index) = round((sum(m2dAppearanceConfusionMatrix(logical(eye(5))))/123)*100,1);
    end
end

m2dSumOfConfusionMatrices = sum(m3dConfusionMatrixPerComparison,3);
m2dSumOfConfusionMatrices = m2dSumOfConfusionMatrices + m2dSumOfConfusionMatrices';
m2dSumOfConfusionMatrices(logical(eye(5))) = 0;

disp("Sum of Confusion Matrices");
disp(m2dSumOfConfusionMatrices);

disp("Number of Disagreements Per Appearance Types")
disp(sum(m2dSumOfConfusionMatrices));


writematrix(m2dConfusionMatrix, fullfile(Experiment.GetResultsDirectory(), 'Confusion Matrix.xlsx'));
writematrix(m2dAgreementRateMatrix, fullfile(Experiment.GetResultsDirectory(), 'Agreement Rate Matrix.xlsx'));
