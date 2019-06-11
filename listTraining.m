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
        NumDone = [NumDone ' D:' num2str(numel(T.ImagesList)-numel(T.ImagesTODODucts)) '/' num2str(numel(T.ImagesList))];
        if isempty(tblT)
            tblT = table({T.User},  {T.ImagesFolder}, {T.Type}, {T.Date}, {NumDone}, {T.UID});
        else
            tblT = [tblT; table({T.User},  {T.ImagesFolder}, {T.Type}, {T.Date}, {NumDone}, {T.UID})];
        end
    end
end