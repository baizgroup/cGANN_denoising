%%cGANN training script

addpath ../code/
in.freqAx = (1600:0.5882:1750);
options = trainingOptions();
noisySpecPath = '..\datasets\onepeak_CLS_tau1500_noise';
cleanSpecPath = '..\datasets\onepeak_CLS_tau1500_clean';

p2pModel = p2p.train(noisySpecPath,cleanSpecPath, options);

save trained_cGANN.mat