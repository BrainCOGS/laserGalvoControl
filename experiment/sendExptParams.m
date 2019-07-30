function sendExptParams(paramList)

% sendExptParams(paramList)
% sends experiment parameters to behavior PC using TCP-IP
% should be modified for user-specific experiments
% related to laserLoopFnTrig_example()

global lsr

%% default parameters
if nargin < 1
  paramList{1}  = 'fn';
  paramList{2}  = 'freq';
  paramList{3}  = 'power';
  paramList{4}  = 'dutyCycle';
  paramList{5}  = 'P_on';
  paramList{6}  = 'rampDownDur';
  paramList{7}  = 'galvofreq';
  paramList{8}  = 'locationSet';
  paramList{9} =  'drawMode';
  paramList{10} = 'epoch';
  paramList{11} = 'rampDownMode';
  paramList{12} = 'gridLabel';
end

fprintf('\nestablishing TCP/IP connection with virmen\n')
TCPIPcomm('init'); % initialize TCIP communication

fprintf('\tsending expt. params to virmen\n')
for ii = 1:length(paramList)
  fprintf(sprintf('\t\tsending %s',paramList{ii}))
  % for location set label is repeated for every entry (can't send a cell)
  if strcmpi(paramList{ii},'locationSet')
    for jj = 1:length(lsr.locationSet)
      % first tell virmen the name of the variable
      TCPIPcomm('send','receiveString') % tell virmen what kind of data will be sent
      virmenHandShake;
      
      TCPIPcomm('send','param\nlocationSet') % parameter name
      virmenHandShake;
      
      TCPIPcomm('send','receiveData') % tell virmen what kind of data will be sent
      virmenHandShake;
      
      % send size of array
      data = numel(lsr.locationSet{jj});
      TCPIPcomm('send',data);
      virmenHandShake;
      
      % send data that goes with label
      data = lsr.locationSet{jj};
      TCPIPcomm('send',data);
      virmenHandShake;
    end
    % epochList may have more than one entry
  elseif strcmpi(paramList{ii},'epoch') && iscell(lsr.epoch)
    for jj = 1:numel(lsr.epoch)
      % first tell virmen the name of the variable
      TCPIPcomm('send','receiveString') % tell virmen what kind of data will be sent
      virmenHandShake;
      
      TCPIPcomm('send','param\nepoch') % parameter name
      virmenHandShake;
      
      TCPIPcomm('send','receiveString') % tell virmen what kind of data will be sent
      virmenHandShake;
      
      % send data that goes with label
      data = lsr.epoch{jj};
      TCPIPcomm('send',data);
      virmenHandShake;
    end
  else
    % first tell virmen the name of the variable
    TCPIPcomm('send','receiveString'); % tell virmen what kind of data will be sent
    virmenHandShake;
    
    TCPIPcomm('send',['param\n' paramList{ii}]); % parameter name
    virmenHandShake;
    
    if strcmpi(paramList{ii},'fn')                || ...
        strcmpi(paramList{ii},'drawMode')     || ...
        strcmpi(paramList{ii},'rampDownMode') || ...
        strcmpi(paramList{ii},'epoch')        || ...
        strcmpi(paramList{ii},'gridLabel')
      TCPIPcomm('send','receiveString') % tell virmen what kind of data will be sent
      virmenHandShake;
      
      % send data that goes with label
      data = eval(sprintf('lsr.%s',paramList{ii}));
      TCPIPcomm('send',data);
      virmenHandShake;
    else
      TCPIPcomm('send','receiveData'); % tell virmen what kind of data will be sent
      
      virmenHandShake;
      
      % send size of array
      data = numel(eval(sprintf('lsr.%s',paramList{ii})));
      TCPIPcomm('send',data);
      
      virmenHandShake;
      
      % send data that goes with label
      data = eval(sprintf('lsr.%s',paramList{ii}));
      TCPIPcomm('send',data);
      virmenHandShake;
    end
  end
  fprintf('\n')
end

% tell virmen it's done
TCPIPcomm('send','done');
fprintf('\tdone!\n')
end

function virmenHandShake
% wait for OK from virmen
dataIn = TCPIPcomm('receiveString');
while ~ strcmpi(dataIn,'OK')
  dataIn = TCPIPcomm('receiveString');
end
fprintf('.')
end