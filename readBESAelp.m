function [Coords, ChanType] = readBESAelp(filename)
% READBESAELP reads the channel position from an ELP-file. 
%
% Parameters:
%     [filename]
%         In the case that the current folder is not the folder containing 
%         the file it should be the full path including the name of the 
%         elp file else only the name of the file should be specified. 
% 
% Return:
%     [Coords] 
%         A matrix containing the polar coordinates of the electrodes. The
%         size of the matrix is [NumChannels x 2].
% 
% Copyright (C) 2013, BESA GmbH
%
% File name: readBESAelp.m
%
% Author: Todor Jordanov
% Created: 2013-07-30
%
% Changes: 2014-05-28 Andre Waelkens: Added possibility of extracting 
%  channel types.

fp = fopen(filename, 'r');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fp >= 3)

    % Read the first line of the file. It should look like this:
    % [EEG] [Fp1] -92 -72 [1]
    % the parameters in [] are not always available.
    FirstLine = fgetl(fp);
    
    ChannelCounter = 1;
    LabelCounter = 1;
    
    % Use as a delimiter for split one ore more white spaces.
    tmp = regexp(FirstLine, '\s+', 'split');
    
    % Get the number of the columns.
    NumParams = size(tmp, 2);
    
    IndexPhi = 0;
    IndexTheta = 0;
    IndexLabels = 0;
    
    % Check how many parameters are available and set the indices of the
    % coordinate values correspondingly.
    switch NumParams
        case 2
            IndexPhi = 1;
            IndexTheta = 2;
        case 3
        	IndexPhi = 2;
            IndexTheta = 3;
            IndexLabels = 1;
        case 4
        	IndexPhi = 3;
            IndexTheta = 4;
            IndexLabels = 1;
        case 5
        	IndexPhi = 3;
            IndexTheta = 4;
            IndexLabels = 1;
        otherwise
        	disp('Wrong number of parameters!!!')
    end

    if(IndexPhi ~= 0 && IndexTheta ~=0)
        
        Coords(1, 1) = str2double(tmp(IndexPhi));
        Coords(1, 2) = str2double(tmp(IndexTheta));
        if(NumParams > 2)
            ChanType(1, 1) = tmp(IndexLabels);
        else
            ChanType(1,1) = 'NA';
        end
        
        while(true)
            
            CurrentLine = fgetl(fp);
            % Check if end of file.
            if(~ischar(CurrentLine))
                break;
            end
            
            tmp = regexp(CurrentLine, '\s+', 'split');
            % Check the type of the channels
            % and proceed only if EEG or MEG or POL!
            if(isempty(strfind(CurrentLine, 'EEG')) && ...
                isempty(strfind(CurrentLine, 'MEG')) && ...
                isempty(strfind(CurrentLine, 'POL')) )
                continue;
            elseif(~isempty(strfind(CurrentLine, 'EEG')) || ...
                ~isempty(strfind(CurrentLine, 'MEG')))
                ChannelCounter = ChannelCounter + 1;
                LabelCounter = LabelCounter + 1;
                Coords(ChannelCounter, 1) = str2double(tmp(IndexPhi));
                Coords(ChannelCounter, 2) = str2double(tmp(IndexTheta)); 
            elseif(~isempty(strfind(CurrentLine, 'POL')) )
                LabelCounter = LabelCounter + 1;
            end
            
            % Determine label sensor.
            if(NumParams > 2)
                ChanType(LabelCounter, 1) = tmp(IndexLabels);
            else
                ChanType(LabelCounter, 1) = 'NA';
            end
            
%            tmp = regexp(CurrentLine, '\s+', 'split');            
        end
        
    end
    
    fclose(fp);
    
    else
    
    Coords = [];
    ChanType = [];
    disp('Error! Invalid file identifier.')
    
end