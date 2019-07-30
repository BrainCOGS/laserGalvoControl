function lsrobj = calculateP_on(lsrobj)

% lsrobj = calculateP_on(lsrobj)
% make sure probability per location does not exceed max allowed, otherwise
% cap at max

numLocations = length(lsrobj.locationSet);
if lsrobj.P_on/numLocations > lsrobj.maxPonPerLoc
    lsrobj.P_on = min([1 numLocations*lsrobj.maxPonPerLoc]);
end