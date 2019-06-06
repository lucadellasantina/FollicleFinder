%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%

function saveTraining(Training, FieldName)
%% Save a variable into a .mat file efficiently depending on its size
    TrainingFolder = [userpath filesep 'FollicleFinder' filesep 'Training']; 
    if nargin == 1
        % If no FieldName then save all field of Training on file
        FieldName = []; 
    end
    
    if ~exist(TrainingFolder,'dir')
        mkdir(TrainingFolder);
    end
    
    if ~isfield(Training, 'UID')
        Training.UID = generateUID;
    end
    FileName = [TrainingFolder filesep Training.UID '.mat'];
    
    lastwarn('') % Clear last warning message
    
    if isempty(FieldName)
        % Save struct on file with fields split tino separate variables
        save(FileName, '-struct', 'Training', '-v7');
        [warnMsg, ~] = lastwarn;
        if ~isempty(warnMsg)
            disp('File bigger than 2Gb, will be saved using larger file format, be patient...')
            save(FileName, '-struct', 'Training', '-v7.3', '-nocompression');
        end
    else
        % Save only a specific FieldName on disk
        save(FileName, '-struct', 'Training', FieldName,'-append');
        [warnMsg, ~] = lastwarn;
        if ~isempty(warnMsg)
            disp('File bigger than 2Gb, will be saved using larger file format, be patient...')
            save(FileName, '-struct', 'Training', FieldName, '-append');
        end
    end    
end