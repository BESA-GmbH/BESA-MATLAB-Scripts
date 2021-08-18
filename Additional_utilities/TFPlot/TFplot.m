function [outTFC] = TFplot(varargin)
%TFPLOT Summary of this function goes here
%   Detailed explanation goes here
lastpath='';
oldparams=struct();
if (exist('lastpath.mat','file')==2)
    load('lastpath.mat');
end
if (exist('params.mat','file')==2)
    load('params.mat');
end
error='';
if nargin>0
    defpath=varargin(1);
elseif isempty(lastpath)==0
    defpath=lastpath;
else
    defpath=getenv('USERPROFILE');
end
selpath=uigetdir(defpath,'Select TFC folder');
if selpath==0
    error='NO_DIRECTORY';
end
if isempty(error)
    lastpath=selpath;
    save('lastpath.mat','lastpath');
    temp=dir([selpath '\*.tfc']);
    for i=1:numel(temp);
        Files{i}=[selpath '\' temp(i).name];
    end
    %[~,~,Files]=dirr(selpath, '\.tfc\>','name');
end
if (numel(Files)==0)
    error='NO_FILES';
end
if isempty(error)
    for i=1:numel(Files)
        tfc{i} = readBESAtfc(Files{i});
        if i==1
            RefTime=tfc{i}.Time;
            RefFreq=tfc{i}.Frequency;
            RefChan=tfc{i}.ChannelLabels;
        else
            if (sum(RefTime~=tfc{i}.Time) |...
               sum(RefFreq~=tfc{i}.Frequency) |...
               sum(RefChan~=tfc{i}.ChannelLabels))
                error='FILE_MISSMATCH';
            end
        end
    end
    
end
 go = true;

 d = dialog('Position',[300 400 250 400],'Name','Set Parameters');
 
while (go && isempty(error)) 
    if isempty(error)
       text=['Number of TFC files loaded: ' num2str(numel(tfc))];
        params=paramsdialog(text,tfc{1},oldparams,d);
        time=[params.TS, params.TE];
        frequency=[params.FS, params.FE];
        ChanIndx=params.Channel;
        [~,TimeIndx]=find(tfc{1}.Time>=time(1) & tfc{1}.Time<=time(2));
        [~,FreqIndx]=find(tfc{1}.Frequency>=frequency(1) & tfc{1}.Frequency<=frequency(2));
        if numel(TimeIndx)<2
            error='WRONG_TIMERANGE';
        end
        if numel(FreqIndx)<2
            error='WRONG_FRREQRANGE';
        end
    end
    if isempty(error)
        oldparams=params;
        save('params.mat','oldparams');
        averageTFC=zeros(numel(TimeIndx),numel(FreqIndx));
        for i=1:numel(tfc)    
            averageTFC(:,:)=averageTFC(:,:)+squeeze(tfc{i}.Data(ChanIndx,TimeIndx,FreqIndx));
        end
        
        %for i=1:numel(tfc)    
       %     meanVal(i)=mean(mean(tfc{i}.Data(ChanIndx,TimeIndx,FreqIndx)));
        %end
        %globalmean=mean(meanVal);
        %globalstd=std(meanVal);
        averageTFC=averageTFC/i;
        MaxVal=max(max(averageTFC));
        MinVal=min(min(averageTFC));
        X=tfc{1}.Time(TimeIndx);
        Y=tfc{1}.Frequency(FreqIndx);
        Scale=0;
        if params.normalize==1
            averageTFC=averageTFC/MaxVal;
        else
            Scale=params.MaxVal;
        end
        if (params.negative==0)
            averageTFC=averageTFC.*(averageTFC>0);
        end
        vq=interp2(averageTFC',5);
        imagesc(X,Y,vq);
        set(gcf,'color','white')
        movegui(gcf,'center')
        set(gca,'YDir','normal','FontSize',params.FontSize);
        if isempty(params.Label)
            title(tfc{1}.ChannelLabels(ChanIndx,:),'Interpreter','none','FontSize',params.FontSize);
        else
            title(params.Label,'Interpreter','none','FontSize',params.FontSize);
        end
         colorbar
        if (params.negative)
            caxis([-Scale Scale]);
        else
            if (MinVal>Scale)
                caxis([0 Scale]);
            else
                caxis([MinVal Scale]);
            end
        end
        if params.ColorScale==1
            colormap(gca,jet(128));
        elseif params.ColorScale==2
            colormap(gca,parula(128));
        else
            colormap(gca,hot(128));
        end
        xlabel('time [ms]','FontSize',params.FontSize);
        ylabel('frequency [Hz]','FontSize',params.FontSize);
        %colorbar

    end
    switch error
        case 'NO_DIRECTORY'
            mydialog('Error', 'No TFC directory chosen');
        case 'NO_FILES'
            mydialog('Error', 'No TFC files in given directory');
        case 'FILE_MISSMATCH'
            mydialog('Error', 'Different files in directory(time range or frequency range or montage'); 
        case 'WRONG_TIMERANGE'
            mydialog('Error', 'Wrong time range for display (at least two time points needed)'); 
        case 'WRONG_FREQRANGE'
            mydialog('Error', 'Wrong frequency range for display (at least two frequency points needed)'); 

    end
    if (params.close==1)
        go=false;
    end
  
 end
 close all;
    outTFC=zeros(numel(tfc{i}.Data(:,1,1)),numel(tfc{1}.Data(1,:,1)),numel(tfc{1}.Data(1,1,:)));
    for i=1:numel(tfc)    
           averageTFC(:,:)=averageTFC(:,:)+squeeze(tfc{i}.Data(ChanIndx,TimeIndx,FreqIndx));
            for chan=1:numel(tfc{i}.Data(:,1,1))
                for time=1:numel(tfc{1}.Data(1,:,1))
                    for freq=1:numel(tfc{1}.Data(1,1,:))
                         outTFC(chan,time,freq)=outTFC(chan,time,freq)+squeeze(tfc{i}.Data(chan,time,freq));
                    end
                end
            end
            outTFC=outTFC/numel(tfc);
    end
end


function mydialog(title,text)
    d = dialog('Position',[400 400 350 150],'Name',title);

    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[20 80 210 40],...
               'String',text);

    btn = uicontrol('Parent',d,...
               'Position',[85 20 70 25],...
               'String','Close',...
               'Callback','delete(gcf)');
    movegui(gcf,'center');
end

function params = paramsdialog(text,tfc,oldparams,dialog)
    d=dialog;
    txt=   uicontrol('Parent',d,...
           'Style','text',...
           'fontweight','bold',...
           'Position',[20 350 210 40],...
           'String',text);
    capF = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 320 210 40],...
           'String','Frequency Range');
    capFS = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[40 310 40 30],...
           'String','Start');
    capFE = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[160 310 40 30],...
           'String','End');
    editFS = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[40 300 40 20],...
           'String','',...
           'Tag','FS',...
           'Callback',@edit_callback);
    editFE = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[160 300 40 20],...
           'String','',...
           'Tag','FE',...
           'Callback',@edit_callback);
       
    capT = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 240 210 40],...
           'String','Time Rnage');
    capTS = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[40 230 40 30],...
           'String','Start');
    capTE = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[160 230 40 30],...
           'String','End');
    editTS = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[40 220 40 20],...
           'String','',...
           'Tag','TS',...
           'Callback',@edit_callback);
       
       
    cap1 = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[10 180 110 20],...
           'String','Select source/channel');
     editTE = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[160 220 40 20],...
           'String','',...
           'Tag','TE',...
           'Callback',@edit_callback);   
    popupChan = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[15 160 100 25],...
           'String',{tfc.ChannelLabels(1,:)},...
           'Callback',@popup_callback);
       
       
   cap2 = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[10 130 110 20],...
           'String','Select colorscale');
    
    popupcolorscale = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[15 110 100 25],...
           'String',{'jet';'parula';'hot'},...
           'Callback',@popup_colorscale);
    negative = uicontrol('Parent',d,...
           'Style','checkbox',...
           'Position',[140 115 110 20],...
           'String','Negative values',...
           'Tag','negative',...
           'Callback',@checkbox_callback);
    normalize = uicontrol('Parent',d,...
           'Style','checkbox',...
           'Position',[140 170 210 20],...
           'String','Normalize',...
           'Tag','normalize',...
           'Callback',@checkbox_callback);
    capMaxScale = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[140 140 60 20],...
           'String','Max Scale');
    maxScale = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[200 145 40 20],...
           'String','',...
           'Tag','MaxVal',...
           'Callback',@edit_callback);
    
     capFontSize = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[140 70 60 20],...
           'String','Font Size');   
     fontSize = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[200 75 40 20],...
           'String','',...
           'Tag','FontSize',...
           'Callback',@edit_callback);
     OverrideLabel = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[15 60 60 40],...
           'String','Override label with:');   
      Label = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[80 75 60 20],...
           'String','',...
           'Tag','Label',...
           'Callback',@edit_callback);
    for i=2:numel(tfc.ChannelLabels(:,1))
        current_entries = cellstr(get(popupChan, 'String'));
        current_entries{i} = tfc.ChannelLabels(i,:);
        set(popupChan, 'String', current_entries);
    end
  
    btn = uicontrol('Parent',d,...
           'Position',[39 20 70 25],...
           'String','Apply',...
           'Callback',@Apply);
           %'Callback', 'uiresume(gcbf)');%'delete(gcf)');
    btn2 = uicontrol('Parent',d,...
           'Position',[129 20 70 25],...
           'String','Close',...
           'Callback',@Close);%'delete(gcf)');
    set(d,'CloseRequestFcn',@Close);
    
    if isempty(fieldnames(oldparams))   
        params.Channel = 1;
        params.ColorScale=1;
        params.FS=tfc.Frequency(1);
        params.FE=tfc.Frequency(numel(tfc.Frequency));
        params.TS=tfc.Time(1);
        params.TE=tfc.Time(numel(tfc.Time));
        params.negative=0;
        params.normalize=0;
        params.MaxVal=0.1;
        params.FontSize=12;
        params.Label='';
    else
        params=oldparams;
    end
    set(editFS, 'String', params.FS);
    set(editFE, 'String', params.FE);
    set(editTS, 'String', params.TS);
    set(editTE, 'String', params.TE);
    set(popupChan, 'Value', params.Channel);
    set(popupcolorscale,'Value',params.ColorScale);
    set(negative,'Value',params.negative);
    set(normalize,'Value',params.normalize);
    set(maxScale,'String',params.MaxVal);
    set(fontSize,'String',params.FontSize);
    set(Label,'String',params.Label);
    if normalize.Value==1
        set(maxScale,'enable','off');
    else
        set(maxScale,'enable','on');
    end
    movegui(gcf,'center')
    % Wait for d to close before running to completion
    uiwait(d)
       function popup_callback(popup,event)
           params.Channel = popup.Value;
       end
       function popup_colorscale(popup,event)
           params.ColorScale = popup.Value;
       end
       function edit_callback(Edit, event)
            if (strcmp(Edit.Tag,'Label'))
                params.(Edit.Tag) = get(Edit, 'String');
            else
                params.(Edit.Tag) = str2double(get(Edit, 'String'));
            end
       end
       function Close(popup,event)
          params.close=true;
          delete(gcf);
       end
       function checkbox_callback(checkbox,event)
          params.(checkbox.Tag)=checkbox.Value;
          if strcmp(checkbox.Tag,'normalize')
              if (checkbox.Value==1)
                  set(maxScale,'enable','off')
              else
                  set(maxScale,'enable','on');
              end
          end
          
       end
       function Apply(popup,event)
            params.close=false;
            uiresume(gcbf);
       end
end