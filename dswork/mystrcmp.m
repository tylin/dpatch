% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% builtin strcmp returns false for empty strings that have different 'sizes'
function res=mystrcmp(str1, str2)
  res=((numel(str1)==0)&&(numel(str2)==0))||strcmp(str1,str2);
end
