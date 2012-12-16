% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Print an estimate of memory usage for the current workspace.

ans=[];
memory_a=whos;
disp(['workspace memory usage: ' num2str(sum([memory_a.bytes])) ' bytes']);
