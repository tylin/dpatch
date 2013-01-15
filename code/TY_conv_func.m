function [feat, imsize] = TY_conv_func(imPaths, modelPath, params, TYPE);
%   img:    the input image
%   npatch: n models
%   params: the params from DPatch discovery code

setmeup;

% set type: recommend: UNENTANGLE
TYPE = 'UNENTANGLE';
% TYPE = 'CONV'
if nargin == 0
    %% load test model
    imPaths = {'image_0024_cal_suburb.jpg'};
    modelPath = 'Cal_suburb.mat';  
    %% load detectors
    %% set params
    %parameters for Saurabh's code
    params= struct( ...
      'imageCanonicalSize', 400,...% images are resized so that their smallest dimension is this size.
      'patchCanonicalSize', {[80 80]}, ...% patches are extracted at this size.  Should be a multiple of sBins.
      'basePatchSize', {[80 80]}, ...% patches are extracted at this size.  Should be a multiple of sBins.
      'scaleIntervals', 1, ...% number of levels per octave in the HOG pyramid 
      'sBins', 8, ...% HOG sBins parameter--i.e. the width in height (in pixels) of each cell
      'useColor', 1, ...% include a tiny image (the a,b components of the Lab representation) in the patch descriptor
      'patchOverlapThreshold', 0.6, ...%detections (and random samples during initialization) with an overlap higher than this are discarded.
      'svmflags', '-s 0 -t 0 -c 0.1', ...
      'numLevel', 3);
end

%% load image and detectors
load([USR.modelDir modelPath], 'data1'); detectors = data1; detectors.params.basePatchSize = [80,80];
img = im2double(imread([USR.imgDir, imPaths{1}]));
data = prepareDataForPaths(USR.imgDir, imPaths);
npatch = detectors.firstLevModels;
%% process starts
detParams = getBaseDetectionParams();
detParams.useDecisionThresh = true;
detParams.fixedDecisionThresh = -.1002;
switch TYPE
    case 'CONV'
        detectors = load(modelPath); % detector can be found at ds.batch.round{k}.detectors.mat
        tic
        feats = constructFeaturePyramidForRawImg(img, params, []);  % reuse the code from dpatch    
        for numDet = 1 : size(npatch.w, 1)
            w = reshape(full(npatch.w(numDet,:)), [8,8,33]);  % current patch discovery code has 31 (hog) + 2 (color) dims features
            rho = npatch.rho(numDet);
            numDim = size(feats.features{1}, 3);
            %% tylin's detection
            numDim = size(w, 3);
            for lev = 1 : length(feats.scales)
                row = size(feats.features{lev}, 1);
                col = size(feats.features{lev}, 2);

                res{lev} = zeros(row, col);
                imfft = fft2(feats.features{lev}, row, col);
                for i = 1 : numDim
                    tmp  = conv2(feats.features{lev}(:,:,i), w(:,:, i), 'same');
                    res{lev} = res{lev} + conv2(feats.features{lev}(:,:,i), w(:,:, i), 'same');
                end
                res{lev} = res{lev} - rho * ones(size(res{lev}));
            end
            % output feat:
            % feat{# of det}.svmout{# of pyramid level}
            feat{numDet}.svmout = res;
        end
        toc
    case 'UNENTANGLE'
        % Run the detectors.
        res = detectors.detectPresenceInImg(data(1), USR.imgDir, true, detParams);

        %% Display the detections

        d = res.firstLevel.detections;
        clf;
        I = imread([USR.imgDir imPaths{1}]);
        imshow(I);
        for i = 1 : length(d)
          if isempty(d(i).metadata)
            continue;
          end
          displayPatchBox(d(i).metadata, d(i).decision);
        end
        
        %% visualization heat map
        figure(2);
        for i = 1 : length(d)
            feat{i}.svmout = d(i).heatmap;
        end
end

%% visualization
for i = 1 : length(feat)
    imagesc(feat{i}.svmout{1});
    colorbar();
    wait = waitforbuttonpress;
end


end