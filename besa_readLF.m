function [Dimensions Leadfield] = besa_readLF(Filename)

% This method reads the leadfield from the BESA leadfield file format.
% The leadfield matrix and a vector with the leadfield dimensions are returned.
% Dimensions = {<Number sensors>, <Number source space nodes>, 
%			    <Number source directions>}
% The leadfield matrix is a matrix with <Number sensors> rows and
% <Number source space nodes> x <Number source directions> columns.
% Each row contains first the potentials for sources at all nodes in x-dir,
% then for sources at all nodes in y-dir, and finally for all nodes in z-dir.
%
% Parameters:
%     [Filename]
%         The name of the file including the leadfield matrix created by
%		  BESA MRI (file extension: *.lft).
%
% Return:
%     [Dimensions] 
%         Vector with leadfield dimensions.
%
%     [Leadfield] 
%         Leadfield matrix with <Number sensors> rows and
%		  <Number source space nodes> x <Number source directions> columns
% 
%
% Copyright (C) 2013, BESA GmbH
%
% File name: besa_readLF.m
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
% Author: Benjamin Lanfer
% Created: 2013-10-07

% Try to open file.
FileID = fopen(Filename, 'rb');
if(FileID < 0)
	printf('Error opening file.\n');
	return
end

% Read version number (int32)
[VersionNumber NrReadElements] = fread(FileID, 1, 'int32');
if(NrReadElements ~= 1)
	printf('Could not read number of elements.\n');
	return
end

% Check version number
ExpectedVersionNumber = 1;
if(VersionNumber ~= ExpectedVersionNumber)
	printf('Wrong version number. Expected: %d, read %d.\n', ExpectedVersionNumber, ...
		VersionNumber);
	return
end

% Read number of sensors (int32)
[NumberSensors NrReadElements] = fread(FileID, 1, 'int32');
if(NrReadElements ~= 1)
	printf('Could not read number of sensors.\n');
	return
end

% Read number of source space nodes (int32)
[NumberSourceSpaceNodes NrReadElements] = fread(FileID, 1, 'int32');
if(NrReadElements ~= 1)
	printf('Could not read number of source space nodes.\n');
	return
end

% Read number of source directions per node (int32)
[NumberDirections NrReadElements] = fread(FileID, 1, 'int32');
if(NrReadElements ~= 1)
	printf('Could not read number of source directions.\n');
	return
end

% Read maximum LF values for each source (source nodes x directions) (float32)
NumberColumns = NumberDirections * NumberSourceSpaceNodes;
[MaxVals NrReadElements] = fread(FileID, NumberColumns, 'float32');
if(NrReadElements ~= NumberColumns)
	printf('Could not read maximum leadfield values from file.\n');
	return
end

% Read compactly stored LF values (int16)
NumberLFValues = NumberColumns * NumberSensors;
[CompactLFVals NrReadElements] = fread(FileID, NumberLFValues, 'int16');
if(NrReadElements ~= NumberLFValues)
	printf('Could not read leadfield values from file.\n');
	return
end

% Reshape matrix with compact LF values.
CompactLFVals = reshape(CompactLFVals, NumberColumns, NumberSensors);
CompactLFVals = CompactLFVals';

% Compute factors for converting compactly stored LF values
% to float values.
ConversionFactors = MaxVals / 32767.0;
clear MaxVals;

% Convert compact LF values to float.
%Leadfield = CompactLFVals * repmat(ConversionFactors, 1, NumberColumns);

% NOTE RS 2013-08-14:
% * operator in line %Leadfield = CompactLFVals * repmat(...) is a real
% matrix multiplication, not a scalar multiplication. Is this intended?

% NOTE RS 2013-08-14:
% Use alternative conversion of compact LF values to float LF
% values due to the extreme memory consumption of the repmat function:
for iCol=1:NumberColumns
    CompactLFVals(:,iCol) = CompactLFVals(:,iCol)*ConversionFactors(iCol);
end
Leadfield = CompactLFVals;

% Copy dimensions.
Dimensions = [NumberSensors; NumberSourceSpaceNodes; NumberDirections];

% Close file.
fclose(FileID);
end
