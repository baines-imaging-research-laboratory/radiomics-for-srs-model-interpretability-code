Experiment.StartNewSection('Process XML');

vsFilenamePerObserver = [...
    "E:\Users\ddevries\VUMC BM\Experiments\FV\500\200 [2021-12-07_14.10.33]\Results\01 Experiment Assets\FV-500-200 [CentralLibrary].mat"   
    "E:\Users\ddevries\VUMC BM\Data\Observer Study\Results\JL\Observer Study XML.xml"
    "E:\Users\ddevries\VUMC BM\Data\Observer Study\Results\AL\Observer Study XML.xml" 
    "E:\Users\ddevries\VUMC BM\Data\Observer Study\Results\TT\Observer Study XML.xml"
    "E:\Users\ddevries\VUMC BM\Data\Observer Study\Results\AA\Observer Study XML.xml"];

vbObserverWasFromVUMC = [...
    true;
    false;
    false;
    false;
    false];

vbObserverWasExpert = [
    true;
    true;
    true;
    false;
    false];

vdObserverProfession = [
    2;
    2;
    1;
    2;
    1]; % 1: radiology; 2: radiation oncology

dNumSamples = 123;
dNumObservers = length(vsFilenamePerObserver);

m2dAppearanceScorePerSamplePerObserver = zeros(dNumSamples,1);

m2dPatientIdPerSamplePerObserver = zeros(dNumSamples,1);
m2dBMNumberPerSamplePerObserver = zeros(dNumSamples,1);

for dObserverIndex=1:dNumObservers
    disp(dObserverIndex);
    
    if dObserverIndex == 1
        oFeatureValues = FileIOUtils.LoadMatFile(vsFilenamePerObserver(dObserverIndex), 'oFeatureValues');
        
        m2dPatientIdPerSamplePerObserver(:, dObserverIndex) = oFeatureValues.GetGroupIds();
        m2dBMNumberPerSamplePerObserver(:, dObserverIndex) = oFeatureValues.GetSubGroupIds();
        
        m2dAppearanceScorePerSamplePerObserver(:, dObserverIndex) = oFeatureValues.GetFeatures();
    else
        stXML = xml2struct(vsFilenamePerObserver(dObserverIndex));
        
        for dSampleIndex=1:dNumSamples
            stPage = stXML.Children(2*dSampleIndex);
            
            c1chSplit = strsplit(stPage.Attributes(2).Value, '-');
            chPatientId = c1chSplit{1};
            chBMNumber = c1chSplit{2};
            
            m2dPatientIdPerSamplePerObserver(dSampleIndex, dObserverIndex) = str2double(chPatientId);
            m2dBMNumberPerSamplePerObserver(dSampleIndex, dObserverIndex) = str2double(chBMNumber);
            
            stQuestionSet = stPage.Children(14);
            stQuest = stQuestionSet.Children(2);
            
            vsResponses = [...
                string(stQuest.Children(2).Children(2).Children(1).Data);
                string(stQuest.Children(4).Children(2).Children(1).Data);
                string(stQuest.Children(6).Children(2).Children(1).Data);
                string(stQuest.Children(8).Children(2).Children(1).Data);
                string(stQuest.Children(10).Children(2).Children(1).Data);];
            
            if sum(vsResponses == "Y") ~= 1
                error('Invalid response')
            end
            
            m2dAppearanceScorePerSamplePerObserver(dSampleIndex, dObserverIndex) = find(vsResponses == "Y");
            % 1: homogeneous
            % 2: heterogeneous
            % 3: cystic (simple)
            % 4: cystic (complex)
            % 5: necrosis
        end
    end
end

vdPatientIdPerSample = m2dPatientIdPerSamplePerObserver(:,1);
vdBMNumberPerSample = m2dBMNumberPerSamplePerObserver(:,1);

m2bPatientIdCompare = repmat(vdPatientIdPerSample,1,dNumObservers) == m2dPatientIdPerSamplePerObserver;
m2bBMNumberCompare = repmat(vdBMNumberPerSample,1,dNumObservers) == m2dBMNumberPerSamplePerObserver;

if ~all(m2bPatientIdCompare(:)) || ~all(m2bBMNumberCompare(:))
    error('Sample ID mismatch across observers');
end




FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'Observer Study Appearance Scores.mat'),...
    'vbObserverWasFromVUMC', vbObserverWasFromVUMC, 'vbObserverWasExpert', vbObserverWasExpert, 'vdObserverProfession', vdObserverProfession,...
    'vdPatientIdPerSamplePerObserver', vdPatientIdPerSample, 'vdBMNumberPerSamplePerObserver', vdBMNumberPerSample,...
    'm2dAppearanceScorePerSamplePerObserver', m2dAppearanceScorePerSamplePerObserver);