% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% 
% The core download and panorama extraction script.  Make sure that
% globalz(setno).downloaddir contains download.txt and mapping.txt,
% and that you can write to gbz.datasetname. 
%
% NOTE THAT CERTAIN USES OF THIS SCRIPT MAY VIOLATE THE GOOGLE STREET VIEW
% TERMS OF SERVICE! Chsck the terms of service online at 
% https://developers.google.com/maps/terms
% (10.1.3 is particularly relevant) and make sure you have permission from 
% Google for whatever you're doing!

myaddpath;

%set the number of parallel jobs
nparallel=8;

%set whether to attempt to distribute them across multiple machines.
isdistributed=0;
gbz=globalz(7);
  dname=gbz.downloaddir;
  dfname=[dname '/download.txt'];
  ctdir=gbz.cutoutdir;
  ctfiles=[dname '/mapping.txt'];
%end

global ds;
dssetout([dname]);


%if ~exist(path,'dir'), mkdir(path), end;
%opath = pwd;
%end
%files=dir(dfname);
ds.panoids={};
ds.panoids{1}={};
%for(i=1:numel(files))
  [s un used]=textread([dfname],'%s %s %s');
  ds.panoids{1}=[ds.panoids{1} s'];
%end
if(~dsmapredisopen())
  dsmapredopen(nparallel, 1, ~isdistributed);
end
ds.panonums=0:(numel(ds.panoids{1})-1);
%fid = fopen(dfname,'r');
dsmapreduce('myaddpath;dsload(''ds.panoids'');ds.panoimg{dsidx}=downloadpano(ds.panoids{1}{ds.panonums(dsidx)+1})',{'ds.panonums'},{'ds.panoimg'},struct('noloadresults',true));
%end
%files=dir(ctfiles);
dataline=cell(1,5);
lastmaxid=-1;
%for(i=1:numel(files))
  fid  = fopen(ctfiles);%[ctdir 'mapping' num2str(i-1) '.txt'  ]);
  scan = textscan(fid, '%f %f %f %s %s');
  scan{1}=scan{1}+lastmaxid+1;
  lastmaxid=max(scan{1});
  for(j=1:5)
    dataline{j}=[dataline{j};scan{j}];
  end
%end
{'ds.dataline','dataline'};dsup;
{'ds.conf.outpath','ctdir'};dsup;
dsmapreduce(['myaddpath;' ...
             'if(numel(ds.panoimg)<dsidx||isempty(ds.panoimg{dsidx})),' ...
                'ds.panoflag{dsidx}=1;return;'...
             'end,'...
             'dsload(''ds.panoids'');'...
             'ds.panoflag{dsidx}=panocutout(ds.panoimg{dsidx},ds.panonums(dsidx))']...
             ,{'ds.panonums','ds.panoimg'},{'ds.panoflag'},struct('noloadresults',true));
dsmapredclose;
setlabel;
return;
