% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% an relatively efficient function to convert a HOG pyramid index 
% (i.e. pyramid level and grid cell) into a position
% in pixel space.
function metadata=pyridx2pos(idx,pyrcanosz,pyrsc,prSize,pcSize,sBins,imsize);
levSc = pyrsc;
canoSc = pyrcanosz;
% [x1 x2 y1 y2]
levelPatch = [ ...
  0, ...
  round((pcSize + 2) * sBins * levSc / canoSc) - 1, ...
  0, ...
  round((prSize + 2) * sBins * levSc / canoSc) - 1, ...
];
x1=idx(2);
y1=idx(1);
xoffset = floor((x1 - 1) * sBins * levSc / canoSc) + 1;
  yoffset = floor((y1 - 1) * sBins * levSc / canoSc) + 1;
  thisPatch = levelPatch + [xoffset xoffset yoffset yoffset];

  metadata.x1 = max(1,thisPatch(1));
  metadata.x2 = min(thisPatch(2),imsize(2));
  metadata.y1 = max(1,thisPatch(3));
  metadata.y2 = min(thisPatch(4),imsize(1));
%if(metadata.x2>936)
%keyboard
%end
end

