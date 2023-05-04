function m2ui64GLCM = CalculateGLCM_BinOnTheFly_NonIntegerMatrix(m3dMatrix, m3bRoiMask, vi64OffsetVector, dFirstBinEdge, dBinSize, ui64NumBins)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes her

if any(isnan(m3dMatrix(:))) || any(isinf(m3dMatrix(:)))
    error(...
        'CalculateGLCM_BinOnTheFly_NonIntegerMatrix:InvalidMatrix',...
        'Matrix may not contain any Nan or Inf values.');
end

CalculateGLCM_InputValidation(m3dMatrix, m3bRoiMask, vi64OffsetVector, dFirstBinEdge, dBinSize, ui64NumBins);

[...
    m2ui64GLCM, vi32Dims, i64Numel,...
    i64Index, i64OffsetIndex,...
    i32RowIndex, i32ColIndex, i32SliceIndex,...
    i32RowOffsetStart, i32ColOffsetStart,...
    i32RowOffsetIndex, i32ColOffsetIndex, i32SliceOffsetIndex,...
    bRowLowWatch, bRowHighWatch,...
    bColLowWatch, bColHighWatch,...
    bSliceLowWatch, bSliceHighWatch,...
    vbDimsValid] =...
    ...
    CalculateGLCM_Setup(...
    ...
    m3dMatrix, vi64OffsetVector, ui64NumBins);

dNumBins = cast(ui64NumBins, 'like', m3dMatrix);

while i64Index <= i64Numel
    
    if all(vbDimsValid) && m3bRoiMask(i64Index) && m3bRoiMask(i64OffsetIndex)
        dRow = BinImage_PerformBinCalculation(...
            m3dMatrix(i64Index),...
            dFirstBinEdge, dBinSize, dNumBins);
        
        dCol = BinImage_PerformBinCalculation(...
            m3dMatrix(i64OffsetIndex),...
            dFirstBinEdge, dBinSize, dNumBins);
        
        m2ui64GLCM(dRow, dCol) = m2ui64GLCM(dRow, dCol) + uint64(1);        
    end
    
    [...
        i64OffsetIndex, i64Index,...
        i32RowIndex, i32ColIndex, i32SliceIndex,...
        i32RowOffsetIndex, i32ColOffsetIndex, i32SliceOffsetIndex,...
        vbDimsValid] =...
        ...
        CalculateGLCM_LoopIndicesUpdate(...
        ...
        vi32Dims, i64OffsetIndex, i64Index,...
        i32RowIndex, i32ColIndex, i32SliceIndex,...
        i32RowOffsetStart, i32ColOffsetStart,...
        i32RowOffsetIndex, i32ColOffsetIndex, i32SliceOffsetIndex,...
        bRowLowWatch, bRowHighWatch,...
        bColLowWatch, bColHighWatch,...
        bSliceLowWatch, bSliceHighWatch,...
        vbDimsValid);
end


end
