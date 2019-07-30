function plotHeadplateOutline(fh)


global obj lsr

if nargin < 1
    fh = [];
end
if isempty(fh)
axes(obj.camfig); % focus
cla
end

imagesc(obj.camData); colormap gray; axis image; 
set(gca,'XDir','reverse','xtick',[],'ytick',[]);

% bregma
hold on
x = lsr.refPxl(1); y = lsr.refPxl(2);
plot(x,y,'m+','markersize',10) 

% headplate
if ~isempty(lsr.headplateOutline)
[y,x] = find(fliplr(lsr.headplateOutline)==1);
plot(x,y,'y.')
end