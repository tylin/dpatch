% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% Given a detector struct, select the ones specified by inds.
%
function [detscpy] = selectDetectors(dets,inds)
flm=dets.firstLevModels;
detscpy = VisualEntityDetectors({}, dets.params);
detscpy.firstLevModels.w = flm.w(inds,:);
detscpy.firstLevModels.rho = flm.rho(inds);
detscpy.firstLevModels.firstLabel = flm.firstLabel(inds);
detscpy.firstLevModels.info = flm.info(inds);
detscpy.firstLevModels.threshold = flm.threshold(inds);
end
