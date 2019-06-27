% Global Average Pooling %

clear all; 
close all; 
clc;

ROW = 200; COL = 200; DEPTH = 3;

% Input map reading %
for k = 1:DEPTH
  filename = fopen(['ifmap' num2str(k) '.txt'],'r');
  ifmap(:,k) = fscanf(filename,'%u',[ROW*COL]);
end 

% Approx Mean calculation %
mean = zeros;
for i = 1:DEPTH
    mean(i) = floor(sum(ifmap(:,i),1)/2^15);
end
