% This file is based on code by Petr Gronat, Michal Havlena, and Jan Knopp,
% and edited by Carl Doersch (cdoersch at cs dot cmu dot edu)
% 
% panocutout generates perspective view cutouts from equirectangular
% panoramas downloaded from Google Street View. PANOIDX is a vector of
% integers prepresenting the index of panorama from wich cutouts will be
% generated. If PANOIDX is not specified cutouts are generated for each
% panorama from whole database. If PANOIDX is a string 'demo' randoma
% panorama is chosen and cutouts generated.

% The main path must include directories 'pano/' 'cutouts/' and
% and files 'download.txt', 'mapping.txt'
%
% More information on the general technique can be found in:
% GRONAT, P., HAVLENA , M., SIVIC , J., AND PAJDLA , T. 2011.
% Building streetview datasets for place recognition and city reconstruction. 
% Tech. Rep. CTU–CMP–2011–16, Czech Tech Univ.
%
%% Reading data
function res=panocutout(panodata,panoIdx)
global ds;
       %mainPath = './';
       %panoFolder = [mainPath 'paris_download6/paris_download/'];
     cutoutFolder = ds.conf.outpath;%'./data6/cutouts/';
         digits = 6;               % No. of digits in panorama filaname, i.e. '000034.jpg'
 filesPerFolder = 1000;
digitsPerFolder = 3;               % No. of digits of panorama foldernames e.g './pano/034/'
%addpath( mainPath   );
addpath('./utility/');
if ~exist(cutoutFolder,'dir'), mkdir(cutoutFolder), end;
    %fprintf('Reading file mapping.txt ... \n');
    %fid  = fopen('data6/mapping.txt');
    %scan = textscan(fid, '%f %f %f %s %s');
    %keyboard;
scan=dsload('ds.dataline');
    pano.Idx    = scan{1,1}(:);
    pano.yawRel = scan{1,2}(:);
    pano.pitch  = scan{1,3}(:);
    pano.fname  = scan{1,4}(:);
    pano.savedir  = scan{1,5}(:);
    %fclose(fid);    clear('scan');
%if strcmp(panoIdx,'demo'), panoIdx=round(rand(1)*1e4)   ; end
%if nargin<1;               panoIdx=pano.Idx(:)          ; end;
%% *** THE MAPPING FROM OUTPUT IMAGE TO INPUT IMAGE IS CONSTANT AND IS ***
%%                      BEING PRECOMPUTED 
%% Perspective view parameters
iimh=3328;  iimw=6656;      % input  image size
oimh=537;   oimw=936;       % output image size
hfov=1.5;                   % horizontal filed of view [rad]

f=oimw/(2*tan(hfov/2));     % focal length [pix]
ouc=(oimw+1)/2; ovc=(oimh+1)/2;             % output image center
iuc=(iimw+1)/2; ivc=(iimh+1)/2;             % input image center    
%% Tangent plane to unit sphere mapping
[X Y] = meshgrid(1:oimw, 1:oimh);
    X = X-ouc;   Y = Y-ovc;             % shift origin to the image center
    Z = f+0*X;
  PTS = [X(:)'; Y(:)'; Z(:)'];
% Transformation for oitch angle -04
  pitch = -04;
   Tx = expm([0     0           0        ;...
              0     0       pitch/180*pi;
              0 -pitch/180*pi   0           ]);
 PTSt = Tx*PTS;                         % rotation w.r.t x-axis about pitch angle
    Xt=reshape(PTSt(1,:),oimh, oimw);
    Yt=reshape(PTSt(2,:),oimh, oimw);
    Zt=reshape(PTSt(3,:),oimh, oimw);
    
 Theta.pitch04 = atan2(Xt, Zt);                 % cartesian to spherical
   Phi.pitch04 = atan(Yt./sqrt(Xt.^2+Zt.^2));
% Transformation for oitch angle -28
     pitch = -28;
   Tx = expm([0     0           0        ;...
              0     0        pitch/180*pi;
              0 -pitch/180*pi   0           ]);
 PTSt = Tx*PTS;                         % rotation w.r.t x-axis about pitch angle
    Xt=reshape(PTSt(1,:),oimh, oimw);
    Yt=reshape(PTSt(2,:),oimh, oimw);
    Zt=reshape(PTSt(3,:),oimh, oimw);

 Theta.pitch28 = atan2(Xt, Zt);                 % cartesian to spherical
   Phi.pitch28 = atan(Yt./sqrt(Xt.^2+Zt.^2));

%% Generating cutouts
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setDefaultStream(s);
ord=randperm(length(panoIdx));
for i=(ord(:)')
    list=find(pano.Idx==panoIdx);    % find cutouts for given panorama
               %cutoutPath = getpathByPanoIdx(panoIdx(i),cutoutFolder,...
               %                              filesPerFolder,digitsPerFolder);
    disp(['num panos:' num2str(numel(list))]);
               cutoutPath = cutoutFolder;
     if ~exist(cutoutPath,'dir'), mkdir(cutoutPath), end;
      cutoutpathcity = [cutoutPath pano.savedir{list(2)} filesep];
     if(exist([cutoutpathcity pano.fname{list(2)}],'file'))
       disp(['skipping ' num2str(panoIdx)])
       continue;
     end
     for j=1:length(list)
         % Check whether a cutout is already generated
         cutoutpathcity = [cutoutPath pano.savedir{list(j)} filesep];
         if exist([cutoutpathcity pano.fname{list(j)}],'file'), continue, end
         if ~exist('iim')   % if the panorama is not loaded read the panorama
             fprintf('Reading panorama %u ... \n', panoIdx);    
               fname = [num2strdigits(panoIdx,digits) '.jpg'];    
            %panoPath = getpathByPanoIdx(panoIdx(i),panoFolder,filesPerFolder,digitsPerFolder);
            %panoPath = [panoPath fname];
                 iim = panodata;%imread(panoPath); 
         end
         % Image shifting w.r.t. yaw and mapping from unit sphere grid to cylinder
             sw=iimw/2/pi;
             sh=iimh/pi;
            yaw=pano.yawRel(list(j));
            yaw=yaw/180*pi;
         if pano.pitch(list(j))==-04, THETA=Theta.pitch04; PHI=Phi.pitch04; end;
         if pano.pitch(list(j))==-28, THETA=Theta.pitch28; PHI=Phi.pitch28; end;
            THETA = THETA+yaw;
             idx  =  find(THETA<pi );  THETA(idx) =  THETA(idx)+2*pi;    % out of the left bound of pano image
             idx  =  find(THETA>=pi);  THETA(idx) =  THETA(idx)-2*pi;    % out of the right bound of pano image
             U=sw*THETA+iuc; 
             V=sh*PHI  +ivc;
           
             oim=iminterpnn(iim, U,V);
             if(~exist(cutoutpathcity,'dir'))
                  mkdir(cutoutpathcity);
             end
             fprintf('Saving cutout %s \n', [cutoutpathcity pano.fname{list(j)}]);
             imwrite(oim,[cutoutpathcity pano.fname{list(j)}],'jpg');      
     end %j-loop
     if exist('iim'), clear iim, end;
end% i-loop
res=1;
end %function
