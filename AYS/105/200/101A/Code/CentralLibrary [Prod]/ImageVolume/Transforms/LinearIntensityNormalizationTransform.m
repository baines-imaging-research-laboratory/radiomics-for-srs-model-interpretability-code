classdef LinearIntensityNormalizationTransform < IndependentImagingObjectTransform
    %LinearIntensityNormalizationTransform
    %
    % Todo
    
    % Primary Author: David DeVries
    % Created: July 22, 2020
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
     
    properties (SetAccess = immutable, GetAccess = public)
        dCurrentMaxIntensityValue (1,1) double {mustBeFinite}
        dNewMaxIntensityValue (1,1) double {mustBeFinite}
        
        dCurrentMinIntensityValue (1,1) double {mustBeFinite} = 0
        dNewMinIntensityValue (1,1) double {mustBeFinite} = 0
        
        chNewImageDataClass(1,:) char
    end    
        
       
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
     
    methods (Access = public) % None
    end
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                        PROTECTED METHODS                          *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = protected)
    end
    

    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                         PRIVATE METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = {?ImagingObjectTransform, ?GeometricalImagingObject})
        
        function obj = LinearIntensityNormalizationTransform(oImageVolume, dCurrentMaxIntensityValue, dNewMaxIntensityValue, dCurrentMinIntensityValue, dNewMinIntensityValue, chNewImageDataClass)
            arguments
                oImageVolume (1,1) ImageVolume
                dCurrentMaxIntensityValue (1,1) double {mustBeFinite}
                dNewMaxIntensityValue (1,1) double {mustBeFinite}
                dCurrentMinIntensityValue (1,1) double {mustBeFinite}
                dNewMinIntensityValue (1,1) double {mustBeFinite}
                chNewImageDataClass(1,:) char
            end
            
            % super-class call
            oImageVolumeGeometry = oImageVolume.GetImageVolumeGeometry();
            
            obj@IndependentImagingObjectTransform(oImageVolumeGeometry, oImageVolumeGeometry); % target and post-transform geometry will be equal
            
            % local call
            obj.dCurrentMaxIntensityValue = dCurrentMaxIntensityValue;
            obj.dNewMaxIntensityValue = dNewMaxIntensityValue;
            
            obj.dCurrentMinIntensityValue = dCurrentMinIntensityValue;
            obj.dNewMinIntensityValue = dNewMinIntensityValue;
            
            obj.chNewImageDataClass = chNewImageDataClass;
        end
        
        function Apply(obj, oImagingObject)
            m3dCurrentImageData = double(oImagingObject.GetCurrentImageDataForTransform());
            
            dCurrentRange = obj.dCurrentMaxIntensityValue - obj.dCurrentMinIntensityValue;
            dNewRange = obj.dNewMaxIntensityValue - obj.dNewMinIntensityValue;
            
            m3dCurrentImageData = ( (m3dCurrentImageData - obj.dCurrentMinIntensityValue) .* (dNewRange / dCurrentRange) ) + obj.dNewMinIntensityValue;
            m3dCurrentImageData = cast(m3dCurrentImageData, obj.chNewImageDataClass);
            
            oImagingObject.ApplyImagingObjectIntensityTransform(m3dCurrentImageData);
        end
    end
    

    % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    

    % *********************************************************************
    % *                        UNIT TEST ACCESS                           *
    % *                  (To ONLY be called by tests)                     *
    % *********************************************************************
    
    methods (Access = {?matlab.unittest.TestCase}, Static = false)        
    end
    
    
    methods (Access = {?matlab.unittest.TestCase}, Static = true)        
    end
end

