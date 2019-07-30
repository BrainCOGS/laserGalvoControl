function dataIn = TCPIPcomm(command,dataOut)

% dataIn = TCPIPcomm(command,dataOut)
% function for TCP-IP handhsakes with behavior PC

global lsr

switch command
  case 'init'
    
    temp = instrfindall('Status','open','Type','tcpip');
    if ~ isempty(temp)
      fclose(instrfindall);
    end
    lsr.tcpObj = tcpip(LaserRigParameters.virmenIP,80,'NetworkRole','Server');
    fopen(lsr.tcpObj);
    
  case 'send'
    
    if ischar(dataOut)
      fprintf(lsr.tcpObj,dataOut);
    else
      fwrite(lsr.tcpObj,dataOut,'double');
    end
    
  case 'receiveString'
    
    dataIn = fscanf(lsr.tcpObj);
    dataIn = dataIn(1:end-1);
    
  case 'receiveData'
    
    dataIn = fread(lsr.tcpObj);
    
  case 'end'
    
    temp = instrfindall('Status','open','Type','tcpip');
    if ~isempty(temp)
      fclose(lsr.tcpObj);
    end
end