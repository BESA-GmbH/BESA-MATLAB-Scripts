function besa_channels = load2besa_channels(filename)
% load2besa_channels reads sensor level data from an AVR and ELP files and. 
%
% Parameters:
%     [filename]
%         In the case that the current folder is not the folder containing 
%         the file it should be the full path including the name of the 
%         elp file else only the name of the file should be specified. 
% 
% Return:
%     [besa_channels] 
%         A Matlab structure containing the data and the corresponding
%         parameters stored in the AVR-file and ELP-file. This structure is
%         identical to the one returned when doing the matlab export in
%         BESA.

% Copyright (C) 2014, BESA GmbH
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
% Author: Andre Waelkens
% Created: 2014-05-27



avrInfo = readBESAavr([filename '.avr']);
[elpInfo, chanTypes] = readBESAelp([filename '.elp']);
%sfhInfo = readBESAsfh([filename '.sfh']);

% Initialize besa_channels with dummy values.
besa_channels.datafile = 'NA';
besa_channels.channeltypes = 'NA';
besa_channels.channellabels = 'NA';
besa_channels.channelunits = 'NA';
besa_channels.channelcoordinates = 'NA';
besa_channels.montage = 'NA';
besa_channels.filters = 'NA';
besa_channels.samplingrate = 0;
besa_channels.HSPcoordinates = 0;
besa_channels.HSPtypes = 'NA';
besa_channels.HSPlabels = 'NA';
besa_channels.headcenter = [0 0 0];
besa_channels.headradius = 0;
besa_channels.electrodethickness = 0;
besa_channels.structtype = 'besa_channels';
besa_channels.datatype = 'Segment';
besa_channels.data = 0;


besa_channels.channellabels = transpose(strread(avrInfo.ChannelLabels,...
    '%s', 'delimiter',' '));
besa_channels.data.amplitudes = transpose(avrInfo.Data);
besa_channels.data.latencies = avrInfo.Time;

% A correction to the latencies has to be done as the avr convention is one
% delta element shifted in comparison to the "sent to Matlab" convention.

besa_channels.samplingrate = (1000 / avrInfo.DI);

besa_channels.channeltypes = transpose(chanTypes);

% Load sfh Information.
%[rows cols] = size(sfhInfo.SurfacePointsCoordinates);
%besa_channels.channelcoordinates = ...
%    sfhInfo.SurfacePointsCoordinates(4:rows, 1:3) / 1000;

end