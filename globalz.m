% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% generate a descriptor for the image dataset.  See the 
% README for info on how to configure this file.  The
% current implementation of this file is just an example
% of how to implement this; res.root isn't actually
% used anywhere in the code.

function res=globalz(setnum)
    %this is the root directory where all the data is, so
    %we can append shorter strings to reference individual datasets.
    res.root='/PATH/TO/ROOT/DIRECTORY';

    %figure out which set we're dealing with; in this example, dataset number 7
    if(setnum==7)
      ctrelname='data7/';
      %this is a path in the current directory, containing the imgs
      %structure with pointers to all the cutouts
      res.datasetname='dataset7.mat';
    else
      disp('no such dataset');
      return;%return without assignign res; throws exception
    end

    %path to the place to store downloaded data, including panoramas and
    %cutouts
    res.downloaddir=[res.root filesep ctrelname];

    %path to store the cutouts from the panoramas, which are pointed to
    %inside of the imgs structure.
    res.cutoutdir=[res.root filesep ctrelname 'cutouts/'];

    %the url where the cutouts can be found online. optional; used only in links in html displays.
    res.imgsurl=['http://your.domain/WEB/ACCESSIBLE/PATH/' ctrelname 'cutouts/'];
end
