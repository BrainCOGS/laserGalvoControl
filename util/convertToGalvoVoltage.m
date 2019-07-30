function [Vx,Vy] = convertToGalvoVoltage(pos,inputUnit)

% [Vx,Vy] = convertToGalvoVoltage(pos,inputUnit)
% pos is 2d coordinate and inputUnit is 'mm' or 'pxl'
% convert mm in brain space or image pxls to galvo voltage

global lsr

switch inputUnit
  case 'mm'
    
    % from mm to pxl on ref image
    x       = round(lsr.pxlPerMM*-pos(1))+ lsr.refPxl(1);
    y       = round(lsr.pxlPerMM*-pos(2))+ lsr.refPxl(2);
    
    % go from ref. map to current image
    if ~isempty(lsr.imTform)
      [x,y] = transformPointsInverse(lsr.imTform, x, y);
    end
    
    
    % to voltage
    t       = transformPointsInverse(lsr.galvoTform,[x y]);
    Vx      = t(1);
    Vy      = t(2);
    
  case 'pxl'
    t       = transformPointsInverse(lsr.galvoTform,pos);
    Vx      = t(1);
    Vy      = t(2);
end

