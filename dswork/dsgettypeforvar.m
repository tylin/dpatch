% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function [type] =gettypeforvar(var,varnm)
    if(iscell(var))
      type='cell';
    elseif(isstruct(var))
      type='struct';
    elseif(dshassuffix(varnm,'img'))
      type='img';
    elseif(dshassuffix(varnm,'png'))
      type='png';
    elseif(dshassuffix(varnm,'fig'))
      type='fig';
    elseif(dshassuffix(varnm,'html'))
      type='html';
    elseif(dshassuffix(varnm,'txt'))
      dotpos=find(varnm=='_');
      type=varnm((dotpos(end)+1):end);
    else
      type='mat';
    end
end
