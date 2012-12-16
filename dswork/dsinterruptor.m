% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% A thread that runs in the background of each worker waiting for the main thread
% to issue dsinterrupt.  Sends an interrupt signal to the the dsmapreducer thread
% when that happens.
while(1)
  if(exist(commlinkin,'file'))
    load(commlinkin);
    delete(commlinkin);
    if(strcmp(cmd.name,'exit'))
      exit;
    elseif(strcmp(cmd.name,'interrupt'))
      unix(['kill -INT ' num2str(slavepid)]);
    end
  end
  [~,lines]=unix(['ps x']);
  if(numel(strfind(lines,num2str(slavepid)))==0)
    a=0;
    save([commlinkin 'nonotifyexit.mat'],'a');
    %parent process exited without notifying us??
    exit;
  end
  pause(5);
end
exit;
