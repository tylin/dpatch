% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function res=dsabspath(relpath)
  global ds;
  if(relpath=='*')
    relpath='ds.*';
  end
  if(dshasprefix(relpath,'.ds'))
    res=relpath;
    return;
  end
  if(~dshasprefix(relpath,'ds'))
    throw(MException('ds:abspath','relative paths must start with ds'));
  end
  if(~dsfield(ds,'sys','currpath'))
    ds.sys.currpath='';
  end
  res=['.ds' ds.sys.currpath relpath(3:end)];
  
end
