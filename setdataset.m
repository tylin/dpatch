% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% A utility function which allows you to specify your own
% dataset.  Its use is explained in 3.2 of the README.
%
% weburl is only used in displays; it can be set to the
% empty string and the code will still function.

function setdataset(imgs, datadir, weburl)
  global ds;
  if(~dsfield(ds,'imgs'))
    ds.imgs={};
  end
  pos=numel(ds.imgs)+1;
  ds.imgs{pos}=imgs;
  ds.conf.gbz{pos}=struct('cutoutdir',datadir,'imgsurl',weburl);
  {'ds.conf.currimset','pos'};dsup;
end
