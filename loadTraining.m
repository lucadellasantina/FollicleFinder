%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%

function Training = loadTraining(RequestedUID, FieldNames)
%% Load objects matching ObjName
TrainingFolder = [userpath filesep 'FollicleFinder' filesep 'Training']; 

if nargin <2
    FieldNames = {};
end

files = dir(TrainingFolder);         % List the content of /Objects folder
    files = files(~[files.isdir]);  % Keep only files, discard subfolders
    
    for d = 1:numel(files)
        load([TrainingFolder filesep files(d).name],'UID');
        if strcmp(UID, RequestedUID)
            if isempty(FieldNames)
                Training = load([TrainingFolder filesep files(d).name]);
            else
                Training = load([TrainingFolder filesep files(d).name], FieldNames{:});                
            end
            return;
        end
    end
end