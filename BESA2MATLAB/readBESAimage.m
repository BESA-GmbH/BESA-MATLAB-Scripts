function image = readBESAimage(filename)
% readBESAimage reads information from exported BESA images (Beamformer, 
% LAURA, sLORETA, swLORETA, LORETA, sSLOFO, User-Defined image, surface 
% minimum norm, Probe scan, Sensitivity). The function poutput is a struct
% with fields containing all relevant information from the image file.
%
% Use as
%   image = readBESAimage(filename)

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
% Modified April 26, 2006 Robert Oostenveld
% Modified November 6, 2006 Karsten Hoechstetter
% Modified January 2, 2008 Karsten Hoechstetter
% Modified April 4, 2019 Mateusz Rusiniak

if isempty(findstr(filename,'.'))
  filename = [filename,'.dat'];
end
fp = fopen(filename);

ImageVersion = fgetl(fp);

% Check Version Number
version = str2num(ImageVersion(findstr(ImageVersion,':')+1:length(ImageVersion)));

switch version
    case 1
        image=import_v1(ImageVersion,fp);
    case 2
        image=import_v2(fp);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Image Version 1.0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image=import_v1(ImageVersion,fp)

% Check type of Image
if ~isempty(findstr(ImageVersion,'MN'))
  image.Imagetype = 'Minimum Norm';
  image.Imagemode = 'Time';
else
  fgetl(fp);
  ImageInfo = fgetl(fp);

  if ~isempty(findstr(ImageInfo,'Sens.'))
    image.Imagetype = 'Sensitivity';
  elseif ~isempty(findstr(ImageInfo,'MSBF'))
    image.Imagetype = 'MSBF';
    image.Imagemode = 'Time-Frequency';
  elseif ~isempty(findstr(ImageInfo,'MSPS'))
    image.Imagetype = 'MSPS';
    if ~isempty(findstr(ImageInfo,'Image (TF)'))
      image.Imagemode = 'Time-Frequency';
    else
      image.Imagemode = 'Time';
    end
  end

  if strcmp(ImageInfo(end-3:end),'[dB]')
    image.Units = 'dB';
  else
    image.Units = '%';
  end
end

% Extract additional information (time and frequency, source, MN Info)
if strcmp(image.Imagemode,'Time-Frequency')
  TimeSeparator = findstr(ImageInfo,' : ');
  Blanks = findstr(ImageInfo,' ');
  [x,Index] = min(abs(Blanks-TimeSeparator));
  TimeIndex=Blanks(Index-1);
  image.Time = sscanf(ImageInfo(TimeIndex:end),'%s',4);
  image.Frequency = sscanf(ImageInfo(findstr(ImageInfo,'ms')+3:end),'%s',2);
elseif strcmp(image.Imagetype,'Sensitivity')
  image.Source = ImageInfo(findstr(ImageInfo,' - ')+3:end);
elseif strcmp(image.Imagetype,'Minimum Norm')
  fgetl(fp);
  h = fgetl(fp); image.DataFile = h(21:end);
  h = fgetl(fp); image.Condition = h(21:end);
  h = fgetl(fp);
  % If h is not empty it means we are dealing with a newer version of the 
  % files. These might also include the information about the cortical 
  % method used (e.g. cortical LORETA, minimum norm, cortical CLARA).
  if(~isempty(h)) % ergo, this is a new version!
  
      image.DataType = h(21:end);
      h = fgetl(fp); image.Method = h(21:end);
      fgetl(fp); % Empty line
      
  else % ergo, this is the old version! Set some default values.
      
      image.DataType = 'n.a.';
      image.Method = 'Surface Minimum Norm';
      
  end
  if(strcmp(image.Method,'Surface Minimum Norm'))
      
      h = fgetl(fp); image.DepthWeighting = h(21:end);
      h = fgetl(fp); image.SpTmpWeighting = h(21:end);
      h = fgetl(fp); image.SpTmpWeightingType = h(21:end);
      h = fgetl(fp); image.Dimension = str2num(h(21:end));
      h = fgetl(fp); image.NoiseEstimation = h(21:end);
      h = fgetl(fp); image.NoiseWeighting = h(21:end);
      h = fgetl(fp); image.NoiseScaleFactor = str2num(h(21:end));
      h = fgetl(fp); image.SelMeanNoise = h(21:end);
  
  elseif(strcmp(image.Method,'Cortical LORETA'))
      
      h = fgetl(fp); image.DepthWeighting = h(25:end);
      h = fgetl(fp); image.RegularizationType = h(25:end);
      h = fgetl(fp); image.RegularizationValue = h(25:end);
      h = fgetl(fp); image.LaplacianType = h(25:end);
      
  elseif(strcmp(image.Method,'Cortical CLARA'))
      
      h = fgetl(fp); image.DepthWeighting = h(25:end);
      h = fgetl(fp); image.RegularizationType = h(25:end);
      h = fgetl(fp); image.RegularizationValue = h(25:end);
      h = fgetl(fp); image.LaplacianType = h(25:end);
      h = fgetl(fp); image.AutomaticIterations = h(25:end);
      h = fgetl(fp); image.NumberOfIterations = h(25:end);
      h = fgetl(fp); image.RegularizeIterations = h(25:end);
      h = fgetl(fp); image.IterationsRegValue = h(25:end);
      h = fgetl(fp); image.ImageClipping = h(25:end);
      
  end
  
  fgetl(fp);
  h = fgetl(fp); image.Locations = str2num(h(21:end));
  h = fgetl(fp); image.TimeSamples = str2num(h(21:end));
  fgetl(fp);  fgetl(fp);   fgetl(fp);
