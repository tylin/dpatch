% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function [nam, pathexist]=dsfindvar(varnm)
      global ds;
      absvar=dsabspath(varnm);
      %=regexp(absvar,'\.','split');
      %if(strcmp(varargin{1},'ds'))
      %    varargin=varargin(2:end);
      %end
      absvar=absvar(4:end);
      if(~dsfield(ds,'sys','currpath'))
        ds.sys.currpath='';
      end
      if(dshasprefix(absvar, ds.sys.currpath))
        nam=absvar((numel(ds.sys.currpath)+1):end);
      else
        nam=['.sys.root' absvar];
      end
      nam=['ds' nam];
      pathexist=dsfield(nam);

end
