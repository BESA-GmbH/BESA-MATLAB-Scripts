function GFPRV = readBESAgfprv(filename)

% readBESAgfprv reads all information from a .dat file that contains the
% global field power (GFP) and the residual variance (RV) as exported from 
% BESA
%
% Use as
%   GFPRV = readBESAgfprv(filename)
%
% The output is a structure containing the following fields:
%   Npts: number of sample points
%   TSB: latency of the first sample
%   DI: time interval between two consecutive sample points
%   Total RV: the total residual variance in percent
%   MinRV: the minimum residual variance in percent
%   MaxGFP: The absolut value of the maximum of the global field power
%   RV: the residual variance in percent [Npts x 1]
%   GFP: the global field power in percent [Npts x 1]
%
% Author: Karsten Hoechstetter
%
% Modified November 10, 2006 Karsten Hoechstetter
% Last modified March 10, 2014 Todor Jordanov

% Check if the name of the file was specified with or without extension.
if isempty(findstr(filename, '.'))
  filename = [filename, '.dat'];
end

fp = fopen(filename);

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fp >= 3)

    header = fgetl(fp);
    headerinfo = regexp(header, '[=]*\s', 'split');
    HeaderVariables = {'Npts' 'TSB' 'DI' 'TotalRV' 'MinRV' 'MaxGFP'};
    
    % Check for variable 'Npts'
    if(sum(strcmp(HeaderVariables{1}, headerinfo)) == 1)
        
        CurrIndex = find(strcmp(HeaderVariables{1}, headerinfo) == 1);
        GFPRV.Npts = str2double(headerinfo(CurrIndex + 1));
        
    end
    
    % Check for variable 'TSB'
    if(sum(strcmp(HeaderVariables{2}, headerinfo)) == 1)
        
        CurrIndex = find(strcmp(HeaderVariables{2}, headerinfo) == 1);
        GFPRV.TSB = str2double(headerinfo(CurrIndex + 1));
        
    end
    
    % Check for variable 'DI'
    if(sum(strcmp(HeaderVariables{3}, headerinfo)) == 1)
        
        CurrIndex = find(strcmp(HeaderVariables{3}, headerinfo) == 1);
        GFPRV.DI = str2double(headerinfo(CurrIndex + 1));
        
    end
    
    % Check for variable 'TotalRV'
    if(sum(strcmp(HeaderVariables{4}, headerinfo)) == 1)
        
        CurrIndex = find(strcmp(HeaderVariables{4}, headerinfo) == 1);

        idx = strfind(headerinfo(CurrIndex + 1), '%');
        if (isempty(idx) == false)
            % When TotalRV is a percentage value (e.g. TotalRV= 8.60623%)
            percentage_value = headerinfo(CurrIndex + 1);
            GFPRV.TotalRV = str2double(percentage_value{1}(1:idx{1}-1));
        else
            GFPRV.TotalRV = str2double(headerinfo(CurrIndex + 1));
        end
        
    end
    
    % Check for variable 'MinRV'
    if(sum(strcmp(HeaderVariables{5}, headerinfo)) == 1)
        
        CurrIndex = find(strcmp(HeaderVariables{5}, headerinfo) == 1);

        idx = strfind(headerinfo(CurrIndex + 1), '%');
        if (isempty(idx) == false)
            % When MinRV is a percentage value (e.g. MinRV= 2.9152%)
            percentage_value = headerinfo(CurrIndex + 1);
            GFPRV.MinRV = str2double(percentage_value{1}(1:idx{1}-1));
        else
            GFPRV.MinRV = str2double(headerinfo(CurrIndex + 1));
        end
        
    end
    
    % Check for variable 'MaxGFP'
    if(sum(strcmp(HeaderVariables{6}, headerinfo)) == 1)
        
        CurrIndex = find(strcmp(HeaderVariables{6}, headerinfo) == 1);
        GFPRV.MaxGFP = str2double(headerinfo(CurrIndex + 1));
        
    end
    
    while(true)
        
        CurrentLine = fgetl(fp);
        % Check if end of file.
        if(~ischar(CurrentLine))
            
            break;
            
        end
        
        % Check if it is 'Residual Variance' or 'Global Field Power'.
        if(~isempty(strfind(CurrentLine, 'GFP')))
            
            GFPRV.GFP = sscanf(CurrentLine(6:end), '%f', [GFPRV.Npts,1]);
        
        else
            
            GFPRV.RV = sscanf(CurrentLine(6:end), '%f', [GFPRV.Npts,1]);
            
        end
        
    end
    
    fclose(fp);

else
    
    GFPRV = [];
    disp('Error! Invalid file identifier.')
    
end
