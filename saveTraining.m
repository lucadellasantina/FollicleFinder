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
    
    if isempty(FieldName)
        % Save struct on file with fields split tino separate variables
        save(FileName, '-struct', 'Training', '-v7.3');
    else
        % Save only a specific FieldName on disk
        save(FileName, '-struct', 'Training', FieldName,'-append');
    end    
end