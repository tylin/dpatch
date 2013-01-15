%% Do detection of discriminative patches.
% Author: saurabh.me@gmail.com (Saurabh Singh).

setmeup;
% Load up the models.

% load([USR.modelDir 'pascal.mat'], 'detectors');
load([USR.modelDir 'Cal_suburb.mat'], 'data1'); detectors = data1; detectors.params.basePatchSize = [80,80];
% load([USR.modelDir 'Forest.mat'], 'data1'); detectors = data1; detectors.params.basePatchSize = [80,80];

%% Load up the image.

% imPaths = {'1.jpg'};
imPaths = {'image_0024_cal_suburb.jpg'};
data = prepareDataForPaths(USR.imgDir, imPaths);

%% Run the detectors.
% Construct detection parameters.
detParams = getBaseDetectionParams();
detParams.useDecisionThresh = true;
detParams.fixedDecisionThresh = -.1;

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
    imagesc(d(i).heatmap{1});
    colorbar();
    wait = waitforbuttonpress;
end
