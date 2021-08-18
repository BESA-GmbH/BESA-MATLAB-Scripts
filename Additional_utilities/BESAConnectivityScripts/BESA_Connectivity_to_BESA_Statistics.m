% BESA_Connectivity_to_BESA_Statistics
%
% Script to read connectivity results (*.conn) exported from
% BESA Connectivity and to prepare data for BESA Statistics
%
% Specify the folder and file(s) that should be converted to *.tfc files in
% the 'Parameters' section.
% Also define the output folder.
%
% Note: This script supports converting multiple *.conn files from the same
%       input folder.
%       A corresponding *.bsa file specifying the channel configuration
%       will be created for the first file only!
%
% Copyright (C) 2018, BESA GmbH
%
% File name: BESA_Connectivity_to_BESA_Statistics.m
%
%
% Author: Robert Spangler
% Created: 2018-11-14


%% Clean up
clc; clear all; close all;


%% Add toolboxes
addpath 'C:\Matlab Toolboxes\besa_matlab_readers';
addpath 'C:\Matlab Toolboxes\MATLAB2BESA';


%% Parameters
% Input folder and filename(s)
% Note: Extension .conn will be appended automatically
InputFolder = 'C:\Users\Public\Documents\BESA Connectivity\Connectivity Results\';
InputFilenames{1} = 'StOn_AC9D_CD_iCoh';
%ImportFilenames{end+1} = '<filename #2>';
%ImportFilenames{end+1} = '<filename #3>';
% Export folder
% Note: Appendix ' - Export' and extension .tfc/.bsa will be added
% automatically
OutputFolder = 'C:\Users\Public\Documents\BESA Connectivity\Connectivity Results\';


%% Output information before starting loop
fprintf('Converting connectivity results to BESA Statistics:\n\n');


%% Load connectivity results and export to *.tfc for all input files
for CntFile=1:length(InputFilenames)
    fprintf('Processing file %i of %i...\n', CntFile, length(InputFilenames));
    % Current filepath incl. basename
    CurrFilePathName = [InputFolder InputFilenames{CntFile}];
    
    % Load results
    ConnResults = readBESAconn([CurrFilePathName '.conn']);

    % Prepare data for *.tfc export
    NumChannelsTFC = ConnResults.NumberChannels^2 - ConnResults.NumberChannels;
    % Split channels from connectivity results 
    LabelsConn = regexp(ConnResults.ChannelLabels, ' ', 'split')';
    LabelsConn(strcmp('',LabelsConn)) = [];
    % Channel labels:
    TFCChannelLabels = cell(NumChannelsTFC, 1);
    % Data matrix (must be: [NumChannels x NumFrequencies x NumSamples):
    Data = zeros(NumChannelsTFC, ConnResults.NumberFrequencies, ConnResults.NumberTimeSamples);
    % Copy imported data to output format
    Idx = 1;
    for i=1:ConnResults.NumberChannels
        for j=1:ConnResults.NumberChannels
            if i ~= j
                TFCChannelLabels{Idx} = [LabelsConn{i} 'to' LabelsConn{j}];
                Data(Idx, :, :) = ConnResults.Data(i, j, :, :);
                Idx = Idx+1;
            end;
        end;
    end;
    
    % Export data as *.tfc file for BESA Statistics
    cfgExport = [];
    cfgExport.NumChannels           = NumChannelsTFC;
    cfgExport.DataType              = ConnResults.DataType;
    cfgExport.ConditionName         = 'Condition1';
    cfgExport.NumTrials             = ConnResults.NumberTrials;
    cfgExport.NumSamples            = ConnResults.NumberTimeSamples;
    cfgExport.TimeStartInMS         = ConnResults.TimeStartInMS;
    cfgExport.TimeIntervalInMS      = ConnResults.IntervalInMS;
    cfgExport.NumFrequencies        = ConnResults.NumberFrequencies;
    cfgExport.FrequencyStartInHz    = ConnResults.FreqStartInHz;    
    if any(strcmp('FreqIntervalInHz',fieldnames(ConnResults)))
        cfgExport.FrequencyIntervalInHz = ConnResults.FreqIntervalInHz;
    end;
    if any(strcmp('Frequencies',fieldnames(ConnResults)))
        cfgExport.FrequenciesInHz = ConnResults.Frequencies;
    end;
    cfgExport.ChannelLabels         = TFCChannelLabels;
    besa_save2Tfc([OutputFolder InputFilenames{CntFile} ' - Export.tfc'], cfgExport, Data);
    
    if CntFile == 1
        % Export *.bsa file for corresponding sensor layout (matrix view)
        % Set source types to dipole for all traces
        ChannelTypes = cell(NumChannelsTFC, 1);
        for i=1:NumChannelsTFC
            ChannelTypes{i} = 'Dip';
        end;
        % Channel positions
        % Coordinate system: -1 -- x --> 1
        %                    1
        %                    |
        %                    |
        %                    y
        %                    |
        %                    |
        %                    v
        %                    -1
        ChannelCoordinates = zeros(NumChannelsTFC, 3); 
        ItemWidth = 2 / (ConnResults.NumberChannels + 1);
        ItemPosY = linspace(-1 + ItemWidth, 1 - ItemWidth, ConnResults.NumberChannels);
        ItemPosX = fliplr(ItemPosY);
        Idx = 1;
        for i=1:ConnResults.NumberChannels
            for j=1:ConnResults.NumberChannels
                if i~=j
                    dX = ItemPosX(i);
                    dY = ItemPosY(j);
                    ChannelCoordinates(Idx, :) = [dY dX 0];
                    Idx = Idx+1;
                end;
            end;
        end;
        % Store *.bsa file
        besa_save2Bsa(OutputFolder, [InputFilenames{CntFile} ' - Export.bsa'], ...
            ChannelCoordinates, zeros(size(ChannelCoordinates)), ...
            TFCChannelLabels, ChannelTypes, false);
    end;
end;


%% Load connectivity results and export to *.tfc for all input files
fprintf('\nScript finished!\n');

