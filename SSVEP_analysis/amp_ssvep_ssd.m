%% clear all

% Main function for getting SSVEP (5Hz) amplitude after applying SSD
% Regarding the details of SSD, please see function ssd()
% Regarding how we select the optimal SSD components, please see cluster_SSD()
% Author: Yonghao Chen (cheny@cbs.mpg.de)
% Jul 13, 2023
% Ref 
% [1]: Nikulin, V. V., Nolte, G., & Curio, G. (2011). A novel method for 
% reliable and fast extraction of neuronal EEG/MEG oscillations on the basis 
% of spatio-spectral decomposition. NeuroImage, 55(4), 1528-1535.
% [2]: Haufe, S., Meinecke, F., Görgen, K., Dähne, S., Haynes, J. D., Blankertz, 
% B., & Bießmann, F. (2014). On the interpretation of weight vectors of linear
% models in multivariate neuroimaging. Neuroimage, 87, 96-110.

clear all;
close all;
clc;

%% default values 

num_sub    = 10;    %Number of subjects
num_event  = 36;    %Number of different state
num_channel= 64;    %Number of channel
fs = 1000;          %Sampling frequency
datalength = 10*fs; %Data length
N = 1000;           %Number of repeated time
num_emo = 6;        %Number of emotion state
num_real = 6;       %Number of realism
num_fbs = 1;        %Number of filter banks
filter_order = 3;

%% Load all data
for idx_sub = 1:num_sub

    [EEG,num_trials,chanlocs] = loadEEG(idx_sub); %(channel*datalength*trials*events)
    EEG_all_seg{idx_sub} = EEG(:,1001:9000,:,:); %Only select the time window [1s,9s]
    EEG_all{idx_sub} = EEG; %All time-window

end

%% For SSD

selection = [1,0,0,1,1,0,0,0,1,1]+1; %This was based on clustering the SSD pattern, can be found in cluster_SSD()
freq  = [4 6; 2 8; 3 7]; % Frequency band choice 1
%freq  = [4.5 5.5; 2.5 7.5; 3.5 6.5]; % Frequency band choice 2

[b,a]=butter(filter_order, [3,40]/(fs/2));

for idx_sub = 1:num_sub

    EEG_sub = EEG_all_seg{idx_sub};
    EEG_SSD_temp = EEG_sub(:,:);

   [W, A, lambda, C_s, X_ssd,X_s] = ssd(EEG_SSD_temp', freq, fs, filter_order,[1, size(EEG_SSD_temp,2)]);
    
    %% Pattern reconstruction 

    X_cov = cov(X_ssd);
    S_cov = cov(X_s);
    Pattern(:,:,idx_sub) = S_cov*W;     % SSD pattern
    EEG_SSD = squeeze(mean(EEG_sub,3)); % Average across trials

    for idx_event = 1:num_event
        
        EEG_SSD_temp = W(:,selection(idx_sub))'*squeeze(EEG_SSD(:,:,idx_event)); 
        EEG_event = EEG_SSD_temp;
        EEG_event = filtfilt(b,a,EEG_event); %Filtering after SSD 
        EEG_avg(idx_sub,idx_event,:)= EEG_event;

    end
end

%% Plot pattern

for idx_sub = 1:num_sub

    Pattern_select(:,idx_sub) = squeeze(Pattern(:,selection(idx_sub),idx_sub));

    %---- Check the polarity --- %
    if Pattern_select(30,idx_sub) < 0  %% check the value of Oz
        Pattern_select(:,idx_sub) = -Pattern_select(:,idx_sub);
    end
    %----------------------------%

end
Pattern_avg = mean(Pattern_select,2);
topoplot(Pattern_avg,chanlocs); % electrode  * subject

%%  Average result 

for idx_sub = 1:num_sub

    EEG_avg_sub = squeeze(EEG_avg(idx_sub,:,:));

    for idx_event = 1:num_event

        EEG_temp = EEG_avg_sub(idx_event,:);
        EEG_event_fft = abs(fft(EEG_temp))/length(EEG_temp);
        FFT_5Hz_com(idx_sub,idx_event)  = EEG_event_fft(5*length(EEG_event_fft)/fs+1);

    end
end

% Average based on the degree of stylization
for idx_real = 1:num_real
    FFT_5Hz_real(:,idx_real) = mean(FFT_5Hz_com(:,(idx_real-1)*num_real+1:idx_real*num_real),2);
end

FFT_5Hz = FFT_5Hz_com(:);

