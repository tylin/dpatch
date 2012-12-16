function res=imgtd(fname,label,link,style,imstyle)
  if(~dshassuffix(lower(fname),'.jpg'))
    fname=[fname '.jpg'];
  end
  if(nargin>=2)
    labelstr=[' title="' label '"'];
  else
    labelstr='';
  end
  link1='';
  link2='';
  if(nargin<4)
    style='';
  end
  if(nargin<5)
    imstyle='';
  end
    if(nargin>=3&&~isempty(link))
      link1=['<a style="border:solid 0px #000" href="' link '">'];
      link2='</a>';
    end

    res=['<td class="imgtd" style="' style '">' link1 '<img style="' imstyle '" src="' fname '"' labelstr '/>' link2 '</td>'];
end
