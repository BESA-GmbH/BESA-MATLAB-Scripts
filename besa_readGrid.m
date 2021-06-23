function [Nodes IndicesNeighbourNodes] = besa_readGrid(Filename)

% This method reads the node coordinates from the BESA location file format.
%
% Parameters:
%     [Filename]
%         The name of the file including the node coordinates created by
%		  BESA MRI (file extension: *.loc).
%
% Return:
%     [Nodes] 
%         N x M matrix where N is the number of nodes and M is 3.
%		  Note: Leadfield grid node coordinates are in ACPC space.
%
%     [IndicesNeighbourNodes] 
%         N x M matrix with indices of neighbour nodes where N is the number
%		  of nodes and M is the number of neighbours of each node.
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

% Read version number.
VersionNumber = fread(FileID, 1, 'int32');

% Read number of nodes.
NrNodes = fread(FileID, 1, 'int32');

% Read node coordinates.
NrDataElements = NrNodes * 3;
[Nodes NrReadElements] = fread(FileID, NrDataElements, 'float64');
if(NrReadElements ~= NrDataElements)
	printf('Could not read grid node coordinates.\n');
	return;
end

% Reshape matrix with node coordinates.
Nodes = reshape(Nodes, 3, NrNodes);
Nodes = Nodes';
% NOTE At this point Nodes is a n x m matrix where n is the number of nodes
% and m is 3.

% Scale LF grid node coordinates to mm, they are stored in m.
Nodes = Nodes*1e3;

% NOTE LF grid node coordinates are in ACPC space and in m. The AC point
% is then, e.g., at (0.128, 0.128, 0.128).

% Read number of neighbours for each grid node.
NumNeighbours = fread(FileID, 1, 'int32');

% Read indices of neighbour nodes for each grid node
TotalNumberNeighbours = NrNodes * NumNeighbours;
[IndicesNeighbourNodes NrReadElements] = fread(FileID, TotalNumberNeighbours, 'int32');
if(NrReadElements ~= TotalNumberNeighbours)
	printf('Could not read neighbour nodes from file.\n');
	return
end
% Reshape matrix with indices of neighbour nodes
IndicesNeighbourNodes = reshape(IndicesNeighbourNodes, NumNeighbours, NrNodes);

% Close file.
fclose(FileID);
end
