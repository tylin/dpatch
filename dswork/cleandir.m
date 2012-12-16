% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% same as dir, except get rid of the entries for . and ..

function files=cleandir(dirname);
  files=dir(dirname);
  function res=isbad(str)
    res=strcmp(str,'..')||strcmp(str,'.');
  end
  files(cellfun(@isbad,{files.name}))=[];
end
