function status = besa_save2Connectivity(file_path_name, cfg, data)
% BESA_SAVE2CONNECTIVITY writes data to file in order to load it in
% BESA Connectivity.
%
% Parameters:
%     [file_path_name]
%         Full path to the folder and file name where the file should be
%         saved (extensions will be added).
% 
%     [cfg]
%         Parameters required for storing dta to disc and writing
%         additional files. The following parameters need to be specified:
%         NumChannels: Number of channels
%         SamplingRate: sampling rate of data in samples/second
%         Prestimulus: Pre-stimulus interval in milliseconds.
%         BaselineStart: Baseline start relative to the stimulus position
%                        in milliseconds.
%         BaselineEnd: Baseline end relative to the stimulus position
%                      in milliseconds.
%         EpochLength: Epoch length in milliseconds.
%         Padding: Information concerning extra data values that surround
%                  the epoch to provide padding for wavelets, expressed in
%                  milliseconds.
%         PaddingExport: Exported padding pre & post trial in milliseconds.
%                        If not defined, 2000 ms padding will be added.
%                        Note: For BESA Connectivity 1.0 a padding of 
%                              2000 ms is required. Later versions of BESA
%                              Connectivity do no necessarily require
%                              padding.
%         ConditionName: Name of the condition.
%         ChannelLabels: nChannels x 1 cell defining channel names.
%         ChannelUnits: nChannels x 1 cell defining channel units.
%         ChannelTypes: nChannels x 1 cell defining channel types.
%         ChannelCoordinates: Coordinates of sensors/sources.
%         ChannelOrientations: Orientations of sources. 
% 
%     [data]
%         A cell array containing waveform matrices for each trial. Every
%         trial data matrix should have the size
%         [NumChannels x (2*Padding+EpochLength)*SamplingRate].
%         This data array needs to contain padding if defined (see Padding
%         in cfg structure.
% 
% Return:
%     [status] 
%         The status of the writing process.
%

% Copyright (C) 2018, BESA GmbH
%
% File name: besa_save2Connectivity.m
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
% Author: Robert Spangler
% Created: 2018-06-08


%% Check parameters
WriteSensorFile = true;
% Check file_path_name
[FilePath, FileBaseName, FileExt] = fileparts(file_path_name); 
FileName_generic = [FileBaseName '.generic'];
FileName_dat = [FileBaseName '.dat'];
FileName_bsa = [FileBaseName '.bsa'];
FileName_elp = [FileBaseName '.elp'];
if exist([FilePath '\' FileName_generic], 'file') ~= 0   ||...
   exist([FilePath '\' FileName_dat], 'file') ~= 0       ||...
   exist([FilePath '\' FileName_bsa], 'file') ~= 0       ||...
   exist([FilePath '\' FileName_elp], 'file') ~= 0
    warning('Files will be overwritten!'); 
    % Change to the directory where the data should be saved.
    cd(FilePath);
    delete([FilePath '\' FileName_generic]);
    delete([FilePath '\' FileName_dat]);
    delete([FilePath '\' FileName_bsa]);
    delete([FilePath '\' FileName_elp]);
end

% Check cfg structure
if any(strcmp('NumChannels',fieldnames(cfg))) == 0
    error('Number of channels must be defined.');
end
if any(strcmp('SamplingRate',fieldnames(cfg))) == 0
    error('Sampling rate must be defined.');
end
if any(strcmp('Prestimulus',fieldnames(cfg))) == 0
    error('Prestimulus must be defined.');
end
if any(strcmp('BaselineStart',fieldnames(cfg))) == 0
    error('Baseline start must be defined.');
end
if any(strcmp('BaselineEnd',fieldnames(cfg))) == 0
    error('Baseline end must be defined.');
end
if any(strcmp('EpochLength',fieldnames(cfg))) == 0
    error('Epoch length must be defined.');
end
if any(strcmp('Padding',fieldnames(cfg))) == 0
    cfg.Padding = 0;
end
if any(strcmp('PaddingExport',fieldnames(cfg))) == 0
    cfg.PaddingExport = 2000;
end
if any(strcmp('ConditionName',fieldnames(cfg))) == 0
    cfg.ConditionName = 'ConditionName';
end
if any(strcmp('ChannelLabels',fieldnames(cfg))) == 0
    cfg.ChannelUnits = cell(cfg.NumChannels, 1);
    for ChanIdx=1:cfg.NumChannels
        cfg.ChannelLabels{ChanIdx} = ['Chan' num2str(ChanIdx)];
    end   
end
if any(strcmp('ChannelUnits',fieldnames(cfg))) == 0
    cfg.ChannelUnits = cell(cfg.NumChannels, 1);
    for ChanIdx=1:cfg.NumChannels
        cfg.ChannelUnits{ChanIdx} = 'µV';
    end 
end
if any(strcmp('ChannelTypes',fieldnames(cfg))) == 0
    cfg.ChannelUnits = cell(cfg.NumChannels, 1);
    for ChanIdx=1:cfg.NumChannels
        cfg.ChannelTypes{ChanIdx} = 'POL';
    end
end
% Check data type (sensor or source)
if any(strcmp(cfg.ChannelTypes,'RegSrc')) || ...
   any(strcmp(cfg.ChannelTypes,'DipSrc')) || ...
   any(strcmp(cfg.ChannelTypes,'SptCmp'))
   WriteSensorFile = false;
end
% Check channel coordinates
if any(strcmp('ChannelCoordinates',fieldnames(cfg))) == 0
    if WriteSensorFile == true
        % Set default spherical coordinates (azimuth, latitude )
        cfg.ChannelCoordinates = zeros(cfg.NumChannels, 2);
    else
        % Set default (x, y, z) coordinates
        cfg.ChannelCoordinates = zeros(cfg.NumChannels, 3);
    end
end
% Check channel orientations
if any(strcmp('ChannelOrientations',fieldnames(cfg))) == 0
    if WriteSensorFile == true
        % Not required
    else
        % Set default (x, y, z) orientations
        cfg.ChannelOrientations = zeros(cfg.NumChannels, 3);
    end
end

% Check data
TrialDataSize = size(data{1});
if TrialDataSize(1) ~= cfg.NumChannels
    error('Dimension mismatch: number of channels in data matrix is incorrect.');
end


%% Parameters
NumTrials = length(data);
NumSamplesTrialSource = cfg.EpochLength/1000*cfg.SamplingRate;
NumSamplesTrialDest = 2*cfg.PaddingExport/1000*cfg.SamplingRate + NumSamplesTrialSource + 1;

NumSamplesPaddingRequired = cfg.PaddingExport/1000*cfg.SamplingRate;
if cfg.PaddingExport == 0
    StartSampleSource = 1;
    StartSampleDest = 1;
    NumSamplesCopy = NumSamplesTrialSource;
elseif cfg.Padding < cfg.PaddingExport
    % Not enough padding provided. 
    StartSampleSource = 1;
    StartSampleDest = (cfg.PaddingExport - cfg.Padding)/1000*cfg.SamplingRate + 1;
    NumSamplesCopy = 2*cfg.Padding/1000*cfg.SamplingRate + NumSamplesTrialSource;
else
    % Enough padding provided.    
    StartSampleSource = (cfg.Padding - cfg.PaddingExport)/1000*cfg.SamplingRate + 1;
    StartSampleDest = 1;
    NumSamplesCopy = NumSamplesTrialDest;
end

DataInclPadding = cell(NumTrials, 1);
for TrialIdx=1:NumTrials
    % Allocate zero values buffer
    DataInclPadding{TrialIdx} = zeros(cfg.NumChannels, NumSamplesTrialDest);
    
    % Copy data
    DataInclPadding{TrialIdx}(:, StartSampleDest:StartSampleDest + NumSamplesCopy - 1) = ...
        data{TrialIdx}(:, StartSampleSource:StartSampleSource + NumSamplesCopy - 1);
    
    % Add symmetric padding:
    if NumSamplesPaddingRequired > 0
        % Before trial data
        StartSamp = NumSamplesPaddingRequired;
        EndSamp = NumSamplesPaddingRequired + NumSamplesPaddingRequired;
        DataInclPadding{TrialIdx}(:, 1:NumSamplesPaddingRequired+1) = ...
            -fliplr(DataInclPadding{TrialIdx}(:, StartSamp:EndSamp));
        % After trial data
        StartSamp = StartSampleDest + NumSamplesCopy - 1 - NumSamplesPaddingRequired;
        EndSamp = StartSampleDest + NumSamplesCopy - 1;
        DataInclPadding{TrialIdx}(:, StartSampleDest + NumSamplesCopy:NumSamplesTrialDest) = ...
            -fliplr(DataInclPadding{TrialIdx}(:, StartSamp:EndSamp));
    end
end


%% Write .generic file
% Open file for writing.
[fid_generic, message] = fopen([FilePath '\' FileName_generic], 'w');
if fid_generic > 0
    fprintf(fid_generic, 'BESA Generic Data v1.1\n');
    fprintf(fid_generic, 'nChannels=%i\n', cfg.NumChannels);
    fprintf(fid_generic, 'sRate=%.2f\n', cfg.SamplingRate);
    TotalNumSamplesPerChannel = ((cfg.EpochLength + 2*cfg.PaddingExport)/1000*cfg.SamplingRate + 1) * NumTrials;
    fprintf(fid_generic, 'nSamples=%.i\n', TotalNumSamplesPerChannel);
    fprintf(fid_generic, 'format=float\n');
    fprintf(fid_generic, 'file=%s\n', FileName_dat);
    fprintf(fid_generic, 'prestimulus=%.3f\n', cfg.Prestimulus);
    fprintf(fid_generic, 'epochs=%i\n', NumTrials);
    fprintf(fid_generic, 'baselineStart=%.3f\n', cfg.BaselineStart);
    fprintf(fid_generic, 'baselineEnd=%.3f\n', cfg.BaselineEnd);
    fprintf(fid_generic, 'epochLength=%.3f\n', cfg.EpochLength);
    if(cfg.Padding == 0)
        fprintf(fid_generic, 'Padding=%.3f\n', cfg.PaddingExport);
    else
        % Use padding as defined in cfg
        fprintf(fid_generic, 'Padding=%.3f\n', cfg.Padding);
    end;
    fprintf(fid_generic, 'conditionName=%s\n', cfg.ConditionName);
    for ChanIdx=1:cfg.NumChannels
        fprintf(fid_generic, 'channelUnits=%s %s\n', cfg.ChannelLabels{ChanIdx}, cfg.ChannelUnits{ChanIdx});
    end
    
    % Close file
    fclose(fid_generic);
else
    error(['Error writing .generic file: ' message]);
end



%% Write .bin file
% Open file for writing.
[fid_dat, message] = fopen([FilePath '\' FileName_dat], 'w');
if fid_dat > 0
    % Write data
    for TrialIdx=1:NumTrials
        fwrite(fid_dat, DataInclPadding{TrialIdx}, 'float32');        
    end
    % Close file
    fclose(fid_dat);
else
    error(['Error writing .dat file: ' message]);
end


%% Write channel position file (*.elp/*.bsa)
if WriteSensorFile == true
    besa_save2Elp([FilePath '\'], FileName_elp, ...
        cfg.ChannelCoordinates, cfg.ChannelLabels, cfg.ChannelTypes);
else
    besa_save2Bsa([FilePath '\'], FileName_bsa, ...
        cfg.ChannelCoordinates, cfg.ChannelOrientations, ...
        cfg.ChannelLabels, cfg.ChannelTypes);
end


%% Return status
status = 1;
