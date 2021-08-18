function status = besa_saveImage(ImageStruct, file_path, file_name)
% BESA_SAVEIMAGE saves image data that was imported from BESA dat file
% with readBESAimage format. Data is exported in BESA IMAGE 2.0 standard
% and can be used in BESA Research (Source Analysis) and BESA Statistics
% function was not tested data standard 1.0 readout so be careful.
%
% Use as
%   besa_saveImage(ImageStruct, file_path, file_name)
%

% Copyright (C) 2019, BESA GmbH
%
% This file is part of MATLAB2BESA.
%
%    MATLAB2BESA is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    MATLAB2BESA is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with MATLAB2BESA. If not, see <http://www.gnu.org/licenses/>.
%
% Author: Mateusz Rusiniak
% Created: April 4, 2019

FullPath = fullfile(file_path, file_name);
% Open file for writing.
fid = fopen(FullPath, 'w');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fid >= 3)
    %define mode for writing 
  
    if (isfield(ImageStruct,'CoordinatesTal'))
         %Voxel values for each dipole orientation
        mode=3;
    elseif (isfield(ImageStruct.Coordinates,'T'))
        %time series
        mode=2;
    else
        %single image
        mode=1;
    end
    % Write the header.
    if (mode==3)
        fprintf(fid, 'BESA_SA_IMAGE_DISCRETE_COMPONENTS_OF_RS:2.0\n');
    else
        fprintf(fid, 'BESA_SA_IMAGE:2.0\n');
    end
    fprintf(fid, '\n');
    if (isfield(ImageStruct,'DataFile'))
        fprintf(fid, 'Data file:          %s\n',ImageStruct.DataFile);
    end
    if (isfield(ImageStruct,'Condition'))
        fprintf(fid, 'Condition:          %s\n',ImageStruct.Condition);
    end
    if (isfield(ImageStruct,'Imagetype'))
        fprintf(fid, 'Method:             %s\n',ImageStruct.Imagetype);
    end
    if (isfield(ImageStruct,'Regularization'))
        fprintf(fid, 'Regularization:     %s\n',ImageStruct.Regularization);
    end
    if (mode==1)
        if (isfield(ImageStruct,'Latency'))
            fprintf(fid, '%s ms',ImageStruct.Latency);
        end
    else
        if (isfield(ImageStruct,'Latency'))
            fprintf(fid, 'Latency:            %s\n',ImageStruct.Latency);
        end
    end
    if (isfield(ImageStruct,'Units'))
        fprintf(fid, '  %s\n',ImageStruct.Units);
    end
    fprintf(fid, '\n');
    if (isfield(ImageStruct,'Coordinates'))
     if (isfield(ImageStruct.Coordinates,'X')&&...
         isfield(ImageStruct.Coordinates,'Y')&&...
         isfield(ImageStruct.Coordinates,'Z'))
        fprintf(fid, 'Grid dimensions ([min] [max] [nr of locations]):\n');     
        fprintf(fid, 'X: %.6f %.6f %d\n',min(ImageStruct.Coordinates.X)...
                                      ,max(ImageStruct.Coordinates.X)...
                                      ,numel(ImageStruct.Coordinates.X));
        fprintf(fid, 'Y: %.6f %.6f %d\n',min(ImageStruct.Coordinates.Y)...
                                      ,max(ImageStruct.Coordinates.Y)...
                                      ,numel(ImageStruct.Coordinates.Y));
        fprintf(fid, 'Z: %.6f %.6f %d\n',min(ImageStruct.Coordinates.Z)...
                                      ,max(ImageStruct.Coordinates.Z)...
                                      ,numel(ImageStruct.Coordinates.Z));
     end
    end
   
    % Write data
    %Voxel values for each dipole orientation
    if (mode==3)
         if (isfield(ImageStruct.CoordinatesTal,'X')&&...
            isfield(ImageStruct.CoordinatesTal,'Y')&&...
            isfield(ImageStruct.CoordinatesTal,'Z')&&...
            isfield(ImageStruct.CoordinatesUnit,'X')&&...
            isfield(ImageStruct.CoordinatesUnit,'Y')&&...
            isfield(ImageStruct.CoordinatesUnit,'Z'))
            fprintf(fid,'==============================================================================================');
            fprintf(fid,'\n');
            fprintf(fid,'Voxel locations (Unit Sphere/Talairach)\n');
            for row=1:numel(ImageStruct.CoordinatesTal.X)
                fprintf(fid,'%3.3f %3.3f %3.3f %3.3f %3.3f%3.3f\n',...
                            ImageStruct.CoordinatesUnit.X(row),...
                            ImageStruct.CoordinatesUnit.Y(row),...
                            ImageStruct.CoordinatesUnit.Z(row),...
                            ImageStruct.CoordinatesTal.X(row),...
                            ImageStruct.CoordinatesTal.Y(row),...
                            ImageStruct.CoordinatesTal.Z(row));       

            end
         end
         if (isfield(ImageStruct.Coordinates,'T')&&...
                 isfield(ImageStruct,'Data'))
             for sample=1:numel(ImageStruct.Coordinates.T)
                fprintf(fid,'Sample %d, Latency %4.2f ms\n',sample,...
                                             ImageStruct.Coordinates.T(sample));
                for xindex=1:numel(ImageStruct.CoordinatesTal.X)
                    fprintf(fid,'%2.7f %2.7f %2.7f\n',ImageStruct.Data(xindex,:,sample));
                end           
             end
         end
    end
    
    
    %TimeSeries
    if (mode==2)
       if (isfield(ImageStruct.Coordinates,'T')&&...
                 isfield(ImageStruct,'Data'))
            for sample=1:numel(ImageStruct.Coordinates.T)
            fprintf(fid,'==============================================================================================');
            fprintf(fid,'\n');
                fprintf(fid,'Sample %d, %.2f ms',sample,...
                                     ImageStruct.Coordinates.T(sample));
                for zindex=1:numel(ImageStruct.Coordinates.Z)
                    fprintf(fid,'\n');
                    fprintf(fid,'Z: %d\n',zindex-1);
                    for yindex=1:numel(ImageStruct.Coordinates.Y)
                        for xindex=1:numel(ImageStruct.Coordinates.X)
                            fprintf(fid,'%.10f ',ImageStruct.Data(xindex,yindex,zindex,sample));
                        end
                        fprintf(fid,'\n');
                    end
                end  
            end
       end
    end
    
    %simple image
    if (mode==1)
        fprintf(fid,'==============================================================================================');
        if (isfield(ImageStruct,'Data'))
            for zindex=1:numel(ImageStruct.Coordinates.Z)

                fprintf(fid,'\n');
                fprintf(fid,'Z: %d\n',zindex-1);
                for yindex=1:numel(ImageStruct.Coordinates.Y)
                    for xindex=1:numel(ImageStruct.Coordinates.X)
                        fprintf(fid,'%.10f ',ImageStruct.Data(xindex,yindex,zindex));
                    end
                fprintf(fid,'\n');
                end

            end  
        end
    end
    
    fclose(fid);
end

