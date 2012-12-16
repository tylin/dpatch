% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% 
% Move a variable or set of variables from one location to another within
% the ds struct.  The syntax is similar to unix mv.  src can be a variable
% or set of variables (absolute or relative paths, *-wildcards supported, no 
% bracket indexing).  dest can be an absolute or relative path, either specifying
% an existing struct within the
% ds (in which case all src variables are moved into that struct), or a path/name that
% does not yet exist, in which case the variable will be renamed.  Changes in the
% workspace are mirrored on disk if the variable appears on disk, and dsmv will still
% function if the variables are not loaded in memory.

function dsmv(src,dest)
  global ds;
  src=dsexpandpath(src);
  try
    for(i=1:numel(src))
      [pathsrc{i},~,srctype]=dsdiskpath(src{i});
      if(~isempty(pathsrc{i}))
        [tmppathdest, pathexist, desttype]=dsdiskpath(dest,true);
        %if(isempty(pathdest))
        %  dotpos=find(desc=='.');
        %  dotpos=dotpos(end);
        %  pathdest=dsdiskpath(dest(1:(dotpos-1));
        %end
        if(pathexist&&strcmp(desttype,'struct'))%in this case, we move the results into the struct
          for(j=1:numel(pathsrc{i}))
            fnam=pathsrc{i}{j};
            spos=find(fnam=='/');
            fnam=fnam((spos(end)+1):end);
            pathdest{i}{j}=[tmppathdest{1} filesep fnam];
          end
        else
          if(numel(src)>1)
            %if we get here, we can't have made any filesystem changes yet
            throw MException('ds:cantmove','cant move multiple ds variables to a single result variable');
          end
          if(pathexist)%we're overwriting something
            for(j=1:numel(tmppathdest))
              %TODO: come up with a way to recover this stuff on error
              delete(tmppathdest{j});
            end
          end
          pathdest{i}=dsdiskpath(dest,true,srctype);
          if(isempty(pathdest{i}))
            throw(MException('ds:cantmove',['cannot move to ' dest '. No such path in dswork.']));
          end
          



        %if(pathexist&&strcmp(desttype,'cell'))%in this case, we need to delete what's there or movefile will do the wrong thing
        %  delete(tmppathdest{1});
        %  pathdest{i}=tmppathdest;
        %else
        %  pathdest{i}=tmppathdest;
        end

        %for(i=1:numel(pathsrc))
        %  if(numel(pathdest)>1)
        %    resnm=pathdest{i};
        %  else
        %    resnm=pathdest{1};
        %  end
        movedidx=0;
        for(j=1:numel(pathsrc{i}))
          movefile(pathsrc{i}{j},pathdest{i}{j});
          movedidx=movedidx+1;
        end
      else
        pathdest{i}=[];
      end
    end
    if(dsfield(ds,'sys','currpath'))
      origcurrpath=ds.sys.currpath;
    else
      origcurrpath='';
    end
    origcurrpath=['ds' origcurrpath];
    absdest=dsabspath(dest)
    absdest=absdest(4:end);
    for(i=1:numel(src))
      abssrc{i}=dsabspath(src{i});
      abssrc{i}=abssrc{i}(4:end);
    end
    dscd('.ds');
    ds2=ds;
    sys=ds.sys;
    if(isempty(absdest)||(dsfield(ds2,absdest(2:end))&&eval(['isstruct(ds2' absdest ')'])))
      for(i=1:numel(src))
        fnam=src{i};
        dotpos=find(fnam=='.')
        fnam=fnam((dotpos(end)+1):end);
        absdest2{i}=[absdest '.' fnam];
      end
    else
      if(numel(abssrc)>1)
        throw MException('ds:cantmove','cant move multiple ds variables to a single result variable');
      end
      absdest2{1}=absdest;
    end
    for(i=1:numel(src))
      if(dshasprefix(absdest2{i},abssrc{i})&&...
         ((numel(abssrc{i})==numel(absdest2{i}))||(absdest2{i}(numel(abssrc{i})+1)=='.')))
        disp(['cannot move ' abssrc{i} ' into a substructure of itself']);
        continue;
      end
      absdest2{i}
      abssrc{i}
      eval(['ds2' absdest2{i} '=ds2' abssrc{i} ';']);
      if(dsfield(sys,['savestate' abssrc{i}]))
        movesst=1;
      else
        movesst=0;
      end
      if(movesst)
        eval(['sys.savestate' absdest2{i} '=sys.savestate' abssrc{i} ';']);
      elseif(dsfield(sys,['savestate' absdest2{i}]))
        dp2=find(absdest2{i}=='.');
        destvarparent=absdest2{i}(1:(dp2(end)-1));
        eval(['sys.savestate' destvarparent '=rmfield(sys.savestate' destvarparent ',''' absdest2{i}((dp2(end)+1):end) ''')']);
      end
      matchstr=abssrc{i};
      dotpos=find(matchstr=='.');
      dotpos=dotpos(end);
      parent=matchstr(1:(dotpos-1))
      child=matchstr((dotpos+1):end)
      eval(['ds2' parent '=rmfield(ds2' parent ',''' child ''')']);
      if(movesst)
        eval(['sys.savestate' parent '=rmfield(sys.savestate' parent ',''' child ''')']);
      end
      if(dshasprefix(origcurrpath,['.' abssrc{i}]))
        origcurrpath=[absdest2{i} origcurrpath(numel(abssrc{i})+2:end)];
      end

    end
    ds=ds2;
    ds.sys=sys;
    dscd(origcurrpath);
  catch ex
    le=lasterror;
    moveback=1'
    dsprinterr;
    try
    dscd(origcurrpath);
    catch
    end
    if(moveback&&exist('movedidx','var'))
      for(j=movedidx:-1:numel(pathsrc{i}))
        movefile(pathdest{i}{j},pathsrc{i}{j});
      end
    end
  end
end
