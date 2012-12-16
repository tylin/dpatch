% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function [matchstr,brakidx]=dssplitmatchstr(matchstr)
    if(sum(matchstr=='{')>0)
      brakpos=zeros(size(matchstr));
      brakpos(find(matchstr=='{'))=1;
      brakpos(find(matchstr=='}'))=-1;
      inbrackets=(cumsum(brakpos)>0);
      opbrak=find(diff([0 inbrackets])==1);
      clbrak=find(diff([0 inbrackets])==-1);
      if(size(opbrak)~=size(clbrak))
        throw(MException('ds:bracemismatch','braces don''t match up'));
      end
      if(numel(opbrak)>1)
        brakidx{1}=evalidxstr(matchstr((opbrak(1)+1):(clbrak(1)-1)));
        brakidx{2}=evalidxstr(matchstr((opbrak(2)+1):(clbrak(2)-1)));
      elseif(numel(opbrak)>0)
        brakidx{1}=[];
        brakidx{2}=evalidxstr(matchstr((opbrak(1)+1):(clbrak(1)-1)));
      end
%      brakpos=find(matchstr=='{');
%      idxstr=matchstr((brakpos(1)+1):(end-1));
      matchstr=matchstr(1:(opbrak(1)-1));
%      brakidx=evalidxstr(idxstr);
    else
      brakidx={[],[]};
    end

end
function brakidx=evalidxstr(idxstr)
  global ds;
  brakidx=eval(['[' idxstr ']']);
end
