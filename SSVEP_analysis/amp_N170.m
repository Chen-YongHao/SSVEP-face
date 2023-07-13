%% clear all

% Main function for getting SSVEP (5Hz) amplitude 
% Author: Yonghao Chen (cheny@cbs.mpg.de)
% Jul 13, 2023

clear all;
close all;
clc;


%%

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

    [EEG,num_trials,chanlocs] = loadEEG(idx_sub); %(channel*datalength*sessions*events)
    EEG_all_seg{idx_sub} = EEG(:,1001:9000,:,:); %Only select the time window [1s,9s]

end


%% For only one channel 

[b,a]=butter(filter_order, [3,40]/(fs/2));

EEG_avg = [];

for idx_sub = 1:num_sub
    EEG_sub = EEG_all_seg{idx_sub};
    EEG_temp = squeeze(mean(EEG_sub,3));   %Average across sessions

    for idx_event = 1:num_event
        for idx_channel = 1:num_channel

            EEG_event = squeeze(EEG_temp(idx_channel,:,idx_event));  
            EEG_event = filtfilt(b,a,EEG_event);
            EEG_avg(idx_sub,idx_event,idx_channel,:)= EEG_event;

        end
    end
end


%% ERP extraction

for idx_sub = 1:num_sub

    EEG_avg_sub = squeeze(EEG_avg(idx_sub,:,:,:));
    for idx_event = 1:num_event

        EEG_temp = squeeze(EEG_avg_sub(idx_event,:,:));
        for idx_channel = 1:num_channel

            EEG_all_temp = EEG_temp(idx_channel,:);
            ERP_temp = zeros(1,fs*0.2);

            for itime = 1:40
                ERP_temp = ERP_temp+EEG_all_temp((itime-1)*fs*0.2+1:itime*fs*0.2); % sum of 200ms responses after each cycle
            end

            ERP(idx_sub,idx_channel,:,idx_event) = ERP_temp/40;    

        end
    end
end

%% N170 of one channel PO8

idx_channel = 64;   %PO8
ERP_PO8 = squeeze(ERP(:,idx_channel,:,:));

for idx_sub = 1:num_sub
    for idx_real = 1:num_real
        ERP_temp = squeeze(mean(ERP_PO8(idx_sub,:,(idx_real-1)*num_emo+1:idx_real*num_emo),3));
        ERP_PO8_amp(idx_sub,idx_real) = -mean (ERP_temp(0.15*fs+1:0.19*fs)); %considering the average value of [150ms,190ms] to be the amplitude of N170
    end
end



