% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function [bkidxstr extrainds]=dsrefstring(szmatchvar,brakidx,riscell)
        %global ds;
%       [matchstr brakidx]=splitmatchstr(matchstr);
       if(~isempty(brakidx{2}))
          ressz=szmatchvar;%eval(['size(matchvar)']);
          inval2=(brakidx{2}>ressz(2));
          bkidx2=brakidx{2};
          bkidx2(inval2)=[];
          extrainds(2)=sum(inval2);
          if(riscell)
            char1='{';
            char2='}';
          else
            char1='(';
            char2=')';
          end
          if(~isempty(brakidx{1}))
            inval1=(brakidx{1}>ressz(1));
            bkidx1=brakidx{1};
            bkidx1(inval1)=[];
            extrainds(1)=sum(inval1);
            bkidxstr=[char1 num2str(bkidx1(:)') ',' num2str(bkidx2(:)') char2];
          else
            bkidxstr=[char1 num2str(bkidx2(:)') char2];
          end
        else
          bkidxstr='';
          extrainds=[0 0];
        end 
end
