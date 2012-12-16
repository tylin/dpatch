function [scale, nr, nc] = getCanonicalScale(canonicalSize, rows, cols)
% Returns the canonical scale for the patches.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).
if(iscell(canonicalSize))
  switch(canonicalSize{1})
    case('sqr')
      scale=sqrt((canonicalSize{2}.^2)/(rows*cols));
  end
  nr=rows*scale;
  nc=cols*scale;
else
  if rows < cols
    scale = canonicalSize / rows;
    nr = rows * scale;
    nc = cols * scale;
  else
    scale = canonicalSize / cols;
    nr = rows * scale;
    nc = cols * scale;
  end
end
end
