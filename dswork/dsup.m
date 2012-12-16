% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Update a variable in the ds struct, and force it to be saved
% the next time dssave is called.  2-d cell arrays are not supported.
%
% Ideally, any piece of code of the following form:
%
% [expr1] = [expr2]
%
% where [expr1] is somewhere in dswork, the following code will have
% exactly the same effect, except the changes will be written to disk
% at the next call to dssave:
%
% {'[expr1]','[expr2]'};dsup;
%
% The odd syntax is necessary because [expr2], as well as any indexing
% expressions in [expr1] are evaluated in the calling workspace.  
%
% In practice, there are restrictions on the form of [expr1] because
% this code was written in a limited amount of time.  [expr1] is
% expected to have the form 'ds.[expr3]' or 'ds.[expr3]{[expr4]}', where [expr3] is
% a series of valid variable names separated by dots (to designate a field of
% a struct), and [expr4] can be anything, as long as the opening and close brackets
% actually match each other, but it must evaluate to an array of integers.  
% Note that extra whitespace is not handled.
%
ds_a=ans;
ds_matchstr=ds_a{1};
ds_src=ds_a{2};
eval([ds_matchstr '=' ds_src ';']);
dssplitmatchstrscript;
%[ds_targ ds_brakidx]=dssplitmatchstr(ds_targ);
ds_dotpos=find(ds_matchstr=='.');
ds_pfx=ds_matchstr(1:(ds_dotpos(1)-1));
ds_sfx=[ds.sys.currpath ds_matchstr((ds_dotpos(1)):end)];
ds_toks=regexp(ds_matchstr,'\.','split');
ds_toks=ds_toks(2:end);
if(dsfield(ds,ds_toks{:}))
  if((~isempty(ds_brakidx))&&dsfield(ds,[ds_pfx '.sys.savestate' ds_sfx])&&(~isempty(eval([ds_pfx '.sys.savestate' ds_sfx]))))
    eval([ds_pfx '.sys.savestate' ds_sfx '{2}(ds_brakidx)=0;']);
  else
    if(dsfield(ds,['sys.savestate',ds_sfx]))
      if(eval(['iscell(' ds_pfx '.sys.savestate' ds_sfx ')']))
        eval([ds_pfx '.sys.savestate' ds_sfx '={};']);
      else
        eval([ds_pfx '.sys.savestate' ds_sfx '=[];']);
      end
    end
  end
end
