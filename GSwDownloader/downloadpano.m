% This file is based on code by Petr Gronat, Michal Havlena, and Jan Knopp,
%  and edited by Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% download the panorama specified by panoid and return the data.
%
% More information on the general technique can be found in:
% GRONAT, P., HAVLENA , M., SIVIC , J., AND PAJDLA , T. 2011.
% Building streetview datasets for place recognition and city reconstruction. 
% Tech. Rep. CTU–CMP–2011–16, Czech Tech Univ.
%
function panodata=downloadpano(panoid)
  if nargin<3
    gzoom_def = 4;
  end
%  rng('shuffle')
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setDefaultStream(s);
  server = floor(rand*3+1);
%ct=1;
%for idx=0:999999
%  tline = fgetl(fid);
%  if ~ischar(tline), break, end;
%  ct=ct+1;
%end
%[~,nfiles]=unix('find . -name "*.jpg" | wc -l');
%nfiles=str2num(nfiles);
%if(nfiles==ct)
%  break;
%end
%fclose(fid);
%[~,hname]=unix('hostname');
%if(~isempty(strfind(hname,'ladoga')))
%  randstart=1;
%else
%  randstart=floor(rand(1)*ct)
%end
%fid = fopen(dfname,'r');
%for idx=0:999999
%  tline = fgetl(fid);
%  if ~ischar(tline), break, end;
%  if(idx<randstart)
%    continue;
%  end
%  if exist([path filesep sprintf('%.3d',floor(idx/1000)) filesep sprintf('%.6d',idx) '.jpg'],'file'), break, end;
%  panoid = strread(tline,'%s');

  gzoom = gzoom_def;
  imtile = fetch_im(gzoom,0,0,panoid,server);  
  
  if isempty(imtile) % not found at gzoom==4, trying gzoom==3
    'not found at zoom level'
    return;%continue;
    %gzoom = gzoom_def-1;
    %imtile = fetch_im(gzoom,0,0,panoid{1},server);
  end

  switch gzoom
    case 3
      tilex = 0:6; tiley = 0:3; tilew = 512; tileh = 512; imw = 6.5*512;
    case 4
      tilex = 0:12; tiley = 0:6; tilew = 512; tileh = 512; imw = 13*512;
  end

  notfound = false;
  im = uint8(zeros(length(tiley)*tileh,length(tilex)*tilew,3));
  for i=tilex
    for j=tiley
      if (i~=0) || (j~=0), imtile = fetch_im(gzoom,i,j,panoid,server); end;
      if ~isempty(imtile), im(j*tileh+1:(j+1)*tileh,i*tilew+1:(i+1)*tilew,:) = imresize(imtile,[tileh tilew]); else notfound = true; end;
    end
  end
  if notfound, fprintf(1,'Pano %.6d may be incomplete!\n',panoid); end;
  im = im(1:imw/2,1:imw,:);
  if gzoom < gzoom_def, im = imresize(im,2); end;
  %if ~exist([path filesep sprintf('%.3d',floor(idx/1000))],'dir'), mkdir(path,sprintf('%.3d',floor(idx/1000))), end;
  %imwrite(im, [path filesep sprintf('%.3d',floor(idx/1000)) filesep sprintf('%.6d',idx) '.jpg']);
  panodata=im;
%end

%fclose(fid);
%cd(opath);
%end
end

function imtile = fetch_im(gzoom,i,j,panoid,server)

  %fn = sprintf('cbk?output=tile&zoom=%d&x=%d&y=%d&cb_client=maps_sv&fover=2&onerr=3&panoid=%s',gzoom,i,j,panoid);
  fn = sprintf('cbk?output=tile&zoom=%d&x=%d&y=%d&cb_client=maps_sv&fover=2&onerr=3&renderer=spherical&v=4&panoid=%s',gzoom,i,j,panoid);
  %cmd = sprintf('http_proxy=proxy.felk.cvut.cz:80 wget -nd -nH -q -nc "http://cbk%d.google.com/%s"',server,fn);
  cmd = sprintf('wget -nd -nH -q -nc "https://cbks%d.google.com/%s"',server,fn);
  cmd
  trials = 1; system(cmd); pause(0.1);
  while ~exist(fn,'file') && (trials < 3)
    pause(5); trials = trials + 1; system(cmd); pause(0.1);
  end
  if exist(fn,'file')
    imtile = imread(fn);
    delete(fn);
    if size(imtile,3) == 1, imtile = repmat(imtile,[1 1 3]); end; % B/W fix
  else
    imtile = [];
  end
end
