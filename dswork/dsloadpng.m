function res=dsloadpng(inpath)
  [res,map,alpha]=imread(inpath);
  if(~isempty(alpha))
    res=cat(3,res,alpha);
  end
end
