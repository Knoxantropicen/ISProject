clear ; close all; clc

%% Global parameters
IMAGE_NAME = 'brain16';
MAX_ROUND = 2;
SCHEME = 'MA';

%% Initial processing
K_LEN = 104+MAX_ROUND*76;
assert(strcmp(SCHEME,'BX')||strcmp(SCHEME,'MA'));

%% Main program

% Initialization
P = imread(strcat('input_image/',IMAGE_NAME,'.tif'));
K = round(rand(1,K_LEN));

% Encryption
C = encryption(P,K,SCHEME,MAX_ROUND);

% Result output
t = Tiff(strcat('output_image/',IMAGE_NAME,'_encrypted.tif'),'w');
tagstruct.ImageLength     = size(C,1);
tagstruct.ImageWidth      = size(C,2);
tagstruct.Photometric     = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample   = 8;
tagstruct.SamplesPerPixel = size(C,3);
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
t.setTag(tagstruct);
t.write(uint8(C));
t.close();

% Decryption
D = decryption(C,K,SCHEME,MAX_ROUND);

% Result output
t = Tiff(strcat('output_image/',IMAGE_NAME,'_decrypted.tif'),'w');
tagstruct.ImageLength     = size(D,1);
tagstruct.ImageWidth      = size(D,2);
tagstruct.Photometric     = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample   = 8;
tagstruct.SamplesPerPixel = size(D,3);
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
t.setTag(tagstruct);
t.write(uint8(D));
t.close();

