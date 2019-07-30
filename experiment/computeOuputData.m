function lsrobj = computeOuputData(lsrobj)

% lsrobj = computeOuputData(lsrobj)
% precalculates 1 sec of galvo and laser data for each possible set of locations

%% loop thorugh locations
for ii = 1:length(lsrobj.locationSet)
  % if one location, just do square waveform, if more than leave laser on
  % to compensate
  if numel(lsrobj.locationSet{ii}) == 1
    % laser
    szl = (1000/lsrobj.freq)*(LaserRigParameters.rate/1000);
    lsrobj.dataout(ii).lsrVec = repmat([ones(floor(szl*lsrobj.dutyCycle),1); ...
      zeros(ceil(szl*(1-lsrobj.dutyCycle)),1)],lsrobj.freq,1).*lsrobj.Vlsr;
    lsrobj.dataout(ii).vecLength = numel(lsrobj.dataout(ii).lsrVec);
    
    % galvo
    [vx,vy] = convertToGalvoVoltage(lsrobj.grid(lsrobj.locationSet{ii},:),'mm');
    lsrobj.dataout(ii).galvoXvec = ones(lsrobj.dataout(ii).vecLength,1).*vx;
    lsrobj.dataout(ii).galvoYvec = ones(lsrobj.dataout(ii).vecLength,1).*vy;
  else
    % galvo
    szg = (1000/lsrobj.galvofreq)*(LaserRigParameters.rate/1000);
    x = []; y =[];
    for jj = 1:numel(lsrobj.locationSet{ii})
      [vx,vy] = convertToGalvoVoltage(lsrobj.grid{ii}(lsrobj.locationSet{ii}(jj),:),'mm');
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
    lsrobj.dataout(ii).galvoXvec = repmat(x,[ceil(LaserRigParameters.rate/numel(lsrobj.locationSet{ii})) 1]);
    lsrobj.dataout(ii).galvoYvec = repmat(y,[ceil(LaserRigParameters.rate/numel(lsrobj.locationSet{ii})) 1]);
    lsrobj.dataout(ii).vecLength = numel(lsrobj.dataout(ii).galvoXvec);
    
    % laser
    lsrobj.dataout(ii).lsrVec = ones(lsrobj.dataout(ii).vecLength,1).*lsrobj.Vlsr;
    
  end
end

% calculate 1 sec of manually set galvo / laser data
szl = (1000/lsrobj.freq)*(LaserRigParameters.rate/1000);
lsrobj.dataout_manual.lsrVec = repmat([ones(floor(szl*lsrobj.dutyCycle),1); ...
  zeros(ceil(szl*(1-lsrobj.dutyCycle)),1)],lsrobj.freq,1).*lsrobj.Vlsr;
lsrobj.dataout_manual.vecLength = numel(lsrobj.dataout_manual.lsrVec);

% galvo
lsrobj.dataout_manual.galvoXvec = ones(lsrobj.dataout_manual.vecLength,1).*lsrobj.galvoManualVx;
lsrobj.dataout_manual.galvoYvec = ones(lsrobj.dataout_manual.vecLength,1).*lsrobj.galvoManualVy;