end

% Get Coordinates and Data
if ~isempty(strmatch(image.Imagetype,strvcat('MSPS','MSBF','Sensitivity')))
  % Get Coordinates
  fgetl(fp); fgetl(fp);
  h = fgetl(fp);
  hx = sscanf(h,'X: %f %f %d');
  xmin = hx(1);  xmax = hx(2);  xnum = hx(3);
  h = fgetl(fp);
  hy = sscanf(h,'Y: %f %f %d');
  ymin = hy(1);  ymax = hy(2);  ynum = hy(3);
  h = fgetl(fp);
  hz = sscanf(h,'Z: %f %f %d');
  zmin = hz(1);  zmax = hz(2);  znum = hz(3);
  fgetl(fp);

  image.Coordinates=struct('X',{[xmin:floor((xmax-xmin)/(xnum-1)*10000)/10000:xmax]},...
    'Y',{[ymin:floor((ymax-ymin)/(ynum-1)*10000)/10000:ymax]},...
    'Z',{[zmin:floor((zmax-zmin)/(znum-1)*10000)/10000:zmax]});

  % Get Data
  image.Data = zeros(xnum,ynum,znum);
  for z=1:znum
    fgetl(fp);
    a=fscanf(fp,'%f',[xnum,ynum]);
    for x=1:xnum
      for y=1:ynum
        image.Data(x,y,z)=a(x,y);
      end
    end
    fgetl(fp);fgetl(fp);
  end

% Minimum Norm Image
elseif ~isempty(strmatch(image.Imagetype,('Minimum Norm')))
  fscanf(fp,'Latency (milliseconds):');
  image.Latency = fscanf(fp,'%f',[1,image.TimeSamples]);
  image.Coordinates = zeros(image.Locations,3);
  image.Data = zeros(image.Locations,image.TimeSamples);
  for i=1:image.Locations
    h=fscanf(fp,'%f',[1,3]);
    image.Coordinates(i,:) = h;
    image.Data(i,:)=fscanf(fp,'%f',[1,image.TimeSamples]);
  end
end

fclose(fp);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Image Version 2.0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image=import_v2(fp)
fgetl(fp);
c=fgetl(fp); image.DataFile = c(21:end);
c=fgetl(fp); image.Condition = c(21:end);
c=fgetl(fp); 
if strfind(c,'Method')
    image.Imagetype = c(21:end);
    image.Imagemode = 'Time';
    c=fgetl(fp); image.Regularization = c(21:end);
    c=fgetl(fp); 
    t=findstr(c,' ms');
    if t
        image.Latency = c(1:t-1);
    else t=0;
    end
    image.Units = strtrim(c(t+3:end));
elseif ~isempty(findstr(c,'MSBF'))
    image.Imagetype = 'MSBF';
    image.Imagemode = 'Time-Frequency';
    if strcmp(c(end-3:end),'[dB]')
        image.Units = 'dB';
    else
        image.Units = '%';
    end
elseif ~isempty(findstr(c,'MSPS'))
    image.Imagetype = 'MSPS';
    if ~isempty(findstr(c,'Image (TF)')) 
        image.Imagemode = 'Time-Frequency';
    else
        image.Imagemode = 'Time';
        image.Latency = c(1:findstr(c,' ms')-1);
    end
    if strcmp(c(end-3:end),'[dB]')
        image.Units = 'dB';
    else
        image.Units = '%';
    end
