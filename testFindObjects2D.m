%% Generate a default RGB image to quantify
Img = imread('coins.png');  % load a default image of coins
Img = cat(3, Img, Img,Img); % convert to RGB
Settings.objfinder.noiseEstimator = 'std';
Settings.objfinder.maxDotSize = inf; 
Settings.objfinder.minDotSize = 10; 
Settings.objfinder.minIntensity = 2;
Settings.objfinder.watershed = false;

%% Run findObjects2D and display segmentation results
Dots = findObjects(Img, Settings);
% show the original image on left panel
subplot(1,2,1);
imshow(Img);

% show the masked pixels on the right channel
subplot(1,2,2);

