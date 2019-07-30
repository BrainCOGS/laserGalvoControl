function lsrL = laserlogger(lsrL,command)

% lsrL = laserlogger(lsrL,command)
% example function for logging data during an experiment. Here there are 3
% types of logging, determined by the command string input:
%   'initialize' creates a file and saves experiment-wode parameters
%   'log' saves trial-by-trial data in a temporary file. This is written
%     such that the saving only happens in inter-trial-intervals, and this
%     computer tells the behavior computer when it's done saving, so as to
%     avoid timing issues on the other end
%   'cleanup' formats the final log, saves the actual file and deletes the
%     temporary file
% see laserLoop() for example calls

%% initialize
global lsr
savestrtemp = sprintf('%s%s\\%s_temp.mat',lsr.savepathroot,lsr.mouseID,lsr.fn); % final file
savestr     = sprintf('%s%s\\%s_laserLog.mat',lsr.savepathroot,lsr.mouseID,lsr.fn); % temp file
varlist     = {'dt';'virmenState';'locationIdx';'data'}; % variables to be saved in log

%% write data
switch command
  case 'init'
    % start log by saving some parameters
    fprintf('starting log\n')
    
    % save experiment parameters
    info.rigParams            = class2struct(LaserRigParameters);
    info.exptParams           = class2struct(lsr);
    info.exptParams.startTime = datestr(datetime,'HHMMSS');
    save(savestrtemp,'info')
    nidaqPulse('on') % tell virmen it's ok to move on, will get turned off once virmen starts
  case 'log'
    % concatenate iterations within each trial. the start of each trial is
    % defined as the SetupTrial state, which is also when the saving happens
    % each trial is saved as an entry in a structure array
    % data from previous trial is saved during setup of the current
    % one, unless experiment is ended
    if lsrL.stop
      % save this trial
      if lsr.varyPower
        lsrL.templog.power = lsrL.currPower;
      end
      eval(sprintf('trial%d = lsrL.templog;',lsrL.trialCounter))
      save(savestrtemp,sprintf('trial%d',lsrL.trialCounter),'-append')
      lsrL.templog = [];
    else
      if lsrL.save
        % save previous trial
        if lsr.varyPower
          lsrL.templog.power = lsrL.prevPower;
        end
        eval(sprintf('trial%d = lsrL.templog;',lsrL.trialCounter-1))
        save(savestrtemp,sprintf('trial%d',lsrL.trialCounter-1),'-append')
        lsrL.lastSavedTrial = lsrL.trialCounter-1;
        lsrL.save = 0;
        
        % start new trial log
        lsrL.templog = [];
        for jj = 1:length(varlist)
          lsrL.templog.(varlist{jj})(lsrL.ii,:) = lsrL.(varlist{jj});
        end
        
        % tell virmen it's ok to move on
        nidaqPulse('on');
      else
        % ATTENTION: dt is from previous iteration
        for jj = 1:length(varlist)
          lsrL.templog.(varlist{jj})(lsrL.ii,:) = lsrL.(varlist{jj});
        end
      end
    end
  case 'cleanup'
    fprintf('saving log\n')
    % structure log for final saving
    load(savestrtemp)
    info.exptParams.endTime = datestr(datetime,'HHMMSS');
    
    % save in blocks such that different starts from the same animal go
    % in the same log file, making it easier and less likely data will
    % get overwritten in case use forgets to change file name
    if isempty(dir(savestr))
      nBlocks = 0;
    else
      load(savestr,'lsrlog')
      nBlocks = length(lsrlog.block);
    end
    
    lsrlog.block(nBlocks+1).info = info;
    for jj = 1:lsrL.trialCounter
      lsrlog.block(nBlocks+1).trial(jj) = eval(sprintf('trial%d',jj));
    end
    save(savestr,'lsrlog')
    delete(savestrtemp)
end
