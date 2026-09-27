%% =========================================================
%  Continuous SEEG epoch segmentation
%
%  Purpose:
%  Divide resting-state continuous SEEG into overlapping epochs
%
%  Epoch length:
%  4 seconds
%
%  Overlap:
%  50% (2-second step)
%
%  MATLAB:
%  R2020b
%
%  EEGLAB:
%  2021.1
%
% =========================================================


clear;
clc;
close all;



%% ================= USER SETTINGS ==========================

project_dir = 'YOUR_PROJECT_PATH';


condition = 'WARD';


input_dir = fullfile(project_dir,...
    '1024final_set',...
    condition);


output_dir = fullfile(project_dir,...
    'epoch',...
    condition);



if ~exist(output_dir,'dir')

    mkdir(output_dir);

end



%% ================= FILE LIST ===============================

files = dir(fullfile(input_dir,'*.set'));


fprintf('Number of datasets: %d\n\n',...
    length(files));



%% ================= EPOCH PARAMETERS ========================

epoch_length = 4;       % seconds

step_length  = 2;       % seconds

overlap = 1-step_length/epoch_length;



fprintf('Epoch length: %.1f s\n',...
    epoch_length);

fprintf('Overlap: %.0f %%\n\n',...
    overlap*100);



%% ================= PROCESS ================================

for subj = 1:length(files)


    fprintf('[%d/%d] %s\n',...
        subj,...
        length(files),...
        files(subj).name);



    %% Load continuous SEEG

    EEG = pop_loadset(...
        'filename',files(subj).name,...
        'filepath',input_dir);



    %% Check continuous data

    if EEG.trials ~= 1

        warning('%s is not continuous data',...
            files(subj).name);

    end



    %% Segment into epochs

    EEG = eeg_regepochs(...
        EEG,...
        'recurrence',step_length,...
        'limits',[0 epoch_length],...
        'rmbase',NaN);



    EEG = eeg_checkset(EEG);



    %% Save

    output_name = ...
        ['epoch_' files(subj).name];


    pop_saveset(...
        EEG,...
        'filename',output_name,...
        'filepath',output_dir);



end



fprintf('\n====================================\n');
fprintf('Epoch segmentation completed.\n');
fprintf('Output:\n%s\n',output_dir);
fprintf('====================================\n');