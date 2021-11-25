function  besa_save(besa_channels,filename)
% BESA_SAVE saves besa_channels struct (as exported) from BESA Research 
% to generic file (basename.generic, basename.dat, basename.evt )
% that can be read directly in BESA Research software
% The exported data can be loaded in BESA Research using 'File/Open'. 
% Select the generated *.generic file and specify the apropriate 
% coordinate files (*.ela, *.elp, *.sfp, *.pos).
% Event file is written alongside and to open it in BESA Research go to
% ERP menu entry and select "Open Event File..."
%
% Parameters:
%     [besa_channels]
%         A structure that was exported from Besa Research. Check BESA
%         documentation for more details. 
% 
%     [filename]
%         File name, optionally with full path where files should be saved. 
%         The extensions will be automatically added. 
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
% Created: 2019-04-23

    [path,file,~]=fileparts(filename);
    if isempty(path)
        path=pwd;
    end
    fullpath=[path '\' file];
    if ~exist(path,'dir')
        mkdir(path);
    end
    %save data
    if strcmp(besa_channels.datatype,'Raw_Data')
        temppath=pwd;
        cd(path);
        besa_matrix2Gen(besa_channels.amplitudes',besa_channels.samplingrate,file);
        cd(temppath);
    else
        data=zeros(numel(besa_channels.channellabels)...
                  ,numel(besa_channels.data)...
                  ,numel(besa_channels.data(1).latencies));
        for epoch=1:numel(besa_channels.data)
        data(:,epoch,:)=besa_channels.data(epoch).amplitudes';    
        end
        temppath=pwd;
        cd(path);
        besa_matrix2Gen(data,besa_channels.samplingrate,file,-besa_channels.data(1).latencies(1));
         cd(temppath);
    end
    %save events
    % Open file for writing.
    fid = fopen([fullpath '.evt'], 'w');
    if (fid>=3)
        fprintf(fid, 'Tmu\tCode\tTriNo\tComnt\n');
        if strcmp(besa_channels.datatype,'Raw_Data')
            events=besa_channels.events;
        else
            eventno=1;
            for epoch=1:numel(besa_channels.data)
                if strcmp(besa_channels.datatype,'Epoched_Data')
                    events(eventno)=besa_channels.data(epoch).event(1);
                    events(eventno).latency=(epoch-1)*numel(besa_channels.data(1).latencies)*1000/besa_channels.samplingrate;
                    events(eventno).type={'Segment'};
                    events(eventno).label={['Epoch Trig ' cell2mat(besa_channels.data(epoch).event(1).label)]};
                    eventno=eventno+1;
                  
                end
                for event=1:numel(besa_channels.data(epoch).event)
                    events(eventno)=besa_channels.data(epoch).event(event);
                    events(eventno).latency=events(eventno).latency+...
                                                                   (epoch-1)*numel(besa_channels.data(1).latencies)*1000/besa_channels.samplingrate...
                                                                    -min(besa_channels.data(1).latencies);
                    eventno=eventno+1;
                end
            end
        end
        for event=1:numel(events)
            comment=events(event).type;
            triNo='0';
            switch lower(cell2mat(events(event).type))
                case {'trigger'}
                    code='1';
                    comment=['Trigger: ' num2str(events(event).label{1})];
                    triNo=events(event).label;
                case {'comment'}
                    code='2';
                    comment=events(event).label;
                case {'marker'}
                    code='3';
                case {'pattern 1'}
                    code='11';
                case {'pattern 2'}
                    code='12';
                case {'pattern 3'}
                    code='13';
                case {'pattern 4'}
                    code='14';
                case {'pattern 5'}
                    code='15'; 
                case {'artifact on'}
                    code='21';
                case {'artifact off'}
                    code='22';
                case {'epoch on'}
                    code='31';
                case {'epoch off'}
                    code='32';         
                otherwise
                    code='42';
                    comment=events(event).label;
                    triNo=num2str(-besa_channels.data(1).latencies(1)*1000);   
            end
            if iscell(comment)
                comment=cell2mat(comment);
            end
             if iscell(events(event).latency)
                 events(event).latency=cell2mat(events(event).latency);
             end
             if iscell(triNo)
                 triNo=cell2mat(triNo);
             end
            fprintf(fid, '%f\t%s\t%s\t%s\n',events(event).latency*1000,....
                                         code,...
                                         triNo,...
                                         comment); 
        end
    end
    fclose(fid);

    fid = fopen([fullpath '.generic'], 'at');
    if (fid>=3)
        fprintf(fid,'EventFile = %s\n',[file '.evt']);
    end
    fclose(fid);

    %save channels
    sc=zeros(numel(besa_channels.channellabels),3);
    for chan=1:numel(besa_channels.channellabels)
    [sc(chan,1),sc(chan,2),sc(chan,3)]=besa_transformCartesian2Spherical(...
                        besa_channels.channelcoordinates(chan,2),...
                        besa_channels.channelcoordinates(chan,1),...
                        besa_channels.channelcoordinates(chan,3));
    end
    besa_save2Elp(path,[file '.elp'],sc,besa_channels.channellabels',char(besa_channels.channeltypes'));
    



end
