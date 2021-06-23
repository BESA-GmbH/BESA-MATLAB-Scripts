function [cfg] = besa_readSFH(filename, chantype)

% This method reads the surface fiducial help file from BESA REsearch/MRI.
%
% Parameters:
%     [filename]
%         In the case that the current folder is not the folder containing 
%         the file it should be the full path including the name of the 
%         elp file else only the name of the file should be specified. 
%
%     [chantype]
%         Defines a specific type of sensors that will be stored in cfg.
%         All other sensors will be ignored.
%         Options: 'all' - default value
%                  'fiducials' - only fiducials will be taken into account
%                  'eeg' - only eeg sensors will be taken into account
% 
% Return:
%     [cfg]
%         Cell array containing info on surface points stored in file.
%          
% Copyright (C) 2013, BESA GmbH
%
% File name: besa_readSFH.m
%
% Author: Robert Spangler
% Created: 2013-08-14

% Check default parameters
if((~exist('chantype', 'var')) ||...
    isempty(chantype))
  chantype='all';
end

% Try to open file.
FileID = fopen(filename, 'r');
if(FileID < 0)
	printf('Error opening file.\n');
	return
end

% Read the first line of the file. It should look like this:
% NrOfPoints: 68
strFirstLine = fgetl(FileID);
strTtmp = regexp(strFirstLine, ' ', 'split');
iNumPoints = str2double(strTtmp{2});

if(iNumPoints < 1)
    printf('No surface points in file.\n');
    return
end

% Read following iNumPoints lines and store surface points in array.
% Each line contains a label, the coordinates in the Head Coordinate
% system, and parameters specifying the size and color of the sensor or
% head surface point as displayed in BESA Research/MRI.
%label = cell(iNumPoints, 1);
%type = cell(iNumPoints, 1);
%position = cell(iNumPoints, 3);
iPointCnt = 0;
for iPts=1:iNumPoints
    strLine = fgetl(FileID);
    SurfPtInfo = regexp(strLine, '\s', 'split');
    % Remove empty cells from the cell array;
    SurfPtInfo(cellfun(@isempty,SurfPtInfo)) = [];
    
    % Assign values
    strLabel = SurfPtInfo{1};
    Location = [str2double(SurfPtInfo{2}) str2double(SurfPtInfo{3})...
                    str2double(SurfPtInfo{4})];
    %iSize = str2double(SurfPtInfo{5});
    %rgbColor = [str2double(SurfPtInfo{6}) str2double(SurfPtInfo{7})...
    %                str2double(SurfPtInfo{8})];
    
    % Get type of current point
    switch strLabel(1:3)
        case 'Fid'
            % Fiducial
            strType = 'fiducial';
        case 'Ele'
            strType = 'eeg';
            % Electrode
        otherwise
            strType = 'unknown';
    end

    % Check if current point needs to be stored.
    bStoreInfo = 0;
    if(strcmp(chantype, 'all') == 1)
        bStoreInfo = 1;
    elseif(strcmp(chantype, strType) == 1)
        bStoreInfo = 1;
    end
        
    % Store info on current point in corresponding cell array
    if(bStoreInfo == 1)
        iPointCnt = iPointCnt + 1;
        label{iPointCnt, 1} = strLabel;
        type{iPointCnt, 1} = strType;
        position{iPointCnt, 1} = Location(1);
        position{iPointCnt, 2} = Location(2);
        position{iPointCnt, 3} = Location(3);
    end
end

% Summarize info in cfg cell array
cfg.label = label;
cfg.chantype = type;
cfg.chanpos = position;

% Close file.
fclose(FileID);
end
