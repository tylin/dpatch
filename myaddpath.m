% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% set up the matlab path if it hasn't been done yet.
function myaddpath(force)
%there's really no easier way to check if this function has been called?
%if(nargin>0||numel(strfind(path,'crossValClustering'))==0)
  addpath('dswork');
  addpath('crossValClustering');
  addpath('GSwDownloader');
  addpath('html');
  addpath('hog');
  addpath('MinMaxSelection');
  libHome='/home/gen/';
  if(strcmp(libHome,'PATH_TO_LIBSVM'))
    error('set libsvm path in myaddpath.m!!');
  end
  addpath([libHome 'libsvm-mat-3.0-1/']);%3.0-1 is the release we used
%end
