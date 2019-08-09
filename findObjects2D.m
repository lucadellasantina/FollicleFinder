%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%
%  This file is part of Follicle Finder
%
%  Follicle Finder is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <https://www.gnu.org/licenses/>.
%

function Dots = findObjects2D(I, Settings)
%% -- STEP 1: Estimate background level and initialize variables

Img = rgb2gray(I(:,:,1:3)); %Convert the image to BW from RGB by averaging

% Estimate either background level (Gmode) according to setting
switch Settings.objfinder.noiseEstimator
    case'mode', Gmode = mode(Img(Img>0)); % Most common intensity (excluding zero)                
    case 'std', Gmode = uint8(ceil(std(single(Img(:))))); % Standard deviation of intensities       
    case 'min', Gmode = min(Img(:)); % Absolute minimum intensity
    otherwise,  Gmode = 0;
end
Gmax          = max(Img(:));
sizeIgm       = [size(Img,1), size(Img,2)];
peakMap       = zeros(sizeIgm(1), sizeIgm(2),'uint8'); % Initialize matrix to map peaks found
thresholdMap  = peakMap; % Initialize matrix to sum passed thresholds
Igl           = [];

%% -- STEP 2: scan the volume and find areas crossing local contrast threshold with a progressively coarser intensity filter --
tic;
fprintf('Searching candidate objects... ');
maxDotSize       = Settings.objfinder.maxDotSize; 
minDotSize       = Settings.objfinder.minDotSize; 
minIntensity     = Settings.objfinder.minIntensity;

% Scan volume to find areas crossing contrast threshold with progressively coarser intensity filter
% Iterating from Gmax to noise level (Gmode+1) within each block
for i = Gmax :-1: ceil(Gmode * minIntensity)+1
%for i = ceil(Gmode * minIntensity)+1
    
    % Label all areas in the block (Igl) that crosses the intensity "i"
    % bwconncomp+labelmatrix is ~10% faster than using bwlabeln
    CC     = bwconncomp(Img >= i,6);
    labels = CC.NumObjects;
    Igl    = labelmatrix(CC);
    
    % Find peak location in each labeled object and check object size
    nPixel = 0; %#ok needed to avoid parfor warning of not-initialized
    switch labels
        case 0,     continue
        case 1,     nPixel = numel(CC.PixelIdxList{1});
        otherwise,  nPixel = hist(Igl(Igl>0), 1:labels); %#ok use old function hist
    end
    
    for p = 1:labels
        pixelIndex = CC.PixelIdxList{p}; % 50% faster than find(Igl==p)
        NumPeaks = sum(peakMap(pixelIndex));
        
        if (nPixel(p) <= maxDotSize) && (nPixel(p) >= minDotSize)
            if NumPeaks == 0
                peakValue = max(Img(pixelIndex));
                peakIndex = find(Img(pixelIndex)==peakValue);
                if numel(peakIndex) > 1
                    % limit one peak per label (where Igl==p)
                    peakIndex = peakIndex(round(numel(peakIndex)/2));
                end
                peakMap(pixelIndex(peakIndex)) = 1;
            end
        else
            Igl(pixelIndex) = 0;
        end
    end % for all labels
    
    % Add +1 to the threshold of all voxels that passed this iteration
    ValidVox = Igl>0;
    thresholdMap(ValidVox) = thresholdMap(ValidVox)+1;
end % for all intensities

wsTMLabels    = Igl;                  % wsTMLabels = block volume labeled with same numbers for the voxels that belong to same object
wsLabelList   = unique(wsTMLabels);   % wsLabelList = unique labels list used to label the block volume
nLabels       = numel(wsLabelList);   % nLabels = number of labels = number of objects detected

fprintf(['DONE in ' num2str(toc) ' seconds \n']);

%% -- STEP 3: Find countours and split using watershed if multiple peaks are found within the same dot --

tic;
if Settings.objfinder.watershed
    fprintf('Split multi-peak objects using watershed segmentation ... ');
    use_watershed = true;
else
    fprintf('Watershed DISABLED by user, collecting candidate objects... ');
    use_watershed = false;
end

if use_watershed
    wsTMapBin       = uint8(thresholdMap>0);            % Binary map of thresholded voxels
    wsTMapBinOpen   = imdilate(wsTMapBin, ones(3,3,3)); % Dilate map with a 3x3x3 kernel (dilated perimeter acts like ridges between background and ROIs)
    wsTMapComp      = imcomplement(thresholdMap);       % Complement (invert) image. Required because watershed() separate holes, not mountains. imcomplement creates complement using the entire range of the class, so for uint8, 0 becomes 255 and 255 becomes 0, but for double 0 becomes 1 and 255 becomes -254.
    wsTMMod         = wsTMapComp.*wsTMapBinOpen;        % Force background outside of dilated region to 0, and leaves walls of 255 between puncta and background.
    wsTMLabels      = watershed(wsTMMod, 6);            % 6 voxel connectivity watershed (faces), this will fill background with 1, ridges with 0 and puncta with 2,3,4,... in double format
    wsBkgLabel      = mode(double(wsTMLabels(:)));      % calculate background level
    wsTMLabels(wsTMLabels == wsBkgLabel) = 0;           % seems that sometimes Background can get into puncta... so the next line was not good enough to remove all the background labels.
