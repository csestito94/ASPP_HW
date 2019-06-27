
% The Atrous Spatial Pyramid Pooling
% Dilated Convolution @ r = [6 12 18 24]

clear all; 
close all; 
clc;

ROW = 200; COL = 200; DEPTH = 3;

% Define DEPTH input feature maps (each with ROW*COL values)
%{
ifmap = zeros;
for i = 1:ROW
    for j = 1:COL
        for k = 1:DEPTH
            ifmap(i,j,k) = randi([0,255]); 
        end
    end
end 
%}

% Input map reading %
for k = 1:DEPTH
  filename = fopen(['ifmap' num2str(k) '.txt'],'r');
  ifmap(:,:,k) = fscanf(filename,'%u',[ROW COL]);
end 

% Transpose
ifmapt = zeros;
for i = 1:ROW
    for j = 1:COL
        for k = 1:DEPTH
            ifmapt(i,j,k) = ifmap(j,i,k);
        end
    end
end
        
% Write each fmap to a text file
%{
for k = 1:DEPTH
    filename = fopen(['ifmap' num2str(k) '.txt'],'w');
    fprintf(filename,'%u\n',ifmapt(:,:,k));
    fclose(filename);
end 
%}

% Weights generation %
W1 = [ -128 0 64 ; -32 -1 127 ; -16 8 4 ];

% Dilated Convolution parameters
K = 3; R = 1;
Ke = K+(K-1)*(R-1);

% Convolution 3x3, rate 1 %
for i = 1:DEPTH
    ofmap1(:,:,i) = conv2(ifmapt(:,:,i),W1,'same');
end    

% Convolution 3x3, rate 6 %
R = 6; 
W6 = zeros(Ke);
for i = 1:K
    for j = 1:K
        W6((i-1)*R+1,(j-1)*R+1) = W1(i,j);
    end
end
for i = 1:DEPTH
    ofmap6(:,:,i) = conv2(ifmapt(:,:,i),W6,'same');
end    

% Convolution 3x3, rate 12 %
R = 12; 
W12 = zeros(Ke);
for i = 1:K
    for j = 1:K
        W12((i-1)*R+1,(j-1)*R+1) = W1(i,j);
    end
end
for i = 1:DEPTH
    ofmap12(:,:,i) = conv2(ifmapt(:,:,i),W12,'same');
end 

% Convolution 3x3, rate 18 %
R = 18; 
W18 = zeros(Ke);
for i = 1:K
    for j = 1:K
        W18((i-1)*R+1,(j-1)*R+1) = W1(i,j);
    end
end
for i = 1:DEPTH
    ofmap18(:,:,i) = conv2(ifmapt(:,:,i),W18,'same');
end 

% Convolution 3x3, rate 24 %
R = 24; 
W24 = zeros(Ke);
for i = 1:K
    for j = 1:K
        W24((i-1)*R+1,(j-1)*R+1) = W1(i,j);
    end
end
for i = 1:DEPTH
    ofmap24(:,:,i) = conv2(ifmapt(:,:,i),W24,'same');
end 

% Flatten ofmaps
for i = 1:ROW
  for j = 1:COL
    for k = 1:DEPTH
        ofmap1_flatten(j+COL*(i-1),k)=ofmap1(i,j,k);
        ofmap6_flatten(j+COL*(i-1),k)=ofmap6(i,j,k);
        ofmap12_flatten(j+COL*(i-1),k)=ofmap12(i,j,k);
        ofmap18_flatten(j+COL*(i-1),k)=ofmap18(i,j,k);
        ofmap24_flatten(j+COL*(i-1),k)=ofmap24(i,j,k);
    end
  end
end

% Convert to unsigned type and then to hex type

% Rate 6
for i = 1:ROW*COL
  for k = 1:DEPTH
    if ofmap6_flatten(i,k) < 0
        ofmap6_u(i,k) = 2^20 + ofmap6_flatten(i,k);
    else
        ofmap6_u(i,k) = ofmap6_flatten(i,k);
    end
  end  
end
for i = 1:DEPTH
    ofmap6_hex(:,:,i) = dec2hex(ofmap6_u(:,i));
end


% Rate 12
for i = 1:ROW*COL
  for k = 1:DEPTH
    if ofmap12_flatten(i,k) < 0
        ofmap12_u(i,k) = 2^20 + ofmap12_flatten(i,k);
    else
        ofmap12_u(i,k) = ofmap12_flatten(i,k);
    end
  end  
end
for i = 1:DEPTH
    ofmap12_hex(:,:,i) = dec2hex(ofmap12_u(:,i));
end
% Rate 18
for i = 1:ROW*COL
  for k = 1:DEPTH
    if ofmap18_flatten(i,k) < 0
        ofmap18_u(i,k) = 2^20 + ofmap18_flatten(i,k);
    else
        ofmap18_u(i,k) = ofmap18_flatten(i,k);
    end
  end  
end
for i = 1:DEPTH
    ofmap18_hex(:,:,i) = dec2hex(ofmap18_u(:,i));
