function colorstr=htmlcolor(colorval)
    color=round(colorval*256);
    colorstr=[];
    for(i=1:3)
      strtmp=lower(dec2hex(color(i)));
      if(numel(strtmp)==1)
        strtmp=['0' strtmp];
      end
      colorstr=[colorstr strtmp];
    end

end