else
    wsTMLabels = bwlabeln(thresholdMap, 6);   % 6 voxel connectivity without watershed on the original threshold map.
end

wsLabelList   = unique(wsTMLabels);
wsTMLabels    = uint16(wsTMLabels);
wsLabelList   = wsLabelList(2:end); % Remove background (1st label)
nLabels       = length(wsLabelList(2:end));

fprintf(['DONE in ' num2str(toc) ' seconds \n']);

%% -- STEP 4: calculate dots properties and store into a struct array --
% TODO only thing we need to accumulate is tmpDot.Vox.Ind, all rest of the
% stats can be calculated later after resolving conflicts

tic;
fprintf('Accumulating properties for each detected object... ');

tmpDot               = struct;
tmpDot.Pos           = [0,0];
tmpDot.Vox.Pos       = 0;
tmpDot.Vox.Ind       = 0;
tmpDot.Vox.RawBright = [0 0 0];
tmpDot.Vox.MeanBright= 0;
tmpDot.Vox.IT        = 0;
tmpDot.Vox.ITMax     = 0;
tmpDot.Vox.ITSum     = 0;
tmpDot.Vol           = 0;

% Count how many valid objects we expect to encounter
NumValidObjects = 0;
VoxelsList  = label2idx(wsTMLabels);
for i = 1:nLabels
    % Ensure watershed multi-peak objects are bigger then minDotSize
    if numel(VoxelsList{i}) >= minDotSize
        NumValidObjects = NumValidObjects+1;
    end
end

if NumValidObjects == 0
    disp('No valid objects');
    Dots = [];
    return;
else
    tmpDots(NumValidObjects) = tmpDot; % Preallocate tmpDots
end

tmpDotNum = 0;
VoxelsList = label2idx(wsTMLabels);

for i = 1:nLabels
    Voxels = VoxelsList{i};
    
    % Accumulate only if object size is within minDotSize/maxDotSize
    if numel(Voxels) >= minDotSize
        peakIndex = Voxels(peakMap(Voxels)>0);
        if isempty(peakIndex)
            continue % There is no peak for the object (i.e. flat intensity)
        else
            peakIndex           = peakIndex(1); % Make sure there is only one peak at this stage
        end
        
        [yPeak,xPeak]       = ind2sub(sizeIgm, peakIndex);
        [yPos, xPos]        = ind2sub(sizeIgm, Voxels);
        
        tmpDot.Pos          = [yPeak, xPeak];
        tmpDot.Vox.Pos      = [yPos,  xPos];
        tmpDot.Vox.Ind      = Voxels;
        for k = 1:size(tmpDot.Vox.Pos, 1)
        	tmpDot.Vox.RawBright(k, :) = I(tmpDot.Vox.Pos(k,1), tmpDot.Vox.Pos(k,2),:); 
        end
        %tmpDot.Vox.RawBright= I(yPos,  xPos, :);
        tmpDot.Vol          = size(unique(tmpDot.Vox.Pos(:, 1:2), 'rows'),1); % Use only X,Y data to measure how many pixels (3rd dimension = color)
        tmpDot.Vox.IT       = thresholdMap(Voxels);
        
        tmpDotNum           = tmpDotNum + 1;
        tmpDots(tmpDotNum)  = tmpDot;
    end
end

fprintf(['DONE in ' num2str(toc) ' seconds \n']);

%% -- STEP 5: Accumulate tmpDots with volume>0 into the "Dots" structure 
tic;
fprintf('Pack detected objects into an easily searchable structure... ');

ValidDots = find([tmpDots.Vol] > 0);
Dots = struct; 
for i = numel(ValidDots):-1:1
    Dots.Pos(i,:)           = tmpDots(ValidDots(i)).Pos;
    Dots.Vox(i).Pos         = tmpDots(ValidDots(i)).Vox.Pos;
    Dots.Vox(i).Ind         = tmpDots(ValidDots(i)).Vox.Ind;
    Dots.Vox(i).RawBright   = tmpDots(ValidDots(i)).Vox.RawBright;
    Dots.Vox(i).IT          = tmpDots(ValidDots(i)).Vox.IT;
    Dots.Vox(i).ITMax       = max(tmpDots(ValidDots(i)).Vox.IT);
    Dots.Vox(i).ITSum       = sum(tmpDots(ValidDots(i)).Vox.IT);
	Dots.Vox(i).MeanBright  = mean(tmpDots(ValidDots(i)).Vox.RawBright);
    Dots.Vol(i)             = tmpDots(ValidDots(i)).Vol;
end

Dots.ImSize = [size(Img,1) size(Img,2) size(Img,3)];
Dots.Num = numel(Dots.Vox); % Recalculate total number of dots
fprintf(['DONE in ' num2str(toc) ' seconds \n']);

clear B* CC contour* cutOff debug Gm* i j k Ig* labels Losing* ans NumalidObjects
clear max* n* Num* Overlap* p peak* Possible* size(Post,2) size(Post,1) size(Post,3) Surrouding*
clear tmp* threshold* Total*  v Vox* Winning* ws* x* y* z* itMin DotsToDelete
clear block blockBuffer blockSize minDotSize minDotSize  MultiPeakDotSizeCorrectionFactor
clear ContendedVoxIDs idx Loser Winner minIntensity use_watershed ValidDots blockSearch
end
