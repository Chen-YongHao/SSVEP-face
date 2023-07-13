%% TRCA-based classification on ssvep-face dataset

% Main function of applying TRCA on SSVEP classification %
% Regarding the main idea of TRCA, please see function train_trca() and test_trca() 
% Author: Yonghao Chen (cheny@cbs.mpg.de)
% Jul 13, 2023

%close all;
clear all;
clc;

%% --Default information-- %%

num_sub    = 10;   %Number of subjects
num_event  = 36;   %Number of events
num_channel= 64;   %Number of channel
num_emotion = 6;   %Number of emotional state (Angry female, angry male, ...etc)
fs = 1000;         %Sampling frequency
window_length = 2; %The length of window (2s&8s)
datalength = 10*fs;%Data length of one trial 

%% Load data

for idx_sub = 1:num_sub

    [EEG,num_trials] = loadEEG(idx_sub);  % Loading data(channel*datalength*trials*events)
    for idx_emotion_state = 1:num_emotion
    %% Selecting channel

    Channel_selection = [25,61,60,63,64,62,29,30,31];   %Occiptial region:Pz,PO3,PO7,PO4,PO8,POz,O1,Oz,O2
    EEG_occip= EEG(Channel_selection,:,:,:);

    %% 2-class classification (R0&R5)

    EEG_occip_R0 = squeeze(EEG_occip(:,:,:,idx_emotion_state));        %R0
    EEG_occip_R1 = squeeze(EEG_occip(:,:,:,idx_emotion_state+6));      %R1
    EEG_occip_R2 = squeeze(EEG_occip(:,:,:,idx_emotion_state+12));     %R2
    EEG_occip_R3 = squeeze(EEG_occip(:,:,:,idx_emotion_state+18));     %R3
    EEG_occip_R4 = squeeze(EEG_occip(:,:,:,idx_emotion_state+24));     %R4
    EEG_occip_R5 = squeeze(EEG_occip(:,:,:,idx_emotion_state+30));     %R5
    EEG_dataset_temp = zeros(2,length(Channel_selection),datalength,num_trials);
    EEG_dataset_temp(1,:,:,:) = EEG_occip_R4;
    EEG_dataset_temp(2,:,:,:) = EEG_occip_R5;

    %% Downsampling & TRCA

    fs_new = 250;
    EEG_dataset = EEG_dataset_temp(:,:,1001:4:1000+window_length*fs,:);
    num_fbs = 1;        %Number of filter banks 
    is_ensemble = 1;    %Use ensemble TRCA or not (please find the definition in corresponding function) 
    results_2 = [];     %Classification results
    find (isnan(EEG_dataset));

    for idx_trial = 1:num_trials

        EEG_dataset_test = squeeze(EEG_dataset(:,:,:,idx_trial));
        EEG_dataset_training = EEG_dataset;
        EEG_dataset_training(:,:,:,idx_trial) = [];
        model = train_trca(EEG_dataset_training, fs_new, num_fbs); %TRCA model
        results_2(idx_trial,:) = test_trca(EEG_dataset_test, model, is_ensemble);
   
    end
    results_2_real =repmat(1:2,num_trials,1);
    result_2class(idx_sub,idx_emotion_state)= length(find(results_2==results_2_real))/num_trials/2; %classification accuracy
    result_2_all (idx_sub,idx_emotion_state,1:num_trials,:) = results_2;

    %% 6-class

    EEG_dataset_temp = zeros(6,length(Channel_selection),datalength,num_trials);
    EEG_dataset_temp(1,:,:,:) = EEG_occip_R0;
    EEG_dataset_temp(2,:,:,:) = EEG_occip_R1;
    EEG_dataset_temp(3,:,:,:) = EEG_occip_R2;
    EEG_dataset_temp(4,:,:,:) = EEG_occip_R3;
    EEG_dataset_temp(5,:,:,:) = EEG_occip_R4;
    EEG_dataset_temp(6,:,:,:) = EEG_occip_R5;

    EEG_dataset = EEG_dataset_temp(:,:,1001:4:1000+window_length*fs,:);
    results_6 = [];
    results_6_real =repmat(1:6,num_trials,1);

    for idx_trial = 1:num_trials

        EEG_dataset_test = squeeze(EEG_dataset(:,:,:,idx_trial));
        EEG_dataset_training = EEG_dataset;
        EEG_dataset_training(:,:,:,idx_trial) = [];
        model = train_trca(EEG_dataset_training, fs_new, num_fbs);
        results_6(idx_trial,:) = test_trca(EEG_dataset_test, model, is_ensemble);
    end
    result_6class(idx_sub,idx_emotion_state) = length(find(abs(results_6-results_6_real)<=0))/num_trials/6; %classification accuracy
    result_6_all (idx_sub,idx_emotion_state,1:num_trials,:) = results_6;

    end
end

