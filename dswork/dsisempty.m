% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% test whether a cell in a cell array exists and is nonempty.
function res=dsisempty(fnam,idx)
  global ds;
  myvar=ds;
  fnam=dsfindvar(fnam);
  toks=regexp(fnam,'\.','split');
  for(i=2:numel(toks))
    if(~isfield(myvar,toks{i}))
      res=false;
      return;
    end
    myvar=getfield(myvar,toks{i});
  end
  if(~iscell(myvar))
    res=(idx==1);
  elseif(numel(myvar)<idx)
    res=0;
  else
    res=isempty(myvar{idx});
  end
end
