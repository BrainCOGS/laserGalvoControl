function lsrobj = computeOuputDataPreSet(lsrobj)

% lsrobj = computeOuputDataPreSet(lsrobj)
% calculates 1 sec of galvo and laser data for each possible set of locations

lsrobj.dataout_preset.lsrVec    = [];
lsrobj.dataout_preset.galvoXvec = [];
lsrobj.dataout_preset.galvoYvec = [];

for iLoc = 1:length(lsrobj.locationSet)
  % if one location, just do square waveform, if more than leave laser on
  % to compensate
  if numel(lsrobj.locationSet{iLoc}) == 1
    % laser
    szl = ((1000*lsrobj.presetLocDur)/lsrobj.freq)*(LaserRigParameters.rate/(1000*lsrobj.presetLocDur));
    lsrobj.dataout_preset.lsrVec = [lsrobj.dataout_preset.lsrVec; repmat([ones(floor(szl*lsrobj.dutyCycle),1); ...
      zeros(ceil(szl*(1-lsrobj.dutyCycle)),1)],lsrobj.freq,1).*lsrobj.Vlsr_preset(iLoc)];
    lsrobj.dataout_preset.lsrVec = repmat(lsrobj.dataout_preset.lsrVec,[lsrobj.presetLocDur 1]);
    if iLoc == 1
      vL = numel(lsrobj.dataout_preset.lsrVec);
    end
    
    % galvo
    if iscell(lsrobj.grid)
      [vx,vy] = convertToGalvoVoltage(lsrobj.grid{iLoc}(lsrobj.locationSet{iLoc},:),'mm');
    else
      [vx,vy] = convertToGalvoVoltage(lsrobj.grid(lsrobj.locationSet{iLoc},:),'mm');
    end
    lsrobj.dataout_preset.galvoXvec = [lsrobj.dataout_preset.galvoXvec; ones(vL,1).*vx];
    lsrobj.dataout_preset.galvoYvec = [lsrobj.dataout_preset.galvoYvec; ones(vL,1).*vy];
  else
    % galvo
    szg = ((1000*lsrobj.presetLocDur)/lsrobj.galvofreq)*(LaserRigParameters.rate/(1000*lsrobj.presetLocDur));
    x = []; y =[];
    for jj = 1:numel(lsrobj.locationSet{iLoc})
      [vx,vy] = convertToGalvoVoltage(lsrobj.grid{iLoc}(lsrobj.locationSet{iLoc}(jj),:),'mm');
      x = [x; ones(szg,1)*vx];
      y = [y; ones(szg,1)*vy];
      %             % rounding here is to reduce galvo travel. due to affine
      %             % transformation locations that are theoretically the same
      %             % voltage have slightly different ones
      %             x = [x; ones(szg,1)*(round(vx*100))/100];
      %             y = [y; ones(szg,1)*(round(vy*100))/100];
    end
    % in case the division of data rate by number of locations is not
    % exact, generate slightly longer vector to ensure all locations
    % get hit equally
    lsrobj.dataout_preset.galvoXvec = [lsrobj.dataout_preset.galvoXvec; repmat(x,[ceil(LaserRigParameters.rate/numel(lsrobj.locationSet{iLoc})) 1])];
    lsrobj.dataout_preset.galvoYvec = [lsrobj.dataout_preset.galvoYvec; repmat(y,[ceil(LaserRigParameters.rate/numel(lsrobj.locationSet{iLoc})) 1])];
    
    if iLoc == 1
      vL = numel(lsrobj.dataout_preset.galvoXvec);
    end
    
    % laser
    lsrobj.dataout_preset.lsrVec    = [lsrobj.dataout_preset.lsrVec; ones(vL,1).*lsrobj.Vlsr_preset(iLoc)];
    
  end
end

currSzSec = length(lsrobj.locationSet)*lsrobj.presetLocDur;
ppSec     = length(lsrobj.dataout_preset.lsrVec)/currSzSec;
fillinsz  = (lsrobj.presetCycleDur-currSzSec)*ppSec;

lsrobj.dataout_preset.lsrVec    = [lsrobj.dataout_preset.lsrVec; zeros(fillinsz,1)];
lsrobj.dataout_preset.galvoXvec = [lsrobj.dataout_preset.galvoXvec; zeros(fillinsz,1)];
lsrobj.dataout_preset.galvoYvec = [lsrobj.dataout_preset.galvoYvec; zeros(fillinsz,1)];

lsrobj.dataout_preset.vecLength = numel(lsrobj.dataout_preset.lsrVec);