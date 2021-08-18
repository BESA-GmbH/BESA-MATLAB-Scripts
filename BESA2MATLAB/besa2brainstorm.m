function besa2brainstorm(besa_channels, bstVar, bWithChannels)
% besa2brainstorm   Import the besa_channels structure to Brainstorm.
%
% Parameters:
%	[besa_channels]
%       BESA besa_channels data structure
%
%   [bstVar]
%       A structure for the Brainstorm database
%           bstVar.ProtocolName : protocol name
%           bstVar.SubjectName  : subject name
%           bstVar.StudyName    : study name
%
%   [bWithChannels]
%       true : with channel information (default)
%       false: withouth channel information
%
% Example:
%   bstVar              = [];
%   bstVar.ProtocolName = 'Protocol01';
%   bstVar.SubjectName  = 'Subject01';
%   bstVar.StudyName    = 'Data01';
%   bWithChannels       = true;
%   besa2brainstorm(besa_channels_2events, bstVar, bWithChannels);
%
% See also:
%   https://neuroimage.usc.edu/brainstorm/Tutorials/Scripting#Example:_Creating_a_new_file
%   https://neuroimage.usc.edu/brainstorm/Tutorials/Epoching#Import_in_database
%   https://neuroimage.usc.edu/brainstorm/Tutorials/Epoching#On_the_hard_drive
%   https://neuroimage.usc.edu/brainstorm/Tutorials/Averaging#On_the_hard_drive
%   https://neuroimage.usc.edu/brainstorm/Tutorials/ChannelFile#On_the_hard_drive

% Copyright (C) 2021, BESA GmbH
%
% This file is part of BESA2MATLAB.
%
%    BESA2MATLAB is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    BESA2MATLAB is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with BESA2MATLAB. If not, see <http://www.gnu.org/licenses/>.
%
% Author: Jae-Hyun Cho
% Created: 2021-01-25
% Modified:
%   JC 2021-04-12: Considered MEG data (.fif and .meg4)

%{
%% Example

% Add paths: BESA2MATLAB; Brainstorm
%addpath('xxx');
%addpath('xxx');

% Prepare a protocol and a subject in Brainstorm
% ex) Protocol: Protocol01; Subject: Subject01

% Epoched data
bstVar              = [];
bstVar.ProtocolName = 'Protocol01';
bstVar.SubjectName  = 'Subject01';
bstVar.StudyName    = 'test_S1_EpochedData';
besa2brainstorm(besa_channels_events, bstVar, true);

% Raw data
bstVar              = [];
bstVar.ProtocolName = 'Protocol01';
bstVar.SubjectName  = 'Subject01';
bstVar.StudyName    = 'test_S1_RawData';
besa2brainstorm(besa_channels_raw, bstVar, true);

brainstorm
%}

% Set default values
if nargin < 2
    error('\tWrong input arguments.');
elseif nargin < 3
    bWithChannels = true;
end

% Check channel type
if isfield(besa_channels, 'channeltypes')
    chType = checkChannelType(besa_channels);
    if strcmp(chType, 'NULL')
         error('\tUnsupported channel type.');
    end
else
    error('\tThe besa_channels.channeltypes is missing.');
end

% Check brainstorm
if exist('brainstorm', 'file')
    % Start brainstorm
    if ~brainstorm('status')
        brainstorm nogui
    end
else
    error('\tPlease add Brainstorm to the search path.');
end


% Get the protocol index
iProtocol = bst_get('Protocol', bstVar.ProtocolName);
if isempty(iProtocol)
	error(['\tUnknown protocol: %s\n', ...
        '\tPlease use a protocol name inlcuded in Brainstorm.'], ...
        bstVar.ProtocolName);
end

% Select the current procotol
gui_brainstorm('SetCurrentProtocol', iProtocol);

% Get the subject index
iSubject = bst_get('Subject', bstVar.SubjectName);
if isempty(iSubject)
	error(['\tUnknown subject: %s\n',...
        '\tPlease use a subject name inlcuded in Brainstorm.'], ...
        bstVar.SubjectName);
end


% Exported data from BESA (besa_channels) to Brainstorm
if strcmp(besa_channels.datatype, 'Raw_Data')
    
    % Raw data -> Brainstorm
    add_BESA_RawData(besa_channels, bstVar, bWithChannels);
    
