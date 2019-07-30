#include <mex.h>
#include <NIDAQmx.h>

#include <iostream>
#include <chrono>
#include <thread>


//-----------------------------------------------------------------------------
#define   USAGE_ERROR()                                                       \
  mexErrMsgIdAndTxt ( "nidaqPulse:usage"                                      \
                    , "Usage:\n"                                              \
                      "    nidaqAOPulse('init', device, channels)\n"          \
                      "    nidaqAOPulse('end')\n"                             \
                      "    nidaqAOPulse('aoPulse', data)  % asynchronous\n"   \
                      "    nidaqAOPulse('on')                 % blocks\n"     \
                      "    nidaqAOPulse('off')                % blocks\n"     \
                    );

#define DAQmxErrChk(errID, functionCall)                                      \
    if ( DAQmxFailed(functionCall) ) {                                        \
  	  char                    errBuff[2048] = {'\0'};                         \
      DAQmxGetExtendedErrorInfo(errBuff, 2048);                               \
      mexErrMsgIdAndTxt(errID, "[%s]  %s", errID, errBuff);                   \
    }


//-----------------------------------------------------------------------------

static const int              CMD_LENGTH      = 10;
TaskHandle                    AOpulseTask     = NULL;
static const double          OFF_VALUES[4]   = {0,0,0,0};

// const float64                 data[4]         = {0,0,0,0};
//std::chrono::duration<double, std::milli>     duration;
//float64     data[1] = {1.0};

static void sendAOPulse(float64 data[4])
{
  //----- Write data to selected channels
  if (DAQmxWriteAnalogF64(AOpulseTask, 1, true, 0, DAQmx_Val_GroupByChannel,data,NULL,NULL))
    return;                   // ERROR
}

static void cleanup()
{
  if (AOpulseTask) {
    DAQmxStopTask(AOpulseTask);
    
    DAQmxWriteAnalogF64(AOpulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL);
    DAQmxClearTask(AOpulseTask);
    AOpulseTask  = NULL;
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
    if (nrhs != 3)            USAGE_ERROR();
    if (AOpulseTask)
      mexErrMsgIdAndTxt("nidaqAOPulse:init", "A NI-DAQ task has already been set up. Call 'end' to clear before 'init'.");

    const int                 device        = static_cast<int>( mxGetScalar(prhs[1]) );
    // const int                 port          = static_cast<int>( mxGetScalar(prhs[2]) );
    const int                 numChannels   = mxGetNumberOfElements(prhs[2]);
    const double*             channel       = mxGetPr(prhs[2]);

    mexAtExit(cleanup);
    DAQmxErrChk( "nidaqAOPulse:init", DAQmxCreateTask("AOpulse", &AOpulseTask) ); 

    char                      config[100];
    for (int iChannel = 0; iChannel < numChannels; ++iChannel) {
      sprintf(config, "Dev%d/ao%d", device, static_cast<int>(channel[iChannel]));
      DAQmxErrChk( "nidaqAOPulse:init", DAQmxCreateAOVoltageChan(AOpulseTask,config,"",-10.0,10.0,DAQmx_Val_Volts,""));
    }

    DAQmxErrChk( "nidaqAOPulse:commit" , DAQmxTaskControl(AOpulseTask, DAQmx_Val_Task_Commit) );
    DAQmxErrChk( "nidaqAOPulse:initoff", DAQmxWriteAnalogF64(AOpulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL) );
  }


  //----- Terminate NI-DAQ communications
  else if (strcmp(command, "end") == 0) {
    if (nrhs != 1)            USAGE_ERROR();
    cleanup();
  }


  //----- Trigger NI-DAQ lines asynchronously
  else if (strcmp(command, "aoPulse") == 0) {
    if (nrhs != 2)            USAGE_ERROR();

    if (!AOpulseTask)
      mexErrMsgIdAndTxt("nidaqAOPulse:aoPulse", "NI-DAQ task has not been set up. Call 'init' before 'aoPulse'.");

    std::thread               pulseThread(sendAOPulse, mxGetPr(prhs[1]));
    pulseThread.detach();
  }

  //----- Turn on NI-DAQ lines (blocking call)
  else if (strcmp(command, "on") == 0) {
    if (nrhs != 1)            USAGE_ERROR();

    if (!AOpulseTask)
      mexErrMsgIdAndTxt("nidaqAOPulse:on", "NI-DAQ task has not been set up. Call 'init' before 'on'.");
    DAQmxErrChk( "nidaqAOPulse:on", DAQmxWriteAnalogF64(AOpulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL) );
  }

  //----- Turn on NI-DAQ lines (blocking call)
  else if (strcmp(command, "off") == 0) {
    if (nrhs != 1)            USAGE_ERROR();

    if (!AOpulseTask)
      mexErrMsgIdAndTxt("nidaqAOPulse:off", "NI-DAQ task has not been set up. Call 'init' before 'off'.");
    DAQmxErrChk( "nidaqAOPulse:off", DAQmxWriteAnalogF64(AOpulseTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL) );
  }

  //----- Unknown command
  else  USAGE_ERROR();
}
