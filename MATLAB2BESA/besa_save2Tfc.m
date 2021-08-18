function status = besa_save2Tfc(file_path_name, cfg, data)
% BESA_SAVE2TFC writes a data matrix into ASCII *.tfc file format 
%
% Parameters:
%     [file_path_name]
%         Full path to the folder where the file should be saved and name
%         of the output file.
%
%     [cfg]
%         Parameters required for storing dta to disc and writing
%         additional files. The following parameters need to be specified:
%         NumChannels: Number of channels
%         DataType: Name specifying data (e.g. Coherence, Wavelet)
%         ConditionName: Name of the exported condition.
%         NumTrials: Number of trials.
%         NumSamples: Number of samples.
%         TimeStartInMS: Epoch start time in milliseconds.
%         TimeIntervalInMS: Interval between two time samples in milliseconds.
%         NumFrequencies: Number of frequencies.
%         FrequencyStartInHz: Start frequency in Hertz.
%         FrequencyIntervalInHz: Frequency spacing in Hertz. This parameter
%                                should be set for equidistant frequency
%                                spacing.
%         FrequenciesInHz: Frequencies in Hertz. This parameter should be
%                          set for non-equidistant frequency spacing.
%         ChannelLabels: NumChannels x 1 cell defining channel labels.
%
%     [data]
%         A 3D data matrix to be saved. It should have the size
%         [NumChannels x NumFrequencies x NumSamples].
% 
% Return:
%     [status] 
%         The status of the writing process. Still unused.
% 

% Copyright (C) 2018, BESA GmbH
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
% Created: 2018-11-14

% Check parameters
if any(strcmp('NumChannels',fieldnames(cfg))) == 0
    error('Number of channels must be defined.');
end;
if any(strcmp('DataType',fieldnames(cfg))) == 0
    cfg.DataType = 'DataType';
end;
if any(strcmp('ConditionName',fieldnames(cfg))) == 0
    cfg.DataType = 'ConditionName';
end;
if any(strcmp('NumTrials',fieldnames(cfg))) == 0
    error('Number of trials must be defined.');
end;
if any(strcmp('TimeStartInMS',fieldnames(cfg))) == 0
    error('Epoch start time must be defined.');
end;
if any(strcmp('TimeIntervalInMS',fieldnames(cfg))) == 0
    error('Time interval must be defined.');
end;
if any(strcmp('NumFrequencies',fieldnames(cfg))) == 0
    error('Number of frequencies must be defined.');
end;
if any(strcmp('FrequencyStartInHz',fieldnames(cfg))) == 0
    error('Start frequency must be defined.');
end;
if any(strcmp('FrequencyIntervalInHz',fieldnames(cfg))) == 0 && ...
   any(strcmp('FrequenciesInHz',fieldnames(cfg)))  == 0
    error('Frequency spacing or frequencies must be defined.');
end;
if any(strcmp('FrequenciesInHz',fieldnames(cfg)))
    if length(cfg.FrequenciesInHz) ~= cfg.NumFrequencies
        error('Number of frequencies must match array size.');
    end;
end;
if any(strcmp('ChannelLabels',fieldnames(cfg))) == 0
    cfg.ChannelLabels = cell(cfg.NumChannels, 1);
    for ChanIdx=1:cfg.NumChannels
        cfg.ChannelLabels{ChanIdx} = ['Chan' num2str(ChanIdx)];
    end;   
end;

% Open file for writing.
fid = fopen(file_path_name, 'w');

% Write the first line of the header.
% Includes the following parameters:
% VersionNumber=__v_5.1 
% DataType=<Data Name, String> 
% ConditionName=<Condition Name, String>
% NumberTrials=<Number of Trials, Integer value> 
% NumberTimeSamples=<Number of Samples, Integer value>
% TimeStartInMS=<Trial Start Time in [ms], Float value>
% IntervalInMS=<Interval spacing in [ms], Float value>
% NumberFrequencies=<Number of frequencies, Integer value>
% FreqStartInHz=<Start Frequency in [Hz], Float value>
% FreqIntervalInHz=<Frequency Spacing in [Hz], Float value>
% or
% FrequenciesInHz=<Array of frequencies in [Hz], Float values>
% NumberChannels=<Number of Channels, Integer value>
% StatisticsCorrection=Off 
% EvokedSignalSubtraction=Off
fprintf(fid, 'VersionNumber=__v_5.1 ');
fprintf(fid, 'DataType=%s ', cfg.DataType);
fprintf(fid, 'ConditionName=%s ', cfg.ConditionName);
fprintf(fid, 'NumberTrials=%i ', cfg.NumTrials);
fprintf(fid, 'NumberTimeSamples=%i ', cfg.NumSamples);
fprintf(fid, 'TimeStartInMS=%.2f ', cfg.TimeStartInMS);
fprintf(fid, 'IntervalInMS=%.2f ', cfg.TimeIntervalInMS);
fprintf(fid, 'NumberFrequencies=%i ', cfg.NumFrequencies);
fprintf(fid, 'FreqStartInHz=%.2f ', cfg.FrequencyStartInHz);
% Frequencies
if any(strcmp('FrequencyIntervalInHz',fieldnames(cfg)))
    fprintf(fid, 'FreqIntervalInHz=%.2f ', cfg.FrequencyIntervalInHz);
else
    fprintf(fid, 'Frequencies=');
    for FreqCnt=1:cfg.NumFrequencies
        fprintf(fid, '%.2f;', cfg.FrequenciesInHz(FreqCnt));
    end;
    fprintf(fid, ' ');
end;
fprintf(fid, 'NumberChannels=%i ', cfg.NumChannels);
fprintf(fid, 'StatisticsCorrection=Off  ');
fprintf(fid, 'EvokedSignalSubtraction=Off ');
fprintf(fid, '\n');

% Write the second line of the header specifying channel labels.
for i=1:cfg.NumChannels
    fprintf(fid, '%s ', cfg.ChannelLabels{i});
end;
fprintf(fid, '\n');

% Write the data matrix to the file.
% Data is stored in the following way:
% Channel i:
% Frequency 1: Values for all time samples
% Frequency 2: Values for all time samples
% ...
% Frequency n: Values for all time samples
for ChanCnt=1:cfg.NumChannels
    for FreqCnt = 1:cfg.NumFrequencies
        % New line
        for SampCnt = 1:cfg.NumSamples
            fprintf(fid, '%.4f\t',data(ChanCnt, FreqCnt, SampCnt));
        end;
        fprintf(fid, '\n');
    end;
    % Add empty line after each channel
    fprintf(fid, '\n');
end;

% Close file
fclose(fid);

status = 1;
