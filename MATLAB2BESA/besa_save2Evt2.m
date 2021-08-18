function status = besa_save2Evt2(file_path, file_name, event_matrix)
% BESA_SAVE2AEVT2 writes events into BESA-compatible ASCII file format 
%
% Parameters:
%     [file_path]
%         Full path to the folder where the file should be saved.
% 
%     [file_name]
%         The name of the file where the output should be written.
%
%     [event_matrix]
%         A matrix containing the event information exported from BESA 
%         and imported into Matlab using the function besaReadevt. 
%
% Return:
%     [status] 
%         The status of the writing process. It is 1 if the writing was
%         succesful and -1 if not.

% Copyright (C) 2015, BESA GmbH
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
% Author: Todor Iordanov
% Created: 2015-11-20

status = 1;

NumEvents = size(event_matrix, 1);
NumParams = size(event_matrix, 2);

filename = fullfile(file_path, file_name);
fp = fopen(filename, 'w');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fp >= 3)
    
    % Write the first line of the header.
    fprintf(fp, 'Tmu         	Code	TriNo	Comnt\n');
    
    % Write the data matrix to the file.
for i=1:NumEvents
    
    for j=1:NumParams

        fprintf(fp, '%d\t\t%d\t%d ', event_matrix(i, j));

    end
    
    fprintf(fp, '\n');
    
end

fclose(fp);
    
else
    
    status = -1;
    disp('Error! Invalid file identifier.')
    
end




