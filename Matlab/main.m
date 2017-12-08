clear ; close all; clc

%% Global parameters
IMAGE_NAME = 'brain8';
MAX_ROUND = 2;
SCHEME = 'MA';

%% Initial processing
K_LEN = 104+MAX_ROUND*76;
assert(strcmp(SCHEME,'BX')||strcmp(SCHEME,'MA'));

t_in = Tiff(strcat('input_image/',IMAGE_NAME,'.tif'));

%% Main program

% Initialization
P = imread(strcat('input_image/',IMAGE_NAME,'.tif'));
K = round(rand(1,K_LEN));

% Encryption
C = encryption(P,K,SCHEME,MAX_ROUND);

% Result output
t_out = Tiff(strcat('output_image/',IMAGE_NAME,'_encrypted.tif'),'w');
tagstruct.ImageLength     = t_in.getTag('ImageLength')+2;
tagstruct.ImageWidth      = t_in.getTag('ImageWidth')+2;
tagstruct.Photometric     = t_in.getTag('Photometric');
tagstruct.BitsPerSample   = t_in.getTag('BitsPerSample');
tagstruct.SamplesPerPixel = t_in.getTag('SamplesPerPixel');
tagstruct.PlanarConfiguration = t_in.getTag('PlanarConfiguration');
if tagstruct.Photometric == Tiff.Photometric.RGB && tagstruct.SamplesPerPixel == 4
    tagstruct.ExtraSamples = t_in.getTag('ExtraSamples');
end
t_out.setTag(tagstruct);
t_out.write(uint8(C));
t_out.close();

% Decryption
D = decryption(C,K,SCHEME,MAX_ROUND);

% Result output
t_out = Tiff(strcat('output_image/',IMAGE_NAME,'_decrypted.tif'),'w');
tagstruct.ImageLength     = t_in.getTag('ImageLength');
tagstruct.ImageWidth      = t_in.getTag('ImageWidth');
tagstruct.Photometric     = t_in.getTag('Photometric');
tagstruct.BitsPerSample   = t_in.getTag('BitsPerSample');
tagstruct.SamplesPerPixel = t_in.getTag('SamplesPerPixel');
tagstruct.PlanarConfiguration = t_in.getTag('PlanarConfiguration');
if tagstruct.Photometric == Tiff.Photometric.RGB && tagstruct.SamplesPerPixel == 4
    tagstruct.ExtraSamples = t_in.getTag('ExtraSamples');
end
t_out.setTag(tagstruct);
t_out.write(uint8(D));
t_out.close();

t_in.close();
