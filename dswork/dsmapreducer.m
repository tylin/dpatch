% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% The 'daemon' that runs on each distributed worker.
if(~exist('ds','var'))
%we are a new dsmapreducer
  global ds;
  disp('starting');
  dssetout(dsoutdir);
  dsload('ds.conf.*');
  ds.sys.distproc.mapreducer=1;
  commlinkout=[dsoutdir 'ds/sys/distproc/master' num2str(dsdistprocid) '.mat']
  progresslink=[dsoutdir 'ds/sys/distproc/progress' num2str(dsdistprocid)]
  commlinkin=[dsoutdir 'ds/sys/distproc/slave' num2str(dsdistprocid) '.mat']
  interruptcommlink=[dsoutdir 'ds/sys/distproc/interrupt' num2str(dsdistprocid) '.mat'];
  %interruptcommlink2=[dsoutdir 'distproc/interrupt2' num2str(dsdistprocid) '.mat'];
  dsworkpath=mfilename('fullpath');
  dotpos=find(dsworkpath=='/');
  dsworkpath=dsworkpath(1:(dotpos(end)-1));

  unix(['matlab -singleCompThread -nodesktop -nosplash -nojvm -r "addpath(''' dsworkpath ''');commlinkin=''' interruptcommlink ''';slavepid=' num2str(feature('getpid')) ';dsinterruptor;" &']);
  cmd.name='started';
  [~,cmd.host]=unix('hostname');
  disp(['running on ' cmd.host]);
  save(commlinkout,'cmd');
else
%we just restarted because we got an interrupt.
  disp('got interrupt');
  cmd=struct();
  cmd.name='interrupted';
  save(commlinkout,'cmd');
end
while(1)
  if(~exist(commlinkin,'file'))
    pause(5);
    continue;
  end
  try
    load(commlinkin);
  catch
    %probably tried to read a half-written file
    dsstacktrace(lasterror);
    pause(1);
    continue;
  end
  delete(commlinkin);
  mycmd=cmd
  cmd=struct();
  if(strcmp(mycmd.name,'exit'))
    disp('got exit signal')
    cmd.name='exit';
    save(interruptcommlink,'cmd');
    while(exist(interruptcommlink,'file'))
      disp('commlink still exists, waiting');
      pause(1);
    end
    disp('interruptor exited.  will now exit.');
    cmd.name='exited';
    save(commlinkout,'cmd');
    disp('dskeeprunning:cuetoexit');
    exit;
  elseif(strcmp(mycmd.name,'run'))
    mycmd
    cmd=[];
    completed=[];
    terminatedwitherror=0;
    if(mycmd.clearslaves)
      rehash;
      ds=[];
      dssetout(dsoutdir);
      conf=struct();
      conf.delete=false;
      scmd=dstryload([ds.sys.outdir 'ds/sys/distproc/savestate.mat'],conf);
      paths=scmd.matlabpath;
      upaths=regexp(paths,':','split');
      tic
      warning off all;
      pfx=which('pwd');
      dotpos=find(pfx=='/');
      pfx=pfx(1:dotpos(end-3));
      for(i=1:numel(upaths))
        if((~dshasprefix(upaths{i},pfx)))
          disp(['adding path ' upaths{i}])
          addpath(upaths{i});
        end
      end
      warning on all;
      toc;
      ds.sys.savestate=scmd.savestate;
      ds.sys.saved={};
      ds.sys.savedjid={};
      ds.sys.distproc.nextfile=1;
      %dsload('ds.conf.*');
      dscd(['.ds' scmd.currpath])
      dsload('ds.conf.*');
      clear scmd;
      
      ds.sys.distproc.mapreducer=1;
    %dsloadsavestate();
      conf=struct();
    end
    ds.sys.distproc.savedthisround=struct('vars',{},'inds',{});%cell(numel(mycmd.mapredout),1);
    %dsload('ds.conf.*');
    if(mycmd.allatonce)
      inds=mycmd.inds(:)';
      idxstr='';
      for(i=1:numel(inds))
        idxstr=[idxstr ' '  num2str(inds(i))];
      end
      try
      disp(['running jobs:' idxstr]);
        for(j=1:numel(mycmd.mapredin))
          dsload([mycmd.mapredin{j} '{' idxstr '}']);
        end
        dsmapredrun(mycmd.cmd,inds);
        dssave;
        completed=inds;
        dsfinishjob(mycmd.mapredout,inds,idxstr,progresslink,completed,1,mycmd.mapredin);
      catch ex
        disp(['ismapreducer:' num2str(ds.sys.distproc.mapreducer)]);
        ds_err=ex;
        dsstacktrace(ds_err);
        cmd.name='error';
        cmd.err=ds_err;
        cmd.errind=i;
        cmd.completed=completed;
        cmd.savedthisround=ds.sys.distproc.savedthisround;
        dstrysave(commlinkout,cmd);
        terminatedwitherror=1;
      end
      if(~terminatedwitherror)
        for(j=1:numel(mycmd.mapredout))
        %  ['dssave ' mycmd.mapredout{j} '{' idxstr '}']
        %  dssave([mycmd.mapredout{j} '{' idxstr '}']);
          %TODO: get rid of this stuff when there's an error, too
          allpaths=dsexpandpath(mycmd.mapredout{j});
          for(k=1:numel(allpaths))
            for(i=inds)
              eval([dsfindvar(allpaths{k}) '{' num2str(i) '}=[]']);
            end
          end
        end
      end
    else
      for(i=mycmd.inds(:)')
        try
          disp(['running job:' num2str(i)]);
          for(j=1:numel(mycmd.mapredin))
            dsload([mycmd.mapredin{j} '{' num2str(i) '}']);
          end
          dsmapredrun(mycmd.cmd,i);
          dssave;
          dsfinishjob(mycmd.mapredout,i,num2str(i),progresslink,[completed; i],i==mycmd.inds(end),mycmd.mapredin);
          completed=[completed;i];
        catch ex
          disp(['ismapreducer:' num2str(ds.sys.distproc.mapreducer)]);
          ds_err=ex;
          dsstacktrace(ds_err);
          cmd.name='error';
          cmd.err=ds_err;
          cmd.errind=i;
          cmd.completed=completed;
          cmd.savedthisround=ds.sys.distproc.savedthisround;
          dstrysave(commlinkout,cmd);
          terminatedwitherror=1;
          break;
        end
          for(j=1:numel(mycmd.mapredout))
          %  ['dssave ' mycmd.mapredout{j} '{' num2str(i) '}']
            dssave([mycmd.mapredout{j} '{' num2str(i) '}']);
            %TODO: get rid of this stuff when there's an error, too
            allpaths=dsexpandpath(mycmd.mapredout{j});
            for(k=1:numel(allpaths))
              eval([dsfindvar(allpaths{k}) '{' num2str(i) '}=[]']);
            end
          end
        %end
      end
    end
    if(~terminatedwitherror)
      cmd.name='done';
      cmd.completed=completed;
      cmd.savedthisround=ds.sys.distproc.savedthisround;
      dstrysave(commlinkout,cmd);
    end
  %elseif(strcmp(mycmd.name,'clear'))
  %  ds=[];
  %  rehash;
  %  dssetout(dsoutdir);
  %  dsload('ds.conf.*');
  %  ds.sys.distproc.mapreducer=1;
  %  cmd=struct();
  %  cmd.name='cleared';
  %  save(commlinkout,'cmd');
  %  ds.sys.distproc.mapreducer=1;
  end
end