elseif ~isempty(findstr(c,'Sens'))
    image.Imagemode = 'Sensitivity';
    image.Units = '%';
    image.Source = sscanf(c,'Src. %i');
end    
fgetl(fp);fgetl(fp);
c=fgetl(fp);  X=sscanf(c,'X: %f %f %f');  
c=fgetl(fp);  Y=sscanf(c,'Y: %f %f %f');
c=fgetl(fp);  Z=sscanf(c,'Z: %f %f %f');
image.Coordinates=struct('X',{[X(1):floor((X(2)-X(1))/(X(3)-1)*10000)/10000:X(2)]},...
    'Y',{[Y(1):floor((Y(2)-Y(1))/(Y(3)-1)*10000)/10000:Y(2)]},...
    'Z',{[Z(1):floor((Z(2)-Z(1))/(Z(3)-1)*10000)/10000:Z(2)]});
fgetl(fp);
c=fgetl(fp);
if strfind(c,'Voxel locations')
    image.CoordinatesTal.X = zeros(1,X(3)*Y(3)*Z(3));
    image.CoordinatesTal.Y = zeros(1,X(3)*Y(3)*Z(3));
    image.CoordinatesTal.Z = zeros(1,X(3)*Y(3)*Z(3));
    image.CoordinatesUnit.X = zeros(1,X(3)*Y(3)*Z(3));
    image.CoordinatesUnit.Y = zeros(1,X(3)*Y(3)*Z(3));
    image.CoordinatesUnit.Z = zeros(1,X(3)*Y(3)*Z(3));
    for i=1:X(3)*Y(3)*Z(3) 
        try
            c=fgetl(fp); C = sscanf(c,'%f %f %f %f %f %f');
            image.CoordinatesUnit.X(i)=C(1);
            image.CoordinatesUnit.Y(i)=C(2);
            image.CoordinatesUnit.Z(i)=C(3);
            image.CoordinatesTal.X(i)=C(4);
            image.CoordinatesTal.Y(i)=C(5);
            image.CoordinatesTal.Z(i)=C(6);
        catch
            image.CoordinatesUnit.X=image.CoordinatesUnit.X(1:i-1);
            image.CoordinatesUnit.Y=image.CoordinatesUnit.Y(1:i-1);                
            image.CoordinatesUnit.Z=image.CoordinatesUnit.Z(1:i-1);
            image.CoordinatesTal.X=image.CoordinatesTal.X(1:i-1);
            image.CoordinatesTal.Y=image.CoordinatesTal.Y(1:i-1);                
            image.CoordinatesTal.Z=image.CoordinatesTal.Z(1:i-1);
            break
        end            
    end
    for t=1:1000000
        if (c>0)
            C=sscanf(c,'Sample %f, Latency %f');
            if (numel(C)==2)   
                if ~isfield(image.Coordinates,'T')
                    image.Coordinates.T=C(2);
                else
                    image.Coordinates.T(numel(image.Coordinates.T)+1)=C(2);      
                end
            end
        end
        try
            temp=fscanf(fp,'%f',[3,length(image.CoordinatesTal.X)]);
            image.Data(:,:,t)=temp';           
            fgetl(fp); c=fgetl(fp);
        catch
            break
        end
    end
elseif strfind(c,'Sample')          % Time Series 
    
    for zindex=1:Z(3)
        for t=1:100000
            if (c>0)
               C=sscanf(c,'Sample %f, %f');
                    if (numel(C)==2)   
                        if ~isfield(image.Coordinates,'T')
                            image.Coordinates.T=C(2);
                        else
                              image.Coordinates.T(numel(image.Coordinates.T)+1)=C(2);
                             
                        end
                    end
            end         
            try
                for zindex=1:Z(3)
                    c=fgetl(fp);
                    image.Data(:,:,zindex,t)=fscanf(fp,'%f',[X(3),Y(3)]);
                    fgetl(fp); fgetl(fp);
                end
                     c=fgetl(fp);
            catch
                break
            end
        end
    end
else                                % Single Image
    image.Data=zeros(X(3),Y(3),Z(3));
    image.Data(:,:,1)=fscanf(fp,'%f',[X(3),Y(3)]);
    for zindex=2:Z(3)
        fgetl(fp); fgetl(fp); fgetl(fp);
        image.Data(:,:,zindex)=fscanf(fp,'%f',[X(3),Y(3)]);
    end
end
fclose(fp);


function matrix=getblock(fp,no_rows,no_columns)
matrix = zeros(no_rows,no_columns);
for row=1:no_rows
    fgetl(fp)
    matrix(row,:)=str2double(fgetl(fp));
end
