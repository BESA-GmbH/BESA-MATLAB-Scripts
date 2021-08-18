function [] = writedatfilemn(besa_image_res,FileName,NumberForAveraging,Dim)
%Writes dat file compatible to BESA_SA_MN_IMAGE:1.0 from MATLAB structure

%....................... Write file.......................................%
DummyText_1 = 'Detailed info currently not available';
DummyText_2 = 'Mixed';
% Open file (create if if necessary) and write header
fp = fopen(FileName,'w');

fprintf(fp,'%s\n\n','BESA_SA_MN_IMAGE:1.0');
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
fprintf(fp,'%s\t%s\n\n',' Filters: ',besa_image_res.filters);

fprintf(fp,'%s \t %s\n', 'Depth weighting:',                            ...
                besa_image_res.MNdepthweighting);
fprintf(fp,'%s \t %s\n', 'Sp.tmp. weighting:',                           ...
                besa_image_res.MNspatiotemporalweighting);
fprintf(fp,'%s \t %s\n', 'Sp.tmp. wgt. type:',                           ...
                besa_image_res.MNspatiotemporalweightingtype);
fprintf(fp,'%s \t\t\t %s\n', 'Dimension:',                                ...
                besa_image_res.MNdimension);  
fprintf(fp,'%s \t %s\n', 'Noise estimation:',                           ...
                besa_image_res.MNnoiseestimation);
fprintf(fp,'%s \t %s\n', 'Noise weighting:',                            ...
                besa_image_res.MNnoiseweighting);
fprintf(fp,'%s  %s\n', 'Noise scale factor:',                         ...
                besa_image_res.MNnoisescalefactor);
fprintf(fp,'%s\n\n', 'Sel. mean noise:');


locationnumber = size(besa_image_res.data,2);
fprintf(fp,'%s          %s\n', 'Locations:', num2str(locationnumber));

timesamples = size(besa_image_res.data,1);
fprintf(fp,'%s       %s\n\n', 'Time samples:', num2str(timesamples));

fprintf(fp,'%s\n','Location (Tal. [x,y,z])      Value');
fprintf(fp,'%s\n','======================================');
fprintf(fp,'%s\t%.2f\n', 'Latency (milliseconds):',                     ...
                    besa_image_res.latencies);
%Write data
for i=1:locationnumber
    fprintf(fp,'%.2f %.2f  %.2f  %f\n', besa_image_res.xcoordinates(i), ...
    besa_image_res.ycoordinates(i),besa_image_res.zcoordinates(i),...
    besa_image_res.data(i));
end;

fclose(fp);
