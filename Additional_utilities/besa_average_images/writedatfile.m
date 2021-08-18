function [] = writedatfile(besa_image_res,FileName,NumberForAveraging,Dim)
%Writes images compatible to BESA_SA_IMAGE:2.0 from MATLAB structure
%....................... Write file.......................................%
DummyText_1 = 'Detailed info currently not available';
DummyText_2 = 'Mixed';
% Open file (create if if necessary) and write header
fp = fopen(FileName,'w');
fprintf(fp,'%s\n\n','BESA_SA_IMAGE:2.0');
if (NumberForAveraging ==1)
    fprintf(fp,'%s \t %s\n','Data file: ', besa_image_res.datafile);
else
    fprintf(fp,'%s %s\n',num2str(NumberForAveraging), 'images');
end;

if isfield(besa_image_res,'numberoftrials')
fprintf(fp,'%s \t%s\t%s%d%s','Condition: ',besa_image_res.condition,':',...
    besa_image_res.numberoftrials,' avs');
else
    fprintf(fp,'%s \t%s\t%s%d%s','Condition: ',besa_image_res.condition);
end;
fprintf(fp,'%s\t%s\n',' Filters: ',besa_image_res.filters);
if (strncmpi(besa_image_res.type,'User',4))
    disp('User-defined method');
    fprintf(fp,'%s %s\n','Method:', DummyText_1);
    fprintf(fp,'%s %s\n','Regularization:', DummyText_1);
else
    fprintf(fp,'%s \t \t%s\n' ,'Method:', besa_image_res.type);
end;
if ischar(besa_image_res.latencies)
    fprintf(fp,'%s  %s%s%s\n\n',DummyText_2,besa_image_res.latencies, ...
    ' ',besa_image_res.units);
else
    fprintf(fp,'%s  %.2f%s%s\n\n',DummyText_2,besa_image_res.latencies, ...
    ' ms ', besa_image_res.units);
end;
fprintf(fp,'%s\n', 'Grid dimensions ([min] [max] [nr of locations]):');

fprintf(fp,'%s%.6f %.6f %d\n', 'X: ', besa_image_res.GridDimensions_X);
fprintf(fp,'%s%.6f %.6f %d\n', 'Y: ', besa_image_res.GridDimensions_Y);
fprintf(fp,'%s%.6f %.6f %d\n', 'Z: ', besa_image_res.GridDimensions_Z);

for i=1:2,
    fprintf(fp,'%s','=================================================');
end;
%Write data
for iz =1:Dim(3),
    fprintf(fp, '\n%s%d\n','Z: ', iz-1);
    for iy = 1: Dim(2)
        fprintf(fp,'%1.10f ',squeeze(besa_image_res.data(1:end-1,iy,iz)));
        fprintf(fp,'%1.10f',squeeze(besa_image_res.data(end,iy,iz)));
        fprintf(fp, '\n');
    end;
end;

fclose(fp);
