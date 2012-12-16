% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% test for the existence of a variable in dswork.  If that variable
% exists, return it; otherwise, return 0.  Most useful for flags,
% where you want the default to be 0.
%
% ds is the ds structure to test; varargin is a list of names specifying
% the path to the variable, in a comma-separated list. E.g. dsbool(ds,'struct1','var1') 
% returns ds.struct1.var1 if that field exists, and 0 otherwise.
%
% currently only supports relative paths to a single variable.
function res=dsbool(ds,varargin)
  ptr=ds;
  for(i=1:numel(varargin))
    if(isfield(ptr,varargin{i}))
      ptr=getfield(ptr,varargin{i});
    else
      res=0;
      return;
    end
  end
  res=ptr;
  return;
end
