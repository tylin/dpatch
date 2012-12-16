% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function cmd=dstryload(filenm,conf)
  myretry=0;
  mydelete=1;
  dowait=1;
  if(nargin>1)
    if(isfield(conf,'delete'))
      mydelete=conf.delete;
    end
    if(isfield(conf,'retry'))
      myretry=conf.retry;
    end
    if(isfield(conf,'nowait'))
      dowait=~(conf.nowait);
    end
  end
  nretries=0;
  while(~exist(filenm,'file'))
    if(myretry)
      if(nretries>5)
        throw(MException('tryload:notexist','too many retries'));
      end
      pause(2)
    else
      cmd=[];
      return;
    end
  end
  iserror=0;
  while(iserror>=0)
    if(iserror>0)
      pause(2)
    end
    try
      val=load(filenm);
      iserror=-1;
      cmd=val.cmd;
    catch ex
      if(~dowait)
        cmd=[];
        return;
      end
      iserror=iserror+1;
      if(iserror==10)
        rethrow(ex);
      end
    end
  end
  if(mydelete)
    delete(filenm);
  end
  %if(~exist(cmd,'var'))
  %  cmd=[];
  %end
end