elseif (strcmp(besa_channels.datatype, 'Epoched_Data') || ...
        strcmp(besa_channels.datatype, 'Segment'))
    
    % Epoched or Segment data -> Brainstorm
    add_BESA_EpochedData(besa_channels, bstVar, bWithChannels);
    
else
    error('\tThe besa_channels.datatype is wrong.');
end


end

% =========================================================================

function scale = scaleUnit(channelUnit)
    
    switch (channelUnit)
        case 'µV'
            scale = 1e-6;
        case 'V'
            scale = 1;
        case 'T'
            scale = 1;
        case 'fT'
            scale = 1e-15;
        case 'fT/cm'
            scale = 1e-13; % = 1e-15 / 1e-2
        otherwise
            scale = 1e-6;
    end
    
end

% -------------------------------------------------------------------------

function scale = scaleTime()

    scale = 1e-3;
    
end

% -------------------------------------------------------------------------

function TF = isStrContain(str, pattern, bIgnoreCase)
    % Input Arguments
    %   str: input text, cell array of character vectors
    %   pattern: search pattern, string array
    %   bIgnoreCase: ignoring case.
    % Output Argument
    %   TF: true or false
    
    if nargin < 3
        bIgnoreCase = false;
    end

    if bIgnoreCase
        TF = sum(not(cellfun('isempty', strfind(lower(str), lower(pattern))))) > 0;
    else
        TF = sum(not(cellfun('isempty', strfind(str, pattern)))) > 0;
    end

end

% -------------------------------------------------------------------------

function chType = checkChannelType(besa_channels)
    % Channel types:
    %   EEG, MEG, MEG_EEG
    % Channel types in besa_channels:
    %   EEG, MEG-AX, MEG-PL, MEG-MAG, ICR, POLYGR, ART
    
    % Check channel type
    chType = 'NULL';
    if isfield(besa_channels, 'channeltypes')

% TODO: iEEG?
        
        chTypesAll = [besa_channels.channeltypes];
        chTypes = unique(chTypesAll);
        
        bIgnoreCase = true;
        if isStrContain(chTypes, 'MEG', bIgnoreCase)
            chType = 'MEG';
            if isStrContain(chTypes, 'EEG', bIgnoreCase)
                chType = 'MEG_EEG';
            end
        elseif isStrContain(chTypes, 'EEG', bIgnoreCase)
            chType = 'EEG';
        end
        
    else
        error('\tThe besa_channels.channeltypes is missing.');
    end
    
end

% -------------------------------------------------------------------------

function channels = convertChannel(besa_channels)
    % Convert channel information from BESA (besa_channels) to the 
    % Brainstorm format
    
    % Check channel type
    chType = checkChannelType(besa_channels);

% TODO: use ChannelMat = db_template('channelmat')
    % Prepare channel information for Brainstorm
    nCh = length(besa_channels.channeltypes);    
    channels = [];
    switch chType
        case 'EEG'
            channels.Comment    = 'BESA_MATLAB channels';
            channels.HeadPoints = [];
            channels.Channel    = [];
            
            for i = 1:nCh
                channelType = besa_channels.channeltypes{i};
                
                 % EOG and ECG 
                if strncmp(channelType, 'POLYGR', 6)
                    if strncmp(besa_channels.channellabels{i}, 'EOG', 3)
                        channelType = 'EOG';
                    elseif strncmp(besa_channels.channellabels{i}, 'ECG', 3)
                        channelType = 'ECG';
                    end
                end

                channels.Channel(i).Name     = besa_channels.channellabels{i};
                channels.Channel(i).Comment  = [];
                channels.Channel(i).Type     = channelType;
                channels.Channel(i).Group    = [];
                channels.Channel(i).Loc(1,1) = transpose(besa_channels.channelcoordinates(i,2)); % X
                channels.Channel(i).Loc(2,1) = transpose(besa_channels.channelcoordinates(i,1)); % Y
                channels.Channel(i).Loc(3,1) = transpose(besa_channels.channelcoordinates(i,3)); % Z
                channels.Channel(i).Orient   = [];
                channels.Channel(i).Weight   = 1;
            end
    
        case {'MEG', 'MEG_EEG'}

            [fPath, fName, fExt] = fileparts(besa_channels.datafile);
            switch (fExt)
                case '.fif'
                    fileFormat = 'FIF';
                case '.meg4'
                    fileFormat = 'CTF';
                case {'.foc', '.fsg'}
