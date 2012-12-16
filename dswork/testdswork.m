% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% A few sanity checks to use when developing dswork.
global ds;
if(~exist('currtest','var'))
  currtest=0;
end
if(currtest<1)
  dssetout('/lustre/cdoersch/testdswork');
  if(~dsmapredisopen())
    dsmapredopen(2,1,1)
  end
  {'ds.a','5'};dsup;
  dssave;
  b=dsload('ds.a');
  if(ds.a~=b)
    throw(MException('dswork:failtest','save and load failed'));
  end
  currtest=1;
end
if(currtest<2)
  dsdelete('ds.*');
  if(isfield(ds,'a'))
    throw(MException('dswork:failtest','delete did not remove variable'));
  end
  if(~exist([ds.sys.outdir '/ds/sys'],'dir'))
    throw(MException('dswork:failtest','delete removed the sys directory'));
  end
  currtest=2;
end
if(currtest<3)
  ds.somepath.mapvar=[1 2 3 4];
  dscd('ds.somepath');
  dsmapreduce('ds.redvar{dsidx}=ds.mapvar(dsidx)+1;',{'ds.mapvar'},{'ds.redvar'});
  dscd('.ds');
  if(~all(cell2mat(ds.somepath.redvar)==(ds.somepath.mapvar+1)))
    throw(MException('dswork:failtest','dsmapreduce results incorrect'));
  end
end
dsmapredclose;
disp('finished testing');
