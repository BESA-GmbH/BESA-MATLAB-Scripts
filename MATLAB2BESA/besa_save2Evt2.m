function status = besa_save2Evt2(file_path, file_name, Events)
% BESA_SAVE2AEVT2 writes events into BESA-compatible ASCII file format 
%
% Parameters:
%     [file_path]
%         Full path to the folder where the file should be saved.
% 
%     [file_name]
%         The name of the file where the output should be written.
%
%     [Events]
%         A cell array containing the event information exported from BESA 
%		  and imported into MATLAB using the function readBESAevt.
%		  Each event is stored as one entry in the cell array. The members  
%		  of each event are saved in the following variables:
%         	Tmu (time in microseconds), Code (event code), 
%			TriNo (trigger number) and Comnt (comment).
%         Old format: A matrix containing the event information 
%		  (event_matrix).
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

filename = fullfile(file_path, file_name);
fp = fopen(filename, 'w');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if (fp >= 3)
    
    % Write the first line of the header.
    fprintf(fp, 'Tmu         	Code	TriNo	Comnt\n');
    
    if ismatrix(Events) && ~iscell(Events)

		NumEvents = size(Events, 1);
		NumParams = size(Events, 2);
		
        % Write the data matrix to the file.
        for i = 1:NumEvents

            for j = 1:NumParams
                fprintf(fp, '%.0f\t\t%d\t%d ', Events(i, j));
            end
			
            fprintf(fp, '\n');
			
        end
		
    elseif iscell(Events)
        
		% Write the data cell to the file.
        for i = 1:length(Events)
		
            if isfield(Events{i}, 'Comment')
                fprintf(fp, '%.0f\t\t%d\t%d\t%s ', ...
                    Events{i}.Time, Events{i}.Code, Events{i}.TriNo, ...
					Events{i}.Comment);
            else
                fprintf(fp, '%.0f\t\t%d\t%d ', ...
                    Events{i}.Time, Events{i}.Code, Events{i}.TriNo);
            end
			
            fprintf(fp, '\n');
			
        end
		
    else
	
    	status = -1;
        disp('Error! Invalid data type.')
		
    end

    fclose(fp);
    
else
    
    status = -1;
    disp('Error! Invalid file identifier.')
    
end
