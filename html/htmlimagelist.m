function [html]=htmlimagelist(instr)
global ds;
html=['<html><body><table>'];
ord=instr.imlist;
for(i=1:numel(ord))
  if(isfield(instr,'label'))
  label=[instr.label{i} ';'];
  html=[html '<tr>' imgtd([ds.conf.imgsurl ds.imgs{ds.conf.currimset}(ord(i)).fullname],...
          [label ' idx:' num2str(ord(i))]) '</tr>'];
end
html=[html '</table></body></html>'];

end
