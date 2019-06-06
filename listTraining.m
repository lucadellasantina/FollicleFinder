%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%

function tblT = listTraining
%% List available object names and UIDs
TrainingFolder = [userpath filesep 'FollicleFinder' filesep 'Training'];

tblT = [];
files = dir(TrainingFolder); % List the content of /Training folder
    files = files(~[files.isdir]);  % Keep only files, discard subfolders
    for d = 1:numel(files)
        T = load([TrainingFolder filesep files(d).name]);
        NumDone = ['F:' num2str(numel(T.ImagesList)-numel(T.ImagesTODOFollicles)) '/' num2str(numel(T.ImagesList))];
        NumDone = [NumDone ' E:' num2str(numel(T.ImagesList)-numel(T.ImagesTODOEyelid)) '/' num2str(numel(T.ImagesList))];
        if isempty(tblT)
            tblT = table({T.User},  {T.ImagesFolder}, {T.Type}, {T.Date}, {NumDone}, {T.UID});
        else
            tblT = [tblT; table({T.User},  {T.ImagesFolder}, {T.Type}, {T.Date}, {NumDone}, {T.UID})];
        end
    end
end