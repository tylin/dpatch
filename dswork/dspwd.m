% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Get the current working directory for ds (that you entered via dscd).
% if nargout=1, return the path; otherwise just print it.

function res=dspwd()
  global ds;
  res=['.ds' ds.sys.currpath];
  if(nargout<1)
    disp(res);
  end
end
