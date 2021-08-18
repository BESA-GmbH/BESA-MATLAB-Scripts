function status = besa_save2Bsa(file_path, file_name, ...
    channel_coords, channel_orientations, ...
    channel_labels, channel_types, CoordinatesInTAL)
% BESA_SAVE2BSA saves a matrix with vertices to a BESA solution file 
% (.bsa). 
%
% Parameters:
%     [file_path]
%         Full path to the folder where the file should be saved.
% 
%     [file_name]
%         The name of the file where the output should be written.
% 
%     [channel_coords]
%         A 2D data matrix with channel coordinates.
%         It should have the size [NumberOfChannels x 3]. 
% 
%     [channel_orientations]
%         A 2D data matrix with channel orientations.
%         It should have the size [NumberOfChannels x 3]. 
%         If not specified, it will be set to [0 0 0] for all channels.
% 
%     [channel_labels]
%         A 2D data matrix with channel labels.
%         It should have the size [NumberOfChannels x 3]. 
%         If not specified, it will be set to 'Chan<number>'.
% 
%     [channel_types]
%         A 2D data matrix with channel types.
%         It should have the size [NumberOfChannels x 3]. 
%         If not specified, it will be set to 'RegSrc' for all channels.
% 
%     [CoordinatesInTAL]
%         True or false value indicating type of coordinates (Talairach or
%         other. 
% 
% Return:
%     [status] 
%         The status of the writing process. If status < 0 then the process
%         wasn't successful.

% Copyright (C) 2014, BESA GmbH
%
% This file is part of MATLAB2BESA.
%
%    MATLAB2BESA is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    MATLAB2BESA is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with MATLAB2BESA. If not, see <http://www.gnu.org/licenses/>.
%
% Author: Todor Jordanov
% Created: 2014-03-11

status = 1;

% Check the size of the grid
Size1 = size(channel_coords, 1);
Size2 = size(channel_coords, 2);

if(Size1 == 3 && Size2 ~= 3)
    
    channel_coords = channel_coords';
    
end

NumVertices = size(channel_coords, 1);

% Check for more parameters
if ~exist('channel_orientations', 'var')
    channel_orientations = zeros(NumVertices, 3);
else
    if any(size(channel_orientations) ~= [NumVertices 3])
        error('Dimension mismatch: channel orientations.');
    end;
end;
if ~exist('channel_labels', 'var')
    channel_labels = cell(NumVertices, 1);
    for ChanCnt=1:NumVertices
        channel_labels{ChanCnt} = ['Source' num2str(ChanCnt)];
    end;
else
    if length(channel_labels) ~= NumVertices
        error('Dimension mismatch: channel labels.');
    end;
end;
if ~exist('channel_types', 'var')
    channel_types = cell(NumVertices, 1);
    for ChanCnt=1:NumVertices
        channel_types{ChanCnt} = 'RegSrc';
    end;
else
    if length(channel_types) ~= NumVertices
        error('Dimension mismatch: channel types.');
    end;
end;
if ~exist('CoordinatesInTAL', 'var')
    CoordinatesInTAL = false;
end;



FullPath = fullfile(file_path, file_name);
% Open file for writing.
fid = fopen(FullPath, 'w');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fid >= 3)

    % Write the first line of the header.
    fprintf(fid, 'BSA_1.04.19990715');
    if(CoordinatesInTAL)
        fprintf(fid, '|TC');
    end;
    fprintf(fid, '\n');

    % Write the second and third line of the header.
    fprintf(fid, ...
        ['Type          x-loc       y-loc       z-loc        x-ori       y-ori       z-ori      color state size\n'...
        '=======================================================================================================\n']);

    for i = 1:NumVertices

        fprintf(fid, '%s   %.6f  %.6f  %.6f     %.6f  %.6f  %.6f        255     2 4.50 Label:%s\n', ...
            channel_types{i}, ...
            channel_coords(i, 1), channel_coords(i, 2), channel_coords(i, 3), ...
            channel_orientations(i, 1), channel_orientations(i, 2), channel_orientations(i, 3), ...
            channel_labels{i});

    end

    fclose(fid);

else
    
    status = -1;
    disp('Error! Invalid file identifier.')
    
end

