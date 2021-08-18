function [] = besa_average_images(varargin)
% This function carries out standard averaging for image files
% corresponding to a chosen type and grid and saves them as *.dat files.
% Averaged files can be read into BESA Research (with the exception of 
% surface minimum norm images).
% This function may be called from BESA Research or run by itself.
% 
% Use as:
%       besa_average_images
%       besa_average_images(besa_image_all)
%       besa_average_images(besa_images_all,'OutputFile')
%       besa_average_images('OutputFile')
%
% where besa_image_all is an acuumulated struct of BESA 3D images
% transferred from BESA Research and 'OutputFile' is a string. 
% If not specified, <besa_average_images> prompts for BESA image ASCII
% files as input.
% The result is written to file 'OutputFile' if specified. Otherwise it is
% saved under a previously selected or default name, or interactively (only
% for "UserDefaultName = 0".
%
% Last modification 2010-03-28
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Please edit

UserInterface = 0;
        % 0: Recommended for batch mode: Runs automatically if 
        %   <besa_image_all> is an input variable; otherwise user interface
        %   opens
        % otherwise: Always open user interface for file selection
 
InputPath = userpath;
        % Path for image file selection (BESA *.dat or MATLAB *.mat files)
        % (used if <UserInterface> = 1 or if there is no <besa_image_all>
        % among the input variables). You can modify this  to be any
        % path, e.g. 
        % InputPath = 'C:\MyPath'
        
OutputPath = userpath;
        % Path for saving averaged image files. You can modify this 
        % to be any path, e.g. 
        % InputPath = 'C:\MyPath'
        
DefaultName = 'Average';
        % Default output filename for averaged image file
        
UseDefaultName = 1; 
        %1: Saves averaged image as <OutputPath>/<DefaultName>.dat 
        %0: user interface for specifying output filename is opened
        
PlotOutput = 1;
        %0: output is not displayed
        %otherwise: output plotted as MATLAB figure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Clear Path variables if required
if OutputPath(end)==';', OutputPath=OutputPath(1:end-1); end
if OutputPath(end)~='\', OutputPath=[OutputPath,'\']; end
if InputPath(end)==';', InputPath=InputPath(1:end-1); end
if InputPath(end)~='\', InputPath=[InputPath,'\']; end

%% Load image file or MATLAB workspace

if (nargin>0) 
    if isstruct(varargin{1})
        besa_image_all = varargin{1};
        if (~strcmp(besa_image_all(1).structtype,'besa_image'))
            error('Input must be of structtype besa_image');
        end;
    elseif isstr(varargin{1})
        DefaultName = varargin{1};
    end;
    if nargin >1 && isstr(varargin{2})
        DefaultName = varargin{2};
    end;
end;

if ( UserInterface||(UserInterface ==0 && ~exist('besa_image_all')))
    %either data are to be selected always, or there is no besa_image_all 
    %in the workspace
    button = questdlg('Image file (*.dat) or MATLAB workspace (*.mat)?',...
        'Load data','dat','mat','mat') ;
    if strcmpi(button,'dat') %load file(s)
        [FileNames,PathName,FilterIndex] = uigetfile({'*.dat'},         ...
           'Please select the files you would like to average',         ...
            InputPath,'MultiSelect','On');
       if ischar(FileNames) %one file selected
           [besa_image_all,image] = readdatfile([PathName,FileNames]);
       else  %several files selected     
           DatFiles={[]};
           for i=1:length(FileNames)
               DatFiles{i} = [PathName,FileNames{i}];
               [besa_image_all(i), image] = readdatfile( [DatFiles{i}]);
           end;
       end;
    else %load workspace
        uiopen([InputPath,'\*.mat']); 
    end;
else
    disp('besa_image_all exists in workspace');
end;

%check for correct dimensions (only one latency and orientation);
j=1;
for k=1:length(besa_image_all)
    if ((ndims(besa_image_all(k).data)>3) ...
        || ((isfield(besa_image_all(k),'latencies')                     ...
        && ~ischar( besa_image_all(k).latencies)                         ...                    
        &&  (size(besa_image_all(k).latencies,2)>1))))
        disp(['Image ',num2str(k),' eliminated - too many latencies or',...
            ' orientations']);
        continue
%    elseif strcmp(besa_image_all(k).type,'Sensitivity')
%        disp(['Image ',num2str(k),' eliminated - imagetype Sensitivity']);
%        continue
    else
        besa_image_temp(j) = besa_image_all(k);
        j=j+1;
    end;
end;

if (j==1)
    warning('No eligible images loaded');
    return;
end;
numberofimages = length(besa_image_temp); %number of all image files 
%meeting the criteria (only one latency, only one orientation)
originalnumberofimages = length(besa_image_all);
if originalnumberofimages > numberofimages
    disp(['Only ', num2str(numberofimages),' of ',                      ...
        num2str(originalnumberofimages),                                ...
        ' images fit averaging criteria before type and grid size check']);
end;
clear besa_image_all j k

%check which types of images are loaded
firstimagetype = besa_image_temp(1).type;
imagenumber = struct([]);
imagenumber(1).index = 1; 
imagenumber(1).Type = firstimagetype;
Type{1}=firstimagetype;
numberoftypes = 1;

Grid = struct([]);
Grid(1).Size = round(besa_image_temp(1).xcoordinates(2)                   ...                  
           - besa_image_temp(1).xcoordinates(1)); %Grid size in mm

xcoords = [besa_image_temp(1).xcoordinates(1),                            ...
           besa_image_temp(1).xcoordinates(end),                          ...
           size(besa_image_temp(1).xcoordinates,2)];
ycoords = [besa_image_temp(1).ycoordinates(1),                            ...
           besa_image_temp(1).ycoordinates(end),                          ...
           size(besa_image_temp(1).ycoordinates,2)];   
zcoords = [besa_image_temp(1).zcoordinates(1),                            ...
           besa_image_temp(1).zcoordinates(end),                          ...
           size(besa_image_temp(1).zcoordinates,2)];   
% number of data points in each dimension
XCoords(1) = xcoords(3);         
YCoords(1) = ycoords(3);
ZCoords(1) = zcoords(3);           
numberofgrids = 1;
Grid(1).index = 1; index = 1;
    
%for check whether latencies are the same
%(this does not affect averaging but output)
 if isfield(besa_image_temp(1),'latencies')                         ...
        && ischar(besa_image_temp(1).latencies)                        
     besa_image_temp(1).latencies = besa_image_temp(1).latencies;
 elseif isfield(besa_image_temp(1),'latencies')                         ...
        && isnumeric(besa_image_temp(1).latencies)
     besa_image_temp(1).latencies = [num2str(besa_image_temp(1).latencies) ' ms'];
 else 
     besa_image_temp(1).latencies = '?';
 end;
latency{1} = besa_image_temp(1).latencies;
 
j=2;
while j <= numberofimages
    %compare image types with first image because in 
            %most cases, all images will be of the same type    
    if isfield(besa_image_temp(j),'latencies')&&                    ...
            ischar(besa_image_temp(j).latencies)
        besa_image_temp(j).latencies = besa_image_temp(j).latencies;
    elseif isfield(besa_image_temp(j),'latencies')&&                    ...
        isnumeric(besa_image_temp(j).latencies)
        besa_image_temp(j).latencies = [num2str(besa_image_temp(j).latencies) ' ms'];
    else 
        besa_image_temp(j).latencies = '?';
    end;
    latency{j} = besa_image_temp(j).latencies;
    if(strncmpi(besa_image_temp(j).type,firstimagetype,4))     
        imagenumber(1).index = [imagenumber(1).index j];
    else
        KnownType = 0;
        for k=1:numberoftypes              
            if (strncmpi(besa_image_temp(j).type,imagenumber(k).Type,4)) 
                imagenumber(k).index = [imagenumber(k).index j];
                   %if the type has occurred before, index for this type grows 
                   KnownType = 1;
            end;
        end;
        if ~KnownType   
            %if this type is new, open new index
            numberoftypes = numberoftypes + 1; 
            imagenumber(numberoftypes).index = j;
            imagenumber(numberoftypes).Type = besa_image_temp(j).type;
            Type{numberoftypes} = besa_image_temp(j).type;
        end; 
    end;
    j=j+1;
end;
   
if (numberoftypes >1)
    [TypeNumber, ok] = listdlg('ListString',Type,'SelectionMode',       ...
        'single', 'ListSize',[150 numberoftypes*20]); %[width height]
    ImageType = char(Type(TypeNumber));
else
    ImageType = firstimagetype;
end;
clear FirstImageType UserInterface InputPath


%If all coordinates and types correspond, only the data field will have to
%be overwritten. The remaining fields will remain.
%Checks: 
%   Desired image type
%   Grid size determination: distance between first two points in x
%   direction
%   check: grid size and number of points in each direction 

index = [];
j=1; 
while (j <= numberofimages)
    if(strncmpi(besa_image_temp(j).type,ImageType,4))                   ...
       %first image of the selected type:
       %start index and define coordinate system
       if (isempty(index)) %first file of type
            xcoords = [besa_image_temp(j).xcoordinates(1),              ...
                besa_image_temp(j).xcoordinates(end),                   ...
                size(besa_image_temp(j).xcoordinates,2)];
            ycoords = [besa_image_temp(j).ycoordinates(1),              ...
                besa_image_temp(j).ycoordinates(end),                   ...
                size(besa_image_temp(j).ycoordinates,2)];   
            zcoords = [besa_image_temp(j).zcoordinates(1),              ...
                besa_image_temp(j).zcoordinates(end),                   ...
                size(besa_image_temp(j).zcoordinates,2)];   
            % number of data points in each dimension
            XCoords(1) = xcoords(3);         
            YCoords(1) = ycoords(3);
            ZCoords(1) = zcoords(3);
            % size of grid in mm (cubic; regard only x direction)
            Grid(1).Size =                                              ...
                    round(besa_image_temp(j).xcoordinates(2)            ...                  
                    - besa_image_temp(j).xcoordinates(1));
            index = j;
            Grid(1).index = index;
        %end
       elseif((size(besa_image_temp(j).xcoordinates,2) == xcoords(3))   ...
           &&(size(besa_image_temp(j).ycoordinates,2) == ycoords(3))    ...
           &&(size(besa_image_temp(j).zcoordinates,2) == zcoords(3))    ...
           &&(round(besa_image_temp(j).xcoordinates(2)                  ...                  
                   - besa_image_temp(j).xcoordinates(1))==Grid(1).Size))
        %In most cases (e.g. if this file is called from BESA) all grid
        %sizes will be the same. So we ask whether
        % - the number of points in every direction agrees with those for
        % the first image of the selected type,
        % - the grid size (calculated for x direction) is the same 
            index = [index j];
            Grid(1).index = index; %if so, index grows
        elseif (strncmpi(besa_image_temp(j).type,ImageType,5) == 0)   
            %different image type: do nothing
        else %If image type is right and the coordinates are not those 
             %of the first grid but of another known grid (initialized
             %below)
            KnownGridSize = 0;
            for k=1:numberofgrids
                if ((size(besa_image_temp(j).xcoordinates,2)                ...
                                == XCoords(k))                              ...
                    &&(size(besa_image_temp(j).ycoordinates,2)              ...
                                == YCoords(k))                              ...
                    &&(size(besa_image_temp(j).zcoordinates,2)              ...
                                == ZCoords(k))                              ...
                    &&(round(besa_image_temp(j).xcoordinates(2)             ...                  
                                - besa_image_temp(j).xcoordinates(1))       ...
                                == Grid(k).Size))
                    Grid(k).index = [Grid(k).index j];
                    KnownGridSize = 1;
                    %if the grid has occurred before, index for this grid
                    %grows
                end;
            end;
            if ~KnownGridSize
                %if this grid spacing is new, open new index and save
                %grid spacing
                numberofgrids = numberofgrids + 1; 
                Grid(numberofgrids).index = j;
                XCoords(numberofgrids) = size(besa_image_temp(j).xcoordinates,2);
                YCoords(numberofgrids) = size(besa_image_temp(j).ycoordinates,2);
                ZCoords(numberofgrids) = size(besa_image_temp(j).zcoordinates,2);
                Grid(numberofgrids).Size =                                          ...
                    round(besa_image_temp(j).xcoordinates(2)            ...                  
                    - besa_image_temp(j).xcoordinates(1));
                 %Grid size in mm         
            end;
        end;
    end;
    j=j+1;
end;

if isempty(index) %no image of chosen type
    %this should not be called as the user can select only among available
    %types
    disp(['No image of chosen type', ImageType]);
   return;
elseif (numberofgrids>1)
    %more than one grid
    ImagesPerGrid = [];
    GridButtons = {};
    switch ImageType
        case 'surface minimum norm'
            for k=1:NumberOfGrids
                ImagesPerGrid(k)=length(Grid(k).index);
                if (ZCoords(k)==750)
                    if (ImagesPerGrid(k)==1)
                        GridButtons{k} = ['Standard Brain (',           ...
                        num2str(ImagesPerGrid(k)), 'image)'];
                    else
                        GridButtons{k} = ['Standard Brain (',           ...
                        num2str(ImagesPerGrid(k)), 'images)'];
                    end;
                else
                    if (ImagesPerGrid(k)==1)
                        GridButtons{k} = [num2str(ZCoords(k)),          ...
                        ' surface locations (',                         ...
                        num2str(ImagesPerGrid(k)), 'image)'];
                    else
                        GridButtons{k} = [num2str(ZCoords(k)),          ...
                        ' surface locations (',                         ...
                        num2str(ImagesPerGrid(k)), 'images)'];
                    end;
                end;
            end;
            [MaxGrid,MaxGridPlace] = max(ImagesPerGrid);
             message = sprintf('%s %i %s \n %s', ...
                 ['Only minimum norm images calculated for the same ',  ...
                 'brain surface can be averaged. The available minimum',...
                 ' norm images are based on '],length(Grid),            ...
                 [' different brain surfaces.',                         ...
                 ' Please select which subgroup to average.'],          ...
                 ['Graphical representation of the output is only ',    ...
                 'possible for the standard brain ',                    ...
                 '(750 surface locations).']);            
        otherwise
            for k=1:numberofgrids %text for grid selection dialog
                ImagesPerGrid(k) = length(Grid(k).index);   
                if (ImagesPerGrid(k)==1)
                    GridButtons{k} = [num2str(Grid(k).Size) ,'mm (',    ...
                    num2str(ImagesPerGrid(k)), ' image)'];  
                else
                    GridButtons{k} = [num2str(Grid(k).Size) ,'mm (',    ...
                    num2str(ImagesPerGrid(k)), ' images)'];  
                end;
            end;
            [MaxGrid,MaxGridPlace] = max(ImagesPerGrid);
             message = ['Only images calculated for the same grid size',...
                 ' can be averaged. ', num2str(length(Grid)),           ...
                 ' grids have been found. ',                            ...
                 'Please select which subgroup to average.'];
   end;
   button = questdlg([message], 'Grid Selection',GridButtons{:},        ...
        GridButtons{MaxGridPlace});
    for k=1:numberofgrids
        if strcmpi(button,GridButtons{k})
            SelectedGrid = k;
        end
    end;
else
    SelectedGrid = 1;
end;%number of files 

SelectedIndex = Grid(SelectedGrid).index;
FirstImageSelected = SelectedIndex(1);
NumberForAveraging = length(SelectedIndex); % Number of images meeting the 
% requirements and used for averaging

besa_image_res = besa_image_temp(FirstImageSelected);

if (NumberForAveraging < numberofimages) 
    if (NumberForAveraging ==1)
        NumberOfImageText = ' images is ';
    else
         NumberOfImageText = ' images are ';
    end;
    if (length(Grid)==1)
        message = ['Only ' num2str(NumberForAveraging) ' of the '       ...
        num2str(numberofimages), NumberOfImageText, 'of type ',ImageType];
    elseif strcmp(ImageType, 'surface minimum norm')
        message = ['Only ' num2str(NumberForAveraging) ' of the '       ...
        num2str(numberofimages), ' minimum norm', NumberOfImageText,    ...
        'based on the same brain surface (',                            ...
        num2str(ZCoords(SelectedGrid)),' surface locations)'  ];
    else
        message = ['Only ' num2str(NumberForAveraging) ' of the '       ...
        num2str(numberofimages), NumberOfImageText, 'of ', ImageType    ...
        ' type and spacing ' num2str(Grid(SelectedGrid).Size) 'mm' ];
    end;
    
    clear NumberOfImageText
    
    disp(message);
end;
%Coordinates for the averaged image are those of the first image of the
%selected grid size (because coordinates agree for all selected images)
besa_image_res.GridDimensions_X =                                       ...
    [besa_image_temp(FirstImageSelected).xcoordinates(1),               ...
    besa_image_temp(FirstImageSelected).xcoordinates(end),              ...
    size(besa_image_temp(FirstImageSelected).xcoordinates,2)];
besa_image_res.GridDimensions_Y =                                       ...
    [besa_image_temp(FirstImageSelected).ycoordinates(1),               ...
    besa_image_temp(FirstImageSelected).ycoordinates(end),              ...
    size(besa_image_temp(FirstImageSelected).ycoordinates,2)];
besa_image_res.GridDimensions_Z =                                       ...
    [besa_image_temp(FirstImageSelected).zcoordinates(1),               ...
    besa_image_temp(FirstImageSelected).zcoordinates(end),              ...
    size(besa_image_temp(FirstImageSelected).zcoordinates,2)];

%Latencies may be different in images. If so, replace latency in output
%file by 'n.a.'
if length(unique(latency(SelectedIndex)))>1
    besa_image_res.latencies = 'n.a.';
end;
%Array dimensions:
Dim = size(besa_image_temp(FirstImageSelected).data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Averaging

% Comparison between the data handed to MATLAB and those written by BESA to
% a *.dat file show that small differences are possible (usu. fifth decimal
% place or smaller). More importantly, MATLAB may be given a "NaN" although
% the corresponding .dat file shows a zero instead. 

for i=1:length(SelectedIndex)
    k=SelectedIndex(i);
    IsNanIndex = find(isnan(besa_image_temp(k).data));
    if ~isempty(IsNanIndex)
        disp('NaNs in data are replaced by zeros');
        besa_image_temp.data(IsNanIndex) = 0;  
    end;
end;
clear IsNanIndex


InputData = besa_image_temp;

AverageImages = 1; %1:          standard averaging 
                   %otherwise:  data of first image conforming to 
                   %            selection criteria (type and grid size)
% call averaging routine
[OutputData]= averageimages_average(InputData,                          ...
    FirstImageSelected,SelectedIndex,ImageType,NumberForAveraging,      ...
    AverageImages); 

besa_image_res.data = OutputData.data;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Write data file and plot output

if (UseDefaultName==1)
    %use default name (e.g. in batch)
    CompleteFileName = [OutputPath,DefaultName,'.dat'];
else %user interaction
    [ChosenFileName,PathName,FilterIndex]                               ...
        = uiputfile([PathName,'\*.dat'], 'Save Averaged Image','Average');
    CompleteFileName = strcat(char(PathName),char(ChosenFileName));
end;

if strcmp(ImageType,'surface minimum norm')
    writedatfilemn(besa_image_res, CompleteFileName, NumberForAveraging,...
        Dim);
else
    writedatfile(besa_image_res, CompleteFileName, NumberForAveraging, Dim);
end;

if PlotOutput 
    if NumberForAveraging >1
        namestring =                                                    ...
            [' - Average of ', num2str(NumberForAveraging), ' images'];
    else
        namestring = ' - One image only';
    end;
        besa_plot_image_ai(besa_image_res, namestring);
end;
%....................... Clear variables .................................%
%clear besa_image_temp; %Because of the exist query at the beginning, it is 
%necessary to delete this variable. Otherwise, the datafile browser may not
%be opened.
  
clear *Type* *Coords *coords *Image* *Name *Grid* *File* h i j k message ...
    *Input* *Output* *index* *Index* Dim NumberForAveraging button ok    ...
    *File* namestring PlotOutput
clear besa_image_res besa_image image besa_image_temp
