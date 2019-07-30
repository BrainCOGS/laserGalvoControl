classdef lsrCtrlParams
  
  %% all the properties below can be modified by the gui
  properties
    
    % general info
    mouseID         = [];
    rootdir         = 'C:\Experiments\laserctrl\'; % the directory where this code lives
    savepath        = 'C:\Data\'; % current directory for data saving
    savepathroot    = 'C:\Data\'; % root directory for data saving
    fn                            % file name (will be populated  by GUI
    note_fn                       % filename for experimenter notes
    console_fn                    % filename for console
    powerCalcheckMsg              % warning message for power calibratiomn
    
    % laser waveform (defaults, may be edited using GUI)
    freq            = 40;       % Hz
    power           = 6;        % mW
    dur             = Inf;      % sec
    dutyCycle       = .8;       % how long is laser on during each pulse
    AP              = 1;        % mm from bregma
    ML              = 1;        % mm from bregma
    maxPonPerLoc    = .3;       % max prob per stim location (will overide P_on)
    P_on            = .8;       % fraction of trials lsr ON
    manualTrigger   = false;    % enable manual trigger
    rampDownDur     = 0.1;      % duration of laser power ramp down in sec
    loopTimeTol     = .8;       % percent time beyond laser loop iteration time before iteration is skipped
    
    % galvo parameters
    galvofreq       = 200;      % Hz (only has effect for multiple locations)
    locationSet                 % cell array with list of locations or sets of locations for current session
    galvoManualVx
    galvoManualVy
    galvoVx
    galvoVy
    galvoX
    galvoY
    
    % power calibration
    powerAtt        = .5;       % skull power attenuation factor (from Guo et al. 2014)
    a_power                     % linear transformation from calibration procedure
    b_power                     % linear transformation from calibration procedure
    maxP
    Vlsr
    Vlsr_preset
    
    % galvo calibration
    pxlPerMM       = 86;        % camera scale
    refPxl         = [960 600]; % reference (zero) pixel, center of image for session start
    refIm                       % reference image of the skull (on which coordinates are calculated)
    currIm                      % current image of the skull (to which coordinates are transformed)
    galvoTform                  % affine transformation from calibration procedure
    imTform                     % affine transformation from current image to ref. image of skull
    
    % tranformation parameters
    a_xGalvo                    % linear transformation from calibration procedure
    b_xGalvo                    % linear transformation from calibration procedure
    a_yGalvo                    % linear transformation from calibration procedure
    b_yGalvo                    % linear transformation from calibration procedure
    
    maxVgalvo
    maxGalvoMM_x
    maxGalvoMM_y
    
    % image registration
    ytolerance       = 0.1; % tolerance of image registration in mm, translation y 
    xtolerance       = 0.1; % tolerance of image registration in mm, translation x 
    atolerance       = 0.5;  % tolerance of image registration in deg, rotation 
    percentTolerance = 1; 
    okFlag           = false;
    headplateOutline            % headplate outline for manual mouse positioning
    headplateOutlineX
    headplateOutlineY
    gridImX
    gridImY
    
    % experiment control
    dataout
    dataout_manual
    dataout_preset
    grid
    gridLabel
    drawMode        = 'pseudo-random';              % how to select locations
    rampDownMode    = 'predicted';                  % how to start ramp laser power ramp down (prediction based on velocity or actual?)
    epoch           = 'whole';                      % when to turn the laser on in the trial
    drawModeList    = {'pseudo-random';'random'};   % draw mode options
    rampDownList    = {'predicted';'actual'};       % ramp down options
    epochList       = {'whole';'cue'};              % trial epoch options
    tcpObj
    varyPower       = 0                             % for experiments where power varies on a trial-by-trial basis
    varyPowerLs 	  = [.25 .5 1 2 4 8 12]; 
    preSetOn        = false
    presetLocDur
    presetCycleDur
    presetMaxDurMin
    presetNTrials
    presetPowers
    ephys
    presetRampDown
    
  end
end