function nidaqComm(command)

% nidaqComm(command)
% command is string, 'init' or 'end'
% starts or ends all MEX-based NI DAQ tasks

switch command
  case 'init'
    nidaqAIread  ('end');
    nidaqAOPulse ('end');
    nidaqDIread  ('end');
    nidaqDOwrite ('end');
    nidaqPulse   ('end');
    
    nidaqAIread  ('init',LaserRigParameters.nidaqDevice,LaserRigParameters.aiChannels);
    nidaqAOPulse ('init',LaserRigParameters.nidaqDevice,LaserRigParameters.aoChannels);
    nidaqDIread  ('init',LaserRigParameters.nidaqDevice,LaserRigParameters.diPort,LaserRigParameters.diChannels);
    nidaqDOwrite ('init',LaserRigParameters.nidaqDevice,LaserRigParameters.doPortLED,LaserRigParameters.doChannelsLED);
    nidaqPulse   ('init',LaserRigParameters.nidaqDevice,LaserRigParameters.doPort,LaserRigParameters.doChannels);
  case 'end'
    nidaqAIread  ('end');
    nidaqAOPulse ('end');
    nidaqDIread  ('end');
    nidaqDOwrite ('end');
    nidaqPulse   ('end');
end