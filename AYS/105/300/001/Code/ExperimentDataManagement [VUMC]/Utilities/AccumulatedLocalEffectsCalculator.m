classdef (Abstract) AccumulatedLocalEffectsCalculator
    
    
    methods (Access = public, Static = true)
        
        function [vdIntervalCentres, vdALEValuePerInterval, vdIntervalPerSample, vdPredictionDifferencePerSample] = CalculateALE(oAllFeatureValues, sFeatureNameToAnalyze, oModel, dNumberOfIntervals)
            vsAllFeatureNames = oAllFeatureValues.GetFeatureNames();
            
            vsFeatureNamesUsedByModel = oModel.oTrainingData.GetFeatureNames();
            
            if ~any(vsFeatureNamesUsedByModel == sFeatureNameToAnalyze)
                vdIntervalCentres = [];
                vdALEValuePerInterval = [];
                vdIntervalPerSample = [];
                vdPredictionDifferencePerSample = [];
            else
                vbKeepFeature = false(size(vsAllFeatureNames));
                
                for dFeatureIndex=1:length(vsAllFeatureNames)
                    vbKeepFeature(dFeatureIndex) = any(vsFeatureNamesUsedByModel == vsAllFeatureNames(dFeatureIndex));
                end
                
                oAllFeatureValues = oAllFeatureValues(:,vbKeepFeature);
                
                if any(oAllFeatureValues.GetFeatureNames() ~= oModel.oTrainingData.GetFeatureNames())
                    error('!');
                end
                
                oFeatureValuesToAnalyze = oAllFeatureValues(:, sFeatureNameToAnalyze == oAllFeatureValues.GetFeatureNames());
                vdFeatureValuesToAnalyze = oFeatureValuesToAnalyze.GetFeatures();
                
                vdIntervalBoundaries = AccumulatedLocalEffectsCalculator.CalculateQuantiles(oFeatureValuesToAnalyze, dNumberOfIntervals);
                
                vdIntervalCentres = zeros(1,dNumberOfIntervals);
                
                for dIntervalIndex=1:dNumberOfIntervals
                    vdIntervalCentres(dIntervalIndex) = mean(vdIntervalBoundaries(dIntervalIndex:dIntervalIndex+1));
                end
                
                vdPredictionDifferencePerSample = zeros(oAllFeatureValues.GetNumberOfSamples(),1);
                vdIntervalPerSample = zeros(oAllFeatureValues.GetNumberOfSamples(),1);
                
                vdAverageDifferencePerInterval = zeros(1,dNumberOfIntervals);
                
                for dIntervalIndex=1:dNumberOfIntervals
                    vbSamplesInInterval = ( vdFeatureValuesToAnalyze >= vdIntervalBoundaries(dIntervalIndex) ) & ( vdFeatureValuesToAnalyze < vdIntervalBoundaries(dIntervalIndex+1) );
                    vdSampleIndices = find(vbSamplesInInterval);
                    dNumSamplesInInterval = length(vdSampleIndices);
                    
                    vdPredictionDifferenceAcrossIntervalPerSample = zeros(dNumSamplesInInterval,1);
                    
                    for dIntervalSampleIndex=1:dNumSamplesInInterval
                        dSampleIndex = vdSampleIndices(dIntervalSampleIndex);
                        
                        vdIntervalPerSample(dSampleIndex) = dIntervalIndex;
                        
                        oSampleFeatureValues = oAllFeatureValues(dSampleIndex,:);
                        vdSampleFeatureValues = oSampleFeatureValues.GetFeatures();
                        
                        % find predicted value at start of interval
                        vdSampleFeatureValues_Low = vdSampleFeatureValues;
                        vdSampleFeatureValues_Low(oSampleFeatureValues.GetFeatureNames() == sFeatureNameToAnalyze) = vdIntervalBoundaries(dIntervalIndex);
                        
                        oSampleFeatureValues_Low = LabelledFeatureValuesByValue(...
                            vdSampleFeatureValues_Low,...
                            oSampleFeatureValues.GetGroupIds(), oSampleFeatureValues.GetSubGroupIds(), oSampleFeatureValues.GetUserDefinedSampleStrings(),...
                            oSampleFeatureValues.GetFeatureNames(),...
                            oSampleFeatureValues.GetLabels(), oSampleFeatureValues.GetPositiveLabel(), oSampleFeatureValues.GetNegativeLabel());
                        
                        oGuessResult_Low = oModel.Guess(oSampleFeatureValues_Low);
                        dPredictedProbability_Low = oGuessResult_Low.GetPositiveLabelConfidences();
                        
                        % find predicted value at end of interval
                        vdSampleFeatureValues_High = vdSampleFeatureValues;
                        vdSampleFeatureValues_High(oSampleFeatureValues.GetFeatureNames() == sFeatureNameToAnalyze) = vdIntervalBoundaries(dIntervalIndex+1);
                        
                        oSampleFeatureValues_High = LabelledFeatureValuesByValue(...
                            vdSampleFeatureValues_High,...
                            oSampleFeatureValues.GetGroupIds(), oSampleFeatureValues.GetSubGroupIds(), oSampleFeatureValues.GetUserDefinedSampleStrings(),...
                            oSampleFeatureValues.GetFeatureNames(),...
                            oSampleFeatureValues.GetLabels(), oSampleFeatureValues.GetPositiveLabel(), oSampleFeatureValues.GetNegativeLabel());
                        
                        oGuessResult_High = oModel.Guess(oSampleFeatureValues_High);
                        dPredictedProbability_High = oGuessResult_High.GetPositiveLabelConfidences();
                        
                        % find difference
                        vdPredictionDifferenceAcrossIntervalPerSample(dIntervalSampleIndex) = dPredictedProbability_High - dPredictedProbability_Low;
                        vdPredictionDifferencePerSample(dSampleIndex) = dPredictedProbability_High - dPredictedProbability_Low;
                    end
                    
                    % find average of difference
                    vdAverageDifferencePerInterval(dIntervalIndex) = mean(vdPredictionDifferenceAcrossIntervalPerSample);
                end
                
                vdAccumulatedValuesPerInterval = cumsum(vdAverageDifferencePerInterval);
                vdALEValuePerInterval = vdAccumulatedValuesPerInterval - mean(vdPredictionDifferencePerSample);
                
                if any(vdIntervalPerSample == 0)
                    error('!');
                end
            end
        end
        
    end
    
    
    methods (Access = private, Static = true)
        
        function vdIntervalBoundaries = CalculateQuantiles(oFeatureValuesToAnalyze, dNumberOfIntervals)
            vdFeatureValues = oFeatureValuesToAnalyze.GetFeatures();
            
            vdQuantiles = quantile(vdFeatureValues,dNumberOfIntervals-1);
            
            vdIntervalBoundaries = [min(vdFeatureValues), vdQuantiles, 1.001*max(vdFeatureValues)];
        end
        
    end
end




