% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% print the exception named ex.  If we are running in a distributed setting,
% rethrow the exception so it can be reported in the main thread.  Otherwise
% go to a keyboard statement for debugging.

%function dsprinterr(ds_err)
%ds_err=lasterror;
%disp(ds_err.message);
%for(i=1:numel(ds_err.stack))
%  disp(ds_err.stack(i));
%end;
%disp(ds_err.identifier);
%if(~exist('ds','var'))
%  global ds;
%end
global ds;
ismapreducer=dsbool(ds,'sys','distproc','mapreducer');
if(~ismapreducer)
  dsstacktrace(ex);
  cwd=dspwd;
  if(~strcmp(cwd,'.ds'));
    disp(['WARNING: current ds wd is: ' cwd '!!']);
  end
  keyboard;
else
  %ex2=MException('ds:dsprinterrdummy','dsprinterr received an error and couldn''t call keyboard, threw this instead.');
  %ex2.addCause(ds_err);
  rethrow(ex);
end
%end
