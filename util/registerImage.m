function [msg,okFlag,offset,tform] = registerImage(ref,im,subImFlag)

% [msg,okFlag,offset,tform] = registerImage(ref,im,subImFlag)
% Function used to register an image (im) to another (ref). "ref" is
% typically a previously saved reference and "im" is typically current
% image. subImFlag is boolean to use only part of the image of registration
% (default: false, true will prompt user to select an ROI)
% OUTPUT
%   msg is string containing quantification about information, to be displayed by the GUI
%   okFlag is boolean, true if registration is within the error margins
%     defined in lsrCtrlParams. If it is not user is not allowed to proceed
%   offset is a data structure containing calculated offset with respect to reference image
%   tform is the matlab transformation object output by thge registration

%%
if nargin < 2; error('I need at least two inputs'); end
if nargin < 3; subImFlag = false; end

global lsr

%% flip
im  = fliplr(im);
ref = fliplr(ref);

%% normalize images
im  = im-mean(mean(im))./std(std(double(im)));
ref = ref-mean(mean(ref))./std(std(double(ref)));

%% use only relevant subregion?
if subImFlag
  f3 = figure;
  imshow(im); title('please select sub-region for registration')
  r = getrect(f3);
  im  = im(r(2):r(2)+r(4),r(1):r(1)+r(3));
  ref = ref(r(2):r(2)+r(4),r(1):r(1)+r(3));
  close(f3)
end

%% use rigid transformation to go from current image im to reference image
[optimizer,metric] = imregconfig('multimodal');
regim = imregister(im,ref,'rigid',optimizer,metric);
tform = imregtform(im,ref,'rigid',optimizer,metric);

offset.angle   = rad2deg(asin(tform.T(2,1)));
offset.xtransl = tform.T(3,1)/lsr.pxlPerMM;
offset.ytransl = tform.T(3,2)/lsr.pxlPerMM;
offset.percent = 100*sum(regim(:)==0)/numel(regim(:)); % % black pixels in registerd image

%% decide whether it's good enough and output message
if    (abs(offset.angle)   <= lsr.atolerance          ...
    && abs(offset.xtransl) <= lsr.xtolerance          ...
    && abs(offset.ytransl) <= lsr.ytolerance          ...
    && offset.percent      <= lsr.percentTolerance)   ...
    || offset.percent      <= lsr.percentTolerance/2
  
  msg    = sprintf('Good alignment!, %1.1f%% off',offset.percent);
  okFlag = true;

else
  
  okFlag = false;
  
  if abs(offset.angle) <= lsr.atolerance
    angtxt = 'angle is good';
  else
    if offset.angle < 0
      angtxt = sprintf('rotate %1.1f deg clockwise',abs(offset.angle));
    else
      angtxt = sprintf('rotate %1.1f deg counterclockwise',abs(offset.angle));
    end
  end
  if abs(offset.xtransl) <= lsr.xtolerance
    xtxt = 'x is good';
  else
    if offset.xtransl < 0
      xtxt = sprintf('move %1.2f mm to the left',abs(offset.xtransl));
    else
      xtxt = sprintf('move %1.2f mm to the right',abs(offset.xtransl));
    end
  end
  if abs(offset.ytransl) <= lsr.ytolerance
    ytxt = 'y is good';
  else
    if offset.xtransl < 0
      ytxt = sprintf('move %1.2f mm forward',abs(offset.ytransl));
    else
      ytxt = sprintf('move %1.2f mm back',abs(offset.ytransl));
    end
  end
  
  msg = sprintf('Bad alignment: %1.1f%% off\n%s, %s, %s', offset.percent, angtxt, xtxt, ytxt);
  
end

%% plot and save  
f2 = figure; 
subplot(2,3,1); imagesc(ref); axis image; axis off; set(gca,'XDir','reverse'); colormap gray; title('reference')
subplot(2,3,2); imagesc(im); axis image; axis off; set(gca,'XDir','reverse'); colormap gray; title('image')
subplot(2,3,3); imagesc(regim); axis image; axis off; set(gca,'XDir','reverse'); colormap gray; title('registered image')

subplot(2,3,4); imshowpair(ref,im); axis image; set(gca,'XDir','reverse'); title('reference + image')
subplot(2,3,5); imshowpair(ref,regim); axis image; set(gca,'XDir','reverse'); title('reference + reg. image')

saveas(f2,sprintf('%s%s_imRegistration',lsr.savepath,lsr.fn))
close(f2)

save(sprintf('%s%s_imRegistration.mat',lsr.savepath,lsr.fn),'tform','offset','msg')



