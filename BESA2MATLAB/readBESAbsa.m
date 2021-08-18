function bsa = readBESAbsa(filename)
% readBESAbsa reads information from a *.bsa file
%
% Use as
%   bsa = readBESAbsa(filename)
%
% The output is a structure containing the following fields:
%   CoordinateSystem:   Coordinate System:
%                           HC = Head Coordinates
%                           US = Unit Sphere
%                           TC = Talairach Coordinates
%                           DC = Device Coordinates
%   Coords:             [Nsources x 3] matrix with source coordinates
%   Orientation:        [Nsources x 3] matrix with source orientations
%                           (x,y,z)
%                           (Orientation = [0 0 0] for regional sources)
%   SourceType:         Type of source:
%                           SngDip = Single Dipole
%                           RegSrc = Regional Source
%                           SptCmp = Spatial Component
%   Labels:             Source Labels (if assigned in BESA)

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
% Last modified April 26, 2006 Robert Oostenveld

if isempty(findstr(filename,'.'))
  filename = [filename,'.bsa'];
end
fp = fopen(filename);

% Read the file
if (fp)
  % Read header of .swf file
  header = fgetl(fp);
  if header(end-3)=='|'
    bsa.CoordinateSystem = 'US';
  else
    bsa.CoordinateSystem = header(end-1:end);
  end
  fgetl(fp);
  fgetl(fp);

  for i=1:1000
    try         % check if there is another waveform
      Typ = cellstr(fscanf(fp,'%s',1));
      bsa.Coords(i,1) = fscanf(fp,'%f',1);
      bsa.Coords(i,2) = fscanf(fp,'%f',1);
      bsa.Coords(i,3) = fscanf(fp,'%f',1);
      bsa.Orientation(i,1) = fscanf(fp,'%f',1);
      bsa.Orientation(i,2) = fscanf(fp,'%f',1);
      bsa.Orientation(i,3) = fscanf(fp,'%f',1);
      bsa.SourceType(i) = Typ;
      a = fgetl(fp);
      b = a(findstr(a,'Label:')+6:end);
      if ~isempty(b)
        bsa.Labels(i) = cellstr(sscanf(b,'%s',1));
      else
        bsa.Labels(i) = cellstr('');
      end
    catch       % stop if end of file is reached
      break
    end
  end
end

fclose(fp);