#include <mex.h>
#include <NIDAQmx.h>

#include <iostream>
#include <chrono>
#include <thread>


//-----------------------------------------------------------------------------
#define   USAGE_ERROR()                                                       \
  mexErrMsgIdAndTxt ( "nidaqDOwrite:usage"                                      \
                    , "Usage:\n"                                              \
                      "    nidaqDOwrite('init', device, port, channels)\n"          \
                      "    nidaqDOwrite('end')\n"                             \
                      "    nidaqDOwrite('writeDO', data)  % asynchronous\n"   \
                    );

#define DAQmxErrChk(errID, functionCall)                                      \
    if ( DAQmxFailed(functionCall) ) {                                        \
  	  char                    errBuff[2048] = {'\0'};                         \
      DAQmxGetExtendedErrorInfo(errBuff, 2048);                               \
      mexErrMsgIdAndTxt(errID, "[%s]  %s", errID, errBuff);                   \
    }


//-----------------------------------------------------------------------------

static const int              CMD_LENGTH      = 10;
TaskHandle                    writeDOTask     = NULL;
//uInt8                         data[8]; // allocate memory, readDI will update it
static const uInt8            OFF_VALUES[8] = { 0,0,0,0,0,0,0,0};

static void writeDO(double* dataIn)
{
	uInt8                        data[8]; // allocate memory
	for (int i = 0; i < 8; ++i)  data[i] = dataIn[i]; // update mex array from read data

  //----- Read data from selected channels
	if (DAQmxWriteDigitalLines(writeDOTask, 1, true, 0, DAQmx_Val_GroupByChannel, data, NULL, NULL))
    return;             
}

static void cleanup()
{
  if (writeDOTask) {
	DAQmxWriteDigitalLines(writeDOTask, 1, true, 0, DAQmx_Val_GroupByChannel, OFF_VALUES, NULL, NULL);
    DAQmxStopTask(writeDOTask);
    DAQmxClearTask(writeDOTask);
    writeDOTask  = NULL;
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
    if (writeDOTask)
      mexErrMsgIdAndTxt("nidaqDOwrite:init", "A NI-DAQ task has already been set up. Call 'end' to clear before 'init'.");

    const int                 device        = static_cast<int>( mxGetScalar(prhs[1]) );
    const int                 port          = static_cast<int>( mxGetScalar(prhs[2]) );
    const size_t              numChannels   = mxGetNumberOfElements(prhs[3]);
    const double*             channel       = mxGetPr(prhs[3]);

    mexAtExit(cleanup);
    DAQmxErrChk( "nidaqDOwrite:init", DAQmxCreateTask("writeDOTask", &writeDOTask) ); 

    char                      config[100];
    for (int iChannel = 0; iChannel < numChannels; ++iChannel) {
      sprintf(config, "Dev%d/port%d/line%d", device, port, static_cast<int>(channel[iChannel]));
	  DAQmxErrChk( "nidaqDOwrite:init", DAQmxCreateDOChan(writeDOTask, config, "", DAQmx_Val_ChanPerLine));
    }

    DAQmxErrChk( "nidaqDOwrite:commit" , DAQmxTaskControl(writeDOTask, DAQmx_Val_Task_Commit) );
  }


  //----- Terminate NI-DAQ communications
  else if (strcmp(command, "end") == 0) {
    if (nrhs != 1)            USAGE_ERROR();
    cleanup();
  }


  //----- Read NI-DAQ lines asynchronously
  else if (strcmp(command, "writeDO") == 0) {
    if (nrhs != 2)            USAGE_ERROR();

    if (!writeDOTask)
      mexErrMsgIdAndTxt("nidaqDOwrite:writeDO", "NI-DAQ task has not been set up. Call 'init' before 'writeDO'.");

  std::thread               pulseThread(writeDO, mxGetPr(prhs[1]));
  pulseThread.detach();
	
  }

  //----- Unknown command
  else  USAGE_ERROR();
}
