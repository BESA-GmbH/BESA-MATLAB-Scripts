function [] = besa_plot_image_ai(imagestruct, varargin)
% Image plots for each 3d image in <besa_image_all> or <besa_image>; 
% shown in slices as 2d (x,y) plots 
% one figure per struct (i.e. subsequent export) in <besa_image_all>
%
% use as besa_plot_image(imagestruct [,'figurename']), where imagestruct 
% is <besa_image_all> or <besa_image> but can have been renamed


%----------------------- Please edit -------------------------------------%
LabelsInSubplots = 0;
%0 (default): extra empty plot with tick labels and colorbar
%otherwise: no colorbar; tick labels in every subplot
PlotAllFigures = 1;
%0: if <imagestruct> contains more than one substructure, 
%   only one figure is drawn and shows the last substructure; 
%   no number in figure title
%otherwise: figures for all exports are plotted, figure title numbered
smooth = 0;
%0: shading flat
%otherwise: shading interp
%-------------------------------------------------------------------------%
if smooth
    factor = 0;
else
    factor = 0.5;
end;

if PlotAllFigures
    k1=1;
else
    k1=length(imagestruct);
end;

%check for correct type
if ~strcmp(imagestruct(k1).structtype,'besa_image')
error(['Incorrect input structure type (must be besa_image or ',        ...
    'besa_image_all)']);
else
end;

%look for existing figures with figure names containing "Plot besa_image", 
%and delete them
if (length(imagestruct)>1)
    h= findobj('type','figure');
    for i=1:length(h)
        n=get(h(i),'Name');
        if strfind(n,'Plot besa_image');
            close(h(i));
        end;
    end;
end;

for k=k1:length(imagestruct)
    image = imagestruct(k);
    %check criteria (only one latency / orientation)
    if ((ndims(image.data)>3)...
        || ((isfield(image(k),'latencies')                     ...
        && ~isstr(image(k).latencies)                         ...                    
        &&  (size(image(k).latencies,2)>1)))) 
    disp([num2str(k),'th image does not meet criteria for plotting']);
    continue
    end;
    namestring = '';
    if (strcmp(image.type,'surface minimum norm'))
        %surface minimum norm: display in case of standard brain, 
        %toolbox required
        if (size(image.data,2)==750) && exist('MyRobustCrust','file') 
            if ((nargin>1) && isstr(varargin{1}))
                namestring = ['Plot besa_image - ', image.type, '  ',   ...
                    varargin{1}];
            else
                namestring = ['Plot besa_image - ', image.type ];
            end; 
            h=figure;
            besa_plot_mn_ai(image, namestring);
        elseif (size(image.data,2)~=750)
            warning('No plot possible: Minimum norm, nonstandard brain');
        elseif ~exist('MyRobustCrust','file') 
            warning('MyCrust toolbox not found in MATLAB path');
        end;
    continue
    end;
    h = figure;
    %if there is more than one input, the second input will be used in the
    %title of the figure
    if ((nargin>1) && isstr(varargin{1}))
        namestring = ['Plot besa_image - ', image.type, '  ', varargin{1}];
    else
        namestring = ['Plot besa_image - ', image.type ];
    end;
    set(h,'Name',namestring);
    clear namestring;
    if ~PlotAllFigures
        set(h,'NumberTitle','off');
    else
    end;
    xcoord= squeeze(image.xcoordinates); 
    xdist = xcoord(2)-xcoord(1);
    ycoord = squeeze(image.ycoordinates); 
    ydist = ycoord(2)-ycoord(1);
    xcoord = squeeze([xcoord xcoord(end)+xdist]-factor*xdist);
    x_lim = [xcoord(1) xcoord(end)];
    ycoord= squeeze([ycoord ycoord(end)+ydist]-factor*ydist);
    y_lim = [ycoord(1) ycoord(end)];
    nr_slices = length(image.zcoordinates);

    %determine minimum and maximum value over all electrodes
    Zmax=max(max(max(image.data)));
    Zmin=min(min(min(image.data)));
    
    if LabelsInSubplots
        NrCols = ceil(sqrt(nr_slices));
        if NrCols*(NrCols-1) >= nr_slices
            NrRows = NrCols-1;
        else 
            NrRows = NrCols;
        end;
        for i=1:nr_slices
            data = squeeze(image.data(:,:,i));
            plotdata = [data,data(:,end)]; 
            plotdata = [plotdata; plotdata(end,:)];
            h=subplot(NrRows,NrCols,i);
            hs=surf(xcoord, ycoord, plotdata','LineStyle','.');
            view([0.0 90.01]); 
            set(h,'XLim',x_lim,'YLim',y_lim,'ZTickLabel',{},...
                'ZTickLabel',{},'clim',[Zmin Zmax*1.01]);
            h=title(['Z = ',num2str(image.zcoordinates(i))],            ...
            'FontSize',9,'Color','b');
            if smooth
                shading interp; 
            else
                shading flat;
            end;
           
        end;
    else
        NrCols = ceil(sqrt(nr_slices+1));
        if NrCols*(NrCols-1) >= nr_slices+1
            NrRows = NrCols-1;
        else 
            NrRows = NrCols;
        end;
        for i=1:length(image.zcoordinates)
            data = squeeze(image.data(:,:,i));
            plotdata = [data,data(:,end)]; 
            plotdata = [plotdata; plotdata(end,:)];
            h=subplot(NrRows,NrCols,i); 
            y=surf(xcoord, ycoord, plotdata','Marker','.');
            view([0.0 90.01]); 
            set(h,'XLim',x_lim,'YLim',y_lim,'clim',[Zmin Zmax],         ...
              'XTickLabel',{},'YTickLabel',{},'ZTickLabel',{},          ...
              'box','on','TickDir','out');       
            h = get(gca,'TickLength'); set(gca,'TickLength',2*h); 
            set(y,'EdgeAlpha',1,'FaceAlpha',1);
            h=title(['Z = ',num2str(image.zcoordinates(i))],'FontSize',9);
            if smooth
                shading interp; 
            else
                shading flat;
            end;
        end;
        h=subplot(NrRows,NrCols,nr_slices+1);  
        set(h,'XLim',x_lim,'YLim',y_lim,'clim',[Zmin Zmax],             ...
            'XColor','k','YColor','k','Color','none',                   ...
            'FontSize',8,'TickDir','out','Layer','top','ZTick',[]); 
            view([0.01 90]); box on;
            %double tick mark length
            x=get(gca,'TickLength'); set(gca,'TickLength',2*x);
            x=get(gca,'Position');
            y=[x(1)+0.6*x(3) x(2)+0.25*x(4) 0.25*x(3) 0.5*x(4)];
            colorbar('Position',y ,'FontSize',8);
    end;
end;

clear Nr* f* h* i* k* n* p* x y xcoord* ycoord* data Z* *lim ans el* m* ...
    Show* Keep* LabelsInSubplots smooth *dist namestring
