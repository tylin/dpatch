 % Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
 % 
 % close a distributed processing session.

 function dsmapredclose()
   global ds;
   cmd=struct();
   cmd.name='exit';
   for(i=1:numel(ds.sys.distproc.commlinkslave))
     save(ds.sys.distproc.commlinkslave{i},'cmd');
   end
   disp('waiting for mapreducers to exit...');
   exited=zeros(numel(ds.sys.distproc.commlinkmaster),1);
   nwaits=0;
   while(~all(exited))
     for(i=1:numel(ds.sys.distproc.commlinkslave))
       res=dstryload(ds.sys.distproc.commlinkmaster{i});
       if((~isempty(res))&&strcmp(res.name,'exited'))
         exited(i)=1;
       end

     end
     if(~all(exited))
       pause(3);
       nwaits=nwaits+1;
       disp([num2str(numel(exited)-sum(exited)) ' still need to exit...']);
       if(nwaits==20)
         disp('maybe we''re stuck on interrupts. trying to remove them.');
          for(i=1:numel(ds.sys.distproc.commlinkinterrupt))
            if(exist(ds.sys.distproc.commlinkinterrupt{i},'file'))
              delete(ds.sys.distproc.commlinkinterrupt{i});
            end
          end
       end
       if(nwaits>30)
         disp('waited too long, giving up.');

         break;
       end
     end
   end
   disp('done');
   ds.sys.distproc.isopen=0
end

