%% =========================================================
% 07_Hippocampal_KLMI_PAC_computation.m
%
% Hippocampal phase-amplitude coupling analysis
% using Kullback-Leibler Modulation Index (KLMI)
%
% Data:
%   Continuous intracranial SEEG
%
% Conditions:
%   AWA  : after consciousness recovery following propofol anesthesia
%   WARD : resting physiological baseline
%
% ROI:
%   Hippocampus (H- contacts)
%
% Method:
%   Low-frequency phase:
%       1-13 Hz, step 0.25 Hz
%
%   High-frequency amplitude:
%       30-250 Hz, step 2.5 Hz
%
%   HF bandwidth:
%       6 Hz
%
%   Phase bins:
%       18
%
% MATLAB:
%   R2020b
%
% =========================================================


clear;
clc;
close all;



%% =========================================================
%% ===================== EEGLAB ============================
%% =========================================================


project_dir = 'YOUR_PROJECT_PATH';



eeglab_path = fullfile(...
    project_dir,...
    'external',...
    'eeglab2021.1');



addpath(genpath(eeglab_path));


eeglab nogui;



%% =========================================================
%% ===================== Output =============================
%% =========================================================


output_dir = fullfile(...
    project_dir,...
    'results',...
    'KLMI');



if ~exist(output_dir,'dir')

    mkdir(output_dir);

end



%% =========================================================
%% ===================== Input ==============================
%% =========================================================


data_root = fullfile(...
    project_dir,...
    '1024final_set');



states = {

    'AWA'

    'WARD'

};



%% =========================================================
%% ===================== KLMI parameters ===================
%% =========================================================


% Low-frequency phase

lf_lower = 1:0.25:13;

lf_upper = lf_lower + 0.5;



% High-frequency amplitude

hf_lower = 30:2.5:250;

hf_upper = hf_lower + 6;



% Number of phase bins

nbins = 18;



%% =========================================================
%% ===================== ROI ================================
%% =========================================================


ROI_prefix = 'H-';

ROI_name = 'Hippocampus';



%% =========================================================
%% ===================== Main loop ==========================
%% =========================================================


for s = 1:length(states)


    state = states{s};



    fprintf('\n');
    fprintf('========================================\n');
    fprintf('Processing state: %s\n',state);
    fprintf('========================================\n');



    data_dir = fullfile(...
        data_root,...
        state);



    if ~exist(data_dir,'dir')

        warning('Missing directory: %s',...
            data_dir);

        continue;

    end



    files = dir(fullfile(...
        data_dir,...
        '*.set'));



    if isempty(files)

        warning('No SET files in %s',...
            data_dir);

        continue;

    end



    %% Subject-level storage

    KLMI_H = cell(length(files),1);



    %% =====================================================
    %% ================= Subject loop =======================
    %% =====================================================


    for subj = 1:length(files)



        fprintf('\nSubject %d/%d : %s\n',...
            subj,...
            length(files),...
            files(subj).name);



        EEG = pop_loadset(...
            'filename',files(subj).name,...
            'filepath',data_dir);



        EEG = eeg_checkset(EEG);



        %% Continuous data check

        if ndims(EEG.data) ~= 2

            error(...
            'Input data must be continuous: %s',...
            files(subj).name);

        end



        chan_names = {EEG.chanlocs.labels};



        %% =================================================
        %% Hippocampal contacts
        %% =================================================


        idx_H = find(cellfun(@(x)...

            strncmpi(x,...
            ROI_prefix,...
            length(ROI_prefix)),...

            chan_names));



        if isempty(idx_H)

            warning(...
            'No hippocampal contacts: %s',...
            files(subj).name);



            KLMI_H{subj}=[];


            continue;

        end



        fprintf('Hippocampal contacts: %d\n',...
            length(idx_H));



        %% =================================================
        %% Channel-level KLMI
        %% =================================================


        KLMI_contact = zeros(...
            length(lf_lower),...
            length(hf_lower),...
            length(idx_H));



        for c = 1:length(idx_H)



            ch = idx_H(c);



            fprintf('  Contact %d/%d\n',...
                c,...
                length(idx_H));



            signal = double(...
                EEG.data(ch,:));



            signal = signal(:)';



            if any(~isfinite(signal))

                signal(~isfinite(signal))=0;

            end



            %% =============================================
            %% LF phase extraction
            %% =============================================


            phase_lf = zeros(...
                length(signal),...
                length(lf_lower));



            for i = 1:length(lf_lower)



                filtered = eegfilt(...
                    signal,...
                    EEG.srate,...
                    lf_lower(i),...
                    lf_upper(i),...
                    0,...
                    [],...
                    0,...
                    'fir1',...
                    0);



                phase_lf(:,i)=...
                    angle(hilbert(filtered))';



            end



            %% =============================================
            %% HF amplitude extraction
            %% =============================================


            amp_hf=zeros(...
                length(signal),...
                length(hf_lower));



            for j=1:length(hf_lower)



                filtered=eegfilt(...
                    signal,...
                    EEG.srate,...
                    hf_lower(j),...
                    hf_upper(j),...
                    0,...
                    [],...
                    0,...
                    'fir1',...
                    0);



                amp_hf(:,j)=...
                    abs(hilbert(filtered))';



            end



            %% =============================================
            %% KLMI calculation
            %% =============================================


            result=get_klmi_jia(...
                phase_lf,...
                amp_hf,...
                nbins);



            MI=result.MI;



            if ndims(MI)==3

                MI=squeeze(MI);

            end



            KLMI_contact(:,:,c)=MI;



        end



        %% =================================================
        %% Hippocampal average
        %% =================================================


        KLMI_H{subj}=mean(...
            KLMI_contact,...
            3);



        clear EEG KLMI_contact



    end



    %% =====================================================
    %% Save state result
    %% =====================================================


    KLMI_parameters.fs = EEG.srate;

    KLMI_parameters.LF_range = ...
        [lf_lower(1),lf_upper(end)];

    KLMI_parameters.HF_range = ...
        [hf_lower(1),hf_upper(end)];

    KLMI_parameters.LF_step = 0.25;

    KLMI_parameters.HF_step = 2.5;

    KLMI_parameters.HF_bandwidth = 6;

    KLMI_parameters.phase_bins = nbins;

    KLMI_parameters.ROI = ROI_name;



    save_file = fullfile(...
        output_dir,...
        ['Hippocampal_KLMI_' state '.mat']);



    save(save_file,...
        'KLMI_H',...
        'lf_lower',...
        'hf_lower',...
        'KLMI_parameters',...
        '-v7.3');



    fprintf('\nSaved:\n%s\n',...
        save_file);



end



fprintf('\n');
fprintf('========================================\n');
fprintf('All KLMI analyses completed.\n');
fprintf('========================================\n');