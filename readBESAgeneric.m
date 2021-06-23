function data = readBESAgeneric(filename)

% readBESAgeneric reads *.generic data files exported from BESA Research.
%
% Use as
%    data = readBESAgeneric(filename)
%
% Created Sept. 17, 2019 Robert Spangler

data = [];
data.ChanLabels = {};
data.ChanUnits = {};

% Perform some checks
[FullPath, Filename, FileExt] = fileparts(filename);
if strcmp(FileExt, '.generic') ~= 1
  error('Error reading file: extension .generic expected!'); 
end

% Read *.generic file
% Open file
fpGeneric = fopen(filename, 'r');
if fpGeneric
    % Read header (single line)
    Header = fgetl(fpGeneric);
    
    % Read all key value pairs in file 
    while ~feof(fpGeneric)
        % Read line
        newLine = fgetl(fpGeneric);
        
        % Does contain channel info
        if ~isempty(findstr(newLine, 'channelUnits='))
            % Get channel info
            CurrChanLine = strrep(newLine, 'channelUnits=', '');
            CurrChanInfo = regexp(CurrChanLine, ' ', 'split');
            % Save channel info
            data.ChanLabels{end+1} = CurrChanInfo{1};
            data.ChanUnits{end+1} = CurrChanInfo{2};
        else
            % Save general file info
            LineInfo = regexp(newLine, '=', 'split');
            if strcmp(LineInfo{1}, 'format') == 1 || ...
               strcmp(LineInfo{1}, 'file') == 1 || ...
               strcmp(LineInfo{1}, 'conditionName') == 1
                data.(LineInfo{1}) = LineInfo{2};
            else
                data.(LineInfo{1}) = str2num(LineInfo{2});
            end;            
        end;
    end;
    
    % Close file 
    fclose(fpGeneric);
end;

% Check if *.dat file is specified and exists
if any(strcmp('file',fieldnames(data))) == 1
    if exist([FullPath '\' data.file], 'file') == 2
        % File exists. Read data samples.
        % Open file
        fpDat = fopen([FullPath '\' data.file], 'r', 'ieee-le');
        if fpDat
            % Samples per epoch
            EpochSamples = data.nSamples / data.epochs;
            
            % Save trials
            data.trial = [];
            for i=1:data.epochs
                %StartSample = (i-1)*data.nSamples + 1;
                %data.trial{i} = xdata(:, StartSample:StartSample+data.nSamples);
                data.trial{i} = fread(fpDat, [data.nChannels, EpochSamples], '*float32');
            end;
            
            % Close file 
            fclose(fpDat);
        end;
    else
        % File does not exist!
        error('Error reading file: .dat file not found!');
    end;
end;
