#include <mex.h>
#include <NIDAQmx.h>

#include <iostream>
#include <chrono>
#include <thread>


//-----------------------------------------------------------------------------
#define   USAGE_ERROR()                                                       \
  mexErrMsgIdAndTxt ( "nidaqPulse:usage"                                      \
                    , "Usage:\n"                                              \
                      "    nidaqPulse('init', device, port, channel)\n"       \
                      "    nidaqPulse('end')\n"                               \
                      "    nidaqPulse('ttl', milliseconds)  % asynchronous\n" \
                      "    nidaqPulse('on')                 % blocks\n"       \
                      "    nidaqPulse('off')                % blocks\n"       \
                    );

#define DAQmxErrChk(errID, functionCall)                                      \
    if ( DAQmxFailed(functionCall) ) {                                        \
  	  char                    errBuff[2048] = {'\0'};                         \
      DAQmxGetExtendedErrorInfo(errBuff, 2048);                               \
      mexErrMsgIdAndTxt(errID, "[%s]  %s", errID, errBuff);                   \
    }


//-----------------------------------------------------------------------------
static const int              CMD_LENGTH      = 10;
static const uInt8            OFF_VALUES[32]  = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
static const uInt8            ON_VALUES[32]   = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

TaskHandle                    pulseTask       = NULL;
int32                         statusOn        = -9;
int32                         statusOff       = -9;
std::chrono::duration<double, std::milli>     duration;

static void sendPulse(double interval)
{
  //----- Write 1 to selected channel
  if (DAQmxWriteDigitalLines(pulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, ON_VALUES, NULL, NULL))
    return;                   // ERROR

  //----- High precision pause
  std::chrono::high_resolution_clock::time_point  \
                              tStart        = std::chrono::high_resolution_clock::now();
  std::chrono::high_resolution_clock::time_point  \
                              tEnd;
  std::chrono::milliseconds   tPass         = std::chrono::milliseconds(0);
  std::chrono::milliseconds   tSleep        = std::chrono::milliseconds(1);

  while (true) {
    tEnd                      = std::chrono::high_resolution_clock::now();
    duration                  = tEnd - tStart;

    double                    tRemaining    = interval - duration.count();
    //std::cout << tRemaining << std::endl;
    if (tRemaining > 2)       std::this_thread::sleep_for(tSleep);
    else if (tRemaining > 0)  std::this_thread::sleep_for(tPass);
    else                      break;
  }

  //----- Write 0 to all lines
  DAQmxWriteDigitalLines(pulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL);
}

static void cleanup()
{
  if (pulseTask) {
    DAQmxStopTask(pulseTask);
    
    DAQmxWriteDigitalLines(pulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL);
    DAQmxClearTask(pulseTask);
    pulseTask  = NULL;
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  //----- Parse arguments
  if (nrhs < 1)               USAGE_ERROR();


  char                        command[CMD_LENGTH];
  mxGetString(prhs[0], command, CMD_LENGTH);


  //----- Initialize NI-DAQ communications
  if (strcmp(command, "init") == 0) {
    if (nrhs != 4)            USAGE_ERROR();
    if (pulseTask)
      mexErrMsgIdAndTxt("nidaqPulse:init", "A NI-DAQ task has already been set up. Call 'end' to clear before 'init'.");

    const int                 device        = static_cast<int>( mxGetScalar(prhs[1]) );
    const int                 port          = static_cast<int>( mxGetScalar(prhs[2]) );
    const int                 numChannels   = mxGetNumberOfElements(prhs[3]);
    const double*             channel       = mxGetPr(prhs[3]);

    mexAtExit(cleanup);
    DAQmxErrChk( "nidaqPulse:init", DAQmxCreateTask("pulse", &pulseTask) ); 

    char                      config[100];
    for (int iChannel = 0; iChannel < numChannels; ++iChannel) {
      sprintf(config, "Dev%d/port%d/line%d", device, port, static_cast<int>(channel[iChannel]));
      DAQmxErrChk( "nidaqPulse:init", DAQmxCreateDOChan(pulseTask, config, "", DAQmx_Val_ChanPerLine) );
    }

    DAQmxErrChk( "nidaqPulse:commit" , DAQmxTaskControl(pulseTask, DAQmx_Val_Task_Commit) );
    DAQmxErrChk( "nidaqPulse:initoff", DAQmxWriteDigitalLines(pulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL) );
  }


  //----- Terminate NI-DAQ communications
  else if (strcmp(command, "end") == 0) {
    if (nrhs != 1)            USAGE_ERROR();
    cleanup();
  }


  //----- Trigger NI-DAQ lines asynchronously
  else if (strcmp(command, "ttl") == 0) {
    if (nrhs != 2)            USAGE_ERROR();

    if (!pulseTask)
      mexErrMsgIdAndTxt("nidaqPulse:ttl", "NI-DAQ task has not been set up. Call 'init' before 'ttl'.");

    std::thread               pulseThread(sendPulse, mxGetScalar(prhs[1]));
    pulseThread.detach();
  }

  //----- Turn on NI-DAQ lines (blocking call)
  else if (strcmp(command, "on") == 0) {
    if (nrhs != 1)            USAGE_ERROR();

    if (!pulseTask)
      mexErrMsgIdAndTxt("nidaqPulse:on", "NI-DAQ task has not been set up. Call 'init' before 'on'.");
    DAQmxErrChk( "nidaqPulse:on", DAQmxWriteDigitalLines(pulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, ON_VALUES, NULL, NULL) );
  }

  //----- Turn on NI-DAQ lines (blocking call)
  else if (strcmp(command, "off") == 0) {
    if (nrhs != 1)            USAGE_ERROR();

    if (!pulseTask)
      mexErrMsgIdAndTxt("nidaqPulse:off", "NI-DAQ task has not been set up. Call 'init' before 'off'.");
    DAQmxErrChk( "nidaqPulse:off", DAQmxWriteDigitalLines(pulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL) );
  }

  //----- Unknown command
  else  USAGE_ERROR();
}
