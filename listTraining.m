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
files = dir(TrainingFolder); % List the content of /Training folder
files = files(~[files.isdir]);  % Keep only files, discard subfolders

tblT = repmat(table({'Empty'}, {'Empty'}, {'Empty'}, {datetime}, {'Empty'}, {'Empty'}),numel(files),1);
for d = 1:numel(files)
    T = load([TrainingFolder filesep files(d).name], 'User', 'ImagesFolder', 'Type', 'Date', 'UID', 'ImagesList', 'ImagesTODOFollicles', 'ImagesTODOEyelid');
    FolliclesDone = numel(T.ImagesList)-numel(T.ImagesTODOFollicles);
    EyelidDone    = numel(T.ImagesList)-numel(T.ImagesTODOEyelid);
    DoneString    = ['F:' num2str(FolliclesDone) '/' num2str(numel(T.ImagesList)) ' E:' num2str(EyelidDone) '/' num2str(numel(T.ImagesList))];
    tblT(d,:)     = table({T.User},  {T.ImagesFolder}, {T.Type}, {T.Date}, {DoneString}, {T.UID});
end

tblT = sortrows(tblT,1); % Sort table by user name
end