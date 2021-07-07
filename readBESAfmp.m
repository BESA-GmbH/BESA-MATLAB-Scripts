function data = besaBESAfmp(filename)
% Reads BESA *.fmp files containing power resulted from FFT.

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

fp = fopen(filename, 'r');

if (fp)
    
    % Boolean variable containing the info if the file is in ascii
    % multiplexed or ascii verctorized format.
    isMul = 1;
    % Read header of .mul file
    data.Spacing = fscanf(fp,'Spacing = %f [Hz]');
    
    % If not .mul, then try reading header of .avr file
    if(isempty(data.Spacing))
    
        isMul = 0;
        Npts = fscanf(fp,'Npts= %i');
        TSB = fscanf(fp,' TSB= %f');    
        data.Spacing = fscanf(fp,'DI= %f');
        
    end
    
    tline = fgetl(fp);

    % Get the channel labels.
    ch_labels = strtrim(fgetl(fp));
    data.ChannelLabels = regexp(ch_labels, '\ ', 'split');
    n_channles = size(data.ChannelLabels, 2);
    
    i = 1;
    %tline = fgetl(fp);
    while ischar(tline)
        
        try 
            
            if(isMul == 1)
                
                data.Power(i,:)=fscanf(fp, '%f', [1 n_channles]);
            
            else
                
                data.Power(i,:)=fscanf(fp, '%f', [1 Npts]);
                
            end
            i = i + 1;
            
        catch
            
            break;
            
        end
        
        %tline = fgetl(fp);
        
    end
    
    if(isMul == 1)
        
        data.Nsamples = size(data.Power, 1);
    
    else
        
        data.Nsamples = Npts;
        
    end
    
    for fr = 1 : data.Nsamples
        
        data.Freqs(fr) = fr * data.Spacing;
        
    end
    
end

fclose(fp);