% TODO: .foc, .fsg
                    error(['\tbesa_channels.datafile = %s\n', ...
                        '\tPlease set the original MEG file path (*.fif; *.meg4) in the besa_channels.datafile field.'], ...
                        besa_channels.datafile);
                otherwise
% TODO: .con (Ricoh; Yokkogawa)
                    error('\tUnsupported data format: %s', fExt);
            end
            
            % Get channel information from the data file
            % import_channel.m is included in Brainstorm.
            channels = import_channel([], besa_channels.datafile, fileFormat);
            
            
            % Compare the number of channels
            if nCh ~= length(channels.Channel)
                error('\tThe number of channels are different.');
            end
            
            % See brainstorm3\toolbox\io\in_data.m
            % No SSP
            if ~isempty(channels) && isfield(channels, 'Projector') && ~isempty(channels.Projector)               
                % Remove projectors that are not already applied
                iProjDel = find([channels.Projector.Status] ~= 2);
                channels.Projector(iProjDel) = [];
            end

            % Reorder the channels
            indexUsed = [];
            temp_Channel = channels.Channel;
            for i = 1:nCh
                %chName = besa_channels.channellabels(i);
                %index = find(strcmp({channels.Channel.Name}, chName{1}) == 1);
                
                chName = channels.Channel(i).Name;
                index = find(strcmpi(besa_channels.channellabels, chName) == 1);
                if isempty(index)
                    % To consider the case that a suffix is added to a channel name
                    % ex) EEG10 and EEG10-ref
                    index = find(not(cellfun('isempty', ...
                        strfind(upper(besa_channels.channellabels), upper(chName)))) == 1);
                                        
                    if isempty(index)
                        % When only one channel is remained
                        if length(setdiff(1:nCh, indexUsed)) == 1
                            index = setdiff(1:nCh, indexUsed);
                        end
                    end
                end
                
                % Check if the channel index is already considered
                index = setdiff(index, indexUsed);
                
                if length(index) == 1
                    temp_Channel(index) = channels.Channel(i);
                    indexUsed = [indexUsed index];
                elseif length(index) > 1
                    error('\tDuplicated channel name');
                else
                    error('\tThe channel name %s (index: %d) is not contained in besa_channels.channellabels.', ...
                        chName, i);
                end
            end
            channels.Channel = temp_Channel;
                        
        otherwise
            error('\tUnsupported channel type: %s', chType);
    end
    
end

% -------------------------------------------------------------------------

function [brainstorm_Events] = convertEvents(brainstorm_Events, ...
    besa_events, timeOffsetSecs)
    % Convert event information from BESA (besa_channels.events) to the 
    % Brainstorm format
    
    % See brainstorm3\toolbox\io\import_events.m
    ColorTable = ...
        [0     1    0   
        .4    .4    1
         1    .6    0
         0     1    1
        .56   .01  .91
         0    .5    0
        .4     0    0
         1     0    1
        .02   .02   1
        .5    .5   .5];
    
    labelAll = [besa_events.label];
    labels   = unique(labelAll);
    nLabels  = length(labels);

    for i = 1:nLabels
        index  = find(strcmp(labelAll, labels{i}));
        nIndex = length(index);

        % If all the colors of the color table are taken, 
        % attribute colors cyclically
        iColor = mod(i-1, length(ColorTable)) + 1;

        brainstorm_Events(i).label      = labels{i};
        brainstorm_Events(i).color      = ColorTable(iColor,:);
        brainstorm_Events(i).epochs     = 1;
        brainstorm_Events(i).times      = zeros(1, nIndex);
        brainstorm_Events(i).reactTimes = [];
        brainstorm_Events(i).select     = 1;
        brainstorm_Events(i).epochs     = ones(1, nIndex);
        brainstorm_Events(i).channels   = cell(1, nIndex);
        brainstorm_Events(i).notes      = cell(1, nIndex);

        cnt = 1;
        for iEvent = index         
            brainstorm_Events(i).times(1,cnt) = ...
                timeOffsetSecs + scaleTime() * besa_events(iEvent).latency;
            cnt = cnt + 1;
        end
    end
    
end

% -------------------------------------------------------------------------

