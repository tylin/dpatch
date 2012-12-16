% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% remove some fields of the patch structure so that the
% outputs of one function can be concatenated with the
% outputs of another.
function res=cleanPatchStruct(res)
  fieldstorm={'imidx','setidx','clust','detScore'};
  for(i=1:numel(fieldstorm))
    if(isfield(res,fieldstorm{i}))
      res=rmfield(res,fieldstorm{i});
    end
  end
end
