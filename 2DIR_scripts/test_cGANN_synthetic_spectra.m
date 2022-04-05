%%cGANN benchmarking script
addpath ../code/
trainedcGANNUrl = 'https://baizgroup.org/data/cGANN/trained_cGANN.mat';

%load pre-trained cGANN (download from URL)
if ~exist('trained_cGANN.mat','file')
websave('trained_cGANN.mat',trainedcGANNUrl);
end

load trained_cGANN.mat

%%
startLoading = 0;% benchmarking set from images 1000-1200;
for imnumber = 1:1:20

    %Read input images
    inputImage = imread(['..\datasets\benchmarking\onepeak_CLS_tau1500_2\spec_4_' num2str(imnumber+startLoading,'%05d') '.png']);
    cleanInputImage = imread(['..\datasets\benchmarking\onepeak_CLS_tau1500_Inf\spec_1_' num2str(imnumber+startLoading,'%05d') '.png']);

    %Run image through cGANN
    translatedImage(:,:,1) = gather(p2p.translate(p2pModel, inputImage));

    %build image array
    gann.noisyinput(:,:,imnumber) = inputImage;
    gann.reference(:,:,imnumber) = cleanInputImage;
    gann.translatedImages(:,:,imnumber) = translatedImage;

    disp(num2str(imnumber))
end

%%
   figure(1); clf;
for imnumber=[1 2 3] %up to 20
    for n=1:3
        if n==1
            modelOut = flipud(gann.noisyinput(:,:,imnumber));
            legendText = 'Noisy input';
        elseif n==2
            modelOut = flipud(gann.reference(:,:,imnumber));
            legendText = 'Ground thruth';
        elseif n >= 3
            modelOut = flipud(gann.translatedImages(:,:,imnumber));
            legendText = 'cGANN denoised';

        end

        subplot(1,3,n)
        spec2.freqAx = (1600:0.5882:1750);
        spectrumMin = min(min(modelOut));
        spectrumMax = max(max(modelOut));

        imagesc(spec2.freqAx,flipud(spec2.freqAx), (modelOut)); hold all;

        contour(spec2.freqAx,spec2.freqAx, modelOut  ,...
            [spectrumMin:(spectrumMax/14):255], "LineWidth",0.1, "LineStyle","-", "LineColor",[0.3 0.3 0.3]);

        caxis([spectrumMin, 255]); colormap(cmap2d(20));
        axis square
        line([spec2.freqAx(1) spec2.freqAx(end)],[spec2.freqAx(1)...
            spec2.freqAx(end)],'color',[0 0 0]);
        set(gca,'YDir','normal')
        xlabel('\omega_1 (cm^{-1})')
        ylabel('\omega_3 (cm^{-1})')
        title(legendText);
    end

end

