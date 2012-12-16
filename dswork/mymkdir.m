% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function mymkdir(arg)
%disp(['mymkdir ' arg]);
%keyboard;
if(~exist(arg,'dir'))
  mkdir(arg)
  unix(['chmod 755 ' arg]);
end
%keyboard;
end
