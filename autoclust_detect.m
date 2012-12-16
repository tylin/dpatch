% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Fire the current detectors specified in ds.batch.round.detectors 
% (whose ids are assumed to be found in ds.batch.roudn.selectedClust)
% on the image specified in ds.batch.round.iminds(dsidx).  Write
% the results to ds.batch.round.topdetsmap{dsidx,:}.  Also write
% a flag to ds.batch.round.topdetsmap(dsidx) so dsmapreduce can track
% the progress.  
myaddpath;
%if(~dsfield(ds,'imgs'))
  imgs=dsload('.ds.imgs');
%end
if(~dsfield(ds,'batch','round','detectors'))
  dsload('ds.batch.round.detectors');
end
if(~dsfield(ds,'batch','round','selectedClust'))
  dsload('ds.batch.round.selectedClust');
end
imind=ds.batch.round.iminds(dsidx);
im=im2double(getimg(ds,imind));
disp('detecting...');
dets=ds.batch.round.detectors.detectPresenceInImg(im);
disp('adding image to metadata...');
for(i=1:numel(dets.firstLevel.detections))
  for(j=1:numel(dets.firstLevel.detections(i).metadata))
    dets.firstLevel.detections(i).metadata(j).im=[ds.conf.gbz{ds.conf.currimset}.cutoutdir imgs{ds.conf.currimset}(imind).fullname];
  end
end
%imidx=(dsidx-1)*numel(ds.batch.round.selectedClust);
ds.batch.round.tmpdsidx=dsidx;
numTopN = 20;
maxOverlap = 0.1;

disp('getResultData...');
indstosave='';
for(i=numel(ds.batch.round.selectedClust):-1:1)
    clusti = (ds.batch.round.selectedClust(i));
    [thisScores, imgMeta] = getResultData(dets, ...
          i, maxOverlap);
   if(numel(thisScores)>0)
     res.scores =  thisScores';
     res.imgIds = ones(1, length(thisScores)) * imind;
     res.meta = imgMeta;
     ds.batch.round.topdetsmap{i,dsidx}=res;
     %dssave(['ds.batch.round.topdetsmap{' num2str(dsidx) '}{' num2str(i) '}']);
     indstosave=[indstosave ' ' num2str(i)];
     %ds.batch.round.topdetsmap{dsidx,i}=[];
   end
end
disp('saving...');
if(numel(indstosave)>0)
     dssave(['ds.batch.round.topdetsmap{' indstosave '}{' num2str(dsidx) '}']);
end
%dssave(['ds.batch.round.negmin.detections{' ...
%        '(1+(ds.batch.round.negmin.tmpdsidx-1)*numel(ds.batch.round.selectedClust)):' ...
%        '((ds.batch.round.negmin.tmpdsidx)*numel(ds.batch.round.selectedClust))}']);
%dssave(['ds.batch.round.negmin.topdetsmap' ...
%        '{ds.batch.round.negmin.tmpdsidx}{:}']);
%    ds.batch.round.topdetsmap{imidx+i}=res;
%end
%avwafsbfbh
%dssave(['ds.batch.round.topdetsmap{' ...
%        '(1+(ds.batch.round.tmpdsidx-1)*numel(ds.batch.round.selectedClust)):'...
%        '((ds.batch.round.tmpdsidx)*numel(ds.batch.round.selectedClust))}']);

%ds.batch.round.topdetsmap={};
ds.batch.round.detectorflags{dsidx}=1;

