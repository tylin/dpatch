% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function dstrysave(filenm,cmd)
%  if(exist(filenm,'file'))
   global ds;
    iserror=0;
    %if(dsbool(ds,'conf','checksaves'))
      ofil=filenm;
      filenm=[filenm '_tmp.mat'];
    %end
    while(iserror>=0)
      if(iserror>0)
        pause(2)
      end
      try
        checkpassed=false;
        while(~checkpassed)
          save(filenm,'cmd');
          iserror=-1;
          checkpassed=(~dsbool(ds,'conf','checksaves'))||checksave(filenm,'''cmd''')
        end
%        cmd=val.cmd;
      catch ex
        iserror=iserror+1;
        if(iserror==5)
          dsprinterr;
          throw(MException('dsmapreducer:cantwrite',['unable to write ' filenm]))
        end
      end
    end
    %if(dsbool(ds,'conf','checksaves'))
      movefile(filenm,ofil,'f');
    %end
%    delete(filenm);
%  else
%    cmd=[];
%  end
end
function res=checksave(fname,vars)
  res=true;
  try
    eval(['load(''' fname ''',' vars ');']);
    disp(['checked save of ' fname]);
  catch ex
    dsstacktrace(ex);
    res=false;
  end
  eval(['clear(' vars ');']);
end