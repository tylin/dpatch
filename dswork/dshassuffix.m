% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function res=dshassuffix(str,suffix)
  if(numel(suffix)>numel(str))
    res=0;
  else
    res=mystrcmp(str((end-numel(suffix)+1):end),suffix);
  end
end
