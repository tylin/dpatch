% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function res=dshasprefix(str,prefix)
  if(numel(prefix)>numel(str))
    res=0;
  else
    res=mystrcmp(str(1:numel(prefix)),prefix);
  end
end
