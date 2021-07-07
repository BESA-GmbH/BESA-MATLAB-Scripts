function conn_data = readBESAconn(filename)
% readBESAconn reads *.conn data files exported from BESA Connectivity.
%
% Use as
%   conn_data = readBESAconn(filename)
%
% The output (conn_data.DATA) is a structure containing a 4D matrix.
% The size of the matrix is [NChannels x NChannels x NFreqSamples x NTimeSamples]. 
%
% NOTE: Connectivity matrix [NChannels x NChannels]: Row indicate from and
%       column indicate to.
%
%                   To
%           1->1    1->2    1->3
%  From     2->1    2->2    2->3
%           3->1    3->2    3->3

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
% Created May 07, 2018 Jae-Hyun Cho

if isempty(findstr(filename,'.'))    
  filename = [filename,'.conn'];
end

fp = fopen(filename, 'r');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fp >= 3) 

    % Get the first line of the file. It looks something like that:
    % VersionNumber=1.0 DataType=CSD ConditionName=Condition 1
    % NumberTrials=98 ..
    FirstLine = fgetl(fp);
    
    if(~isempty(strfind(FirstLine, 'ConditionName=')))
        tmp = regexp(FirstLine, 'ConditionName=.+?(?=NumberTrials)', 'split');
        FirstLine_part1 = tmp{1};
        FirstLine = tmp{2};
    end

    headline_part1 = sscanf(FirstLine_part1, 'VersionNumber=%s DataType=%s ');

    conn_data.VersionNumber     = headline_part1(1:3);
    conn_data.DataType  		   = headline_part1(4:end);
    %conn_data.ConditionName     = fscanf(FirstLine_part1, 'ConditionName=%s %i '); % FIXME

    % Check if frequencies are specified (for non-equidistand frequency
    % spacing)
    StringCheckFrequency = ' Frequencies=';
    if(isempty(strfind(FirstLine, StringCheckFrequency)))
        % Equidistand frequency spacing
        headline = sscanf(FirstLine,...
            'NumberTrials=%i NumberTimeSamples=%i TimeStartInMS=%f IntervalInMS=%f NumberFrequencies=%f FreqStartInHz=%f FreqIntervalInHz=%f NumberChannels=%i');
    else
        % Non-equidistand frequency spacing
        SplitFirstLine = regexp(FirstLine, 'FreqIntervalInHz= ', 'split');

        % First part (before 'FreqIntervalInHz= ')
        headline = sscanf(SplitFirstLine{1},...
            'NumberTrials=%i NumberTimeSamples=%i TimeStartInMS=%f IntervalInMS=%f NumberFrequencies=%f FreqStartInHz=%f');
        
        % Second part (after 'FreqIntervalInHz= ')
        SplitFirstLineSecondPart = regexp(SplitFirstLine{2}, ' NumberChannels=', 'split');
        
        % Get frequencies
        % 1: Frequencies=...
        % 2: <number of channels>
        % Remove 'Frequencies=' string from substring
        SplitFirstLineSecondPart{1} = strrep(SplitFirstLineSecondPart{1}, 'Frequencies=', '');
        % Convert frequencies string to float array
        Frequencies = str2num(SplitFirstLineSecondPart{1})';
        % Get number of channels
        headline(8) = str2double(SplitFirstLineSecondPart{2});  
    end;
    
    % Set parameters
    conn_data.NumberTrials      = headline(1);
    conn_data.NumberTimeSamples = headline(2); % 4
    conn_data.TimeStartInMS     = headline(3);
    conn_data.IntervalInMS      = headline(4);
    conn_data.NumberFrequencies = headline(5); % 3
    conn_data.FreqStartInHz     = headline(6);    
    if(isempty(strfind(FirstLine, StringCheckFrequency)))
        % Equidistand frequency spacing
        conn_data.FreqIntervalInHz  = headline(7);
    else
        % Non-equidistand frequency spacing
        conn_data.Frequencies = Frequencies;
    end;   
    conn_data.NumberChannels	= headline(8); % 1, 2

    % The second line could contain the channel labels but it also could be
    % that it contains data.
    SecondLine = fgetl(fp);
    
    % Check if the second line contains labels or data values
    Characters = {'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' ...
        'n' 'o' 'p' 'q' 'r' 's' 't' 'u' 'v' 'w' 'x' 'y' 'z'};
    %iCounter = 1;
    
	conn_data.ChannelLabels = [];

    % If the second line contains characters then these are the channel labels.
	if(~isempty(regexpi(SecondLine, Characters, 'match')))
        conn_data.ChannelLabels = SecondLine;
    end
	
    conn_data.Data = zeros(conn_data.NumberChannels, conn_data.NumberChannels,...
    					  conn_data.NumberFrequencies, conn_data.NumberTimeSamples);
                      
	n_ch1     = 1;
	n_ch2     = 1;
	n_freqs   = 1;
	n_samples = conn_data.NumberTimeSamples;

    tline = fgetl(fp);
    tline = strtrim(tline);
    
    while ischar(tline)

        %tline = strtrim(tline);
        tmp   = regexp(tline, '\t', 'split');
        %n_samples = size(tmp, 2);
        
        for i = 1:n_samples
            % NOTE here
            % From (row) and To (column)
            conn_data.Data(n_ch2, n_ch1, n_freqs, i) = sscanf(tmp{i}, '%f');
            
            % To (row) and From (column)
            %conn_data.Data(n_ch1, n_ch2, n_freqs, i) = sscanf(tmp{i}, '%f');
        end

		if (n_freqs == conn_data.NumberFrequencies)
			n_freqs = 1;

            if (n_ch2 == conn_data.NumberChannels)
                n_ch2 = 1;
                n_ch1 = n_ch1 + 1;
            else
                n_ch2 = n_ch2 + 1;
            end

		else
		    n_freqs = n_freqs + 1;
		end

		tline = fgetl(fp);
        if isempty(tline)
            tline = fgetl(fp);
        end
       % tline = strtrim(tline);

    end
     
    fclose(fp);

else    
    conn_data = [];
    disp('Error! Invalid file identifier.')    
end
