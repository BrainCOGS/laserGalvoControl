function lsrL = laserLoop

% lsrL = laserLoop
% initializes and selects hardware behavior (eg, preset, manual control, PC-triggered), 
% and controls the loop. What happens inside the loop must be defined in
% separate functions (e.g. see laserLoopFnManual(), laserLoopFnTrig_example())

%% INITIALIZE
global lsr obj
rng('shuffle')

% initialize parameters
lsrL.loopT              = 1/LaserRigParameters.rate; % skip iteration if longer than this
lsrL.loopTth            = (1+lsr.loopTimeTol)*(1/LaserRigParameters.rate); % skip iteration if longer than this
lsrL.stop               = 0; % received from virmen in triggered mode or GUI button in manual control
lsrL.rampDown           = 0; % boolean to signal rampDown procedure in progress
lsrL.rampDownCounter    = 1; % to know when to stop
lsrL.rampDownVals       = linspace(1,0,LaserRigParameters.rate*lsr.rampDownDur); % ramp down scaling per iteration
lsrL.ii                 = 1; % iteration number
lsrL.lsrCounter         = 1; % to cycle thorugh galvo/laser "buffered" data
lsrL.lsrON              = false; % boolean to decide if laser is ON or not
lsrL.data               = zeros(1,4); % current data output
lsrL.prevlocationIdx    = 0;  % only change data output if ~= this
lsrL.locationIdx        = 0;
lsrL.dt                 = 0;
lsrL.templog            = [];
lsrL.virmenState        = virmenStateCodes.NotRunning; % pre-virmen communication
lsrL.prevState          = virmenStateCodes.NotRunning; % pre-virmen communication
lsrL.currPower          = lsr.power; % for power-varying experiments
lsrL.powerFactor        = 1; % for power-varying experiments
lsrL.powers             = lsr.varyPowerLs; % for power-varying experiments
lsrL.npowers            = numel(lsr.varyPowerLs); % for power-varying experiments

%% ramp down
if isempty(lsrL.rampDownVals)
  lsrL.rampDownVals    = 0;
else
  lsrL.rampDownVals(1) = []; % first entry is full power
end
lsrL.rampDownMax = numel(lsrL.rampDownVals);

%% select laser loop. 
%% EDIT HERE FOR USER-DEFINED EXPERIMENTS
if lsr.preSetOn % for preset experiments (e.g. ephys)
  % update status
  set(obj.statusTxt,'foregroundColor','c')
  set(obj.statusTxt,'String','running preset protocol')
  
  % run
  lsrL.totalDur     = 0;
  lsrL.maxDur       = lsr.presetMaxDurMin*60;
  lsrL.cycleCounter = 0;
  lsrL.ncycles      = floor(lsrL.maxDur/lsr.presetCycleDur);

  commandwindow; clc
  fprintf('starting pre-set experiment\n')

  while ~ lsrL.stop
    lsrL = laserLoopFnPreSet(lsrL);
  end
  fprintf('done\n')
  
  set(obj.statusTxt,'String','Idle','foregroundColor',[.3 .3 .3])
  figure(obj.fig)
  
else
  switch lsr.manualTrigger
    case true % manual trigger
      
      % update status
      set(obj.statusTxt,'foregroundColor','b')
      set(obj.statusTxt,'String','manual Laser ON')
      
      while ~ lsrL.stop && sum(lsrL.dt) <= lsr.dur
        lsrL = laserLoopFnManual(lsrL);
      end
      
      set(obj.statusTxt,'String','Idle','foregroundColor',[.3 .3 .3])
      
    case false % controled by behavior PC
      %% THIS IS AN EXAMPLE FOR BEHAVIOR CONTROLLED BY A SEPARATE VR PC
      % must be modified for your purposes. refer to manual for details
      
      % update status
      set(obj.statusTxt,'foregroundColor',[0 .5 0],'String','under ViRMEN control')
      updateConsole(sprintf('Behavior experiment started, mouse %s',lsr.mouseID))
      
      commandwindow; clc
      
      % send experiment parameters to behavior PC
      sendExptParams;
      
      % start log
      lsrL = laserlogger(lsrL,'init');
      
      % wait for virmen to actually start
      fprintf('waiting for behavior pc to start session...')
      while lsrL.virmenState <= 0
        lsrL.prevState   = lsrL.virmenState;
        DIdata           = nidaqDIread('readDI'); % receive 8-bit binary location code
        lsrL.virmenState = bin2dec(num2str(DIdata(LaserRigParameters.virmenStateChannels))); % convert to virmen state index
      end
      lsrL.trialCounter = 1;
      
      % let the fun begin!
      fprintf('\nstarting\n\t\ttrial #1\n')
      while ~ lsrL.stop
        lsrL = laserLoopFnTrig_example(lsrL);
      end
      
      % save (update status)
      lsrL = laserlogger(lsrL,'cleanup');
      figure(obj.fig)
      
      set(obj.statusTxt,'String','Experiment done','foregroundColor','k')
      updateConsole('Behavior experiment ended')
  end
end
