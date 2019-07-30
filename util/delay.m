function t = delay(seconds)
% function pause the program
% seconds = delay time in seconds
tic; t=0;
while t < seconds
    t=toc;
end
end