function [besa_temp, image] = readdatfile(filename)
%reads image files using readBESAimage and converts them into the format of
%a structure exported by BESA (structtype 'besa_image')

image = readBESAimage(filename);


besa_temp.datafile  = image.DataFile;
if isfield(image,'Imagetype')
    method  = image.Imagetype; 
elseif isfield(image,'Imagemode')&& strcmp(image.Imagemode,'Sensitivity')
    method  = image.Imagemode;
end;

%In the .dat file, methods are given as "Standard XXX" instead of "XXX",
%and instead of the entry "User Defined", detailed information about the
%method is given including a string "first method: user".
%First ask whether the method is user-defined, then ask for other methods
if findstr('User', method)
    besa_temp.type = 'User-defined image';
elseif findstr('Standard',method)
    [beginning, method]    = strtok(method,' ');
    besa_temp.type      =   method; 
else
    besa_temp.type = method;
end;
%remove blanks
besa_temp.type = strtrim(besa_temp.type);

if strcmpi(method,'Minimum Norm')
    besa_temp.data                          = image.Data';
    besa_temp.xcoordinates                  = image.Coordinates(:,1)';
    besa_temp.ycoordinates                  = image.Coordinates(:,2)';
    besa_temp.zcoordinates                  = image.Coordinates(:,3)';
    if isstr(image.Latency)
         besa_temp.latencies     = str2double(image.Latency);
    else
        besa_temp.latencies     = image.Latency;
    end;
    besa_temp.MNdepthweighting              = image.DepthWeighting;
    besa_temp.MNspatiotemporalweighting     = image.SpTmpWeighting;
    besa_temp.MNspatiotemporalweightingtype = image.SpTmpWeightingType;
    besa_temp.MNdimension                   = num2str(image.Dimension); 
    besa_temp.MNnoiseestimation             = image.NoiseEstimation;
    besa_temp.MNnoiseweighting              = image.NoiseWeighting;
    besa_temp.MNnoisescalefactor            = num2str(double(image.NoiseScaleFactor));
    besa_temp.MNmeannoise                   = image.SelMeanNoise %??
    besa_temp.type      = 'surface minimum norm'; %as in structure exported by MATLAB
    [Cond, nr_trials] = strtok(image.Condition,':');
    besa_temp.condition     = Cond;
        [nr_trials,rest]= strtok(nr_trials,' ');
        [nr_trials,rest]=strtok(rest,' ');
        [avs, rest] = strtok(rest,' ');
        [filt, Filters] = strtok(rest,' ');
    besa_temp.numberoftrials = str2num(nr_trials);
    besa_temp.filters = strtrim(Filters);

elseif strcmpi(method,'MSBF')
    besa_temp.data          = image.Data;
    besa_temp.xcoordinates  = image.Coordinates.X;
    besa_temp.ycoordinates  = image.Coordinates.Y;
    besa_temp.zcoordinates  = image.Coordinates.Z;
    besa_temp.units         = image.Units;
    besa_temp.domain        = image.Imagemode;  
       [Cond,Filters]= strtok(image.Condition,' ');
    besa_temp.condition     = Cond;
       [FilterString, Filters] = strtok(strtrim(image.Condition),' ');
    besa_temp.filters    = strtrim(Filters);
    besa_temp.type          = 'Beamformer';
else  
    besa_temp.data          = image.Data;
    besa_temp.xcoordinates  = image.Coordinates.X;
    besa_temp.ycoordinates  = image.Coordinates.Y;
    besa_temp.zcoordinates  = image.Coordinates.Z;
    if isfield(image,'Latency') 
        if isstr(image.Latency)
             besa_temp.latencies = str2double(image.Latency);
        else
            besa_temp.latencies = image.Latency;
        end;
    else
        image.latencies = '?';
    end;
    if isfield(image,'Regularization')
         besa_temp.regularization= image.Regularization;
    else 
        besa_temp.regularization = '';
    end;
    besa_temp.units         = image.Units;
    besa_temp.domain        = image.Imagemode;
        [Cond,Filters]= strtok(image.Condition,' ');
    besa_temp.condition     = Cond;
    besa_temp.filters       = Filters;
end;

besa_temp.structtype = 'besa_image';