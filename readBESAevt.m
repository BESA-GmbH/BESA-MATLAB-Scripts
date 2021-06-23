function Events = readBESAevt(filename)
% READBESAEVT reads events from a BESA EVT-file. 
%
% Parameters:
%     [filename]
%         In the case that the current folder is not the folder containing 
%         the file it should be the full path including the name of the 
%         evt file else only the name of the file should be specified. 
% 
% Return:
%     [Events] 
%         A struct containing the events from the file. Ech event is stored
%         as one entry in the struct. The members of each event are saved
%         in the following variables:
%         Time, Code, TriNo and Comment.
% 
% Copyright (C) 2015, BESA GmbH
%
% File name: readBESAevt.m
%
% Author: Todor Jordanov
% Created: 2015-11-20
%
% Modified:
% 2019-04-10 - Robert Spangler

Events = {};

fp = fopen(filename, 'r');

% MATLAB reserves file identifiers 0, 1, and 2 for standard input,  
% standard output (the screen), and standard error, respectively. When 
% fopen successfully opens a file, it returns a file identifier greater 
% than or equal to 3.
if(fp >= 3)
    
    % Get the first line of the file. It looks something like that:
    % Tmu         	Code	TriNo	Comnt
    FirstLine = fgetl(fp);
    
    LineCounter = 1;
    
    while(true)
        
        CurrentLine = fgetl(fp);
        
        % Check if end of file.
        if(~ischar(CurrentLine))            
            break;            
        end
        
        % Read event/trigger time and code
        EventTimeCode = sscanf(CurrentLine, '%d', 3);
        if EventTimeCode(2) == 41
            % New segment event
            Events{LineCounter}.Time = EventTimeCode(1);
            Events{LineCounter}.Code = EventTimeCode(2);
            Events{LineCounter}.TriNo= -1;
            if length(EventTimeCode) > 2
                Events{LineCounter}.Comment = ...
                    CurrentLine(strfind(CurrentLine, EventTimeCode(3)):end);
            end;
        elseif EventTimeCode(2) == 1
            % Trigger event
            Events{LineCounter}.Time = EventTimeCode(1);
            Events{LineCounter}.Code = EventTimeCode(2);
            Events{LineCounter}.TriNo= EventTimeCode(3);
            
            % Set comment
            EvtComment= CurrentLine(find(isletter(CurrentLine), 1):end);
            Events{LineCounter}.Comment = deblank(EvtComment);
        else
            Events{LineCounter}.Time = -1;
            Events{LineCounter}.Code = -1;
            Events{LineCounter}.TriNo= -1;
        end;              
        
        % Increment line counter
        LineCounter = LineCounter + 1;        
    end
        
else    
    Events = {};
    disp('Error! Invalid file identifier.')    
end