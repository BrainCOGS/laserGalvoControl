function plotGridAndHeadplate(fh)

% plotGridAndHeadplate(fh)
% plot both grid and headplate reference on axis fh

%% initialize / focus
global obj lsr

if nargin < 1; fh = []; end

if isempty(fh)
  axes(obj.camfig); % focus
end
cla

%% image
imagesc(obj.camData); colormap gray; axis image; hold on
set(gca,'XDir','reverse','xtick',[],'ytick',[]);

%% bregma
x = lsr.refPxl(1); y = lsr.refPxl(2);
plot(x,y,'m+','markersize',10) % reference

% headplate
if ~isempty(lsr.headplateOutline)
  plot(lsr.headplateOutlineX,lsr.headplateOutlineY,'y.')
end

%% galvo locations
cl = {'y','b','r','c','g','m','w','k',[.2 .2 .2],[.4 .4 .4],[.6 .6 .6],[.8 .8 .8],...
  [1 .2 .2],[1 .4 .4],[1 .6 .6],[1 .8 .8],[.2 1 .2],[.4 1 .4],[.6 1 .6],[.8 1 .8],...
  [.2 .2 1],[.4 .4 1],[.6 .6 1],[.8 .8 1],[1 .2 0],[1 .4 0],[1 .6 0],[1 .8 0],...
  [0 1 .2],[0 1 .4],[0 1 .6],[0 1 .8],[1 0 .2],[1 0 .4],[1 0 .6],[1 0 .8],...
  [.2 0 1],[.4 0 1],[.6 0 1],[.8 0 1]};

for ii = 1:length(lsr.grid)
  if iscell(lsr.grid)
    for jj = 1:size(lsr.grid{ii},1)
      plot(lsr.gridImX{ii}{jj},lsr.gridImY{ii}{jj},'o','color',cl{ii})
      if jj == 1; text(lsr.gridImX{ii}{jj},lsr.gridImY{ii}{jj},num2str(ii),'color',cl{ii}); end
    end
  else
    text(lsr.gridImX{ii},lsr.gridImY{ii},num2str(ii),'color',cl{1},'horizontalAlignment','center')
  end
end
