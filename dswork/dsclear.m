% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% clear a variable from memory, but unlike dsdelete, do not
% get rid of any copies that have been saved to disk.
% allmatchstr can be an absolute or relative path; *-wildcards
% and braces are understood.

function dsclear(allmatchstr)
  global ds;
  if(nargin<1)
    allmatchstr='ds.*';
  end
  [allmatchstr brakidx]=dssplitmatchstr(allmatchstr);
  matchstrs=dsexpandpath(allmatchstr);
  for(i=1:numel(matchstrs))
    %[matchstr brakidx]=dssplitmatchstr(matchstrs{i})
    matchstr=dsfindvar(matchstrs{i});
    if(dsfield(matchstr))
      %matchstr=dsfindvar(matchstr);
      [bkidxstr]=dsrefstring(eval(['size(' matchstr ')']),brakidx,1);
      if(~isempty(bkidxstr))
        eval([matchstr bkidxstr '=[];']);
      else
        dotpos=find(matchstr=='.');
        dotpos=dotpos(end);
        parent=matchstr(1:(dotpos-1));
        child=matchstr((dotpos+1):end);
        eval([parent '=rmfield(' parent ',''' child ''')']);
      end
    end
  end
end
