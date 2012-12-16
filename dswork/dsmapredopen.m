% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Open a mapreduce session.  njobs is the number of separate
% workers.  If supported, nprocs is the number of cores to be
% requested for each worker.  submitlocal is a flag that, if
% set to 1, means that the jobs will be started on the local
% machine.  If 0 or omitted, the jobs will be run in parallel.
%
% You may need to rewrite this function to work on your cluster.
% The assumptions are (1) that ds.sys.outdir will point to a directory
% accessible to both the main thread and the distributed worker
% threads, (2) that filesystem should support sequential, close-to-open,
% or an equivalently strong consistency model, (3) that it supports
% fifo's, and (4) that it supports bash.  If these requirements are met, 
% this function should submit scripts to be run on the worker nodes.
%
function dsmapredopen(njobs,nprocs,submitlocal)
  %general setup; should not need to be modified.
  if(nargin<3)
    submitlocal=0;
  end
  global ds;
  sysdir=[ds.sys.outdir 'ds/sys/'];
  mymkdir(sysdir);
  distprocdir=[ds.sys.outdir 'ds/sys/distproc/'];
  mymkdir(distprocdir);
  unix(['rm ' distprocdir '*']);
  ds.sys.distproc=struct();
  ds.sys.distproc.nmapreducers=njobs;
  ds.sys.distproc.hostname=num2cell(char(ones(njobs,1,'uint8').*uint8('?')))';
  ds.sys.distproc.commlinkmaster=cell(njobs,1);
  ds.sys.distproc.commlinkslave=cell(njobs,1);
  ds.sys.distproc.progresslink=cell(njobs,1);
  ds.sys.distproc.allslaves=[];
  ds.sys.distproc.possibleslaves=1:njobs;
  ds.sys.distproc.commfailures=zeros(ds.sys.distproc.nmapreducers,1);
  ds.sys.distproc.notresponding=[];
  dsworkpath=mfilename('fullpath');
  dotpos=find(dsworkpath=='/');
  dsworkpath=dsworkpath(1:(dotpos(end)-1));

  for(i=1:njobs)
    ds.sys.distproc.commlinkmaster{i}=[distprocdir 'master' num2str(i) '.mat'];
    ds.sys.distproc.commlinkslave{i}=[distprocdir 'slave' num2str(i) '.mat'];
    ds.sys.distproc.progresslink{i}=[distprocdir 'progress' num2str(i)];
    ds.sys.distproc.commlinkinterrupt{i}=[distprocdir 'interrupt' num2str(i) '.mat'];
  end
  dssave();
  for(i=1:njobs)
     %generate the script.
     disp(['submitting job ' num2str(i)]);
     tmpOutFName = [distprocdir 'qsubfile' num2str(i) '.sh'];
     fid = fopen(tmpOutFName, 'w');
     logfile=[distprocdir 'output' num2str(i) '.log'];
     logfileerr=[distprocdir 'stderr' num2str(i) '.log'];
     logfileout=[distprocdir 'stdout' num2str(i) '.log'];
     %keyboard;
     if(submitlocal)
       matlabbin='nice -n 15 matlab';
     else
       %this should point to the matlab binary accessible on worker nodes.
       matlabbin='/opt/matlab/amd64_f7/7.10/lib/matlab7/bin/matlab';
     end
     %the actual command run in matlab once everything is set up.
     matlabcmd=['dsdistprocid=' num2str(i) ';addpath(''' dsworkpath ''');dsoutdir=''' ds.sys.outdir ''';dsmapreducer']
     mlpipe=[distprocdir '/mlpipe' num2str(i)];
     fprintf(fid, '%s\n',['#!/bin/bash'] );
     fprintf(fid, '%s\n',['cd "' pwd '";'] );
     fprintf(fid, '%s\n',['if [[ ! -p ' mlpipe ' ]]; then']);
     fprintf(fid, '%s\n',['    mkfifo ' mlpipe]);
     fprintf(fid, '%s\n',['fi']);
     % on each worker, matlab is run with the fifo (mlpipe) as the STDIN that it reads commands from.  It sends output to
     % logfile.  In the background, there is a process (dskeeprunning.sh) that watches logfile and waits until a command
     % prompt appears along with the standard message "Operation terminated by user during ..." (which should only happen 
     % if the worker receives an interrupt signal--note that there is no way to catch such interrupts in matlab).  When 
     % it sees the prompt, it will send the dsmapreducer command into the fifo to restart the worker.
     fprintf(fid, '%s\n',['   ( tail -f ' mlpipe ' &  echo $! >&3 ) 3>' distprocdir 'pid' num2str(i) ' | ' matlabbin ' -nodesktop -nosplash -nojvm 2>&1 3>' distprocdir 'matpid' num2str(i) ' | ' dsworkpath '/dskeeprunning.sh "' mlpipe '" "' matlabcmd '" > "' logfile '"' ]);
     %fprintf(fid, '%s\n',['   ( tail -f ' mlpipe ' &  echo $! >&3 ) 3>' distprocdir 'pid' num2str(i) ' | ' matlabbin ' -nodesktop -nosplash -nojvm -singleCompThread 2>&1 3>' distprocdir 'matpid' num2str(i) ' | ' dsworkpath '/dskeeprunning.sh "' mlpipe '"
     fprintf(fid, '%s\n','kill $(<pid)');
     fprintf(fid, '%s\n',['rm ' mlpipe]);

     fclose(fid);
     unix(['chmod 755 ' tmpOutFName]);
     % actually submit the jobs.  tmoOutFName is the actual script that needs to be run on each node.  In my case,
     % warp.hpc1.cs.cmu.edu was the root node of the cluster, which handled handled queueing for the cluster via
     % torque.
     if(submitlocal)
       unix(['sleep ' num2str(floor(i/2)) ' && ' tmpOutFName ' &']);
     else
       logstring = ['-e "' logfileerr '" -o "' logfileout '"']; 
       qsub_cmd=['/opt/torque/bin/qsub -N dsmapreducer' num2str(i) ' -l nodes=1:ppn=' num2str(nprocs) ' ' logstring ' ' tmpOutFName]
       ssh_cmd = sprintf(['ssh warp.hpc1.cs.cmu.edu ''%s'''], qsub_cmd)
       unix(ssh_cmd);
     end
  end
  ds.sys.distproc.isopen=1;
end
