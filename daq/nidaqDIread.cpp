#include <mex.h>
#include <NIDAQmx.h>

#include <iostream>
#include <chrono>
#include <thread>


//-----------------------------------------------------------------------------
#define   USAGE_ERROR()                                                       \
  mexErrMsgIdAndTxt ( "nidaqDIread:usage"                                      \
                    , "Usage:\n"                                              \
                      "    nidaqDIread('init', device, channels)\n"          \
                      "    nidaqDIread('end')\n"                             \
                      "    nidaqDIread('readDI', data)  % asynchronous\n"   \
                      "    nidaqDIread('on')                 % blocks\n"     \
                      "    nidaqDIread('off')                % blocks\n"     \
                    );

#define DAQmxErrChk(errID, functionCall)                                      \
    if ( DAQmxFailed(functionCall) ) {                                        \
  	  char                    errBuff[2048] = {'\0'};                         \
      DAQmxGetExtendedErrorInfo(errBuff, 2048);                               \
      mexErrMsgIdAndTxt(errID, "[%s]  %s", errID, errBuff);                   \
    }


//-----------------------------------------------------------------------------

static const int              CMD_LENGTH      = 10;
TaskHandle                    readDITask     = NULL;
uInt8                         data[16]; // allocate memory, readDI will update it

static void readDI()
{
  // uInt8   data[8];
  int32   read,bytesPerSamp;

  //----- Read data from selected channels
if (DAQmxReadDigitalLines(readDITask, 1, 0, DAQmx_Val_GroupByChannel, data, 16, &read, &bytesPerSamp, NULL)) 
    return;                  // returns data
}

static void cleanup()
{
  if (readDITask) {
    DAQmxStopTask(readDITask);
    DAQmxClearTask(readDITask);
    readDITask  = NULL;
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
    if (readDITask)
      mexErrMsgIdAndTxt("nidaqDIread:init", "A NI-DAQ task has already been set up. Call 'end' to clear before 'init'.");

    const int                 device        = static_cast<int>( mxGetScalar(prhs[1]) );
    const int                 port          = static_cast<int>( mxGetScalar(prhs[2]) );
    const size_t              numChannels   = mxGetNumberOfElements(prhs[3]);
    const double*             channel       = mxGetPr(prhs[3]);

    mexAtExit(cleanup);
    DAQmxErrChk( "nidaqDIread:init", DAQmxCreateTask("readDITask", &readDITask) ); 

    char                      config[100];
    for (int iChannel = 0; iChannel < numChannels; ++iChannel) {
      sprintf(config, "Dev%d/port%d/line%d", device, port, static_cast<int>(channel[iChannel]));
	  DAQmxErrChk( "nidaqDIread:init", DAQmxCreateDIChan(readDITask, config, "", DAQmx_Val_ChanPerLine));
    }

    DAQmxErrChk( "nidaqDIread:commit" , DAQmxTaskControl(readDITask, DAQmx_Val_Task_Commit) );
  }


  //----- Terminate NI-DAQ communications
  else if (strcmp(command, "end") == 0) {
    if (nrhs != 1)            USAGE_ERROR();
    cleanup();
  }


  //----- Read NI-DAQ lines asynchronously
  else if (strcmp(command, "readDI") == 0) {
    if (nrhs != 1)            USAGE_ERROR();

    if (!readDITask)
      mexErrMsgIdAndTxt("nidaqDIread:readDI", "NI-DAQ task has not been set up. Call 'init' before 'readDI'.");
    // uInt8 data = readDI();
    readDI(); // get data
    plhs[0] = mxCreateDoubleMatrix(1 , 16, mxREAL); // create mex array
	  double* output = mxGetPr(plhs[0]);   // pointer
	  for (int i = 0; i < 16; ++i)  output[i] = data[i]; // update mex array from read data
	
  }

  //----- Unknown command
  else  USAGE_ERROR();
}
