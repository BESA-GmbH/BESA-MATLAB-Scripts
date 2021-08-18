function status = besa_createTriggerFromChannel(FilePath, FileName, ...
    TriggerChannel, TimeStampChannel)
% BESA_CREATETRIGGERFROMCHANNEL extracts the trigger information from a 
% trigger channel and creates an evt-file containing thrigger codes,
% trigger time and trigger label.
%
% Parameters:
%     [FilePath]
%         Full path to the folder where the file should be saved.
% 
%     [FileName]
%         The name of the file where the output should be written.
% 
%     [TriggerChannel]
%         A 1D array containing the data of the trigger channel.
%         Size: [1 x NumberOfTimeSamples]
% 
%     [TimeStampChannel]
%         A 1D array with the time samples corresponding to the data.
%         Size: [1 x NumberOfTimeSamples]   
% 
% 
% Return:
%     [status] 
%         The status of the writing process:
%           1: Successful
%          -1: Failure
% 

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
% Author: Todor Jordanov
% Created: 2015-10-21

status = 1;

EventFile = fullfile(FilePath, FileName);

NumTimeSamples = length(TriggerChannel);

% Open file for writing.
fid = fopen(EventFile, 'w');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fid >= 3)

    % Create the header line
    fprintf(fid, 'Tmu         	Code	TriNo	Comnt\n');
    
    t = 1;
    % Use a "while" instead of "for" since in the for case
    % it is not possible to change the value of the incremeted
    % variable t.
    while(t<=NumTimeSamples) % for t = 1:NumTimeSamples
        
        % Get the trigger value for the current sample.
        CurrSample = TriggerChannel(t);
        
        % If the value is not zero then there should be a trigger.
        if(CurrSample > 0)
            
            % Get the current time for the trigger.
            TriggerTime = round(TimeStampChannel(t));
            TriggerValue = CurrSample;
            
            TrgCounter = 0;
            InternalIdx = t;
            
            % From all subsequent trigger values different than zero 
            % calculate the trigger code.
            while(CurrSample ~= 0)
                
                TrgCounter = TrgCounter + 1;
                InternalIdx = InternalIdx + 1;
                CurrSample = TriggerChannel(InternalIdx);
                TriggerValue = TriggerValue + CurrSample;
                
            end
            
            % The trigger code is the mean over all non-zero values.
            TriggerValue = round(TriggerValue/TrgCounter);
            t = InternalIdx;
            
            % Store the information for the current trigger in the
            % evt-file.
            fprintf(fid, '%i\t\t%i\t%i%i\t%s\n', TriggerTime, 1, ...
                TrgCounter, TriggerValue, 'Trigger');
            
        else
            
            % increment t
            t = t + 1;
            
        end
        
    end
    
    % Close the file
    fclose(fid);

% An error accured.
else
    
    status = -1;
    disp('Error! File could not be created.')
    
end
