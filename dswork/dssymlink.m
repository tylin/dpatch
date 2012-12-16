% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% create a symlink in the persisted ds structure.  dsvar is
% a relative path to a single variable.  That variable will be stored at targpath
% and symlinked to the proper location in ds.sys.outdir.  This function will save the
% minimum amount of data to disk that is required for the symlink to point to something
% valid.  If the target specified by dsvar has already been saved, all previously
% saved contents will be moved.  If the target does not exist on disk or in memory,
% it will be created as a struct before the symlinking occurrs.  targpath should
% be a path on disk, outside of ds.sys.outdir.
%
% For example, say ds is the following
%
% ds - struct1
%    - struct2 - field1 (a cell array)
%              - field2 (an int)
%
% dssymlink('ds.struct2.field2','/nfs/hdisk') will result in a symlink
% [ds.sys.outdir '/ds/struct2/field2.mat'] -> '/nfs/hdisk/field2.mat', and 
% /nfs/hdisk/field2.mat will contain the data for field2.
%
% dssymlink('ds.struct2.field1','/nfs/hdisk') will result in a symlink
% [ds.sys.outdir '/ds/struct2/field2[]'] -> '/nfs/hdisk/field2[]', and 
% /nfs/hdisk/field[] will be a directory.  If field1 has been saved previously,
% all files in [ds.sys.outdir '/ds/struct2/field2[]'] will be moved to
% /nfs/hdisk/field2[].  Otherwise the next call to dssave will
% cause the contents of field1 to be saved in /nfs/hdisk/field1[]
%
% dssymlink('ds.struct2','/nfs/hdisk') will result in a symlink
% [ds.sys.outdir '/ds/struct2'] -> '/nfs/hdisk/struct2', and 
% /nfs/hdisk/struct2 will be a directory.  Contents of 
% [ds.sys.outdir '/ds/struct2/'] will be moved to
% /nfs/hdisk/struct2. Any unsaved variables will be saved to 
% /nfs/hdisk/struct2 at the next call to dssave. 
%
% Note that once a symlink has been created, it will be more-or-less 'forgotten'
% internally by dswork.
%
function dssymlink(dsvar,targpath)
  global ds;
  %dssave(dsvar);
  mymkdir(targpath);
  if(targpath(end)=='/')
    targpath=targpath(1:(end-1));
  end
  %dotpos=find(dsvar=='.');
  %ds_suffix=dsvar((dotpos(1)+1):end);
  dsfoundvar=dsfindvar(dsvar);
  if(~dsfield(ds,dsfoundvar(4:end)))
    eval([dsfoundvar '=struct();']);
  end
  %srcnm=dsvar;
  %srcnm(dotpos)='/';
  %pathtovar=[ds.sys.outdir srcnm];
  savestnam=dsabspath(dsvar);
  [pathtovar pathexists]=dsdiskpath(savestnam,true);
  savnm=['ds.sys.savestate' savestnam(3:end)];
  if(pathexists)
    namstomove=pathtovar;
    for(i=1:numel(namstomove))
      if(~unix(['[[ -h ' namstomove{i} ' ]]']))
        disp(['warning: ' namstomove{i} ' is already a symlink...and there''s stuff saved there.  Not sure what to do.']);
        keyboard;
        %unix(['rm ' namstomove{i}]);
      end
      spos=find(namstomove{i}=='/');
      disknams{i}=namstomove{i}((spos(end)+1):end);
      disp(['moving ' disknams{i} '...']);
      movefile(namstomove{i},targpath);
      disp('1')
      ['ln -s ' targpath '/' disknams{i} ' ' namstomove{i}]
      unix(['ln -s ' targpath '/' disknams{i} ' ' namstomove{i}]);
    end 
  else
    for(i=1:numel(pathtovar))
      dotpos=find(pathtovar{i}=='/')
      if(numel(dotpos)>0)
        varnm=pathtovar{i}((dotpos(end)+1):end)
      else
        varnm=pathtovar{i}%this case may not actually be possible...
      end
      if(numel(savnm)>3&&~dsfield(ds,[savnm(4:end)]))
        eval([savnm '=struct()']);
      end
      mymkdir([targpath '/' varnm]);
      if(~unix(['[[ -h ' pathtovar{i} ' ]]']))
        disp(['warning: ' pathtovar{i} ' is already a symlink (though it was not found in the savestate). Replacing.']);
        unix(['rm ' pathtovar{i}]);
      end
      ['ln -s ' targpath '/' varnm ' ' pathtovar{i}]
      unix(['ln -s ' targpath '/' varnm ' ' pathtovar{i}]);
    end
  end
end
