function mul = readBESAmul(filename)
% readBESAmul read information from a *.mul file
%
% Use as
%   mul = readBESAMul(filename)
%
% The output is a structure containing the following fields:
%   Npts: number of sample ponts
%   TSB: latency of the first sample in the data files
%   DI: time interval between two sample points
%   Scale: scaling factor
%   ChannelLabels: Channel labels
%   Data: data matrix [Npts x Number of Channels]

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
  filename = [filename,'.mul'];
end

fp = fopen(filename);

% Read the file
if (fp)
  % Read header of .mul file
  headline=fscanf(fp,'TimePoints=%f  Channels=%f  BeginSweep[ms]=%f  SamplingInterval[ms]=%f  Bins/uV=%f');
  mul.Npts=headline(1);
  NChan=headline(2);
  mul.TSB=headline(3);
  mul.DI=headline(4);
  mul.Scale=headline(5);
  fgets(fp);
  for Channel=1:NChan
    mul.ChannelLabels(Channel) = cellstr(fscanf(fp,'%s ',1));
  end

  mul.data=zeros(mul.Npts,NChan);
  for i=1:mul.Npts
    mul.data(i,:)=fscanf(fp,'%f',[1 NChan]);
  end
end
fclose(fp);
