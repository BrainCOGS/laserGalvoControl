function plotGalvoGrid(fh)

% plotGalvoGrid(fh)
% plots currently selected inactivation grid on axis fh (typically on top
% of camera image

%% intialize / focus
global obj lsr

if nargin < 1; fh = []; end

if isempty(fh)
  axes(obj.camfig); % focus
  cla
end

%% plot image
imagesc(obj.camData); colormap gray; axis image; hold on
set(gca,'XDir','reverse','xtick',[],'ytick',[]);
if ~isempty(lsr.imTform)
  [x,y] = transformPointsInverse(lsr.imTform, lsr.refPxl(1),lsr.refPxl(2));
else
  x = lsr.refPxl(1); y = lsr.refPxl(2);
end

%% bregma reference
plot(x,y,'m+','markersize',10) 

%% grid
cl = {'y','b','r','c','g','m','w','k',[.2 .2 .2],[.4 .4 .4],[.6 .6 .6],[.8 .8 .8],...
  [1 .2 .2],[1 .4 .4],[1 .6 .6],[1 .8 .8],[.2 1 .2],[.4 1 .4],[.6 1 .6],[.8 1 .8],...
  [.2 .2 1],[.4 .4 1],[.6 .6 1],[.8 .8 1],[1 .2 0],[1 .4 0],[1 .6 0],[1 .8 0],...
  [0 1 .2],[0 1 .4],[0 1 .6],[0 1 .8],[1 0 .2],[1 0 .4],[1 0 .6],[1 0 .8],...
  [.2 0 1],[.4 0 1],[.6 0 1],[.8 0 1]};

for ii = 1:length(lsr.grid)
  if iscell(lsr.grid)
    hold on
    for jj = 1:size(lsr.grid{ii},1)
      x = round(lsr.pxlPerMM*-lsr.grid{ii}(jj,1)) + lsr.refPxl(1);
      y = round(lsr.pxlPerMM*-lsr.grid{ii}(jj,2)) + lsr.refPxl(2);
      % go from ref. map to current image
      if ~isempty(lsr.imTform)
        [x,y] = transformPointsInverse(lsr.imTform, x, y);
      end
      plot(x,y,'o','color',cl{ii})
      if jj == 1; text(x,y,num2str(ii),'color',cl{ii}); end
    end
  else
    hold on
    x  = round(lsr.pxlPerMM*-lsr.grid(ii,1)) + lsr.refPxl(1);
    y  = round(lsr.pxlPerMM*-lsr.grid(ii,2)) + lsr.refPxl(2);
    % go from ref. map to current image
    if ~isempty(lsr.imTform)
      [x,y] = transformPointsInverse(lsr.imTform, x, y);
    end
    text(x,y,num2str(ii),'color',cl{1},'horizontalAlignment','center')
    
  end
end
