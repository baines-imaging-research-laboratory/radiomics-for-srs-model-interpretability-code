classdef MATLABLabelMapRegionsOfInterest < LabelMapRegionsOfInterest
    %RegionsOfInterest
    %
    % ???
    
    % Primary Author: David DeVries
    % Created: Apr 22, 2019
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
         
    properties (SetAccess = private, GetAccess = public)
        m2dRegionOfInterestDefaultRenderColours_rgb = []
        vsRegionOfInterestNames
    end
    
    properties (SetAccess = private, GetAccess = public)
        chFilePath = ''
    end  
    
    properties (Constant = true, GetAccess = private)        
        vdDefaultRenderColours = [...
            1 0 0;
            0 1 0;
            0 0 1;
            1 1 0;
            0 1 1;
            1 0 1]
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
           
    methods (Access = public)
        
        function obj = MATLABLabelMapRegionsOfInterest(xMaskData, oImageVolumeGeometry, vsRegionOfInterestNames)
            %obj = ImageVolume(m3xImageData)
            %
            % SYNTAX:
            %  obj = LabelmapRegionsOfInterest(m3bMask, oImageVolumeGeometry)
            %  obj = LabelmapRegionsOfInterest(c1m3bMasks, oImageVolumeGeometry)            
            %  obj = LabelmapRegionsOfInterest(__, __, vsRegionOfInterestNames)
            %
            % DESCRIPTION:
            %  Constructor for NewClass
            %
            % INPUT ARGUMENTS:
            %  input1: What input1 is
            %  input2: What input2 is. If input2's description is very, very
            %         long wrap it with tabs to align the second line, and
            %         then the third line will automatically be in line
            %
            % OUTPUTS ARGUMENTS:
            %  obj: Constructed object
            arguments
                xMaskData {MATLABLabelMapRegionsOfInterest.MustBeValidMaskData(xMaskData)}
                oImageVolumeGeometry (1,1) ImageVolumeGeometry
                vsRegionOfInterestNames (:,1) string = string.empty(0,1)
            end
            
            if islogical(xMaskData)
                xMaskData = {xMaskData};
            end
                                    
            [m3uiLabelMaps, dNumberOfRois] = MATLABLabelMapRegionsOfInterest.ValidateAndGetLabelMapsFromCellArray(xMaskData);
            
            if ~isempty(vsRegionOfInterestNames)
                if length(vsRegionOfInterestNames) ~= dNumberOfRois
                    error(...
                        'MATLABLabelMapRegionsOfInterest:Constructor:InvalidRegionOfInterestNames',...
                        'Region of interest names must be empty or have the same number of elements as number of masks.');
                end
            end
            
            m2dRenderColours_rgb = zeros(dNumberOfRois,3);
            
            dNumDefaultColourChoices = size(MATLABLabelMapRegionsOfInterest.vdDefaultRenderColours,1);
            
            for dRoiIndex=1:dNumberOfRois
                m2dRenderColours_rgb(dRoiIndex,:) = MATLABLabelMapRegionsOfInterest.vdDefaultRenderColours(mod(dRoiIndex-1,dNumDefaultColourChoices)+1,:);
            end
            
            % super-class constructor
            obj@LabelMapRegionsOfInterest(oImageVolumeGeometry, dNumberOfRois, 'LabelMaps', m3uiLabelMaps);
                        
            % set properities
            obj.m2dRegionOfInterestDefaultRenderColours_rgb = m2dRenderColours_rgb;  
            obj.vsRegionOfInterestNames = vsRegionOfInterestNames;
        end      
        
        function SelectRegionsOfInterest(obj, vdRegionOfInterestNumbers)
            arguments
                obj
                vdRegionOfInterestNumbers (1,:) double {MustBeValidRegionOfInterestNumbers(obj, vdRegionOfInterestNumbers)}
            end
            
            c1m3bMasks = cell(1,length(vdRegionOfInterestNumbers));
            
            for dROIIndex=1:length(vdRegionOfInterestNumbers)
               c1m3bMasks{dROIIndex} = obj.GetMaskByRegionOfInterestNumber(vdRegionOfInterestNumbers(dROIIndex));
            end
            
            [m3uiLabelMaps, dNumberOfRois] = MATLABLabelMapRegionsOfInterest.ValidateAndGetLabelMapsFromCellArray(c1m3bMasks);
            
            obj.m3uiLabelMaps = m3uiLabelMaps;
            
            if ~isempty(obj.vsRegionOfInterestNames)
                obj.vsRegionOfInterestNames = obj.vsRegionOfInterestNames(vdRegionOfInterestNumbers);
            end
            
            obj.m2dRegionOfInterestDefaultRenderColours_rgb = obj.m2dRegionOfInterestDefaultRenderColours_rgb(vdRegionOfInterestNumbers,:);
            
            obj.dNumberOfRegionsOfInterest = dNumberOfRois;
        end
        
        % >>>>>>>>>>>>>>>>>>>>>>>>> GETTERS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        
        function m2dColours_rgb = GetDefaultRenderColours_rgb(obj)
            m2dColours_rgb = obj.m2dRegionOfInterestDefaultRenderColours_rgb;
        end
        
        function vdColour_rgb = GetDefaultRenderColourByRegionOfInterestNumber_rgb(obj, dRegionOfInterestNumber)
            vdColour_rgb = obj.m2dRegionOfInterestDefaultRenderColours_rgb(dRegionOfInterestNumber,:);
        end
        
        function vsRegionOfInterestNames = GetRegionsOfInterestNames(obj)
            vsRegionOfInterestNames = obj.vsRegionOfInterestNames;
        end
        
        function chFilePath = GetOriginalFilePath(obj)
            if isempty(obj.chFilePath)
                chFilePath = 'Not saved to disk.';
            else
                chFilePath = obj.chFilePath;                
            end            
        end
                          
        
        % >>>>>>>>>>>>>>>>>>>>>>>>>> FILE I/O <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                    
        function UnloadVolumeData(obj)
            % overwriting superclass
            if isempty(obj.chFilePath) && isempty(obj.chMatFilePath)% not saved, can't unload
                
            else
                UnloadVolumeData@LabelMapRegionsOfInterest(obj);
            end
        end
        
        function Save(obj, chMatFilePath, bForceApplyAllTransforms, bAppend, varargin)
            arguments
                obj
                chMatFilePath (1,:) char
                bForceApplyAllTransforms (1,1) logical = false
                bAppend (1,1) logical = false
            end
            arguments (Repeating)
                varargin
            end
            
            if obj.dCurrentAppliedImagingObjectTransform == 1 % no transforms have happened yet, so we can set this to be the "original data"
                obj.chFilePath = FileIOUtils.GetAbsolutePath(chMatFilePath);
            end 
            
            Save@LabelMapRegionsOfInterest(obj, chMatFilePath, bForceApplyAllTransforms, bAppend, varargin{:});                       
        end
    end
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                        PROTECTED METHODS                          *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = protected)
        
        function cpObj = copyElement(obj)
            % super-class call:
            cpObj = copyElement@LabelMapRegionsOfInterest(obj);
            
            % local call
            % - no deep copy required
        end
        
        function m3uiLabelMaps = LoadLabelMapsFromDisk(obj)
            if ~isempty(obj.chFilePath)
                m3uiLabelMaps = FileIOUtils.LoadMatFile(obj.chFilePath, LabelMapRegionsOfInterest.chLabelMapsMatFileVarName);
            else
                error(...
                    'MATLABLabelMapRegionsOfInterest:LoadLabelMapsFromDisk:Invalid',...
                    'The original data was never saved to disk, and so cannot be retreived.');
            end
        end
        
        function saveObj = saveobj(obj)
            % super-class call
            saveObj = saveobj@LabelMapRegionsOfInterest(obj);
            
            % error if data hasn't been saved via "Save"
            if isempty(obj.chMatFilePath)
                error(...
                    'MATLABLabelMapRegionsOfInterest:saveobj:NotSavedToDisk',...
                    'The MATLABLabelMapRegionsOfInterest object has not been saved using the ".Save()" command, and therefore no copy of it''s labelmap data is on disk. If the current save was performed it WOULD NOT maintain a copy of the labelmap data within the MATLABLabelMapRegionsOfInterest object, and so the saved copy of the object would be useless.');
            end
        end
        
        function c1xRoiDataNameValuePairs = GetNameValuePairsForSave(obj, chMatFilePath)
            c1xRoiDataNameValuePairs = GetNameValuePairsForSave@LabelMapRegionsOfInterest(obj, chMatFilePath);            
        end
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                         PRIVATE METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
        
    
    methods (Access = private, Static = true)
                
        function [mNuiLabelMaps, dNumLabelMaps] = ValidateAndGetLabelMapsFromCellArray(c1mNbLabelMaps)
                        
            if ~CellArrayUtils.AreAllIndexClassesEqual(c1mNbLabelMaps) || ~isa(c1mNbLabelMaps{1}, 'logical')
                error(...
                    'MATLABLabelMapRegionsOfInterest:ValidateAndGetLabelMapsFromCellArray:InvalidLabelMapType',...
                    'Label maps provided in a cell array must all be of type logical.');
            end
            
            dNumLabelMaps = length(c1mNbLabelMaps);
            
            if dNumLabelMaps > 64
                error(...
                    'MATLABLabelMapRegionsOfInterest:ValidateAndGetLabelMapsFromCellArray:TooManyLabelMaps',...
                    'A maximum of 64 label maps can be stored.');
            end
            
            mNbLabelMapMaster = c1mNbLabelMaps{1};
            vdDimsMaster = size(mNbLabelMapMaster);
            
            mNuiLabelMaps = zeros(vdDimsMaster, LabelMapRegionsOfInterest.GetLabelMapUintType(dNumLabelMaps));
            
            for dLabelMapIndex=1:dNumLabelMaps
                vdDims = size(c1mNbLabelMaps{dLabelMapIndex});
                
                if length(vdDimsMaster) ~= length(vdDims) || ~all(vdDimsMaster == vdDims)
                    error(...
                        'MATLABLabelMapRegionsOfInterest:ValidateAndGetLabelMapsFromCellArray:DimsMismatch',...
                        'All label maps must have the same dimensions.');
                else
                    if any(c1mNbLabelMaps{dLabelMapIndex}(:))
                        mNuiLabelMaps = bitset(mNuiLabelMaps, dLabelMapIndex, c1mNbLabelMaps{dLabelMapIndex});
                    else
                        warning(...
                            'MATLABLabelMapRegionsOfInterest:ValidateAndGetLabelMapsFromCellArray:InvalidLabelMap',...
                            "Label map " + string(dLabelMapIndex) + " has no true values.");
                    end
                end
            end
        end
        
        function MustBeValidMaskData(xMaskData)
            if ~islogical(xMaskData) && ~(iscell(xMaskData) && isvector(xMaskData))
                error(...
                    'MATLABLabelMapRegionsOfInterest:MustBeValidMaskData:Invalid',...
                    'Labelmaps must either be given as a single 3D logical matrix or a cell vector of 3D logical matrices of the same dimensions.');
            end
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




