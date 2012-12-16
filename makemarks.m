% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Utility function: basically the inverse operation of "find".
% sz specifies the size of the output.
function res=makemarks(idx,sz)
  res=logical(zeros(1,sz));
  res(idx)=true;
end
