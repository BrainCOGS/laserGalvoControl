function [DAQs,data,lsr,aidata,didata] = DAQctrlLsr(DAQs,command,data,lsr)

% [DAQs,data,lsr,aidata,didata] = DAQctrlLsr(DAQs,command,data,lsr)
% controls NIDAQ communications

% defaults
defaults={[];'init';[];[]};
inputnames = {'DAQs';'command';'data';'lsr'};
if nargin < length(defaults)
  for iArg = nargin+1:length(defaults)
    temp=defaults{iArg};
    eval([inputnames{iArg} '=temp;']);
  end
end

%% if not initializng make sure session handle exists
if (~strcmpi(command,'init') && ~strcmpi(command,'reset'))  && isempty(DAQs)
  error('please initialize DAQ session first')
end

%% translate high level commands to DAQ
switch command
  case 'init' % create NI DAQ session
    fprintf('initializing DAQ session..\n');
    daqreset; % Reset DAQ in case it is still in use
    DAQs = lsrDAQinit; % nested function
    
  case 'aoPrepareCont' % compute data and prepare buffer for trigger
    if isempty(data)
      data     = computeDataMat(lsr);
    end
    [DAQs,lsr] = prepareDataOutput(DAQs,lsr,data);
    
  case 'aoStartCont' % start sending ao data
    DAQs.ao.startBackground();
    
  case 'aoStopCont' % stop sending ao data
    DAQs.ao.stop();
    delete(lsr.aolh)
    outputSingleScan(DAQs.ao,[0 0 0 0]); % zero lines
    
  case 'aoStartSinglePulse' % send single pulse of data
    if isempty(data)
      error('please provide data matrix')
    end
    outputSingleScan(DAQs.ao,data);
    
  case 'aoStopSinglePulse' % zero channels
    outputSingleScan(DAQs.ao,[0 0 0 0]); % zero lines
    
  case 'diRead'
    didata = inputSingleScan(DAQs.dio);
    aidata = [];
    
  case 'aiRead' % read analog input
    %[aidata,aits,DAQs,lsr] = dataInputCont(DAQs,lsr);
    %lh = addlistener(DAQs.ai,'DataAvailable',@(src,event));
    aidata = DAQs.ai.startBackground;
  case 'triggerMode' % run continuosly with start triggered by ext. stim
    
  case 'reset' % reset daq
    daqreset;
    
  case 'close' % stop DAQ session
    DAQs.ao.stop(); 
    DAQs.ai.stop();
    delete(DAQs.ao); 
    delete(DAQs.ai);
    daqreset;
end

end

% -------------------------------------------------------------------------
%% Create DAQ session
function DAQs = lsrDAQinit
% separate AO and AI sessions
DAQs.ao                   = daq.createSession('ni');
DAQs.ao.Rate              = LaserRigParameters.rate;
DAQs.ao.DurationInSeconds = LaserRigParameters.duration;
DAQs.ao.IsContinuous      = LaserRigParameters.iscontinuous;

DAQs.ai                   = daq.createSession('ni');
DAQs.ai.Rate              = LaserRigParameters.rate;
DAQs.ai.DurationInSeconds = LaserRigParameters.duration;
DAQs.ai.IsContinuous      = LaserRigParameters.iscontinuous;

DAQs.dio = daq.createSession('ni');
dchlist  = sprintf('port%1d/line%1d',LaserRigParameters.digTrigPort, LaserRigParameters.digTrigChannel);
addDigitalChannel(DAQs.dio,LaserRigParameters.nidaqDevice,dchlist,'InputOnly');

if iscell(LaserRigParameters.nidaqDevice) % multiple devices
  for nd = 1:length(LaserRigParameters.nidaqDevice)
    if ~isempty(LaserRigParameters.aoChannels{nd})
      addAnalogOutputChannel(DAQs.ao,LaserRigParameters.nidaqDevice{nd},...
        LaserRigParameters.aoChannels{nd},'Voltage');
    end
    if ~isempty(LaserRigParameters.aiChannels{nd})
      addAnalogInputChannel(DAQs.ai,LaserRigParameters.nidaqDevice{nd},...
        LaserRigParameters.aiChannels{nd},'Voltage');
    end
  end
else
  addAnalogOutputChannel(DAQs.ao,LaserRigParameters.nidaqDevice,LaserRigParameters.aoChannels,'Voltage');
  addAnalogInputChannel(DAQs.ai,LaserRigParameters.nidaqDevice,LaserRigParameters.aiChannels,'Voltage');
end

outputSingleScan(DAQs.ao,[0 0 0 0]); % zero lines just in case
end

% -------------------------------------------------------------------------
%% Calculate data matrix according to laser and buffer parameter
function data = computeDataMat(lsr)

% freq modulation: square waves
sz = (1000/lsr.freq)*(LaserRigParameters.rate/1000);
datafreq = repmat([zeros(ceil(sz*(1-lsr.dutyCycle)),1); ...
  5.*ones(floor(sz*lsr.dutyCycle),1)],lsr.freq,1);

% data mat for DAQ w/ 4 cols: [GalvoX GalvoY Power Freq] or whatever order
% is in params.
data = zeros(LaserRigParameters.rate);
data(:,LaserRigParameters.galvoCh(1)) = ones(LaserRigParameters.rate,1)*lsr.Vx;
data(:,LaserRigParameters.galvoCh(2)) = ones(LaserRigParameters.rate,1)*lsr.Vy;
data(:,LaserRigParameters.lsrPowerCh) = ones(LaserRigParameters.rate,1)*lsr.Vlsr;
data(:,LaserRigParameters.lsrFreqCh)  = datafreq;

% expand to desired buffer size
bfSizeSamp = LaserRigParameters.buffSize*LaserRigParameters.rate;
if bfSizeSamp < LaserRigParameters.rate
  data = data(1:bfSizeSamp,:);
else
  dr = rem(LaserRigParameters.rate,bfSizeSamp);
  if dr == 0
    data = repmat(data,[LaserRigParameters.rate/bfSizeSamp 1]);
  else
    data = repmat(data,[floor(LaserRigParameters.rate/bfSizeSamp) 1]);
    data(end+1:end+dr) = data(1:dr,:);
  end
end
end

% -------------------------------------------------------------------------
%% Load buffer and prepare AO channels
function [DAQs,lsr] = prepareDataOutput(DAQs,lsr,data)

queueOutputData(DAQs.ao,data); % queue data

% add event listener to add data to buffer if necessary
% first calculate lisner data according to params
% expand to desired buffer size
bfSizeSamp = LaserRigParameters.buffRefill*LaserRigParameters.rate;
if bfSizeSamp < LaserRigParameters.rate
  lhdata = data(1:bfSizeSamp,:);
else
  dr = rem(LaserRigParameters.rate,bfSizeSamp);
  if dr == 0
    lhdata = repmat(data,[LaserRigParameters.rate/bfSizeSamp 1]);
  else
    lhdata = repmat(data,[floor(LaserRigParameters.rate/bfSizeSamp) 1]);
    lhdata(end+1:end+dr) = data(1:dr,:);
  end
end

% create listener
lsr.aolh = addlistener(DAQs.ao,'DataRequired',@(src,event) ...
  src.queueOutputData(lhdata));

prepare(DAQs.ao) % prepare

end