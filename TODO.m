%% ---- Manual identification of follicles via GUI ------------------------
%
% + Debugging
%
%% ----- Calibration of images using anatomical features ------------------
%
% + Use tarsal gland ducts opening size (constant) to calibrate images
% |- Find in the medical literature the diameter of these ducts +-SEM
% |- Implement a third manual segmentation mode for these ducts
% |- Automatize identification of ducts using findObjects() or NeuralNet 
% |- Ensure these ducts are visible in all photos taken
% |- Don't process age information of the patient if this feat is universal
%
% + Use eyelash thickness
% |- Find in the medical literature how eyelash thickness changes with age
% |- Investigate if there is a way to automatize detection
% |- Create a look up table of eyelash thickness per age
% |- We will need age information to be associable with each image
%
% + Use eyelid size
% |- Find in the medical literature how eyelid size changes with age
% |- Stratify this information by ethnicity (caucasian vs asian etc..)
% |- Create a look up table of expected eyelid size per age per ethnicity
% |- We will need age information to be associable with each image
%
%% ----- Automatic eyelid segmentation  -----------------------------------
%
% + Generate a pixel classifier to detect the eyelid region in photos
% |ND Start by manually find the area of interest in the ground truth photos
% |ND Look in MATLAB's computer vision toolbox for net architecture
% |- Store labels in the format required for training pixel classifiers
% |- If no good, convert PlOS2019 net architecture (on Travis' GitHub)
% |- For each eyelid, make sure to store orientation of major axis
% |- For each eyelid, store perimeter (will be used later to measure dists)
%
%% ----- Automatic follicles segmentation ---------------------------------
%
% + Refactor findObjects() from ObjectFinder to work on 2D RGB images
% |- Isolate the function from ObjectFinder
% |- Generate a GUI tab to allow user to set findObjects() search settings
% |- Adapt the output of findObjects() to be compatible with Follicles
%
% + Generate a pixel classifier to detect the eyelid region in photos
% |- Start by manually find the area of interest in the ground truth photos
% |- Look in MATLAB's computer vision toolbox for net architecture
% |- If no good, convert PlOS2019 net architecture (on Travis' GitHub)
% |- For each eyelid, make sure to store orientation of major axis
% |- For each eyelid, store perimeter (will be used later to measure dists)
%
% + Find best settings for findObjects() to detect all potential follicles
% |- Manually try multiple settings across images
% |- If no single set of settings work for all, implement a best estimator
%
% Simplify findObjects and use it for automatic segmentation
%
%% ----- Automatic validation of follicle candidates ----------------------
%
% + Create a classifier using the WHO criteria for follicle identification
% |-- Follicle size >= 5mm (check with Tom his latest standard)
% |-- Follicle color off-white (find examples of white and yellow false+)
% |-- Uniform distance between follicles
% |-- Soft edges
%
% + Create a deep learning classifier to determine the follicle type
% |-- Implement transfer training of AlexNet, GoogleNet, VGG-16 models
% |-- Define multiple categories of follicles (False, TF, TS)
%
%% ----- Automatic diagnosis of disease in each photo ---------------------
%
% + Make a routine that checks all validated follicles in the image for
% |-- TF if total number of validated follicles >= 5
% |-- TF if is also the most probable class from the deep-learning network
% |-- TI if no more blood vessels are visible due to inflammation
% |-- TS if the most probable class from deep-learning network
%
