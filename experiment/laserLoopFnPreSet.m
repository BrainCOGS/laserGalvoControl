function lsrL = laserLoopFnPreSet(lsrL)

% lsrL = laserLoopFnPreSet(lsrL)
% example laser loop for preset data (e.g. not triggered, just governed by fixed experiment timing)
% data should be pre computed

global lsr

tic;

% output data
lsrL.data(LaserRigParameters.galvoCh(1))  = lsr.dataout_preset.galvoXvec(lsrL.lsrCounter); 
lsrL.data(LaserRigParameters.galvoCh(2))  = lsr.dataout_preset.galvoYvec(lsrL.lsrCounter);
lsrL.data(LaserRigParameters.lsrWaveCh)   = lsr.dataout_preset.lsrVec(lsrL.lsrCounter);

if lsrL.stop
    lsrL.data = [0 0 0 0];
else
    lsrL.data(LaserRigParameters.lsrSwitchCh) = 5;
end

% send AO data with MEX function
nidaqAOPulse('aoPulse',lsrL.data);

% update iteration info
if lsrL.lsrCounter == lsr.dataout_preset.vecLength; 
    lsrL.lsrCounter  = 0; 
    lsrL.cycleCounter = lsrL.cycleCounter+1; 
    fprintf('\tcycle #%03d / %03d\n',lsrL.cycleCounter,lsrL.ncycles)
end
lsrL.lsrCounter = lsrL.lsrCounter+1;
lsrL.ii         = lsrL.ii+1;

% wait till iteration time is up for constant data rate
t1 = toc;
if t1 < lsrL.loopT
    t2=delay(lsrL.loopT-t1);
    lsrL.lastdt = t1+t2;
else
    lsrL.lastdt = t1;
end
% lsrL.dt(lsrL.ii) = lsrL.lastdt; % write time stamp (actually, dT)
lsrL.totalDur = lsrL.totalDur + lsrL.lastdt;

% check GUI for stop once every sec, it talkes about 50 ms
if lsrL.totalDur >= lsrL.maxDur 
    lsrL.stop = 1;
end
end