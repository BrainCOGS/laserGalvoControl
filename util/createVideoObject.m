function obj = createVideoObject(obj)

% obj = createVideoObject(obj)
% creates video object for image registration / video streaming

if isfield(obj,'vid'); delete(obj.vid); end

obj.vid                   = videoinput(LaserRigParams.camName, 1, LaserRigParams.camImageType);
src                       = getselectedsource(obj.vid);
src.ExposureMode          = 'Auto';
src.FrameRate             = 10;
obj.vid.FramesPerTrigger  = 1;
obj.vidRes                = get(obj.vid, 'VideoResolution');
nBands                    = get(obj.vid, 'NumberOfBands');
obj.hImage                = image(zeros(obj.vidRes(2),obj.vidRes(1), nBands),'Parent',obj.camfig);
set(obj.camfig,'visible','on')

obj.vid.TriggerRepeat     = Inf;
obj.vid.FrameGrabInterval = 1;
triggerconfig(obj.vid, 'manual');