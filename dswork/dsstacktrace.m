% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function dsstacktrace(ds_err,unwrap)
disp(ds_err.message);
if(exist('unwrap','var')&&unwrap)
  while(strcmp(ds_err.identifier,'ds:dsprinterrdummy'))
    ds_err=ds_err.cause{1};
  end
end
for(i=1:numel(ds_err.stack))
  disp(ds_err.stack(i));
end;
disp(ds_err.identifier);

end
