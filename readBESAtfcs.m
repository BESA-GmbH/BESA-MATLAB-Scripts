function tfc_data = readBESAtfcs(filename)

% readBESAtfcs reads single trial TFC data exported from BESA Research.
%
% Use as
%   tfc = readBESAtfcs(filename)
%
% The output is a structure containing a 3D matrix with complex numbers 
% for every trial. The size of the matrix is 
% [NChannels x NFreqSamples x NTimeSamples]. 
%
% Created June 28, 2012 Todor Jordanov

if isempty(findstr(filename,'.'))
    
  filename = [filename,'.tfcs'];
  
end

fp = fopen(filename, 'r');

if (fp)
    
    tfc_data.trials = {};
    
    n_trials = 0;
    n_channels = 0;
    n_freqs = 0;

    tline = fgetl(fp);
    tline = strtrim(tline);
    
    while ischar(tline)
        
        if(strncmpi(tline, 'Trial', 5))
            
            n_trials = n_trials + 1;
            n_channels = 0;
            n_freqs = 0;
            
        elseif(strncmpi(tline, 'Channel', 7))

            n_channels = n_channels + 1;
            n_freqs = 0;

        else
            
            tline = strtrim(tline);
            
            n_freqs = n_freqs + 1;
                    
            % two_reals(1,:) : real components
            % two_reals(2,:) : imaginary components
            two_reals = sscanf(tline, '%f +i* %f\t', [2, Inf]);
            
            tfc_data.trials{n_trials}(n_channels, n_freqs, :) = ...
                complex(two_reals(1,:), two_reals(2,:));
            
        end
        
        tline = fgetl(fp);

    end

    fclose(fp);

end
