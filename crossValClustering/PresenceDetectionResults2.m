% Edit: Carl Doersch (cdoersch at cs dot cmu dot edu) to use dswork to load the
% detection data efficiently.
classdef PresenceDetectionResults2 < handle
  % Class representing detection results.
  %
  % Author: saurabh.me@gmail.com (Saurabh Singh).
  properties
%    results;
%    resultsDir;
    myidx;
    mynumclusters;
    myiminds;
  end
  methods
    function obj = PresenceDetectionResults2(idx,numclusters,iminds)
      obj.myidx=idx;
      obj.myiminds=iminds;
      obj.mynumclusters=numclusters;
    end

    function result = getPosResult(obj, id)
      global ds;
      idx=find(obj.myiminds==id);
      %diskidx=(find(obj.myiminds==id)-1)*obj.mynumclusters+obj.myidx;
      %dsload(['ds.batch.round.topdetsmap{' num2str(diskidx) '}']);
      %result=ds.batch.round.topdetsmap{diskidx};
      %ds.batch.round.topdetsmap{diskidx}=[];
      tic
      dsload(['ds.batch.round.topdetsmap{' num2str(obj.myidx(:)') '}{' num2str(idx(:)') '}']);
      %dsload(['ds.batch.round.topdetsmap{' num2str(idx) '}']);
      %toc
      if((size(ds.batch.round.topdetsmap,2)>=idx))%&&(size(ds.batch.round.topdetsmap,1)>obj.myidx))
        %disp('got results')
        %numel(obj.myidx)
        for(i=1:numel(obj.myidx))
          if(size(ds.batch.round.topdetsmap,1)>=obj.myidx(i)&&~isempty(ds.batch.round.topdetsmap{obj.myidx(i),idx}))
            result(i)=ds.batch.round.topdetsmap{obj.myidx(i),idx};
          else
%          try
            result(i)=struct('scores',{[]},'imgIds',{[]},'meta',{[]});
 %           catch,keyboard;end
          end
        end
        ds.batch.round.topdetsmap={};
      else
        result=[];
      end

      %fileName = sprintf('%s/pos/%d_res.mat', obj.resultsDir, id);
      %result = loadAndCheck(fileName, 'detResults');
    end

    function result = getNegResult(obj, id)
      %fileName = sprintf('%s/neg/%d_res.mat', obj.resultsDir, id);
      %result = loadAndCheck(fileName, 'detResults');
      result=getPosResult(obj,id);%they use the same id scheme
    end

    function numClusters = getNumClusters(obj)
      %numClusters = length(obj.results.selectedClusters);
      %global ds;
      numClusters= numel(obj.myidx)%mynumclusters;%numel(ds.batch.round.selectedClust);
    end

    %function numPos = getNumPosResults(obj)
    %  numPos = length(obj.results.allPos);
    %end

    %function numNeg = getNumNegResults(obj)
    %  numNeg = length(obj.results.allNeg);
    %end
  end
end

