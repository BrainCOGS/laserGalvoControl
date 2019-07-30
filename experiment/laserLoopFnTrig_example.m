function lsrL = laserLoopFnTrig_example(lsrL)

% lsrL = laserLoopFnTrig_example(lsrL)
% This is an example of a function that controls the laser / galvo system
% based on commands coming from another computer running the behavior.
% Experiment parameters are first sent to the behavior computer, which does
% all the trial drwaing / randomization. Here this PC just receives laser
% ON, laser OFF, laser location and ramp-down instructions, as well as
% current state of the behavioral trial, because local logging is
% constrained to only be done during inter-trial periods. The information
% from the behavior PC comes through 8 digital lines

global lsr

tic;

lsrL.prevlocationIdx = lsrL.locationIdx;
lsrL.prevState       = lsrL.virmenState;

% receive laser and galvo info from ViRMEn computer
lsrL.DIdata      = nidaqDIread('readDI'); % receive 8-bit binary location code
lsrL.locationIdx = bin2dec(num2str(lsrL.DIdata(LaserRigParameters.locationChannels))); % convert to location index
lsrL.virmenState = bin2dec(num2str(lsrL.DIdata(LaserRigParameters.virmenStateChannels))); % convert to virmen state index

% if setup of the first trial is done, shut down "OK" for the
% sake of the following trials
if lsrL.virmenState > virmenStateCodes.SetUpTrial 
  nidaqPulse('off')
end

% experiment end?
if lsrL.virmenState == virmenStateCodes.EndOfExperiment
  lsrL.stop = 1; % stop signal from virmen
end

% reset laser counter if location change (unless it' to laser off)
if lsrL.locationIdx ~= lsrL.prevlocationIdx
  if lsrL.locationIdx == 0 && lsrL.prevlocationIdx ~= 0 % start rampdown?
    lsrL.rampDown = 1;
  else
    lsrL.lsrCounter = 1;
  end
end

% if ramp down lock galvo positions
if lsrL.rampDown && lsrL.rampDownCounter == 1
  lsrL.rampDownlocationIdx = lsrL.prevlocationIdx;
end

% laser ON or OFF?
if lsrL.stop || (lsrL.locationIdx == 0 && lsrL.rampDown == 0)
  lsrL.lsrON = false;
else
  lsrL.lsrON = true;
end

if lsrL.lsrON && lsrL.prevlocationIdx == 0 && lsrL.rampDown == 0;
  fprintf('\t\t\tLaser ON, Galvo location %d\n',lsrL.locationIdx)
end

% output data
if ~ lsrL.lsrON
  lsrL.data = zeros(1,4);
else
  lsrL.data(LaserRigParameters.lsrSwitchCh) = 5;
  
  if lsrL.rampDown % ramp down laser power according to rampDownVals
    lsrL.data(LaserRigParameters.galvoCh(1))  = lsr.dataout(lsrL.rampDownlocationIdx).galvoXvec(lsrL.lsrCounter);
    lsrL.data(LaserRigParameters.galvoCh(2))  = lsr.dataout(lsrL.rampDownlocationIdx).galvoYvec(lsrL.lsrCounter);
    lsrL.data(LaserRigParameters.lsrWaveCh)   = ...
      lsr.dataout(lsrL.rampDownlocationIdx).lsrVec(lsrL.lsrCounter)*lsrL.rampDownVals(lsrL.rampDownCounter);
  else
    lsrL.data(LaserRigParameters.galvoCh(1))  = lsr.dataout(lsrL.locationIdx).galvoXvec(lsrL.lsrCounter);
    lsrL.data(LaserRigParameters.galvoCh(2))  = lsr.dataout(lsrL.locationIdx).galvoYvec(lsrL.lsrCounter);
    lsrL.data(LaserRigParameters.lsrWaveCh)   = lsr.dataout(lsrL.locationIdx).lsrVec(lsrL.lsrCounter);
  end
end

% send AO data with MEX function
nidaqAOPulse('aoPulse',lsrL.data); % laser switch channel also goes to virmen

lsrL = updateCounters(lsrL); % update iteration info

lsrL = laserlogger(lsrL,'log'); % handle data and save if appropriate trial epoch

% wait till iteration time is up for constant data rate, write dt
t1 = toc;
if t1 < lsrL.loopT
  t2=delay(lsrL.loopT-t1);
  lsrL.dt = t1+t2;
else
  lsrL.dt = t1;
end
end

%% update time counters
function lsrL = updateCounters(lsrL)

global lsr

if lsrL.lsrCounter==lsr.dataout(1).vecLength; lsrL.lsrCounter = 0; end
if lsrL.rampDownCounter==lsrL.rampDownMax
  lsrL.rampDownCounter = 1;
  lsrL.rampDown = 0;
  lsrL.lsrCounter = 1;
end

if lsrL.rampDown; lsrL.rampDownCounter = lsrL.rampDownCounter+1; end
if lsrL.lsrON;    lsrL.lsrCounter = lsrL.lsrCounter+1;           end

% new trial?
if lsrL.prevState == virmenStateCodes.InterTrial ...
    && lsrL.virmenState == virmenStateCodes.SetUpTrial
  
  lsrL.trialCounter = lsrL.trialCounter + 1;
  fprintf('\t\ttrial #%d\n',lsrL.trialCounter);
  lsrL.ii           = 1;
  lsrL.save         = 1; % flag to save previous trial's log
else
  lsrL.ii           = lsrL.ii+1;
  lsrL.save         = 0;
end

end