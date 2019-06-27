clear all;
close all;
clc;

ROW = 200; COL = 200; DEPTH = 3;

% Define DEPTH input feature maps (each with ROW*COL values)
ifmap = zeros;
for i = 1:DEPTH
    for j = 1:ROW*COL
        ifmap(i,j) = randi([0,255]); 
    end
end

% Write to DEPTH text file (for each ifm)
for i = 1:DEPTH
    filename = fopen(['ifmap' num2str(i) '.txt'],'w');
    fprintf(filename,'%u\n',ifmap(i,:));
    fclose(filename);
end