% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Generate the ds.bestbin structure used by dispres_discpatch,
% or append additional patches to an existing one.
% detsimple is a list of detections to include in the display.
% batchidx is just an identifier of the batch number, used to
% separate different batches in the final display.  npatchesper
% is an upper bound on the number of patches included for each
% detector.  ranks specifies the ranks of the detections displayed.
function preppatchwisebestbin(detsimple,batchidx,npatchesper,ranks)
try
  global ds;
  if(~exist('npatchesper','var'))
    npatchesper=5;
  end
  if(~dsfield(ds,'bestbin','alldisclabelcat'))
    ds.bestbin.alldisclabelcat=[];
    ds.bestbin.alldiscpatchimg=[];
    ds.bestbin.decision=[];
    if(exist('ranks','var'))
      ds.bestbin.rank=[];
    end
    %ds.bestbin.iscorrect=[];
    ds.bestbin.group=[];
  end
  detsimple([detsimple.detector]==0)=[];
  detectors=unique([detsimple.detector]);
  alldetectors=[detsimple.detector];
  alldecisions=[detsimple.decision];
  tokeep=zeros(size(alldetectors));
  saveranks=zeros(size(detsimple));
  for(i=detectors(:)')
    inds=find(alldetectors==i);
    [~,inds2]=maxk(alldecisions(inds),npatchesper);
    tokeep(inds(inds2))=1;
    if(exist('ranks','var'))
      saveranks(inds(inds2))=ranks(1:numel(inds2));
    end
  end
  detsimple=detsimple(tokeep==1);
  if(exist('ranks','var'))
    saveranks=saveranks(tokeep==1);
    saveranks=saveranks(:);
  end
  {'ds.bestbin.alldisclabelcat','[ds.bestbin.alldisclabelcat;[[detsimple.imidx]'',[detsimple.detector]'']]'};dsup;
  ds.bestbin.alldiscpatchimg=[ds.bestbin.alldiscpatchimg [extractpatches(detsimple,ds.imgs{ds.conf.currimset},struct('noresize',true))]];
  {'ds.bestbin.decision','[ds.bestbin.decision;[detsimple.decision]'']'};dsup;
  if(exist('ranks','var'))
    {'ds.bestbin.rank','[ds.bestbin.rank;saveranks]'};dsup;
  end
  {'ds.bestbin.group','[ds.bestbin.group;repmat(batchidx,numel(detsimple),1)]'};dsup;
  ds.bestbin.imgs=ds.imgs{ds.conf.currimset};
  if(isfield(ds.bestbin,'iscorrect'))
    ds.bestbin.iscorrect=[ds.bestbin.iscorrect;ds.ispos([detsimple.imidx])'];%ismember({ds.bestbin.imgs([detsimple.imidx]').city},ds.mycity)'];
  end
  [ds.bestbin.tosave, ord]=unique(ds.bestbin.alldisclabelcat(:,2),'first');
  [~,ord]=sort(ord,'ascend');
  {'ds.bestbin.tosave','ds.bestbin.tosave(ord)'};dsup;
  {'ds.bestbin.isgeneral','ones(1,numel(ds.bestbin.tosave))'};dsup;
catch ex
  dsprinterr;
end
end
