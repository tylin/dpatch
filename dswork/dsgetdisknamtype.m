% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function disknams=getdisknamtype(varnm,type,dirpath)
    switch(type)
      case('cell')
        disknams={[dirpath varnm '[]']};
      case('struct')
        disknams={[dirpath varnm]};
      case('img')
        disknams={[dirpath varnm '.jpg']};
      case('png')
        disknams={[dirpath varnm '.png']};
      case('fig')
        disknams={[dirpath varnm '.jpg'], [dirpath varnm '.pdf']};
      case('html')
        disknams={[dirpath varnm '.html']};
      case('mat')
        disknams={[dirpath varnm '.mat']};
      otherwise
        disknams={[dirpath varnm '.' type(1:(end-3))]};
    end
end
