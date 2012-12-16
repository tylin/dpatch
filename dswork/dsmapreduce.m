% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% run a matlab command in parallel.  The name is a misnomer; it is not a full
% mapreduce implementation, but instead simply maps jobs to processors and
% collects the results back on disk, to be read by the main thread.
%
% mapvars specifies variables within dswork whose data should be mapped to
% workers.  reducevars specifies data that will get reduced back from
% each worker.  Each variable specified as a map variable must contain the
% same number of elements n, and the code specified in command will be
% then run n times.  There are no restrictions on what this code can be;
% the workers are independent matlab processes that do not share workspaces
% with the main thread.  The only sharing that happens with the main thread
% happens through disk, and is automated by the dswork abstraction.  When
% a worker begins working on a job, its workspace will contain two things:
% 
%   - dsidx: a variable specifying which of then indexes in the mapvars the
%            worker should work on.  By default it is just a single number.
%
%   - ds: a clone of the ds struct from the main thread, pointing to the
%         same working directory as the main thread.  
%
% The ds has a copy of the savestate from the main workspace--thus, it knows
% what variables are on disk and their types, and so dsload should allow you
% to load anything that's in the ds of the main workspace.  Some things are
% loaded automatically:
%
%    - ds.conf and all subfields.  Note that this path is relative.
%
%    - all variables specified in mapvars; if any variable specified in mapvars
%      is a cell array, these variables are only loaded for the index(es) specified
%      in dsidx; for ordinary arrays, the entire array is loaded.
%
% Only the mapvars are cleared from memory between each execution 
% of command; other variables stay in memory until the end of the entire 
% dsmapreduce function call.
%
% Finally, reducevars are "reduced"--i.e. their creation is mirrored in the main workspace
% after dsmapreduce returns.  At the end of the execution of the command on the worker,
% the worker node checks each index(es) specified by dsidx for each variable specified in
% reducevars, and all those that are nonempty are loaded in the main workspace.
%
% In all other respects, the ds variable will behave like an ordinary ds variable:
% any variables added will be saved to disk if and only if you call dssave on them.
% The main thread will not be notified of these changes unless you call dsloadsavestate
% in the main thread.
%
% command: a command to be run.
%
% mapvars: a cell array where each cell is the absolute or relative path
%          to a variable.  This variable can be either a cell array or an
%          ordinary array.  command will be run once for every element of
%          these arrays (so the arrays) must all have the same length.
%
% reducevars: a cell array where each cell is the absolute or relative path
%             to a variable.  After each distributed job exits, dsmapreduce
%             will attempt to load all variables specified here, and do so
%             while other jobs run (which is why you may notice lagging in
%             the dsmapreduce outputs).  The variables specified are expected
%             to be created during execution, and they must have the type
%             cell array.
%
%             Prior to starting, dsmapreduce also checks each of the
%             cells in the reducevars, and if any are nonempty for a given
%             index, no job is run for that index.  This means that dsmapreduce
%             can be interrupted and it will pick up where it left off.
%
% conf: a struct specifying additional configuration information.  Possible
%       fields can include:
%
%       noloadresults: do not load results in the main thread as they are 
%                      created (note that the internal savestate in the
%                      main thread will still be updated)
%
%       allatonce: if not present or set to 0, dsmapreduce will only assign
%                  a subset of jobs to workers at any given time, and dsidx
%                  will be a single number for each execution of command.  This
%                  allows dsmapreduce to dynamically balance the load--workers that
%                  finish jobs faster will be assigned more work.  setting allatonce=1
%                  means that all jobs are allocated simultaneously (each processor gets
%                  ceil(#jobs/#workers).  Each worker will execute the command exactly once,
%                  and dsidx will be an array containing every index assigned to that
%                  node.  Assignment is sequential; i.e. each node gets all of the jobs
%                  between some lower bound and some upper bound.
% 
% dsmapreduce displays progress during the execution: it displays the currently executing
% command followed by numbers formatted like x+y/z, where x is the number of complete jobs,
% y is the number of jobs that have been assigned but are not complete, and z is the total
% number of jobs to be assigned.  Finally, "working procs" is a list of workers that have
% jobs assigned to them.
%
% dsmapreduce makes some attempt at fault tolerance.  If a worker thread throws an exception,
% the exception will be reported in the main thread, and the job will be reassigned to a
% different worker.  Workers will be blacklisted if a job is assigned to them but they go for
% a very long time without accepting the job.  There is currently no mechanism to detect
% when a worker dies during the execution of a command.  
%
% Logfiles for each worker are stored in [ds.sys.outdir '/sys/distproc/output*.log'].  
%
function dsmapreduce(command,mapvars,reducevars,conf)
  try
  global ds;
  dssave();
  loadresults=true;
  allatonce=false;
  if(nargin>3)
    if(isfield(conf,'noloadresults'))
      loadresults=~(conf.noloadresults);
    end
    if(isfield(conf,'allatonce'))
      allatonce=(conf.allatonce==1);
    end
  end
  %for(i=1:numel(reducevars))
  %  dsloadsavestate(reducevars{i});
  %end
  mapvars2={};
  reducevars2={};
  for(i=1:numel(mapvars))
    mapvars2=[mapvars2;dsexpandpath(mapvars{i})];
  end
  for(i=1:numel(reducevars))
    %note: reducevars2 generally won't contain the full set of reduce variables,
    %since many of them may not have been created in dswork yet.  Currently
    %olny used for checkign completeness.
    reducevars2=[reducevars2;dsexpandpath(reducevars{i})];
  end
  for(i=1:numel(mapvars2))
    brakopen=find(mapvars2{i}=='{');
    brakclose=find(mapvars2{i}=='}');
    if(numel(brakopen)>0&&numel(brakclose)>0)
      mapvars2{i}(brakopen(1))='(';
      mapvars2{i}(brakclose(numel(brakclose)))=')';
    end
  end
  for(i=1:numel(reducevars2))
    brakopen=find(reducevars2{i}=='{');
    brakclose=find(reducevars2{i}=='}');
    if(numel(brakopen)>0&&numel(brakclose)>0)
      reducevars2{i}(brakopen(1))='(';
      reducevars2{i}(brakclose(numel(brakclose)))=')';
    end
  end
  %njobs=eval(['numel(ds.' mapvars2{1} ')'])
  cmd.savestate=ds.sys.savestate;
  cmd.currpath=ds.sys.currpath;
  cmd.matlabpath=path;
  save([ds.sys.outdir 'ds/sys/distproc/savestate.mat'],'cmd');


  maxsz=1;
  for(i=1:numel(mapvars2))
    ap=dsabspath(mapvars2{i});
    sz=0;
    if(dsfield(['ds.sys.savestate' ap(4:end)])&&eval(['iscell(ds.sys.savestate' ap(4:end) ')']))
      sz=eval(['numel(ds.sys.savestate' ap(4:end)  '{2})']);
    else
      sz=eval(['numel(' dsfindvar(mapvars2{i}) ')']);
    end
    if(maxsz==1)
      maxsz=sz;
      varwithmaxsz=mapvars2{i};
    else
      if(sz~=1&&sz~=maxsz)
        throw(MException('dsmapreduce:arglength',['dsmapreduce args ' mapvars{i} ' and ' varwithmaxsz...
                         ' are not the same length.']));
      end
    end
  end
%  toks=regexp(reducevars2{1},'\.','split');
%  toks=toks(2:end);

%  complete=eval(['ds.savestate.' reducevars2{1} '{2}']);
  complete=zeros(maxsz,1);
  %anycomplete=0;
  for(i=1:numel(reducevars2))
    nm=dsabspath(reducevars2{i});
    disp(['checking savestate' nm(4:end) ]);
    if(dsfield(ds,['sys.savestate' nm(4:end)]))
      compfull=zeros(size(complete));
      comptmp=eval(['ds.sys.savestate' nm(4:end) '{2}']);
      if(~any(size(comptmp)==1))
        comptmp=(sum(comptmp,1)>0);
      end
      compfull(1:numel(comptmp))=comptmp;
      %try
      complete=complete + compfull;
      %catch,keyboard;end
      %anycomplete=1;
    end
  end
  complete=(complete>0);%anycomplete.*complete;
  if(any(complete))
    disp(['found ' num2str(sum(complete)) ' jobs already finished']);
  end
  %clean up anything from last time, load new procs
  ds.sys.distproc.jobsinq=1:maxsz;
  ds.sys.distproc.jobsinq(find(complete))=[];
  ds.sys.distproc.jobsproc=zeros(2,0);
  ds.sys.distproc.donotassociate=zeros(2,0);
%  availslaves=1:ds.sys.distproc.nmapreducers;
  %if(~dsfield(ds,'distproc','idlemapreducers'))
  %  ds.sys.distproc.idlemapreducers=zeros(size(availslaves));
  %end
  %if(~dsfield(ds,'distproc','commfailures'))
  %  ds.sys.distproc.commfailures=zeros(ds.sys.distproc.nmapreducers,1);
  %  ds.sys.distproc.notresponding=[];
  %end
  if(~dsmapredisopen())
    jobsbyround=ds.sys.distproc.jobsinq;
    if(allatonce)
      jobsbyround=jobsbyround';
    end
    ct=0;
    for(i=jobsbyround)
      fwascleared=false(max(i),numel(mapvars2));
      for(j=1:numel(mapvars2))
        sz=eval(['numel(' dsfindvar(mapvars2{j}) ')']);
        for(thisi=i(:)')
          if(thisi>sz&&eval(['iscell(' dsfindvar(mapvars2{j}) ')']) && isempty(eval([dsfindvar(mapvars2{j}) '{' num2str(thisi) '}'])))
            fwascleared(thisi,j)=true;
            dsload([mapvars2{j} '{' num2str(thisi) '}']);
          end
        end
      end
      dsmapredrun(command,i);
      dssave;
      for(j=1:numel(mapvars2))
        for(thisi=i(:)')
          if(fwascleared(thisi,j))
            dsclear([mapvars2{j} '{' num2str(thisi) '}']);
          end
        end
      end
      if(~loadresults)
        for(j=1:numel(reducevars2))
          dsclear([reducevars2{j} '{' num2str(i(:)') '}']);
        end
      end
      ct=ct+1;
      disp([command ': ' num2str(ct) '/' num2str(numel(jobsbyround))]);
    end
    return;
  end

  ds.sys.distproc.availslaves=setdiff(ds.sys.distproc.allslaves,ds.sys.distproc.notresponding);
  ds.sys.distproc.idleprocs=ds.sys.distproc.availslaves;
  ds.sys.distproc.nextfile=ones(1,numel(ds.sys.distproc.commlinkslave));
  warning off all;
  for(i=1:ds.sys.distproc.nmapreducers)
    readslave(i,false,reducevars2,loadresults); %to pick up newly started mapreducers
    delete([ds.sys.distproc.progresslink{i} '_*']);
  end
  warning on all;
  ds.sys.distproc.availslaves=setdiff(ds.sys.distproc.allslaves,ds.sys.distproc.notresponding);
    toread=ds.sys.distproc.availslaves;
    toread2=[];
    for(k=[1 5 3 7 2 6 4 8])
      toread2=[toread2 toread(k:8:end)];
    end
  ds.sys.distproc.idleprocs=toread2;
  ds.sys.distproc.hcrashct=zeros(ds.sys.distproc.nmapreducers,1);
  ds.sys.distproc.hdead=ds.sys.distproc.notresponding;
  ds.sys.distproc.jcrashct=zeros(max(ds.sys.distproc.jobsinq),1);
  ds.sys.distproc.jdead=[];
  ds.sys.distproc.loadqueue=[];
  ds.sys.distproc.loaddone=[];
  ds.sys.distproc.uniqueredvars={};
  ds.sys.distproc.nloads=zeros(size(reducevars2));
  ds.sys.distproc.totalloadtime=zeros(size(reducevars2));
  ds.sys.distproc.jobprogress=complete;
  ds.sys.distproc.redsize=maxsz;
  ds.sys.distproc.assignmentlog=[];
  nextjob=1;


  %for(i=ds.sys.distproc.idleprocs(:)')
  %  cmd=struct();
  %  cmd.name='clear';
  %  save(ds.sys.distproc.commlinkslave{i},'cmd');
  %end
  %disp('waiting for mapreducers to clear...');
  %exited=zeros(numel(ds.sys.distproc.commlinkmaster),1);
  %while(~all(exited))
  %  for(i=1:numel(ds.sys.distproc.commlinkslave))
  %    res=dstryload(ds.sys.distproc.commlinkmaster{i});
  %    if((~isempty(res))&&strcmp(res.name,'cleared'))
  %      exited(i)=1;
  %    end
  %  end
  %  if(~all(exited))
  %    pause(2);
  %    disp([num2str(numel(exited)-sum(exited)) ' still need to clear...']);
  %  end
  %end

  runthisround=[];;
  while((numel(ds.sys.distproc.jobsinq)+size(ds.sys.distproc.jobsproc,2))>0)
    sjp=sum(ds.sys.distproc.jobprogress);
    disp([command ': ' num2str(sjp)...
          '+' num2str(maxsz-numel(ds.sys.distproc.jobsinq)-sjp) '/' num2str(maxsz)]);
    wait=1;
    if(allatonce)
      jobsthisround=ceil(numel(ds.sys.distproc.jobsinq)/(numel(ds.sys.distproc.possibleslaves)-numel(ds.sys.distproc.hdead)));
    else
      jobsthisround=ceil(numel(ds.sys.distproc.jobsinq)/(2*(numel(ds.sys.distproc.possibleslaves)-numel(ds.sys.distproc.hdead))));
    end
    if(isnan(jobsthisround))
      disp('all mapreducers are dead')
      return;
    end
    toread=setdiff(ds.sys.distproc.possibleslaves,ds.sys.distproc.notresponding);
    toread2=[];
    for(k=[1 5 3 7 2 6 4 8])
      toread2=[toread2 toread(k:8:end)];
    end
    for(i=toread2(:)')
      readslave(i,1,reducevars2,loadresults);
    end
    allocated=zeros(size(ds.sys.distproc.idleprocs));
    idleprocsidx=1;
    %'idleprocs'
    %ds.sys.distproc.idleprocs
    workingprocs=setdiff(setdiff(ds.sys.distproc.availslaves,ds.sys.distproc.idleprocs),ds.sys.distproc.hdead);
    disp(['working procs: ' num2str(workingprocs(:)')]);
    disp([num2str(numel(ds.sys.distproc.idleprocs)) ' idle.']);
    for(i=ds.sys.distproc.idleprocs(:)')
      if(numel(ds.sys.distproc.jobsinq)>0)
        cmd=struct();
        cmd.name='run';
        cmd.cmd=command;
        badids=ds.sys.distproc.donotassociate(1,find(ds.sys.distproc.donotassociate(2,:)==i));
%        avail=ds.sys.distproc.jobsinq(
        availjiqidx=find(~ismember(ds.sys.distproc.jobsinq,sort(badids)));
        availjiqidx=availjiqidx(1:min(numel(availjiqidx),jobsthisround));
        cmd.inds=ds.sys.distproc.jobsinq(availjiqidx);
        ds.sys.distproc.jobsinq(availjiqidx)=[];
        cmd.mapredin=mapvars;
        cmd.mapredout=reducevars;
        cmd.allatonce=allatonce;
        if(~ismember(i,runthisround))
          cmd.clearslaves=true;
          runthisround=[runthisround,i];
        else
          cmd.clearslaves=false;
        end
        save(ds.sys.distproc.commlinkslave{i},'cmd');
        ds.sys.distproc.jobsproc=[ds.sys.distproc.jobsproc [cmd.inds(:)'; ones(1,numel(cmd.inds))*i]];
        ds.sys.distproc.assignmentlog=[ds.sys.distproc.assignmentlog [cmd.inds(:)'; ones(1,numel(cmd.inds))*i]];
        allocated(idleprocsidx)=1;
      end
      idleprocsidx=idleprocsidx+1;
    end
    ds.sys.distproc.idleprocs(allocated==1)=[];
    if((numel(ds.sys.distproc.jobsinq)+size(ds.sys.distproc.jobsproc,2))==0)
      wait=0;
    end
    if(wait)
      loaduntiltimeout(3,reducevars);
    end
    clearslaves=false;
  end
  %for(i=1:numel(reducevars))
  %  disp(['var:' reducevars{i}]);
  %  disp('loading savestate');
  %  dsloadsavestate(reducevars{i});
  %  if(loadresults)
  %    disp('loading results');
  %    dsload(reducevars{i});
  %  end
  %end
  loaduntiltimeout(Inf,reducevars);
  %loaduntiltimeout(Inf,reducevars2);
  delete([ds.sys.outdir 'ds/sys/distproc/savestate.mat']);
  disp('dsmapreduce finished.');
  catch ex,dsprinterr;end
end
%end

function readslave(idx,isrunning,redvars,loadresults)
  global ds;
  if(exist(ds.sys.distproc.commlinkmaster{idx},'file'))
    iserror=0;
    %while(iserror>=0)
    %  if(iserror>0)
        %pause(1)
    %    return;
    %  end
      try
        load(ds.sys.distproc.commlinkmaster{idx});
        if(~exist('cmd','var'))
          iserror=iserror+1;
        else
          iserror=-1;
        end
      catch
        iserror=iserror+1;
        if(iserror==10)
          throw(MException('mapred:read',['Unable to read mapreducer communication in file ' ds.sys.distproc.commlinkmaster{idx}]));
        end
      end
    %end
    if(iserror==-1)
      delete(ds.sys.distproc.commlinkmaster{idx});
      if(strcmp(cmd.name,'started'))
        %if(~ismember(idx,ds.sys.distproc.idleprocs))
        %  ds.sys.distproc.idleprocs=[ds.sys.distproc.idleprocs idx];
        %end
        %if(~ismember(idx,ds.sys.distproc.idleprocs))
        %  ds.sys.distproc.availprocs=[ds.sys.distproc.availprocs idx];
        %end
        ds.sys.distproc.allslaves=[ds.sys.distproc.allslaves idx];
        ds.sys.distproc.idleprocs=[ds.sys.distproc.idleprocs idx];
        ds.sys.distproc.availslaves=[ds.sys.distproc.availslaves idx];
        ds.sys.distproc.hostname{idx}=cmd.host;
      elseif(strcmp(cmd.name,'done'))
        ds.sys.distproc.idleprocs=[ds.sys.distproc.idleprocs idx];
          if(isrunning&&numel(ds.sys.distproc.idleprocs)>numel(ds.sys.distproc.availslaves))
            disp('too many idle procs');
            keyboard;
          end
        ds.sys.distproc.jobsproc(:,ismember(ds.sys.distproc.jobsproc(1,:),cmd.completed))=[];
        if(isrunning)
          handlewritten(cmd.savedthisround,cmd.completed,loadresults);
        end
      elseif(strcmp(cmd.name,'cleared'))
      elseif(strcmp(cmd.name,'exited'))
        ds.sys.distproc.availslaves(ds.sys.distproc.availslaves==idx)=[];
      elseif(strcmp(cmd.name,'error'))
        disp(['job no. ' num2str(cmd.errind) ' crashed on mapreducer ' num2str(idx) ', host ' ds.sys.distproc.hostname{idx}]);
        ds.sys.distproc.hcrashct(idx)=ds.sys.distproc.hcrashct(idx)+1;
        if(ds.sys.distproc.hcrashct(idx)>=3)
          ds.sys.distproc.hdead=unique([ds.sys.distproc.hdead; idx]);
          disp(['mapreducer '  num2str(idx) ' has crashed twice in this mapreduce round. It will be disabled for the remainder of the round.']);
        else
          ds.sys.distproc.idleprocs=[ds.sys.distproc.idleprocs idx];
          if(isrunning&&numel(ds.sys.distproc.idleprocs)>numel(ds.sys.distproc.availslaves))
            disp('too many idle procs');
            keyboard;
          end
        end
        dsstacktrace(cmd.err,1);
        mycompjobs=ismember(ds.sys.distproc.jobsproc(1,:),cmd.completed);
        ds.sys.distproc.jobsproc(:,mycompjobs)=[];
        myincompjobs=ismember(ds.sys.distproc.jobsproc(2,:),idx);
        ds.sys.distproc.donotassociate=[ds.sys.distproc.donotassociate ds.sys.distproc.jobsproc(:,myincompjobs)];
        ds.sys.distproc.jobsinq=[ds.sys.distproc.jobsproc(1,myincompjobs) ds.sys.distproc.jobsinq];
        ds.sys.distproc.jobsproc(:,myincompjobs)=[];
        if(isrunning)
          handlewritten(cmd.savedthisround,cmd.completed,loadresults);
        end
      end
      %if(~isrunning)
        %if(exist(ds.sys.distproc.progresslink{idx}))
        %end
      %end
    end
  end
  if(isrunning)
    cmd=struct();
    while((~isempty(cmd))&&exist([ds.sys.distproc.progresslink{idx} '_' num2str(ds.sys.distproc.nextfile(idx)) '.mat'],'file'))
      cmd=dstryload([ds.sys.distproc.progresslink{idx} '_' num2str(ds.sys.distproc.nextfile(idx)) '.mat'],struct('nowait',true));
      if(isrunning&&~isempty(cmd))
        handlewritten(cmd.savedthisround,cmd.completed,loadresults);
        ds.sys.distproc.nextfile(idx)=ds.sys.distproc.nextfile(idx)+1;
      end
    end
  end
  if(exist(ds.sys.distproc.commlinkslave{idx},'file'))
    ds.sys.distproc.commfailures(idx)=ds.sys.distproc.commfailures(idx)+1;
    if(ds.sys.distproc.commfailures(idx)>50)
      disp(['mapreducer ' num2str(idx) ', host ' ds.sys.distproc.hostname{idx} ' has stopped responding.  Sending it an exit signal'])
      ds.sys.distproc.notresponding=unique([ds.sys.distproc.notresponding; idx]);
      ds.sys.distproc.availslaves(ds.sys.distproc.availslaves==idx)=[];
      cmd.name='exit';
      dstrysave(ds.sys.distproc.commlinkslave{idx},cmd);
      
      myincompjobs=ismember(ds.sys.distproc.jobsproc(2,:),idx);
      ds.sys.distproc.jobsinq=[ds.sys.distproc.jobsproc(1,myincompjobs) ds.sys.distproc.jobsinq];
      ds.sys.distproc.jobsproc(:,myincompjobs)=[];
    end
  else
    ds.sys.distproc.commfailures(idx)=0;
  end
end

function handlewritten(saved,completed,loadresults)
  try
  global ds;
  ds.sys.distproc.jobprogress(completed)=1;
  for(i=1:size(saved,1))
    sv.var=saved{i,1};
    sv.inds=saved{i,2};
    sv.jid=saved{i,3};
    nm=dsabspath(saved{i,1});
    %for(j=1:numel(saved{i}))
    svnm=['ds.sys.savestate' nm(4:end)];
    if((~isstruct(sv.inds))&&(~iscell(sv.inds)))
      if((~isempty(sv.inds)))
        %for(j=1:size(sv.inds,1))
          %indstr=num2str(sv.inds(j,1));
         
        if(size(sv.inds,2)~=2)
          sv.inds=[ones(size(sv.inds(:))) sv.inds(:)];
            %indstr=[indstr ',' num2str(sv.inds(j,2))];
          %else
            %indstr=['1,' indstr];
        end
        %end
        
        if(~dsfield(svnm)||eval(['numel(' svnm ')<2'])||eval(['~all(size(' svnm '{2})>=max(sv.inds,[],1))']))
          eval([svnm '{2}(max(sv.inds(:,1)),max(sv.inds(:,2)))=0;'])
        end
        indstr=sub2ind(eval(['size(' svnm '{2})']),sv.inds(:,1),sv.inds(:,2));
        indstr=['[' num2str(indstr(:)') ']'];
        if(eval(['any(' svnm '{2}(' indstr ')==1)']))
          disp('warning: mapreducer wrote a variable that''s already been loaded??');
        end
        %['ds.sys.savestate' nm(4:end) '{2}(' indstr ')=true;']
        %if(dsfield(['ds.sys.savestate' nm(4:end) '']));
        %  eval(['ds.sys.savestate' nm(4:end) '{2};']);
        %end
        %['ds.sys.savestate' nm(4:end) '{2}(' indstr ')=true;']
        %tic
        eval([svnm '{2}(' indstr ')=true;']);
        %toc
        eval([svnm '{1}=1;']);
        %eval(['ds.sys.savestate' nm(4:end) '{2};']);
      else
        eval([svnm '=true;']);
      end
    end
    %locnm=dsfindvar(nm);
    %if(~dsfield(locnm)||(eval(['numel(' locnm ')'])<j))
    %  eval([locnm '{' num2str(ds.sys.distproc.redsize) '}=[];']);
    %end
    if(isstruct(sv.inds)||iscell(sv.inds))
      pth=dsfindvar(sv.var);
      if(~dsfield(pth))
        eval([pth '=sv.inds']);
      end
    elseif(loadresults)
      enqueue=struct('vars',{},'inds',{},'jid',{});;
      if(isempty(sv.inds))
          enqueue(end+1)=struct('vars',sv.var,'inds',[],'jid',sv.jid);
      else
        for(j=1:size(sv.inds,1))
          enqueue(end+1)=struct('vars',sv.var,'inds',sv.inds(j,:),'jid',sv.jid);
        end
      end
      ds.sys.distproc.loadqueue=[ds.sys.distproc.loadqueue;enqueue(:)];
    end
    %end
  end
  catch ex,dsprinterr;end
end

function loaduntiltimeout(timeout,redvars)
  global ds;
  try
  a=tic;
  firstit=1;
  while(numel(ds.sys.distproc.loadqueue)>0)
    lq=ds.sys.distproc.loadqueue;
    loadvar=lq(1).vars;
    idx=lq(1).inds;
    jid=lq(1).jid;
    [~,varidx]=ismember({loadvar},ds.sys.distproc.uniqueredvars);
    if(varidx==0)
      varidx=numel(ds.sys.distproc.uniqueredvars)+1;
      ds.sys.distproc.uniqueredvars{varidx}=loadvar;
      ds.sys.distproc.nloads(varidx)=0;
      ds.sys.distproc.totalloadtime(varidx)=0;
    end
    timespent=toc(a);
    if(~firstit&&(~isinf(timeout))&&((ds.sys.distproc.nloads(varidx)==0)||(ds.sys.distproc.totalloadtime(varidx)/ds.sys.distproc.nloads(varidx)+timespent>timeout)))
      break;
    end
    b=tic;
    firstit=0;
    varnm=dsabspath(loadvar);
    %disp(['dsload(''' varnm '{' num2str(idx) '}'')']);
    clear lq;
    loadstr=getvarstr(varnm,idx);
    sucval=false;
    try
      dsload(loadstr);
      sucval=true;
    catch ex
      dsprinterr;
      disp(['read failed.  deleting ' num2str(jid) ' and resubmitting']);
      ds.sys.distproc.jobsprogress(jid)=0;
      lq=[ds.sys.distproc.loadqueue; ds.sys.distproc.loaddone];
      marks=false(size(lq));
      for(t=1:numel(lq))
        marks(t)=ismember(lq(t).jid,jid);
        if(marks(t))
          dsdelete(getvarstr(lq(t).vars,lq(t).inds));
        end
      end
      ds.sys.distproc.loaddone(marks((numel(ds.sys.distproc.loadqueue)+1):end))=[];
      ds.sys.distproc.loadqueue(marks(1:numel(ds.sys.distproc.loadqueue)))=[];
      ds.sys.distproc.jobsinq=[idx ds.sys.distproc.jobsinq];
    end
    if(sucval)
      ds.sys.distproc.nloads(varidx)=ds.sys.distproc.nloads(varidx)+1;
      ds.sys.distproc.totalloadtime(varidx)=ds.sys.distproc.totalloadtime(varidx)+toc(b);
      ds.sys.distproc.loaddone=[ds.sys.distproc.loaddone;ds.sys.distproc.loadqueue(1)];
      ds.sys.distproc.loadqueue(1)=[];
      lq=ds.sys.distproc.loadqueue;
      if(numel(lq)>0)
        pending = [];
      else
        pending=unique([lq.jid]);
      end
      ld=ds.sys.distproc.loaddone;
      marks=false(size(ld));
      for(t=1:numel(ld))
        marks(t)=(~any(ismember(ld(t).jid,pending)));
      end
      %note: we're assuming that if a jid is in loaddone but isn't in the 
      %current loadqueue, it'll never show up there again.  This relies on
      %an underlying assumption that once a job is finished, everything that
      %job wrote will end up in the loadqueue all at once.  in practice, the
      %loadqueue should be organized by job, but meh, do that later.
      ds.sys.distproc.loaddone(marks)=[];
    end
  end
  timeremaining=timeout-toc(a);
  if(~isinf(timeremaining)&&timeremaining>0)
    pause(timeremaining);
  end
  catch ex,dsprinterr;end
end

function loadstr=getvarstr(varnm,idx)
    if(numel(idx)==0)
      loadstr=[varnm];
    elseif(numel(idx)==1)
      loadstr=[varnm '{' num2str(idx) '}'];
    else
      loadstr=[varnm '{' num2str(idx(1)) '}{' num2str(idx(2)) '}'];
    end
end