function add_ChannelInfo(besa_channels, iStudy, outputFolder)

    if (isfield(besa_channels, 'channellabels') && ...
        isfield(besa_channels, 'channeltypes') && ...
        isfield(besa_channels, 'channelcoordinates'))

        channels = convertChannel(besa_channels);

        % Generate a unique filename (with a timestamp)
        MatrixFile = bst_process('GetNewFilename', outputFolder, 'channel');

        % Save file
        bst_save(MatrixFile, channels, 'v6');

        % Reference saved file in the database
        db_add_data(iStudy, MatrixFile, channels);
    else
        error('\tError occurred.');
    end
    
end

% -------------------------------------------------------------------------

function add_BESA_RawData(besa_channels, bstVar, bWithChannels)

    % Create a new folder "bstVar.StudyName" in subject "bstVar.SubjectName"
    iStudy = db_add_condition(bstVar.SubjectName, bstVar.StudyName);        
    
    % Get the corresponding study structure
    sStudy = bst_get('Study', iStudy);
    
    % Get the full path to the new folder
    % (same folder as the brainstormstudy.mat file for this study)
    outputFolder = bst_fileparts(file_fullpath(sStudy.FileName));
    
    
    % ===== Channels =====
    if bWithChannels
        add_ChannelInfo(besa_channels, iStudy, outputFolder);
    end
    
    
    % ===== Raw data =====
    nCh = numel(besa_channels.channeltypes);
    
% TODO: bad channel
    data = db_template('datamat');
    %data.F           = [];
    %data.Std         = [];
    %data.Comment     = [];
    data.ChannelFlag = ones(nCh,1);
    %data.Time        = [];
    %data.DataType    = 'recordings';
    data.Device      = 'BESA_MATLAB';
    data.nAvg        = 1;
    data.Leff        = 1;
    %data.Events      = [];
    %data.History     = [];
    
    
% TODO: 'T' in besa_channels.channelunits shoud be changed to 'fT'
    [fPath, fName, fExt] = fileparts(besa_channels.datafile);
    if strcmp(fExt, '.fif')
        for i = 1:length(besa_channels.channelunits)
            if strcmp(besa_channels.channelunits{i}, 'T')
                besa_channels.channelunits{i} = 'fT';
            end
        end
    end
        
    
    if strcmp(besa_channels.datatype, 'Raw_Data')

        nTime = size(besa_channels.amplitudes, 1);
        timeOffsetSecs = 0;
        
        data.Comment = 'Raw_Data';
        data.F       = zeros(nCh, nTime);
        data.Time    = scaleTime() .* besa_channels.latencies;

        for iCh = 1:nCh
            if isfield(besa_channels, 'channelunits')
                data.F(iCh,:) = scaleUnit(besa_channels.channelunits{iCh}) .* ...
                    transpose(besa_channels.amplitudes(:, iCh));
            else
                data.F(iCh,:) = transpose(besa_channels.amplitudes(:, iCh));
            end
        end
        
        data.Events = convertEvents(data.Events, ...
            besa_channels.events, timeOffsetSecs);
    else
        
        error('\tThe besa_channels.datatype should be Raw_Data');
    end
    
    % Generate a unique filename (with a timestamp)
    MatrixFile = bst_process('GetNewFilename', outputFolder, 'data');
    
    % Save file
    bst_save(MatrixFile, data, 'v6');
    
    % Reference saved file in the database
    db_add_data(iStudy, MatrixFile, data);
    
    % Update the database explorer display
    %panel_protocols('UpdateNode', 'Study', iStudy);
    
    % Reload only the select data folder
    db_reload_studies(iStudy);
    
end

% -------------------------------------------------------------------------

function add_BESA_EpochedData(besa_channels, bstVar, bWithChannels)
    
    % Create a new folder "bstVar.StudyName" in subject "bstVar.SubjectName"
    iStudy = db_add_condition(bstVar.SubjectName, bstVar.StudyName);      
    
    % Get the corresponding study structure
    sStudy = bst_get('Study', iStudy);    
    
    % Get the full path to the new folder 
    % (same folder as the brainstormstudy.mat file for this study)
    outputFolder = bst_fileparts(file_fullpath(sStudy.FileName));
    
    
    % ===== Channels =====
    if bWithChannels
        add_ChannelInfo(besa_channels, iStudy, outputFolder);
    end
    
    
    % ===== Epochs or Segment =====
    if (strcmp(besa_channels.datatype, 'Epoched_Data') || ...
        strcmp(besa_channels.datatype, 'Segment'))
        
