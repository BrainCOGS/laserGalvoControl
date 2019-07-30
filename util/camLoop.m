function camLoop

% camLoop
% function that handles video acquisition and streaming

global obj lsr

stopL   = false; 

% focus camera
axes(obj.camfig)
start(obj.vid)

% generate headplate outline
if ~isempty(lsr.headplateOutline)
  [lsr.headplateOutlineY,lsr.headplateOutlineX] = find(fliplr(lsr.headplateOutline)==1);
else
  lsr.headplateOutlineY = [];
  lsr.headplateOutlineX = [];
end

% generate grid location markers
lsr.gridImX = cell(1,length(lsr.grid));
lsr.gridImY = cell(1,length(lsr.grid));
for ii = 1:length(lsr.grid)
    if iscell(lsr.grid)
        hold on
        for jj = 1:size(lsr.grid{ii},1)
            lsr.gridImX{ii}{jj} = round(lsr.pxlPerMM*-lsr.grid{ii}(jj,1)) + lsr.refPxl(1);
            lsr.gridImY{ii}{jj} = round(lsr.pxlPerMM*-lsr.grid{ii}(jj,2)) + lsr.refPxl(2);
            % go from ref. map to current image
            if ~isempty(lsr.imTform)
                [lsr.gridImX{ii}{jj},lsr.gridImY{ii}{jj}] = transformPointsInverse(lsr.imTform, lsr.gridImX{ii}{jj}, lsr.gridImY{ii}{jj});
            end
        end
    else
        hold on
        lsr.gridImX{ii}  = round(lsr.pxlPerMM*-lsr.grid(ii,1)) + lsr.refPxl(1);
        lsr.gridImY{ii}  = round(lsr.pxlPerMM*-lsr.grid(ii,2)) + lsr.refPxl(2);
        % go from ref. map to current image
        if ~isempty(lsr.imTform)
            [lsr.gridImX{ii},lsr.gridImY{ii}] = transformPointsInverse(lsr.imTform, lsr.gridImX{ii}, lsr.gridImY{ii});
        end        
    end
end

% timing here is not strictly enforced
while ~ stopL
  
    % get cam data 
    trigger(obj.vid);

    dataRead    = getdata(obj.vid, obj.vid.FramesAvailable, 'uint8');
    obj.camData = dataRead(:,:,:,end);
    if isempty(dataRead); continue; else; clear dataRead; end
    
    % plot
    plotGridAndHeadplate(obj.camfig)
    
    % check for other stuff in gui and roughly enforce timing
    drawnow()
    if get(obj.camON,'Value') == false; stopL = true; end
end

% delete object
stop(obj.vid);
flushdata(obj.vid)
delete(obj.vid);