% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%function [matchstr,brakidx]=dssplitmatchstr(matchstr)
    if(sum(ds_matchstr=='{')>0)
      ds_brakpos=find(ds_matchstr=='{');
      ds_idxstr=ds_matchstr((ds_brakpos(1)+1):(end-1));
      ds_matchstr=ds_matchstr(1:(ds_brakpos-1));
      ds_brakidx=eval(['[' ds_idxstr ']']);
    else
      ds_brakidx=[];
    end

%end
%function brakidx=evalidxstr(idxstr)
%  global ds;
%end
