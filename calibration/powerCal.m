function powerCal

% powerCal
% laser power calibration function
% calibrate laser power in VGAT set-up
% LP aug 15 / ST oct 2015
% revamp LP jan 2016

%% initialize
global lsr

rootdir  = [lsr.rootdir 'calibration\'];
savepath = [lsr.savepathroot 'calibration\'];
fn = sprintf('%sPowerCalibration.mat',rootdir);

commandwindow; %clc
fprintf('Input power meter readings when prompted\n\n')

% first save a copy of previous cal file (if any) by appending previous
% date
if ~isempty(dir(fn))
  load(fn,'PowerCalibration','calDate')
  copyfile(fn,sprintf('%sPowerCalibration_%s.mat',savepath,calDate));
  clear calDate
  
  % Construct a questdlg with three options
  choice = questdlg('A Voltage to Power Calibration has been found (see Matlab Command). Do you want to recalibrate?', ...
    'Power calibration',                    ...
    'Only V_Photodiode vs Vcontrol',        ...
    'Only Powermeter vs Vcontrol',          ...
    'V_Photodiode & Powermeter vs Vcontrol',...
    'V_Photodiode vs Vcontrol'              );
  
  disp('  ')
  disp('---- Existing power calibration -----   ')
  disp(['PhotoDiodeV2LsrPower: ',num2str(PowerCalibration.PhotoDiodeV2LsrPower)]);
  disp(['ControlVoltageToPhotodiodeOutput: ',num2str(PowerCalibration.ControlVoltageToPhotodiodeOutput.slope),',  ',num2str(PowerCalibration.ControlVoltageToPhotodiodeOutput.constant)]);
  disp(['MaxLaserPower (dutyCycle=100%): ',num2str(PowerCalibration.MaxLaserPower)]);
  disp(['ControlVoltageToLaserPower: ',num2str(PowerCalibration.ControlVoltageToLaserPower.slope),',  ',num2str(PowerCalibration.ControlVoltageToLaserPower.constant)]);
  disp('-------------------------------------   ')
  
  % Handle response
  switch choice
    case 'Only V_Photodiode vs Vcontrol'
      ReadPhotodiode=1;
      ReadPowerMeter=0;
    case 'Only Powermeter vs Vcontrol'
      ReadPhotodiode=0;
      ReadPowerMeter=1;
    case 'V_Photodiode & Powermeter vs Vcontrol'
      ReadPhotodiode=1;
      ReadPowerMeter=1;
  end
end

% parameters
vmin = 0; % minimal voltage controlling laser power
vmax = 5; % maximal voltage controlling laser power
vstp = 1; % voltage steps for calibration
dur  = 4; % in sec
calDate = datestr(datetime,'yymmdd_HHMMSS');

%% send voltage according to desired steps
szl = (1000/lsr.freq)*(LaserRigParameters.rate/1000);
datafreq = repmat(repmat([ones(floor(szl*lsr.dutyCycle),1); ...
  zeros(ceil(szl*(1-lsr.dutyCycle)),1)],lsr.freq,1),[dur 1]);
dataout = zeros(1,4);
dataout(LaserRigParameters.lsrSwitchCh) = 5;

vPower = vmin:vstp:vmax;
lsrPower = zeros(size(vPower));
RecordPhotoDiodeVoltages=zeros(length(vPower),3);

vPower = vmin:vstp:vmax;
lsrPower = zeros(size(vPower));
RecordPhotoDiodeVoltages=zeros(length(vPower),3);

% increase voltage progressively and measure input
for ii = 1:length(vPower)
  
  % measure for "dur" sec
  datain = zeros(length(datafreq),1);
  for jj = 1:LaserRigParameters.rate*dur
    tic;
    dataout(LaserRigParameters.lsrWaveCh) = datafreq(jj)*vPower(ii);
    nidaqAOPulse('aoPulse',dataout);
    delay(.001);
    
    if ReadPhotodiode
      temp = nidaqAIread('AIread');
      datain(jj) = temp(LaserRigParameters.pdInCh);
    end
    ts = toc;
    delay(1/LaserRigParameters.rate-ts);
  end
  nidaqAOPulse('aoPulse',[0 0 0 0]);
  
  if ReadPowerMeter
    % user inputs power meter reading
    lsrPower(ii) = input(sprintf('Voltage = %1.1d. Power reading (mW): ',vPower(ii)));
  else
    disp('calibrating');
    pause(1)
  end
  
  if ReadPhotodiode
    %histogram
    [counts,centers]=hist(datain,-1:0.01:10);
    %the two largest bins are
    [~ ,I1]=max(counts(:));
    counts(I1)=0;
    [~,I2]=max(counts(:));
    VMean=mean(datain);%round(1000*mean(datain))/1000;
    VMin=min(centers(I1),centers(I2));
    VMax=max(centers(I1),centers(I2));
    RecordPhotoDiodeVoltages(ii,:)=[VMean VMin VMax];
  end
  
  
end

%% plot results, try to fit line, save
h1=figure;
if ReadPowerMeter
  p = polyfit(vPower,lsrPower,1);
  a = p(1); b = p(2);
  xaxis = vmin:.01:vmax;
  plot(vPower,lsrPower,'ko');  hold on; plot(xaxis,a.*xaxis+b,'r-');
  text(1,15,['a=',num2str(a),';   b=',num2str(b)]);
  %the relation control Voltage to LaserPower is
  PowerCalibration.ControlVoltageToLaserPower.slope=p(1);
  PowerCalibration.ControlVoltageToLaserPower.constant=p(2);
  
  %what is expected max power out of the fiber at controls=5V (power=110% of
  %nominal value)?
  PowerCalibration.MaxLaserPower=(1/(1-lsr.dutyCycle))*max(lsrPower(:));
end

if ReadPhotodiode
  %the relation control Voltage to Photodiode signal is
  p = polyfit(vPower',RecordPhotoDiodeVoltages(:,1),1);
  a = p(1); b = p(2);
  xaxis = vmin:.01:vmax;
  plot(vPower,RecordPhotoDiodeVoltages(:,1),'ko');  hold on; plot(xaxis,a.*xaxis+b,'r-');
  text(3,0.5,['a=',num2str(a),';   b=',num2str(b)]);
  %the relation control Voltage to photodiodeOutput is
  PowerCalibration.ControlVoltageToPhotodiodeOutput.slope=p(1);
  PowerCalibration.ControlVoltageToPhotodiodeOutput.constant=p(2);
end
xlabel('Control Voltage Vmax (V)')


if ReadPhotodiode && ReadPowerMeter
  clf(h1);
  [hAx,hLine1,hLine2] = plotyy(vPower,lsrPower,vPower,RecordPhotoDiodeVoltages(:,1));  hold on;
  
  hLine1.Marker = 'o'; hLine1.Color='k';
  hLine2.Marker = 'o'; hLine2.Color='b';
  title(['Power Calibration for DutyCycle ',num2str(lsr.dutyCycle),', and Freq ',num2str(lsr.freq),' Hz'])
  xlabel('Control Voltage Vmax (V)')
  
  ylabel(hAx(1),'Powermeter  measurement (mW)') % left y-axis
  ylabel(hAx(2),'Photodiode measurement (mean value in V)') % right y-axis
  hAx(1).YTick=[0 5 10 15 20 25 30];
  grid on;
  h1.PaperPositionMode='auto';
  temp = datetime;
  calDate = datestr(temp,'yymmdd_HHMMSS');
  saveas(h1,[lsr.savepathroot 'calibration\powerCalGraph1_',num2str(calDate),'.pdf'])
  
  
  h2=figure; plot(lsrPower,RecordPhotoDiodeVoltages(:,1),'bo'); hold on;
  p = polyfit(lsrPower',RecordPhotoDiodeVoltages(:,1),1);
  a = p(1); b = p(2);
  xaxis = 0:.01:5*(round(max(lsrPower(:)/5+1)));
  plot(xaxis,a.*xaxis+b,'r-');
  legend(['a=',num2str(a),';   b=',num2str(b)]);
  title(['Conversion Mean Photodiode Voltage to MilliWatts :', num2str(round(100/a)/100), ' mW / V'])
  h2.PaperPositionMode='auto';
  temp = datetime;
  calDate = datestr(temp,'yymmdd_HHMMSS');
  saveas(h2,[lsr.savepathroot 'calibration\powerCalGraph2_',num2str(calDate),'.pdf'])
  
  %the conversion factor to read the power through the amplified photodiode
  %signal is:
  PowerCalibration.PhotoDiodeV2LsrPower=num2str(round(100/a)/100);
end

%% close and save
answer = questdlg('Close Figures?');
if strcmpi(answer,'Yes')
  close(h1); 
  close(h2); 
end

disp('  ')
disp('---- Updated power calibration -----   ')
disp(['PhotoDiodeV2LsrPower: ',num2str(PowerCalibration.PhotoDiodeV2LsrPower)]);
disp(['ControlVoltageToPhotodiodeOutput: ',num2str(PowerCalibration.ControlVoltageToPhotodiodeOutput.slope),',  ',num2str(PowerCalibration.ControlVoltageToPhotodiodeOutput.constant)]);
disp(['MaxLaserPower (dutyCycle=100%): ',num2str(PowerCalibration.MaxLaserPower)]);
disp(['ControlVoltageToLaserPower: ',num2str(PowerCalibration.ControlVoltageToLaserPower.slope),',  ',num2str(PowerCalibration.ControlVoltageToLaserPower.constant)]);
disp('-------------------------------------   ')

lsrparams = class2struct(lsr);
save(fn,'PowerCalibration','calDate','lsrparams');

