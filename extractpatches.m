% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Extract patches corresponding to detections in images.
% detsimple is the set of detections, with a 'pos' field
% specifying positions, and a 'imidx' field, specifying
% an index into the current image set. imgs_all us unused.
function res=extractpatches(detsimple,imgs_all,conf)
global ds;
if(~exist('conf','var'))
  conf=struct();
end
try
%    dsload('ds.imgs');
%    global imgs;
%    if(isempty(imgs))
  imgs=cell(numel(ds.imgs{ds.conf.currimset}),1);
%    end
numel(detsimple)
loaded=[];
ct=1;
[~,ord]=sort([detsimple.imidx]);
  for(dsidx=ord(:)')
    pos=detsimple(dsidx).pos;
    i=detsimple(dsidx).imidx;
    if(isempty(imgs{i}))
      imgs{i}=getimg(ds,i);%imread([ds.conf.gbz.cutoutdir imgs_all(i).fullname]);
      loaded(loaded==i)=[];
      loaded=[loaded i];
      if(numel(loaded)>1)
        imgs{loaded(1)}=[];
        loaded(1)=[];
      end
    end
    
    if(dsbool(conf,'noresize'))
      res{dsidx}=imgs{i}(pos.y1:pos.y2,pos.x1:pos.x2,:);
    else
      maxsz=max(pos.y2-pos.y1,pos.x2-pos.x1);
      reszx=80*(pos.x2-pos.x1)/maxsz;
      reszy=80*(pos.y2-pos.y1)/maxsz;
      res{dsidx}=imresize(imgs{i}(pos.y1:pos.y2,pos.x1:pos.x2,:),[reszy reszx]);
    end
    if(mod(ct,10)==0)
      disp(ct)
    end
    ct=ct+1;
    
  end
catch ex
  dsprinterr
end
