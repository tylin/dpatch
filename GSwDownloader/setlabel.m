% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Generate an imgs structure and save it to gbz.datasetname.
% It reads all directories contained in gbz.cutoutdir and
% collects all of the images.

imdirs=dir(gbz.cutoutdir);
[~,inds]=sort({imdirs.name})
imdirs=imdirs(inds);
imgs=[];
imdata=[];
smdata=[];
for(fn=1:numel(imdirs))
  if(strcmp(imdirs(fn).name,'.')||strcmp(imdirs(fn).name,'..'))
    continue;
  end
  imdirs(fn).name
  imgs1=cleandir([gbz.cutoutdir '/' imdirs(fn).name]);
  %this code lets you not select a random subset of what you downloaded
  %if(numel(imgs1)<=3000)
  %  n=1000;
  %else
  %  n=11000;
  %end
  %rp=randperm(numel(imgs1);
  %imgs1=imgs1(rp(1:n));
  [~,inds]=sort({imgs1.name});
  imgs1=imgs1(inds);
  rand('seed',fn);
  s=randperm(numel(imgs1));
  for(m=1:numel(imgs1))
    imgs1(m).city=imdirs(fn).name;
    imgs1(m).istrain=(s(m)<=numel(imgs1)/2);
    imgs1(m).fullname=[imdirs(fn).name filesep imgs1(m).name];
    imtmp=imread([gbz.cutoutdir imgs1(m).fullname]);
    imsize=size(imtmp);
    imgs1(m).imsize=imsize(1:2);
    tmp=regexp(imgs1(m).name,'_','split');
    im.lat=str2num(tmp{1});
    im.lng=str2num(tmp{2});
    %imdata1(m,:)=imtmp(:)';
    %imsm=imresize(imtmp,.3);
    %smdata1(m,:)=imsm(:)';
  end
  imgs=[imgs;imgs1];
  %imdata=[imdata; imdata1];
  %smdata=[smdata;smdata1];
end
save(gbz.datasetname,'imgs');
