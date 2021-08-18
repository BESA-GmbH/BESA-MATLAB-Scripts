function [OutputData] = averageimages_average(InputData,                ...
    FirstImageSelected, SelectedIndex,ImageType,NumberForAveraging,     ...
    AverageImages)  

if (NumberForAveraging ==1)
    AverageImages = 0;
end;
switch AverageImages
    case 1
    %Averaging
    %1st step: simply average over all images
        OutputData.data                                                 ...
            = zeros(size(InputData(FirstImageSelected).data));
        for i=1:NumberForAveraging;
            ImageNumber = SelectedIndex(i);
            OutputData.data=OutputData.data + InputData(ImageNumber).data;
        end;
        OutputData.data=OutputData.data/NumberForAveraging;
        disp(['Averaged ', num2str(NumberForAveraging),                 ...
            ' images of ',ImageType, ' type']);
  
    otherwise
        %simply write data for first image corresponding to chosen type and
        %grid
        OutputData.data=InputData(FirstImageSelected).data;
        disp('Only one image to be written to file');
end;