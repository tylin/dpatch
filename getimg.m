% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Load an image at the position specified by idx.  Optionally,
% the first parameter can be the ds structure, avoiding
% a call to global.  
function res=getimg(ds,idx)
  if(nargin<2)
    idx=ds;
    clear ds;
    global ds;
  end
  imgs=dsload('.ds.imgs{ds.conf.currimset}');
  res=imread([ds.conf.gbz{ds.conf.currimset}.cutoutdir imgs(idx).fullname]); 
end
