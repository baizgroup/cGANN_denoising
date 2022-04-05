addpath ../code/
trainedcGANNUrl = 'https://baizgroup.org/data/cGANN/trained_cGANN.mat';

%load pre-trained cGANN (download from URL)
if ~exist('trained_cGANN.mat','file')
websave('trained_cGANN.mat',trainedcGANNUrl);
end

load trained_cGANN.mat

freqAx = 1680:((1790-1680)/255):1790; %interpolated frequency axis
t2 = [150,300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500,1600,1700,1800,1900,2000,2200,2400,2600,2800,3000]; %waiting time in fs

%% %this is for plotting the training data set.

for startLoading = 1 %[1:1:10];% benchmarking set;


    for imnumber = 1:1:24

        %load input images
        inputImage = imread(['C:\Users\baizgroup\Desktop\Carlos\pix2pix\datasets\benchmarking\experimental\' num2str(t2(imnumber)) 'fs\int_' num2str(imnumber+startLoading,'%05d') '.png']);
        cleanInputImage = imread(['C:\Users\baizgroup\Desktop\Carlos\pix2pix\datasets\benchmarking\experimental\' num2str(t2(imnumber)) 'fs\int_sum.png']);

        %run input images through cGANN
        translatedImage(:,:,1) = double(gather(p2p.translate(p2pModel, inputImage)));
        translatedImage(:,:,1) = flipud(translatedImage(:,:,1)) - 64;
        translatedImage(:,:,1) = translatedImage(:,:,1)./max(max(translatedImage(:,:,1)));

        %collect outputs
        gann.noisyinput(:,:,imnumber) = flipud(double(inputImage))./double(max(max((inputImage))));
        gann.reference(:,:,imnumber) = flipud(double(cleanInputImage))./double(max(max(cleanInputImage)));
        gann.translatedImages(:,:,imnumber) = translatedImage;
        
        disp(num2str(imnumber))
    end
end
%% Plot spectra

figure(1); clf;

for n=1:3
    if n==1
        modelOut = gann.noisyinput(:,:,imnumber);
        legendText = 'Noisy input';
    elseif n==2
        modelOut = gann.reference(:,:,imnumber);
        legendText = 'Clean spectrum';
    elseif n >= 3
        modelOut = gann.translatedImages(:,:,imnumber);
        legendText = 'cGANN denoised';

    end
    subplot(1,3,n)
    spec2.freqAx = freqAx;
    spectrumMin = min(min(modelOut));
    spectrumMax = max(max(modelOut));

    imagesc(spec2.freqAx,flipud(spec2.freqAx), (modelOut)); hold all;

    contour(spec2.freqAx,spec2.freqAx, modelOut  ,...
        [spectrumMin:(spectrumMax/14):255], "LineWidth",0.1, "LineStyle","-", "LineColor",[0.3 0.3 0.3]);

    caxis([spectrumMin, spectrumMax]); colormap(cmap2d(20));
    axis square
    line([spec2.freqAx(1) spec2.freqAx(end)],[spec2.freqAx(1)...
        spec2.freqAx(end)],'color',[0 0 0]);
    set(gca,'YDir','normal')
    xlabel('\omega_1 (cm^{-1})')
    ylabel('\omega_3 (cm^{-1})')
    title(legendText);
end