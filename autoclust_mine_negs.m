% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Mine an image (specified in ds.batch.round.negmin.iminds(dsidx)) 
% for negative examples for each detector.  Detectors are in
% ds.batch.round.detectors, with ids in ds.batch.round.selectedClust.
% Results for detector k (where k is the index into the array
% ds.batch.round.detectors, not the id) are given in 
% ds.batch.round.negmin.detections{k,dsidx}.  A flag is written to
% ds.batch.round.negmin.imageflags so that dsmapreduce can track progress.
myaddpath;
if(~dsfield(ds,'imgs'))
  %disp(['ismapreducera:' num2str(ds.distproc.mapreducer)]);
  dsload('ds.imgs');
  %disp(['ismapreducerb:' num2str(ds.distproc.mapreducer)]);
  dsload('ds.batch.round.detectors');
  %disp(['ismapreducerc:' num2str(ds.distproc.mapreducer)]);
  dsload('ds.batch.round.selectedClust');
end
iminds=ds.batch.round.negmin.iminds;
im=im2double(getimg(ds,iminds(dsidx)));
%ds.batch.round.negmin.detections{dsidx}=
disp('detecting...');
tic
dets=ds.batch.round.detectors.detectPresenceInImg(im);
toc
selectedClust=ds.batch.round.selectedClust;
%imidx=(dsidx-1)*numel(ds.batch.round.selectedClust);
tmpdets=simplifydets(dets,iminds(dsidx));
%ds.batch.round.negmin.detections=cell(dsidx,numel(selectedClust));
indstosave='';
for(k=1:numel(selectedClust))
   alldets=[];
   clustId=selectedClust(k);
   %dsload(['ds.batch.round.negmin.detections{' num2str(k) '}']);
   %ds.batch.round.negmin.detections{k}=[];
   if(size(tmpdets)>0)
     alldets=tmpdets([tmpdets.detector]==k);
   end
   if(~isempty(alldets))
     ds.batch.round.negmin.detections{k,dsidx}=alldets;
%     dssave(['ds.batch.round.negmin.detections{' num2str(dsidx) '}{' num2str(k) '}']);
     indstosave=[indstosave ' ' num2str(k)];
     %if(numel(alldets)>0)
     %keyboard;
     %end
     %ds.batch.round.negmin.detections{dsidx,k}=[];
   end
end
if(numel(indstosave)>0)
  dssave(['ds.batch.round.negmin.detections{' indstosave '}{' num2str(dsidx) '}']);
  ds.batch.round.negmin.detections={};
  %disp(['ismapreducerd:' num2str(ds.distproc.mapreducer)]);
end
%dssave(['ds.batch.round.negmin.detections{' ...
%        '(1+(ds.batch.round.negmin.tmpdsidx-1)*numel(ds.batch.round.selectedClust)):' ...
%        '((ds.batch.round.negmin.tmpdsidx)*numel(ds.batch.round.selectedClust))}']);
%dssave(['ds.batch.round.negmin.detections' ...
%        '{ds.batch.round.negmin.tmpdsidx}{:}']);


ds.batch.round.negmin.imageflags{dsidx}=1;
