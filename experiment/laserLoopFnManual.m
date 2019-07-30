function lsrL = laserLoopFnManual(lsrL)

% lsrL = laserLoopFnManual(lsrL)
% laser loop when hardwrae is being manually controlled from GUI

global obj lsr

tic;

% output data
lsrL.data(LaserRigParameters.galvoCh(1))  = lsr.dataout_manual.galvoXvec(lsrL.lsrCounter);
lsrL.data(LaserRigParameters.galvoCh(2))  = lsr.dataout_manual.galvoYvec(lsrL.lsrCounter);
lsrL.data(LaserRigParameters.lsrWaveCh)   = lsr.dataout_manual.lsrVec(lsrL.lsrCounter);

if lsrL.stop
  lsrL.data = [0 0 0 0];
else
  lsrL.data(LaserRigParameters.lsrSwitchCh) = 5;
end

% send AO data with MEX function
nidaqAOPulse('aoPulse',lsrL.data);

% update iteration info
if lsrL.lsrCounter==lsr.dataout_manual.vecLength; lsrL.lsrCounter = 0; end
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
lsrL.dt(lsrL.ii) = lsrL.lastdt; % write time stamp (actually, dT)

% check GUI for stop once every sec, it talkes about 50 ms
if lsrL.lsrCounter == 1
  drawnow();
  if get(obj.pulse,'Value') == false
    lsrL.stop = 1;
  end
end
end