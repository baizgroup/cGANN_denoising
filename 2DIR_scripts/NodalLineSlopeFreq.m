function [NLSSlope, stdev, lowerBoundFit, upperBoundFit, positiveWaitingTimes, NLSFitFig, NLSDecayFitFig, prelimExponentialCurve] =...
    NodalLineSlopeFreq(Data, freqAxis, listWaitingTimes, freqLowHigh, cutoffWaitingTimes)

% This is for generating nodal line slopes (NLS), which can be used for
% normalized FFCF
%   Modified 2020.4.15  X. You
%   Modified 2022.3     C. Baiz
%   Comments 2022.3     Z. Al-Mualem

% Inputs:
%   Data = array of 2D spectra; 3rd dim is organized by the waiting time (t2 delay)
%   freqAxis = frequency axis of the 2D spectra data
%   listWaitingTimes = list of waiting times at which the 2D spectra were collected
%   freqLowHigh = frequency range for fitting, low freq to high freq
%   cutoffWaitingTimes = cutoff range of the waiting time used in the fit
% Outputs:
%   NLSSlope = fitted nodal line slope value from each 2D spectrum for each waiting time
%   stdev = standard deviation for the NLS decay plot
%   lowerBoundFit = Lower bounds of fit
%   upperBoundFit = upper bounds of fit
%   positiveWaitingTimes = positive waiting times in listWaitingTimes 
%   NLSFitFig = figure that shows the NLS on the 2D IR spectra
%   NLSDecayFitFig = figure of the NLS decay as a function of waiting time
%   prelimExponentialCurve = exponential curve from fitting

    % Error handling for dimension mismatch
    if length(listWaitingTimes) ~= size(Data,3) 
        error('Wrong Input: Data and waiting time values do not match.');
        return %#ok<UNRCH> 
    else
        if length(freqAxis) ~= size(Data,1)
            error('Wrong Input: Data and frequency axis do not match.');
            return %#ok<UNRCH> 
        end
    end
    
    % Error handling for waiting time cutoff
    if ~exist('cutoffWaitingTimes', 'var')
        cutoffWaitingTimes = [0 10000]; % waiting time in fs
        warning('No waiting time cuttoff input! Setting waiting time range to 0 to 10 ps');
    end
    
    % Only use data collected at positive waiting times
    PosData = Data(:,:, listWaitingTimes > 0);
    positiveWaitingTimes = listWaitingTimes(listWaitingTimes > 0);
    
    % Preallocate variables for speed
    % NLS values from fit
    NLSSlope = zeros(1,length(positiveWaitingTimes));
    lowerBoundFit = zeros(1,length(positiveWaitingTimes));
    upperBoundFit = zeros(1,length(positiveWaitingTimes));
    
    % Create figure
    NLSFitFig = figure('name', 'NLS Analysis, 2D IR Spectra'); clf;
    set(NLSFitFig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1])
    
    [~, pumpIndexLow] = min(abs(freqAxis-freqLowHigh(1)));
    [~, pumpIndexHigh] = min(abs(freqAxis-freqLowHigh(2)));
    
    for n = 1:length(positiveWaitingTimes)
        % Function used in fitting
        logFun = 'a/(1+exp(-b*(x-c)))+d';

        % Find probe frequencies
        ProbeIndex = zeros(1,size(PosData,2));
        Value = zeros(1,size(PosData,2));

        for PumpIndex = [pumpIndexLow:pumpIndexHigh]
            [minValue,minIndex] = min(PosData(5:end-5,PumpIndex,n));
            [maxValue,maxIndex] = max(PosData(5:end-5,PumpIndex,n));
            if    minIndex > maxIndex - 5
                continue;
            end
            x = [minIndex:maxIndex];
            logFunFit = fitOptions(x',PosData(minIndex:maxIndex,PumpIndex,n),...
                logFun,'StartPoint',...
                [maxValue-minValue, 1, 0.5*(minIndex+maxIndex), minValue]);
            ProbeIndex(PumpIndex) = logFunFit.c;
            Value(PumpIndex) = maxValue;
        end
        
        % Remove regions that are not in the peak. Fit the peak
        PeakIndex1 = [pumpIndexLow:1:pumpIndexHigh];
        PeakIndex3 = ProbeIndex(PeakIndex1);
        IntervalX = (max(freqAxis) - min(freqAxis))/(length(freqAxis)-1);
        ProbePosition = PeakIndex3 * IntervalX + min(freqAxis);
    
        fitOptions = fitoptions('Method','NonlinearLeastSquares',...
                   'Lower',[-Inf,-10],...
                   'Upper',[Inf,10],...
                   'StartPoint',[1 0]);
        LinearFit = fitOptions(freqAx(PeakIndex1)'-mean(freqAx(PeakIndex1)),...
            ProbePosition'-mean(ProbePosition'),'poly1');
            
        % Extract the slope
        NLSSlope(n) = LinearFit.p1;
        NLSLine = LinearFit.p1*freqAxis + LinearFit.p2;
        confidenceInterval = confint(LinearFit);
        lowerBoundFit(n) = confidenceInterval(1,1);
        upperBoundFit(n) = confidenceInterval(2,1);
        
        % Plot NLS (we use subplot instead of tiledlayout to support older
        % version of matlab)
        subplot(4,ceil(length(positiveWaitingTimes)/4),n);
        contourf(freqAxis,freqAxis,PosData(:,:,n),[-1:0.1:1],'LineWidth',0.5);
        colormap(cmap2d(50));
        hline = refline(1,0);
        hline.Color = 'k'; hline.LineWidth = 1;
        hold on;
        axis square;
        plot(freqAxis(PeakIndex1),ProbePosition,'o','Color',[0 1 1]);
        plot(freqAxis,NLSLine,'r','LineWidth',2);
        title(['t_2 = ' num2str(positiveWaitingTimes(n))])
        xlim([min(freqAxis) max(freqAxis)]);
        ylim([min(freqAxis) max(freqAxis)]);
        legend off;
    end
    
    stdev = (upperBoundFit - lowerBoundFit)./4;
    
    % Preliminary Fit
    disp('Computing preliminary fit...');
    
    cutoffWaitingTimesIndex = positiveWaitingTimes >= cutoffWaitingTimes(1) &...
        positiveWaitingTimes <= cutoffWaitingTimes(2);
    
    NLSDecayFitFig = figure('name', 'NLS: Preliminary Fit'); 
    clf; hold on; box on;
    prelimExponentialCurve = fitOptions(positiveWaitingTimes(cutoffWaitingTimesIndex)',...
        NLSSlope(cutoffWaitingTimesIndex)', 'a*exp(-x/b)+c',...
        'StartPoint', [1, 1000, 0.1], 'Lower', [0, 0, -0.1], 'Upper', [inf, inf ,1], 'Robust', 'ON');
    errorbar(positiveWaitingTimes(cutoffWaitingTimesIndex), NLSSlope(cutoffWaitingTimesIndex),...
        NLSSlope(cutoffWaitingTimesIndex)-lowerBoundFit(cutoffWaitingTimesIndex),...
        upperBoundFit(cutoffWaitingTimesIndex)-NLSSlope(cutoffWaitingTimesIndex), 's');
    plot(prelimExponentialCurve,'--','predfun');
    xlabel('Time (fs)'); ylabel('NLS');
    title('NLS Decays');
    hold off;

end



