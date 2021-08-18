function besa_plot_mn_ai(mnimage, varargin)
% use as besa_plot_mn_ai(mnimage) or besa_plot_mn_ai(mnimage, namestring)
% mnimage: either *.dat file or output of readBESAimage
%
% Import and visualize BESA standard minimum norm image 
% To display besa_image, please call indirectly by using besa_plot_image
% Requires the MATLAB toolbox 'MyCrust' by Luigi Giaccari.
% Based on displayBESAminimumnorm(filename)

% Last modified by Karsten Hoechstetter Oct. 7, 2009
% 2009-12-14 Andrea Ostendorf: input file -> struct

if isstruct(mnimage)
    minnorm.Coordinates(:,1) = mnimage.xcoordinates';
    minnorm.Coordinates(:,2) = mnimage.ycoordinates';
    minnorm.Coordinates(:,3) = mnimage.zcoordinates';
    minnorm.Data             = mnimage.data';
elseif isstr(mnimage)
	minnorm=readBESAimage(mnimage); %if read by file
else
    return
end

namestring = '';

if size(minnorm.Coordinates(:,1),1)~=750
    warning('Nonstandard brain cannot be displayed');
    return;
end;
if ~exist('MyRobustCrust','file') 
    warning('MyCrust toolbox not found in MATLAB path');
    return;
end;
if (nargin > 1 && isstr(varargin{1}))
    namestring = varargin{1};
else 
    namestring = 'Plot besa_image: Minimum Norm (Standard) ';
end;

[t,norm]=MyRobustCrust(minnorm.Coordinates);

h=patch([minnorm.Coordinates(t(:,1),1) minnorm.Coordinates(t(:,2),1) minnorm.Coordinates(t(:,3),1)]', ...
    [minnorm.Coordinates(t(:,1),2) minnorm.Coordinates(t(:,2),2) minnorm.Coordinates(t(:,3),2)]', ...
    [minnorm.Coordinates(t(:,1),3) minnorm.Coordinates(t(:,2),3) minnorm.Coordinates(t(:,3),3)]', ...
    mean([minnorm.Data(t(:,1)) minnorm.Data(t(:,2)) minnorm.Data(t(:,3))],2)'/max(minnorm.Data(:)));
rotate3d on;
temp=t';
set(h,'LineStyle','None', 'FaceLighting','phong', 'EdgeLighting','phong',...
    'EdgeColor','none','AmbientStrength',0.8, ...
    'FaceVertexCData',([minnorm.Data(temp(:))]), ...
    'FaceColor','interp', 'EdgeColor','interp');
colorbar;
set(gcf,'Name', namestring);
axis equal; axis vis3d; axis off;
light('Style','infinite', 'Position',[-1 0 0]);