end

% Rate 24
for i = 1:ROW*COL
  for k = 1:DEPTH
    if ofmap24_flatten(i,k) < 0
        ofmap24_u(i,k) = 2^20 + ofmap24_flatten(i,k);
    else
        ofmap24_u(i,k) = ofmap24_flatten(i,k);
    end
  end  
end
for i = 1:DEPTH
    ofmap24_hex(:,:,i) = dec2hex(ofmap24_u(:,i));
end

% 8-bit quantization (consider only 2 first hex digits)
for i = 1:DEPTH
  ofmap6_quant(:,:,i) = ofmap6_hex(:,[1 2],i);
  ofmap12_quant(:,:,i) = ofmap12_hex(:,[1 2],i);
  ofmap18_quant(:,:,i) = ofmap18_hex(:,[1 2],i);
  ofmap24_quant(:,:,i) = ofmap24_hex(:,[1 2],i);
end

% Conversion to dec type
for i = 1:DEPTH
  ofmap6_quant_dec(:,:,i) = hex2dec(ofmap6_quant(:,:,i));
  ofmap12_quant_dec(:,:,i) = hex2dec(ofmap12_quant(:,:,i));
  ofmap18_quant_dec(:,:,i) = hex2dec(ofmap18_quant(:,:,i));
  ofmap24_quant_dec(:,:,i) = hex2dec(ofmap24_quant(:,:,i));
end  

% From unsigned to signed values
for i = 1:ROW*COL
    for k = 1:DEPTH
        if ofmap6_quant_dec(i,1,k) > 127
            ofmap6_quant_signed(i,1,k) = ofmap6_quant_dec(i,1,k)-2^8;
        else
            ofmap6_quant_signed(i,1,k) = ofmap6_quant_dec(i,1,k);
        end 
    end
end

for i = 1:ROW*COL
    for k = 1:DEPTH
        if ofmap12_quant_dec(i,1,k) > 127
            ofmap12_quant_signed(i,1,k) = ofmap12_quant_dec(i,1,k)-2^8;
        else
            ofmap12_quant_signed(i,1,k) = ofmap12_quant_dec(i,1,k);
        end 
    end
end

for i = 1:ROW*COL
    for k = 1:DEPTH
        if ofmap18_quant_dec(i,1,k) > 127
            ofmap18_quant_signed(i,1,k) = ofmap18_quant_dec(i,1,k)-2^8;
        else
            ofmap18_quant_signed(i,1,k) = ofmap18_quant_dec(i,1,k);
        end 
    end
end

for i = 1:ROW*COL
    for k = 1:DEPTH
        if ofmap24_quant_dec(i,1,k) > 127
            ofmap24_quant_signed(i,1,k) = ofmap24_quant_dec(i,1,k)-2^8;
        else
            ofmap24_quant_signed(i,1,k) = ofmap24_quant_dec(i,1,k);
        end 
    end
end

% Partial fmaps accumulation
final_map6 = sum(ofmap6_quant_signed,3);
final_map12 = sum(ofmap12_quant_signed,3);
final_map18 = sum(ofmap18_quant_signed,3);
final_map24 = sum(ofmap24_quant_signed,3);

% Rectified Linear Unit (ReLU)

ReLU_map6 = zeros;
for i = 1: ROW*COL
  if final_map6(i) >= 0
    ReLU_map6(i,1) = final_map6(i);
  else
    ReLU_map6(i,1) = 0;
  end
end  

ReLU_map12 = zeros;
for i = 1: ROW*COL
  if final_map12(i) >= 0
    ReLU_map12(i,1) = final_map12(i);
  else
    ReLU_map12(i,1) = 0;
  end
end  

ReLU_map18 = zeros;
for i = 1: ROW*COL
  if final_map18(i) >= 0
    ReLU_map18(i,1) = final_map18(i);
  else
    ReLU_map18(i,1) = 0;
  end
end  

ReLU_map24 = zeros;
for i = 1: ROW*COL
  if final_map24(i) >= 0
    ReLU_map24(i,1) = final_map24(i);
  else
    ReLU_map24(i,1) = 0;
  end
end  


% VIVADO&MATLAB results comparison

ReLU_map6_hex = dec2hex(ReLU_map6);
ReLU_map12_hex = dec2hex(ReLU_map12);
ReLU_map18_hex = dec2hex(ReLU_map18);
ReLU_map24_hex = dec2hex(ReLU_map24);

ofmaps_concat_hex = cat(2,ReLU_map6_hex,ReLU_map12_hex,ReLU_map18_hex,ReLU_map24_hex);
ofmaps_concat_dec = hex2dec(ofmaps_concat_hex);
ofmaps_concat_read = fscanf(fopen('hw_res_final.txt','r'),'%x');

true_array = zeros;
for i = 1:ROW*COL
    if ofmaps_concat_read(i) == ofmaps_concat_dec(i)
       true_array(i) = 1;
    end 
end

if sum(true_array) == ROW*COL
    disp('Correct results');
else
    disp('Wrong results');
end




