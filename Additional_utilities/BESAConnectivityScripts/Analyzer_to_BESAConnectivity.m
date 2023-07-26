% Matlab_to_BESAConnectivity
%
% Script to generate generate and export data from
% MATLAB to BESA Connectivity.
%
% It shows how to define required parameters, generates
% example sine waves and calls the export function 
% besa_save2Connectivity to store the simulated example 
% data to disc. It will store the file containing the 
% binary data matrix, as well as the header file and 
% channel description file in ASCII format.
%
% The script can be easily adopted to export your trial data 
% do BESA Connectivity for time-frequency and connectivity 
% analysis! 
%
% Copyright (C) 2023, BESA GmbH
%
% File name: Matlab_to_BESAConnectivity.m
%
%
% Author: Robert Spangler and Mateusz Rusiniak
% Created: 2023-07-26


% Clean up
%clc; clear all; close all;


%% Add toolboxes
addpath 'C:\Matlab Toolboxes\MATLAB2BESA';


%% Parameters
NumChannels = EEG.nbchan;
NumTrials = EEG.trials;
SamplingRate = EEG.srate;
EpochLength = [EEGTime(1) EEGTime(end)];
Baseline = [EEGTime(1) 0];
ConditionName = 'BAtoBESA';
FilePathName = [pwd '\BAtoBESA.generic'];


%% Channel labels and units
ChannelLabels = cell(NumChannels, 1);
ChannelUnits = cell(NumChannels, 1);
ChannelTypes = cell(NumChannels, 1);
ChannelCoordinates = zeros(NumChannels, 3);
for ChanIdx=1:NumChannels
    ChannelLabels{ChanIdx} = [EEG.chanlocs(ChanIdx).labels];
    ChannelUnits{ChanIdx} = 'µV'; % 'nAm' 'µV'
    if ~isempty(EEG.chanlocs(ChanIdx).sph_theta)
        ChannelTypes{ChanIdx} = 'EEG'; % 'DipSrc' 'POL' 'EEG' 'MEG'
        [ChannelCoordinates(ChanIdx,1),...
     ChannelCoordinates(ChanIdx,2),...
     ChannelCoordinates(ChanIdx,3)]=besa_transformCartesian2Spherical(...
                        EEG.chanlocs(ChanIdx).Y,...
                        EEG.chanlocs(ChanIdx).X,...
                         EEG.chanlocs(ChanIdx).Z);
    else
        ChannelTypes{ChanIdx} = 'POL';
    end
    %EEG.chanlocs(ChanIdx).sph_phi];
end    


%% Sine waves
 TotalEpochLength = EpochLength(2) - EpochLength(1);
 NumberSamples = EEG.pnts;
 Latencies = linspace(EpochLength(1), EpochLength(2), NumberSamples) * 0.001;
 Data = cell(1, NumTrials);
 for TrialIdx=1:NumTrials
     TrialData = zeros(NumChannels, NumberSamples);
     for ChanIdx=1:NumChannels
         TrialData(ChanIdx,:)=EEG.data(ChanIdx,:,TrialIdx);
%         % Generate sine waves incl. noise
%         AmplitudeSignal = 1;
%         AmplitudeNoise = 0.2;
%         Frequency = 5;
%         TrialData(ChanIdx, :) = ...
%             AmplitudeSignal*sin(2*pi*Frequency*Latencies) + ...
%             AmplitudeNoise*randn(size(Latencies));
     end    
     Data{TrialIdx} = TrialData;
 end


%% Plot data of first trial
%%{
% MaxVal = max(max(abs(Data{1})));
% for ChanIdx=1:NumChannels
%     subplot(NumChannels, 1, ChanIdx);
%     plot(Latencies, Data{1}(ChanIdx,:));
%     hold on;
%     plot([Latencies(1) Latencies(end)], [0 0], 'k');
%     plot([0 0], [-MaxVal MaxVal], 'k');
%     xlim([Latencies(1) Latencies(end)]);
%     ylim([-MaxVal MaxVal]);
% end
%}


%% Export to BESA Connectivity
cfgExport = [];
cfgExport.NumChannels   = NumChannels;
cfgExport.SamplingRate  = SamplingRate;
cfgExport.Prestimulus   = abs(EpochLength(1));
cfgExport.BaselineStart = Baseline(1);
cfgExport.BaselineEnd   = Baseline(2);
cfgExport.EpochLength   = EpochLength(2) - EpochLength(1);
cfgExport.Padding       = 0;
cfgExport.PaddingExport = 0;
cfgExport.ConditionName = ConditionName;
cfgExport.ChannelLabels = ChannelLabels;
cfgExport.ChannelUnits  = ChannelUnits;
cfgExport.ChannelTypes  = ChannelTypes;
cfgExport.ChannelCoordinates = ChannelCoordinates;
besa_save2Connectivity(FilePathName, cfgExport, Data);
