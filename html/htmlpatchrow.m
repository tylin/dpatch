function html=htmlpatchrow(ds,binid,patchpath,style)
try
    html=['<tr>'];
  if(nargin<4)
    style='';
  end
  %  html=['<tr>'];
  %end
  global lsh;
  global kmn;
  if(~dsfield(ds,'bestbin','isgeneral'))
    ds.bestbin.isgeneral=ones(size(ds.bestbin.tosave));
  end
  pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
  if(~isempty(lsh))
    counts=[lsh.lsh{1}.counts(binid,1)];
    if(numel(lsh.lsh)>1)
      counts=[counts lsh.lsh{2}.counts(binid,1)];
    end
  elseif(~isempty(kmn))
    counts=kmn.counts(binid,:);
  elseif(dsfield(ds,'bestbin','counts'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    counts=ds.bestbin.counts(pos,:);
  else
    counts=[];
    
  end
  if(dsfield(ds,'bestbin','imgcounts'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    imgcountstr=[' paris_img:' num2str(ds.bestbin.imgcounts(pos,1)) ' nonparis_img:' num2str(ds.bestbin.imgcounts(pos,2))];
  else
    imgcountstr=[];
  end
  if(dsfield(ds,'bestbin','gain'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    entstr=['theme_prob: ' num2str(ds.bestbin.initialprob(pos(1))) '<br/>patch prob:' num2str(ds.bestbin.finalprob(pos(1))) '<br/>entropy gain:' num2str(ds.bestbin.gain(pos(1))) '<br/>'];
  else
    entstr=[];
  end
  if(dsfield(ds,'bestbin','misclabel'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    miscstr=ds.bestbin.misclabel{1}{pos(1)};
  else
    miscstr=[];
  end
  if(dsfield(ds,'bestbin','detweight'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    weightstr=['tf-idf:' num2str(ds.bestbin.detweight(pos(1))) '<br/>'];
  else
    weightstr=[];
  end
  corresplink=[];
  if(dsfield(ds,'bestbin','corresphtml'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    if(numel(pos)>0)
      if(numel(pos)>1)
        pos=pos(1);
      end
      corresplink=[' <a href="corresphtml[]/' num2str(pos) '.html">&gt; corresp.</a>'];
    end
  end
  if(dsfield(ds,'bestbin','svmweight'))
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    svmweightstr=['svmweight: ' num2str(ds.bestbin.svmweight(pos))];
  else
    svmweightstr=[];
  end
  if(numel(counts)>0)
    countstr=[' paris:' num2str(counts(1)) ' non:' num2str(counts(2))];
  else
    countstr=[];
  end
    pos=find(ds.bestbin.tosave(find(ds.bestbin.isgeneral))==binid);
    %html=[html '<td style="' style '" > paris:' num2str(counts(1)) ' non:' num2str(counts(2)) ' binid:' num2str(binid) ' ' corresplink '</td>\n'];
  %elseif(numel(counts)>0)
  %  html=[html '<td style="' style '" > patches:' num2str(counts(1)) '</td>\n'];
  %else
    html=[html '<td class="postd" style="' style '" ><img src="" style="width:201px;height:0px"/> ' num2str(pos) ':' num2str(binid) '<br/> ' countstr imgcountstr entstr ' ' weightstr ' ' svmweightstr ' ' miscstr '</td>\n'];
    %html=[html '<td class="postd" style="' style '" ><p> ' num2str(pos) '<br/> ' countstr imgcountstr entstr ' ' cluststr ' ' weightstr ' ' svmweightstr '</p></td>\n'];
  %end
  if(dsfield(ds,'bestbin','coredetection'))
    html=[html imgtd([patchpath '/alldiscpatchimg[]/' num2str(ds.bestbin.coredetection)],ds.bestbin.coredetectionlabel)];
  end
%  if(size(ds.alldisclabelcat,2)==5)
%    marks=(ds.alldisclabelcat(:,5)==binid);
%  else
%  end
  marks=(ds.bestbin.alldisclabelcat(:,end)==binid);
  patches=find(marks);%alldiscpatch(:,:,:,marks);
  %keyboard;
  %if(isempty(patches))
  %  continue;
  %end
  %clf;
  patches=patches(randperm(numel(patches)));
  if(dsfield(ds,'bestbin','decision'))
    [~,ord]=sort(ds.bestbin.decision(patches),'descend');
    patches=patches(ord);
  end
  if(dsfield(ds,'bestbin','group'))
    [~,ord]=sort(ds.bestbin.group(patches));
    patches=patches(ord);
    ct=1;
    grouprank=zeros(size(patches));
    grouprank(1)=1;
    for(i=2:numel(patches))
      if(ds.bestbin.group(patches(i))==ds.bestbin.group(patches(i-1)))
        grouprank(i)=grouprank(i-1)+1;
      else
        grouprank(i)=1;
      end
    end
  end
  if(numel(patches)>20&&~dsfield(ds,'bestbin','group'))
    patches=patches(1:20);
  end
  for(k=1:numel(patches))
    label='';
    if(dsfield(ds,'bestbin','decision'))
      %try
      label=[label 'score: ' num2str(ds.bestbin.decision(patches(k)))];
      %if(exist('grouprank','var'))
      %  label=[label ' rank:' num2str(grouprank(k))];
      %end
      %catch
      %keyboard;
      %end
    end
    if(dsfield(ds,'besbtin','rank'))
      label=[label '; rank: ' num2str(ds.bestbin.rank(patches(k)))];
    end
    link='';
    %dsfield(ds,'bestbin','detectvishtml')
    if(dsfield(ds,'bestbin','detectvishtml')&&dsbool(ds,'bestbin','linktovisualization'))
      link=[patchpath 'detectvishtml[]/' num2str(ds.alldisclabelcat(patches(k),1)) '.html'];
    elseif(dsfield(ds,'imgsurl'))
      patches(k);
      %ds.imgs(ds.bestbin.alldisclabelcat(patches(k),1))
      if(ds.bestbin.alldisclabelcat(patches(k),1)>0)
        link=[ds.imgsurl '/' ds.bestbin.imgs(ds.bestbin.alldisclabelcat(patches(k),1)).fullname];
      end
    end
    %keyboard;
    style='';
    if(dsfield(ds,'bestbin','iscorrect'))
      if(ds.bestbin.iscorrect(patches(k)))
        style='border: solid 1px #0F0;';
      else
        style='border: solid 1px #F00;';
      end
    end
    if(dsfield(ds,'bestbin','group')&&(k>1)&&(ds.bestbin.group(patches(k))~=ds.bestbin.group(patches(k-1))))
      style=[style 'border-left:solid 8px #00F;'];
    end
    imstyle=['width:80px;height:80px;'];
    html=[html imgtd([patchpath '/alldiscpatchimg[]/' num2str(patches(k))],label,link,style,imstyle) '\n'];
    if(dsfield(ds,'bestbin','alldiscpatchlabimg'))
      html=[html imgtd([patchpath '/alldiscpatchlabimg[]/' num2str(patches(k))]) '\n'];
    end
  end
  html=[html '</tr>\n'];
catch ex
  dsprinterr
end
end
