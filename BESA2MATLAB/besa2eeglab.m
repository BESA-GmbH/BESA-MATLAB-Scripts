function [ EEG ] = besa2eeglab( besa_channels )
% BESA2EEGLAB saves besa_channels struct as exported from BESA Research
% to EEG struct in EEGLAB. Check function EEGLAB2BESA for converting it
% back
%
% Parameters:
%     [besa_channels]
%         BESA standard struct
%
% Return:
%     [EEG]
%         A structure that can be used in EEGLAB functinos. 
% 

% Copyright (C) 2019, BESA GmbH
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
% Author: Mateusz Rusiniak
% Created: 2019-04-23

    EEG.setname='Besa export';
    EEG.filename='';
    EEG.filepath='';
    EEG.subject='';
    EEG.group='';
    if strcmp(besa_channels.datatype,'Segment')
        EEG.condition=besa_channels.data.event.label;
    else
        EEG.condition='';
    end
    EEG.session=[];
    EEG.comments=['Original file: ' besa_channels.datafile];
    EEG.nbchan=numel(besa_channels.channellabels);
    
   
    EEG.srate=besa_channels.samplingrate;
    if strcmp(besa_channels.datatype,'Epoched_Data')||strcmp(besa_channels.datatype,'Segment')
        EEG.trials=numel(besa_channels.data); 
        EEG.pnts=numel(besa_channels.data(1).latencies);
        EEG.xmin=min(besa_channels.data(1).latencies)/1000;
        EEG.xmax=max(besa_channels.data(1).latencies)/1000;
        EEG.times=besa_channels.data(1).latencies;
        EEG.data=single(zeros(EEG.nbchan,EEG.pnts,EEG.trials));
        EEGevent=1;
        for epoch=1:numel(besa_channels.data)
            EEG.data(:,:,epoch)=single(besa_channels.data(epoch).amplitudes');
            if exist('besa_channels.data(epoch).timeoffsetsecs','var')
               EEG.event(epoch).timeoffsetsecs=besa_channels.data(epoch).timeoffsetsecs;
            end
            EEG.epoch(epoch).epoch=epoch;
            EEG.epoch(epoch).label=cell2mat(besa_channels.data(epoch).event(1).label);
            EventsInEpoch=[];
            for event=1:numel(besa_channels.data(epoch).event)
                EEG.event(EEGevent).type=cell2mat(besa_channels.data(epoch).event(event).label);
                EEG.event(EEGevent).latency=-EEG.xmin *(EEG.srate)+1+(epoch-1)*EEG.pnts+besa_channels.data(epoch).event(event).latency/1000*EEG.srate;
                EEG.event(EEGevent).besatype=cell2mat(besa_channels.data(epoch).event(event).type);
                EEG.event(EEGevent).epoch=epoch;
                EEG.event(EEGevent).urevent=EEGevent;
                EEG.urevent(EEGevent).epoch=epoch;
                EEG.urevent(EEGevent).type=EEG.event(epoch).type;
                EEG.urevent(EEGevent).latency=EEG.event(epoch).latency;
                EventsInEpoch=[EventsInEpoch EEGevent];
                EEG.epoch(epoch).event=epoch;
                EEGevent=EEGevent+1;
            end
            EEG.epoch(epoch).event=EventsInEpoch;
        end
       
   else
        EEG.trials=1;
        EEG.pnts=numel(besa_channels.latencies);
        EEG.xmin=min(besa_channels.latencies)/1000;
        EEG.xmax=max(besa_channels.latencies)/1000;
        EEG.times=besa_channels.latencies;
        EEG.data=single(besa_channels.amplitudes');
        for event=1:numel(besa_channels.events)
            EEG.event(event).type=cell2mat(besa_channels.events(event).label);
            EEG.event(event).latency=floor(besa_channels.events(event).latency /(1000/EEG.srate))+1;
             EEG.event(event).besatype=cell2mat(besa_channels.events(event).type);
            EEG.event(event).urevent=event;
            EEG.urevent(event).type=EEG.event(event).type;
            EEG.urevent(event).latency=EEG.event(event).latency;
        end
        EEG.epoch=[];
    end
    EEG.icaact=[];
    EEG.icawinv=[];
    EEG.icasphere=[];
    EEG.icaweights=[];
    EEG.icachansind=[];
    for chan=1:EEG.nbchan
         label=cell2mat(besa_channels.channellabels(chan));
         index=strfind(label,'-');
         if index>0
            label=label(1:index(numel(index))-1);
         end
        EEG.chanlocs(chan).labels=label;
        EEG.chanlocs(chan).ref=[];
        EEG.chanlocs(chan).theta=[];
        EEG.chanlocs(chan).radius=[];
        EEG.chanlocs(chan).X=besa_channels.channelcoordinates(chan,2);
        EEG.chanlocs(chan).Y=-besa_channels.channelcoordinates(chan,1);
        EEG.chanlocs(chan).Z=besa_channels.channelcoordinates(chan,3);
        EEG.chanlocs(chan).sph_theta=[];
        EEG.chanlocs(chan).sph_phi=[];
        EEG.chanlocs(chan).sph_radius=[];
        EEG.chanlocs(chan).type=cell2mat(besa_channels.channeltypes(chan));
        EEG.chanlocs(chan).urchan=[];
    end
   
    EEG.urchanlocs=[];
    EEG.chaninfo.plotrad=[];
    EEG.chaninfo.shrink=[];
    EEG.chaninfo.nosedir='+X';
    EEG.chaninfo.nodatchans=[];
    
    ref=cell2mat(besa_channels.channellabels(1));
    index=strfind(ref,'-');
    ref=ref(index+1:numel(ref));
    if (strcmpi(ref,'ref')||strcmpi(ref,'com')||strcmpi(ref,'avr'))
        EEG.ref='common';
    else
        EEG.ref=ref;
    end
    clear ref;
    clear index;
   
    EEG.eventdescription=cell(1,6);
    EEG.eventdescription=[];
    EEG.epochdescription={};
    EEG.reject.rejjpE=[];
    EEG.reject.rejjp=[];
    EEG.reject.rejkurtE=[];
    EEG.reject.rejkurt=[];
    EEG.reject.rejmanualE=[];
    EEG.reject.rejmanual=[];
    EEG.reject.rejthreshE=[];
    EEG.reject.rejthresh=[];
    EEG.reject.rejconstE=[];
    EEG.reject.rejconst=[];
    EEG.reject.rejfreqE=[];
    EEG.reject.rejfreq=[];
    EEG.reject.icarejjpE=[];
    EEG.reject.icarejjp=[];
    EEG.reject.icarejkurtE=[];
    EEG.reject.icarejkurt=[];
    EEG.reject.icarejmanualE=[];
    EEG.reject.icarejmanual=[];
    EEG.reject.icarejthreshE=[];
    EEG.reject.icarejthresh=[];
    EEG.reject.icarejconstE=[];
    EEG.reject.icarejconst=[];
    EEG.reject.icarejfreqE=[];
    EEG.reject.icarejfreq=[];
    EEG.reject.rejglobal=[];
    EEG.reject.rejglobalE=[];
    EEG.reject.rejmanualcol=[1,1,0.783000000000000];
    EEG.reject.rejthreshcol=[0.848700000000000,1,0.500800000000000];
    EEG.reject.rejconstcol=[0.694000000000000,1,0.700800000000000];
    EEG.reject.rejjpcol=[1,0.699100000000000,0.753700000000000];
    EEG.reject.rejkurtcol=[0.688000000000000,0.704200000000000,1];
    EEG.reject.rejfreqcol=[0.688000000000000,0.704200000000000,1];
    EEG.reject.disprej={}; 
    EEG.reject.threshold=[0.800000000000000,0.800000000000000,0.800000000000000];
    EEG.reject.threshentropy=600;
    EEG.reject.threshkurtact=600;
    EEG.reject.threshkurtdist=600;
    EEG.reject.gcompreject=[];
    EEG.stats.jp=[];
    EEG.stats.jpE=[];
    EEG.stats.icajp=[];
    EEG.stats.icajpE=[];
    EEG.stats.kurt=[];
    EEG.stats.kurtE=[];
    EEG.stats.icakurt=[];
    EEG.stats.icakurtE=[];
    EEG.stats.compenta=[];
    EEG.stats.compentr=[];
    EEG.stats.compkurta=[];
    EEG.stats.compkurtr=[];
    EEG.stats.compkurtdist=[];
    EEG.specdata=[];
    EEG.specicaact=[];
    EEG.splinefile='';
    EEG.icasplinefile='';
    EEG.dipfit=[];
    EEG.history='';
    EEG.saved='no';
    EEG.etc='';
    EEG.datfile='';
    
    
     if exist('pop_chanedit')
        EEG=pop_chanedit(EEG,'convert','cart2all');
    elseif exist('eeglab')
        eeglab;
        EEG=pop_chanedit(EEG,'convert','cart2all');
    end

end