% TODO: 'T' in besa_channels.channelunits shoud be changed to 'fT'
        [fPath, fName, fExt] = fileparts(besa_channels.datafile);                    
        if strcmp(fExt, '.fif')
            for i = 1:length(besa_channels.channelunits)
                if strcmp(besa_channels.channelunits{i}, 'T')
                    besa_channels.channelunits{i} = 'fT';
                end
            end
        end
    
        nCh     = numel(besa_channels.channeltypes);
        nEpochs = numel(besa_channels.data);
        
        labelAll = cell(1,nEpochs);
        for iEpoch = 1:nEpochs 
            nEvent = numel(besa_channels.data(iEpoch).event);
            if nEvent == 1
                iEvent = 1;
            elseif nEvent > 1
                [~, minIdx] = min(abs([besa_channels.data(iEpoch).event.latency]));
                iEvent = minIdx;         
            else
                error('\tError occurred.');
            end
            
            % 'labelAll' will be used later to set 'data.Comment'
            for i = 1:nEvent                
                eventType = besa_channels.data(iEpoch).event(i).type{1};         
                if strcmpi(eventType, 'Trigger')                     
                    labelAll{iEpoch} = besa_channels.data(iEpoch).event(i).label{1};
                    break
                else
                    labelAll{iEpoch} = besa_channels.data(iEpoch).event(i).label{1};
                end
            end
        end
        
        labels   = unique(labelAll(:));
        nLabels  = numel(labels);
        
        for iLabel = 1:nLabels
            
            allIndex = find(strcmp(labelAll, labels{iLabel}));            
            if size(allIndex,1) > size(allIndex,2)
                allIndex = transpose(allIndex);
            end
            
            cnt = 1;
            for iIdx = allIndex
                
                nTime = size(besa_channels.data(iIdx).amplitudes, 1);
                timeOffsetSecs = 0;
                
                data             = db_template('datamat');
                data.F           = zeros(nCh, nTime);
                %data.Std         = [];
                data.ChannelFlag = ones(nCh, 1);
                data.Time        = scaleTime() .* besa_channels.data(iIdx).latencies;
                %data.DataType    = 'recordings';
                data.Device      = 'BESA_MATLAB';
                %data.nAvg        = 1;
                %data.Leff        = 1;
                %data.Events      = [];
                %data.History     = [];
                
                switch besa_channels.datatype
                    case 'Segment'
                        data.Comment = 'Segment';
                        timeOffsetSecs = besa_channels.data(iIdx).timeoffsetsecs;
                    case 'Epoched_Data'
                        data.Comment = [labels{iLabel}, ' (#', num2str(cnt), ')'];
                end
                               
                for iCh = 1:nCh
                    if isfield(besa_channels, 'channelunits')
                        data.F(iCh,:) = scaleUnit(besa_channels.channelunits{iCh}) .* ...
                            transpose(besa_channels.data(iIdx).amplitudes(:,iCh));
                    else
                        data.F(iCh,:) = transpose(besa_channels.data(iIdx).amplitudes(:,iCh));
                    end
                end

                data.Events = convertEvents(data.Events, ...
                    besa_channels.data(iIdx).event, timeOffsetSecs);
               
                % Check if labels{iLabel} is valid as a filename
                fName_check = regexp(labels{iLabel}, '[/\*:?"<>|]', 'once');
                if ~isempty(fName_check)
                    fName_label = strrep(labels{iLabel}, ...
                        labels{iLabel}(fName_check), '_');
                else
                    fName_label = labels{iLabel};
                end
                                
                % Generate a unique filename
                fName = sprintf('data_%s_trial%03i.mat', fName_label, cnt);
                MatrixFile = file_unique(bst_fullfile(outputFolder, fName));
                
                % Save file
                bst_save(MatrixFile, data, 'v6');
                
                % Reference saved file in the database
                db_add_data(iStudy, MatrixFile, data);     
                
                cnt = cnt + 1;
            end
            
        end
        
        % Update the database explorer display
        %panel_protocols('UpdateNode', 'Study', iStudy);
    else
       error('\tError occurred.');
    end

    % Reload only the select data folder
    db_reload_studies(iStudy);
    
end
