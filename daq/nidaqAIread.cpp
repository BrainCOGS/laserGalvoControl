#include <mex.h>
#include <NIDAQmx.h>

#include <iostream>
#include <chrono>
#include <thread>


//-----------------------------------------------------------------------------
#define   USAGE_ERROR()                                                       \
  mexErrMsgIdAndTxt ( "nidaqPulse:usage"                                      \
                    , "Usage:\n"                                              \
                      "    nidaqAIread('init', device, channels)\n"          \
                      "    nidaqAIread('end')\n"                             \
                      "    nidaqAIread('AIread', data)  % asynchronous\n"   \
                    );

#define DAQmxErrChk(errID, functionCall)                                      \
    if ( DAQmxFailed(functionCall) ) {                                        \
  	  char                    errBuff[2048] = {'\0'};                         \
      DAQmxGetExtendedErrorInfo(errBuff, 2048);                               \
      mexErrMsgIdAndTxt(errID, "[%s]  %s", errID, errBuff);                   \
    }


//-----------------------------------------------------------------------------

static const int              CMD_LENGTH = 10;
TaskHandle                    AIreadTask = NULL;
float64                       data[4];

static void readAI()
{
	int32       read,numSamp;
	//----- Write data to selected channels
	if (DAQmxReadAnalogF64(AIreadTask, 1, 0, DAQmx_Val_GroupByChannel, data, 4, &read, NULL))
		return;                   // ERROR
}

static void cleanup()
{
	if (AIreadTask) {
		DAQmxStopTask(AIreadTask);
		DAQmxClearTask(AIreadTask);
		AIreadTask = NULL;
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
		if (AIreadTask)
			mexErrMsgIdAndTxt("nidaqAIread:init", "A NI-DAQ task has already been set up. Call 'end' to clear before 'init'.");

		const int                 device = static_cast<int>(mxGetScalar(prhs[1]));
		const int                 numChannels = mxGetNumberOfElements(prhs[2]);
		const double*             channel = mxGetPr(prhs[2]);

		mexAtExit(cleanup);
		DAQmxErrChk("nidaqAIread:init", DAQmxCreateTask("AIread", &AIreadTask));

		char                      config[100];
		for (int iChannel = 0; iChannel < numChannels; ++iChannel) {
			sprintf(config, "Dev%d/ai%d", device, static_cast<int>(channel[iChannel]));
			DAQmxErrChk("nidaqAIread:init", DAQmxCreateAIVoltageChan(AIreadTask, config, "", DAQmx_Val_Diff, -10.0, 10.0, DAQmx_Val_Volts, ""));
			//DAQmxErrChk("nidaqAIread:init", DAQmxCfgSampClkTiming(AIreadTask, "", 10000.0, DAQmx_Val_Rising, DAQmx_Val_FiniteSamps, numChannels));
		}

		DAQmxErrChk("nidaqAIread:commit", DAQmxTaskControl(AIreadTask, DAQmx_Val_Task_Commit));
	}


	//----- Terminate NI-DAQ communications
	else if (strcmp(command, "end") == 0) {
		if (nrhs != 1)            USAGE_ERROR();
		cleanup();
	}


	//----- Trigger NI-DAQ lines asynchronously
	else if (strcmp(command, "AIread") == 0) {
		if (nrhs != 1)            USAGE_ERROR();

		if (!AIreadTask)
			mexErrMsgIdAndTxt("nidaqAIread:AIread", "NI-DAQ task has not been set up. Call 'init' before 'AIread'.");

		readAI(); // get data
		plhs[0] = mxCreateDoubleMatrix(1, 4, mxREAL); // create mex array
		double* output = mxGetPr(plhs[0]);   // pointer
		for (int i = 0; i < 4; ++i)  output[i] = data[i]; // update mex array from read data
	}

	//----- Unknown command
	else  USAGE_ERROR();
}
