function [Epoch_data,num_trials,chanlocs] = loadEEG(idx_sub)

% Function of loading data
% Please change the corresponding filepath if neccesscary

% input:
%   idx_sub: index of subject
%
% output:
%   Epoch_data: data format(channel*datalength*trials*events)
%   num_trials: Number of sessions(trials)
%   chanlocs: channel location
%% Basic information

filepath = '/data/p_02694/SSVEP_face_data/EEG data face study/EEG data face study/';
sub_index = ["07","08","09","10","11","12","13","14","15","16"];
filename = convertStringsToChars(append('ssvep_faces00',sub_index(idx_sub),'.vhdr'));
EEG = pop_loadbv(filepath,filename);

%% --Default information-- %%

num_event  = 36;   %Number of different state
num_channel= 64;   %Number of channel
fs = 1000;         %Sampling frequency
datalength = 10*fs;%Data length
chanlocs = EEG.chanlocs;
%% Event_load
event_info = EEG.event;
event_start = [];
event_end = [];
idx_start = 1;
idx_end   = 1;
for idx_temp = 1:length(event_info)
    type_temp    = event_info(idx_temp).type;
    if event_info(idx_temp).type == "S 61"||(type_temp(1)=="S"&&event_info(idx_temp-1).type=="0")
        event_start(idx_start)= idx_temp;
        idx_start = idx_start+1;
    end
    if event_info(idx_temp).type == "S 60"
        event_end(idx_end)= idx_temp;
        idx_end = idx_end+1;
    end
end

num_trials = length(event_start);
%% Epoching data

% Event info : 3 emotion * 2 gender * 6 realness
t = EEG.times;
EEG_signal = EEG.data;
Epoch_data   = zeros(num_channel,datalength,num_trials,num_event);
for idx_trial = 1:num_trials
    for idx_event_trial = event_start(idx_trial):event_end(idx_trial)
        type_temp    = event_info(idx_event_trial).type;
        code_temp    = event_info(idx_event_trial).code;
        latency_temp = event_info(idx_event_trial).latency;
        type_temp    = str2num(type_temp(3:end));
        if type_temp<37&&type_temp>0&&strcmp(code_temp,'Stimulus')
            Epoch_data(:,:,idx_trial,type_temp) = EEG_signal(:,latency_temp:latency_temp+datalength-1);
        end
       
    end
end

end