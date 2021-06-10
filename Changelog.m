%% Trachoma Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019-2020 Luca Della Santina
%
%% ChangeLog
%
% Version 2.11 - created on 2021-06-09
% 
% + Generate training data: Blur outside eyelid for image classifiers
% + Export masked eyelid/follicles with optional blurring in the surrounds
%
% Version 2.10 - created on 2021-06-02
% 
% + New Net type: Image Classifier
% + New Net target: TF (to use with image classifiers)
% + New Grad-Cam exploration of net activation heatmaps
% + New ImageLIME exploration of net activation
% + New occlusion sensitivity exploration of net activation
%
% Version 2.9 - created on 2021-05-10
% 
% + App ported to MATLAB R2021a, now required
% + New Backup annotations button
% + listTraining now fully loads .mat files to avoid corruption
%
% Version 2.8 - created on 2020-11-18
% 
% + App ported to MATLAB R2020b, now required
% + Single instance enforced
% + Custom app icon
% + Import B/W images and automatically convert them to RGB
% + Fixed error if user cancels photo folder selection
%
% Version 2.7 - created on 2020-09-05
% 
% + inspectPhoto: Diagnosis UI changed from combobox to listbox
% + Import record: Progress dialog with verbose info
%
% Version 2.3 - created on 2020-03-23
% 
% + Adjustable neural net confidence P level
% + Test network saves the original raw image along with predictions
%
% Version 2.2 - created on 2020-03-22
% 
% + Unified eyelid and follicles agreement comparison
% + Agreement comparison uses Intraclass Correlation Coefficient (ICC)
% + Simplified UI removing bottom bar, merged auto and manual detection tab
% + User can choose which images to review from a list
% 
% Version 2.1 - created on 2020-03-10
% 
% + Fixed U-Net training parameters
% + Added DeepLab v3+ neural net for semantic segmentation
% + Version number automatically retrieved from FollicleFinder properties
%
% Version 2.0 - created on 2019-10-07
%
% + Licensed under the GNU General Public License v3 (GPLv3)
% + Automatic follicle finder using findObjects2D iterative thresholding
% + Added individual grading for each disease hallmark (F,P,C,TE,CC)
% + Added diagnosis type (TNormal,TF,TI,TF+TI,TS,TT,CO) for each image
% + Removed tarsal duct detection (need to use different method to calib)
% + Stored R,G,B pixel brightness of each masked object in Vox.RawBright
% + inspectPhoto fixed redraw glitches when mouse is closed to img border
% + Common framework to store / train / test neura networks
% + Design NeuralNet architecture using Deep Network Designer
% + Import NeuralNet layers from base workspace into selected NeuralNet
% + Raw brightness values are not stored when segmenting eyelids
% + New Magic Wand tool adds new Follice based on color space difference
% + Fixed mismatch cursor position when using mouse wheel to change brush
% + Hid brush when using refine tool
% + Tool: batch image resize tool
% + Tool: Create eyelid masks as TIF images
% + Tool: Save individual follicles as TIF images
% + Tool: Create follicles mask as TIF images
% + Tool: Save follicle bounding box coordinates into excel tables
% + Tool: Relink images folder to a new location
% + Tool: Merge records
% + Tool: Clear eyelid or follicles record
% + Export copy of selected Training / NeuralNet to a custom folder
% + Import saved training file into the local repository
% + Fixed calculation of animatedline thickness
% + Fixed error calculating PosRect when using ZoomIn/Out buttons
% + validatePath methods provides platform independent path validation
% + Refresh table button always available at bottom left corner of the UI
% + Handle multiple record selection in table
% + Added "ungradable" among diagnosis values when photo quality too low
% + Duplicate selected training recor
% + Automatic detection - Detect eyelid 
% + Import neural network from file
% + Consistent use of word photos across the application
% + Automatic follicle detection does NOT shuffle filenames order
% + Faster RGB values extraction in inspectPhoto and findObject2D
% + New Pixel classifier net: FCN-AlexNet
% + Fixed error when trying to enclose region with only 1 pixel
% + Converted all confirmation dialog using new UI interface
% + Fixed error when manually reviewing eyelid nothing was selected
% + Added progressbars for manually grading images
% + Neural net table is sorted by name
% + Compare multiple neural nets
%
% Version 1.2 - created on 2019-06-08
%
% + Custom crosshair pointer for pixel-level precision selection
% + Zoomed region drawn in left panel as an overlayed rectangle object
% + Follicle types drawn in different colors (True=g, False=g, Maybe=y)
% + Follicles of all types are drawn on screen
% + Speeded up inspectPhoto by refreshing only the changed panel
% + Fixed inverted direction panning when user right-clicked on right panel
% + Custom circular brush with pixel-level precision for "Add" tool
% + Speeded up "Refine" tool by convolving pixels only at mouseUp event
% + Everytime a new objct is added, it is also selected from list for stats
% + Refine tool uses custom circle mouse pointer same diameter as brush
% + Brush size now correctly scaled when zoom level is changed
% + Allow user to use custom colors to label follicles
% + Store/load preferences across sessions, or restore defaults via button
% + Error in Refine mode when animatedLine had no new pixels to add/remove
% + If user selected listbox item out of field of view, center view on it

% Version 1.1 - created on 2019-06-05
%
% + Diagnosis field to determine the diagnosis for the current photo
% + Filter has 3 modes: 1 = True follicle, -1 = False follicle, 0 = Maybe
% + Enclose mode will automatically add an object if none are selected
%

% Version 1.0 - created on 2019-05-29
%
% + Speeded up painting operation by using overlayed brush
% + Edit modes: Add, Refine, Select, Enclose allow interaction with objects
% 