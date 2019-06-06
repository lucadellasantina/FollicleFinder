%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%

function deleteTraining(UID)
%% Remove saved training matching the passed unique identifier string UID
TrainingFolder = [userpath filesep 'FollicleFinder' filesep 'Training'];

if exist([TrainingFolder filesep UID '.mat'],'file')
    delete([TrainingFolder filesep UID '.mat']);
end

end