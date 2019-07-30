function lsrobj = getCalValues(lsrobj)

% lsrobj = getCalValues(lsrobj)
% retrieves calibration values

% voltage for laser power
load ([lsrobj.rootdir 'calibration\PowerCalibration.mat'],'PowerCalibration')

lsrobj.a_power    = PowerCalibration.ControlVoltageToLaserPower.slope;
lsrobj.b_power    = PowerCalibration.ControlVoltageToLaserPower.constant;
lsrobj.Vlsr       = (lsrobj.power-lsrobj.b_power)/lsrobj.a_power;
lsrobj.maxP       = (5*lsrobj.a_power+lsrobj.b_power); % maximum power (corresponding to 5V)

% voltage for galvo
load ([lsrobj.rootdir '\calibration\galvoCal.mat'],'galvoCal')

lsrobj.a_xGalvo   = galvoCal.linFit.slope_x; 
lsrobj.b_xGalvo   = galvoCal.linFit.constant_x; 
lsrobj.a_yGalvo   = galvoCal.linFit.slope_y;
lsrobj.b_yGalvo   = galvoCal.linFit.constant_y; 
lsrobj.galvoTform = galvoCal.tform;
