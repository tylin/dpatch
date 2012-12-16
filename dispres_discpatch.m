% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Generate a display using whatever data is in ds.bestbin.  At minimum
% this should include (1) a field ds.besbtin.alldiscpatchimg{} which is
% contains all patches to display, one per cell, (2) ds.bestbin.alldisclabel,
% which is two columns and a number of rows equal to the number of elemetns
% in alldiscpatchimg.  The first column is the image the patch came from,
% and the second is the detector id, and (3) ds.bestbin.tosave, which
% is a list of unique detectors to display.  Results are written to
% ds.bestbin.bbhtml.  

%gbz=globalz();
%dirs={'nnsave','nnsave_blur','nnsave_lsh','nnsave_lsh_sm','nnsave_lsh_lin'};
%dir='nnsave_lsh_itq';
%dirs={'nnsave_blur'};
%load(['nnsave/main.mat']);
%load(['nnsave/im2.mat']);
%load('disthist.mat');
%load([dir '/discpatch.mat']);
%load('dataset.mat')
%gbz=globalz();

html='<table>';
%html=[html '<tr><td>'];
%html=[html htmlfig('histfig')];

%html=[html '</td></tr>'];
%tosave=ds.bestbin.tosave;
relpath='.';
drdp_split=0;
if(dsbool(ds,'bestbin','splitflag'))
  drdp_split=1;
  relpath='../';
end
if(dsfield(ds,'bestbin','alldisclabel'))
  ds.bestbin.alldisclabelcat=cell2mat(ds.bestbin.alldisclabel);
end
if(numel(ds.bestbin.alldisclabelcat)==0)
  ds.bestbin.alldisclabelcat=zeros(0,5);
end
mytosave=ds.bestbin.tosave(find(ds.bestbin.isgeneral));
%mysaveprob=ds.bestbin.saveprob(ds.bestbin.isgeneral);
htmlall={};
drdp_ct=0;
for(drdp_j=mytosave(:)')
  drdp_ct=drdp_ct+1;
  html=[html htmlpatchrow(ds,drdp_j,relpath,'')];%'border:solid 2px #000;width:300px;')];
  if(drdp_split&&mod(drdp_ct,20)==0)
    html=[html '</table>'];
    disp(drdp_ct)
    htmlall{end+1}=html;
    html='<table>';
  end
  %if(numel(lsh.lsh)>1)
  %  html=[html '<td> paris:' num2str(lsh.lsh{1}.counts(j,1)) ' non:' num2str(lsh.lsh{2}.counts(j,1)) '</td>'];
  %else
  %  html=[html '<td> patches:' num2str(lsh.lsh{1}.counts(j,1)) '</td>'];
  %end
  %marks=(alldisclabelcat(:,5)==j);
  %patches=find(marks);%alldiscpatch(:,:,:,marks);
  %if(isempty(patches))
  %  continue;
  %end
  %clf;
  %for(k=numel(patches):-1:1)
  %  html=[html imgtd(['alldiscpatchimg[]/' num2str(patches(k))])];
  %end
  %html=[html '</tr>'];
end
html=[html '</table>'];
if(drdp_split)
  htmlall{end+1}=html;
  {'ds.bestbin.bbhtml','htmlall'};dsup;
else
  {'ds.bestbin.bbhtml','html'};dsup;
end
%if(dsfield(ds,'savestate','bestbin','bbhtml'))
%  ds.savestate.bestbin.bbhtml=0;
%end
%ds.bestbin.bbhtml=html;
