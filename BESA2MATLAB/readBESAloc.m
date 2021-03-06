function [Nodes IndicesNeighbourNodes] = readBESAloc(filename)
% readBESAloc reads the source space grid nodes the BESA *.loc file format.
% The coordinates of the source space nodes and a matrix defining the 
% neighbouring nodes are returned.
%
% Parameters:
%     [filename]
%         In the case that the current folder is not the folder containing 
%         the file it should be the full path including the name of the 
%         loc file else only the name of the file should be specified. 
% 
% Return:
%     [dim] 
%         Leadfield dimensions {<number sensors>, <number source space
%         nodes>, <number source directions>}
% 
%     [lf] 
%         Leadfield matrix with <number sensors> rows and <number source
%         space nodes> x <number source directions> columns. Each row
%         contains first the potentials for sources at all nodes in x-dir,
%         then for sources at all nodes in y-dir, and finally for all
%         nodes in z-dir.

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
% Author: Benjamin Lanfer/Robert Spangler
% Created: 2013-11-27


% Try to open file.
FileID = fopen(filename, 'rb');

% Read version number.
VersionNumber = fread(FileID, 1, 'int32');

% Read number of nodes.
NrNodes = fread(FileID, 1, 'int32');

% Read node coordinates.
NrDataElements = NrNodes * 3;
[Nodes NrReadElements] = fread(FileID, NrDataElements, 'float64');
if(NrReadElements ~= NrDataElements)
	fprintf('Could not read grid node coordinates.\n');
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
NumNeighbours = fread(FileID, NrNodes, 'int32');

% Allocate cell for neighbor indices
IndicesNeighbourNodes = cell(NrNodes, 1);

% Read indices of neighbour nodes for each grid node
for iNode=1:NrNodes
    IndicesNeighbourNodes{iNode} = fread(FileID, NumNeighbours(iNode), 'int32');
end;

% Close file.
fclose(FileID);
end
