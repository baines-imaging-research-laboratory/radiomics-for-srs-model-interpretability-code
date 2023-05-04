function m2ui64GLRLM = CalculateGLRLM_BinningPreComputed_double(m3dRawMatrix, m3ui32BinnedMatrix, m3bRoiMask, i32OffsetVector, dFirstBinEdge, dBinSize, ui64NumBins, dEqualityTheshold, dNumberOfColumns, bTrimColumns)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes her

bForNonIntegerMatrix = true;
bBinOnTheFly = false;

m2ui64GLRLM = CalculateGLRLM_Algorithm(...
    m3dRawMatrix, m3ui32BinnedMatrix, m3bRoiMask,...
    i32OffsetVector,...
    dFirstBinEdge, dBinSize,...
    ui64NumBins,...
    dEqualityTheshold,...
    bForNonIntegerMatrix, bBinOnTheFly,...
    dNumberOfColumns, bTrimColumns);

end

