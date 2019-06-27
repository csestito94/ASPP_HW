% Files .h generation %

clear all; close all; clc;

ROW = 200; COL = 200; DEPTH = 3;

% Input map reading %
for k = 1:DEPTH
  filename = fopen(['ifmap' num2str(k) '.txt'],'r');
  ifmap(:,k) = fscanf(filename,'%u',[ROW*COL]);
end 

% Write to files .h %
for k = 1:DEPTH
    filename = fopen(['ifmap' num2str(k) '.h'],'w');          
    fprintf(filename, ['unsigned char ifmap' num2str(k) '[40000] = {']);
    fprintf(filename, '%u, ',ifmap(1:ROW*COL-1,k));    
    fprintf(filename, '%u};', ifmap(ROW*COL,k));
    fclose(filename);
end


