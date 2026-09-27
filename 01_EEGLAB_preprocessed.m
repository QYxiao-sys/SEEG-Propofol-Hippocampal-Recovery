%% =========================================================
%  EEG preprocessing pipeline
%
%  Purpose:
%  Resampling and filtering SEEG continuous recordings
%
%  MATLAB:
%  R2020b
%
%  Toolbox:
%  EEGLAB 2021.1
%
%  Processing:
%  1. Resample to 1024 Hz
%  2. Band-pass filter (1-250 Hz)
%  3. Remove line noise and harmonics (50/100/150 Hz)
%
% =========================================================


clear;
clc;
close all;


%% ================= USER SETTINGS =========================

project_dir = 'YOUR_PROJECT_PATH';


input_dir = fullfile(project_dir,...
    'raw_data',...
    'AWA',...
    'chan_set');


output_dir = fullfile(project_dir,...
    'preprocessed_data',...
    'AWA',...
    '1024Hz');


if ~exist(output_dir,'dir')
    mkdir(output_dir);
end



%% ================= LOAD FILES =============================

files = dir(fullfile(input_dir,'*.set'));

fprintf('Total files: %d\n\n',length(files));



%% ================= PREPROCESSING ===========================

for i = 1:length(files)


    fprintf('[%d/%d] Processing %s\n',...
        i,...
        length(files),...
        files(i).name);



    %% Load dataset

    EEG = pop_loadset(...
        'filename',files(i).name,...
        'filepath',input_dir);



    %% Resample

    target_fs = 1024;

    if EEG.srate ~= target_fs

        EEG = pop_resample(EEG,target_fs);

    end



    %% Band-pass filtering

    low_cutoff = 1;

    high_cutoff = min(250,...
        EEG.srate/2-5);


    EEG = pop_eegfiltnew(...
        EEG,...
        low_cutoff,...
        high_cutoff);



    %% Remove line noise harmonics

    notch_freq = [50 100 150];


    for f = notch_freq

        EEG = pop_eegfiltnew(...
            EEG,...
            f-1,...
            f+1,...
            [],...
            1);

    end



    %% Keep first event only
    %
    % Continuous resting-state recording:
    % only the first event marker was retained

    if isfield(EEG,'event') && length(EEG.event)>1

        EEG.event = EEG.event(1);

        EEG = eeg_checkset(EEG);

    end



    %% Save

    EEG = pop_saveset(...
        EEG,...
        'filename',files(i).name,...
        'filepath',output_dir);


end



fprintf('\n====================================\n');
fprintf('All datasets completed.\n');
fprintf('Output folder:\n%s\n',output_dir);
fprintf('====================================\n');