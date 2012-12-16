% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Determine whether a field exists.  The first argument is to the
% ds, but it can be omitted and the global ds will be used.  The
% second argument can be a single string specifying a relative path to
% a variable in ds, or an argument list where each string specifies a
% subfield of the previous variable.  e.g. dsfield(ds,'struct1','var1')
% tests the existence of ds.struct1.var1.
function res=dsfield(ds,varargin)
  if(nargin<2)
    if(~ischar(ds))
      throw MException('ds:args','one-arg version of dsfield requires string input');
    end
    if(numel(ds)<=3)
      if(strcmp(ds,'ds'))
        res=1;
      else
        res=0;
      end
      return;
    end
    varargin{1}=ds(4:end);
    clear ds;
    global ds;
  end
  ptr=ds;
  if(any(varargin{1}=='.'))
    varargin=regexp(varargin{1},'\.','split');
    if(strcmp(varargin{1},'ds'))
      varargin=varargin(2:end);
    end
  end
  for(i=1:numel(varargin))
    if(isfield(ptr,varargin{i}))
      ptr=getfield(ptr,varargin{i});
    else
      res=0;
      return;
    end
  end
  res=1;
  return;
end
