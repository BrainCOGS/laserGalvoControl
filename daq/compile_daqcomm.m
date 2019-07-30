function compile_daqcomm()

% compile_daqcomm()
% compiles MEX files for NIDAQ communication

% Only support modern enough compilers
cCompiler   = mex.getCompilerConfigurations('C','Selected');
if      ~strncmpi(cCompiler.ShortName', 'msvc', 4)  ...
    ||  str2double(cCompiler.Version) < 11
  fprintf('!!  WARNING:  This is only supported for Microsoft Visual C++ 2012 and newer. Doing nothing.\n');
  return;
end


% Code files to compile
code        = { 'nidaqPulse.cpp'    ...
              , 'nidaqAOPulse.cpp'  ...
              , 'nidaqDIread.cpp'   ...
              , 'nidaqDOwrite.cpp'  ...
              , 'nidaqAIread.cpp' };

% NI-DAQ environment
nidaqDir    = fullfile(getenv('NIDAQmxSwitchDir'), '..', '..', 'Shared', 'ExternalCompilerSupport', 'C');
mexOpts     = { ['-I' fullfile(nidaqDir, 'include')]                              ...
              , ['-L' fullfile(nidaqDir, ['lib' osBitSize()], 'msvc')]            ...
              , '-lNIDAQmx'                                                       ...
              , '-O'                                                              ...
              };
            
% Change to the directory that hosts this file (and by assumption the mex code)
origLoc     = cd(fullfile(fileparts(mfilename('fullpath'))));

for iCode = 1:numel(code)
  fprintf('====================  Compiling %s  ====================\n', code{iCode});
  mex(code{iCode}, mexOpts{:});
end

cd(origLoc);

