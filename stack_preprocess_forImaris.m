clear;clc;close all;
%% Input
name='C:\Users\Desktop\lipid';
filename=strcat(name,'.tif');
I=fullfile(filename);
info=imfinfo(I);
depth=length(info);
fmt=info.Format;
stackname=info.Filename;
imagewidth=info.Width;
imageheight=info.Height;
imagebit=info.BitDepth;
imageLUT=info.ColorType;
stack=zeros(imagewidth,imageheight,depth,'uint16');
output=zeros(imagewidth,imageheight,depth,'uint16');
masked_output=zeros(imagewidth,imageheight,depth,'uint16');
bw=zeros(imagewidth,imageheight,depth,'logical');
%% Filtered stack display
for i=1:depth
    stack(:,:,i) = imread(I,i);
end
w_size = 3;
gau_sigma = 0.5;
stre_upper = 0.99;
stre_lower = 0.01;
for i=1:depth
    output(:,:,i) = wiener2(stack(:,:,i),[w_size,w_size]);  % wiener default is [3,3]
    output(:,:,i) = imgaussfilt(output(:,:,i),gau_sigma);   % gaussian default is 0.5
    output(:,:,i) = imadjust(output(:,:,i),stretchlim(output(:,:,i),[stre_lower,stre_upper]));
end
% figure
% montage((output))
%% Binarize and mask the filtered stack
T = 12000/65535; % manual global threshold 
for k=1:depth
    holdon = output(:,:,k);
    bw(:,:,k) = imbinarize(holdon,T);

% Close mask with default, remove holes smaller than the defined SE
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
bw = imclose(bw, se);

% Open mask with default, remove foreground objects smaller than definedSE
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
bw = imopen(bw, se);

% % Fill holes
% bw = imfill(bw, 'holes');

    holdon(~bw(:,:,k)) = 0;
    masked_output(:,:,k) = holdon;
end
%% Save BW stack
output_name=strcat(name,'_bw','.tif');
start_frame = 1;
end_frame = depth;
imwrite(im2uint8(bw(:,:,start_frame)),output_name)
for j=(start_frame+1):end_frame
    imwrite(im2uint8(bw(:,:,j)),output_name,"WriteMode","append")
end