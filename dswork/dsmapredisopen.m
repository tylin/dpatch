% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% test whether there is currently a distributed session open.
% In reality, it evaluates to false if dsmapredclose has been
% called more recently than dsmapredopen, or if dsmapredopen
% has not been called.  It does not directly attempt to
% communicate with the workers, and so failures in dsmapredopen
% or dsmapredclose may cause the value to be 'incorrect'.
function res=dsmapredisopen()
  global ds;
  res=dsbool(ds,'sys','distproc','isopen');
end
