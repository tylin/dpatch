function [prSize, pcSize, pzSize, pExtra] = getCanonicalPatchHOGSize(params)
% Canonical size for patch HOGs.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).
prSize = round(params.patchCanonicalSize(1) / params.sBins) - 2;
pcSize = round(params.patchCanonicalSize(2) / params.sBins) - 2;
pExtra=0;
if(isfield(params,'useColor')&&params.useColor)
  pzSize = 33;
elseif(dsfield(params,'patchOnly'))
  pzSize=1;
else
  if(dsbool(params,'useColorHists'))
    pExtra=20;
  end
  pzSize=31;
end
end
