% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function res=dsgetdisknam(var,varnm,currpath)
  type=dsgettypeforvar(var,varnm);
  res=dsgetdisknamtype(varnm,type,currpath);
end
