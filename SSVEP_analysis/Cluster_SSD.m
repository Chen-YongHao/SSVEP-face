%% 
clear all;
close all;
clc;

% Clustering the SSD pattern according to their similiarity
% Author: Yonghao Chen (cheny@cbs.mpg.de)
% Jul 13, 2023
% Ref 
% [1]: Nikulin, V. V., Nolte, G., & Curio, G. (2011). A novel method for 
% reliable and fast extraction of neuronal EEG/MEG oscillations on the basis 
% of spatio-spectral decomposition. NeuroImage, 55(4), 1528-1535.
% [2]: Haufe, S., Meinecke, F., Görgen, K., Dähne, S., Haynes, J. D., Blankertz, 
% B., & Bießmann, F. (2014). On the interpretation of weight vectors of linear
% models in multivariate neuroimaging. Neuroimage, 87, 96-110.

%% -------------------try to cluster four components----------------------------%%
%% 

num_sub    = 10;        %Number of subjects
num_event  = 36;        %Number of different state
num_channel= 64;        %Number of channel
fs = 1000;              %Sampling frequency
datalength = 10*fs;     %Data length
N = 1000;               %Number of repeated time
num_emo = 6;            %Number of emotion state
num_real = 6;           %Number of realism
num_fbs = 1;            %Number of filter banks
filter_order = 3;
num_ssd = 3;            %Number of SSD components taken into consideration

%% Load all data

for idx_sub = 1:num_sub

[EEG,num_trials,chanlocs] = loadEEG(idx_sub); %(channel*datalength*trials*events)
EEG_all_seg{idx_sub} = EEG(:,1001:9000,:,:); %Only select the time window [1s,9s]
EEG_all{idx_sub} = EEG; %All time-window


%% For SSD of one partcipants

freq  = [4 6; 2 8; 3 7];

EEG_avg = [];
EEG_sub = EEG_all_seg{idx_sub};
EEG_SSD = EEG_sub(:,:);  %% concatnating the data 
[W, A, lambda, C_s, X_ssd,X_s] = ssdreal(EEG_SSD', freq, fs, filter_order,[1, size(EEG_SSD,2)]);

%% Pattern reconstruction 

X_cov = cov(X_ssd);
S_cov = cov(X_s);
%Pattern(:,:,idx_sub) = S_cov*W*inv(X_cov); % Approach 1
Pattern(:,:,idx_sub) = S_cov*W; % Approach 2

end

%% Maxmize the inter-cluster similarity

num_iter = num_ssd^num_sub;  %%number of possible combination
itr_idx = zeros(num_iter,num_sub);

%% Create sequence 

for idx_iter = 1:num_iter
    idx_temp = idx_iter-1;
    for idx_sub = num_sub:-1:1
        itr_idx(idx_iter,idx_sub) = floor(idx_temp/num_ssd^(idx_sub-1));
        idx_temp = idx_temp - itr_idx(idx_iter,idx_sub)*num_ssd^(idx_sub-1);
    end
end

%% Combine all possible combination
Pattern_cluster_all = [];
for idx_iter = 1:num_iter
    for idx_sub = 1:num_sub
        idx_seg = itr_idx(idx_iter,idx_sub)+1;
        Pattern_cluster_all(idx_iter,idx_sub,:) = squeeze(Pattern(:,idx_seg,idx_sub));
    end
end

%% Calculate all the similarity 
 
for idx_iter = 1:num_iter
    similarity_temp = 0;
    for idx_sub_1 = 1:num_sub
        for idx_sub_2 = 1:num_sub
            Pattern_temp_1 = squeeze(Pattern_cluster_all(idx_iter,idx_sub_1,:));
            Pattern_temp_2 = squeeze(Pattern_cluster_all(idx_iter,idx_sub_2,:));            
            similarity_temp = similarity_temp +  abs(Pattern_temp_1'*Pattern_temp_2/(norm(Pattern_temp_1)*norm(Pattern_temp_2)));
        end
    end
    similarity(idx_iter) = similarity_temp;
end
[a,b] = sort(similarity);%[1,0,0,1,1,0,0,0,1,1]


