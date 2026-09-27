%% =========================================================
% 05_Hippocampal_PE_computation_AdaptiveTau.m
%
% Normalized Permutation Entropy analysis of hippocampal SEEG
%
% Purpose:
%   Estimate frequency-specific normalized permutation entropy
%   in hippocampal contacts
%
% Conditions:
%   AWA  : after consciousness recovery following propofol anesthesia
%   WARD : resting physiological baseline
%
% Method:
%   Band-pass filtering + adaptive window + adaptive tau
%
% Parameters:
%   Sampling rate:
%       1024 Hz
%
%   Embedding dimension:
%       m = 3
%
%   Normalization:
%       PE / log(m!)
%
%   Overlap:
%       40%
%
% MATLAB:
%   R2020b
%
% EEGLAB:
%   2021.1
%
%% =========================================================


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
%% ===================== Parameters ========================
%% =========================================================


fs = 1024;


% Embedding dimension

m = 3;


% Normalization factor

PE_norm_factor = log(factorial(m));



%% =========================================================
%% ===================== Frequency bands ===================
%% =========================================================


freq_bands = [

     1    4
     4    8
     8   13
    13   30
    30   80
    80  150
   150  250

];


band_names = {

    'Delta'
    'Theta'
    'Alpha'
    'Beta'
    'LowGamma'
    'HighGamma'
    'Ripple'

};



%% =========================================================
%% ===================== Adaptive tau ======================
%% =========================================================


tau_values = [

    8
    6
    4
    3
    2
    1
    1

];



%% =========================================================
%% ================= Adaptive window ======================
%% =========================================================


window_seconds = [

    10
     8
     5
     5
     3
     3
     2

];



%% =========================================================
%% ================= Overlap ===============================
%% =========================================================


overlap_ratio = 0.40;



%% =========================================================
%% ================= ROI ===================================
%% =========================================================


ROI_name = 'H-';

ROI_label = 'Hippocampus';



%% =========================================================
%% ================= Input paths ===========================
%% =========================================================


states = {

    'AWA'

    'WARD'

};



input_dirs = {

    fullfile(project_dir,...
    '1024final_set',...
    'AWA')

    fullfile(project_dir,...
    '1024final_set',...
    'WARD')

};



%% =========================================================
%% ================= Output ================================
%% =========================================================


output_dir = fullfile(...
    project_dir,...
    'results',...
    'PE');


if ~exist(output_dir,'dir')

    mkdir(output_dir);

end



%% =========================================================
%% ================= Initialize ============================
%% =========================================================


Result = {};

row = 1;



fprintf('\n');
fprintf('============================================\n');
fprintf(' Hippocampal Normalized Permutation Entropy\n');
fprintf(' Adaptive tau + adaptive window\n');
fprintf('============================================\n');



%% =========================================================
%% ================= State loop ============================
%% =========================================================


for g = 1:length(states)


    current_state = states{g};


    fprintf('\nProcessing state: %s\n',...
        current_state);



    files = dir(fullfile(...
        input_dirs{g},...
        '*.set'));



    fprintf('Subjects: %d\n',...
        length(files));



    %% =====================================================
    %% ================= Subject loop ======================
    %% =====================================================


    for s = 1:length(files)


        fprintf('\nSubject %d/%d : %s\n',...
            s,...
            length(files),...
            files(s).name);



        %% Load EEG

        EEG = pop_loadset(...
            'filename',files(s).name,...
            'filepath',input_dirs{g});



        chan_names = {EEG.chanlocs.labels};



        %% =================================================
        %% Hippocampal channels
        %% =================================================


        roi_idx = find(cellfun(@(x)...

            strncmpi(x,ROI_name,length(ROI_name)),...

            chan_names));



        if isempty(roi_idx)


            warning(...
                'No hippocampal channels: %s',...
                files(s).name);


            continue;


        end



        fprintf('Hippocampal contacts: %d\n',...
            length(roi_idx));



        nSamples = size(EEG.data,2);



        %% =================================================
        %% Band loop
        %% =================================================


        for b = 1:length(band_names)



            band_name = band_names{b};


            f_low  = freq_bands(b,1);

            f_high = freq_bands(b,2);



            tau = tau_values(b);



            win_sec = window_seconds(b);


            win_samples = round(...
                win_sec*fs);



            overlap = round(...
                win_samples*overlap_ratio);



            step = win_samples-overlap;



            if nSamples < win_samples

                warning(...
                    'Recording too short: %s %s',...
                    files(s).name,...
                    band_name);


                continue;

            end



            nWindow = floor(...
                (nSamples-win_samples)/step)+1;



            fprintf('%s: %g-%g Hz, tau=%d, windows=%d\n',...
                band_name,...
                f_low,...
                f_high,...
                tau,...
                nWindow);



            %% =================================================
            %% Channel PE
            %% =================================================


            PE_values = nan(...
                length(roi_idx),...
                nWindow);



            for c = 1:length(roi_idx)



                ch = roi_idx(c);



                signal = double(...
                    EEG.data(ch,:));



                if any(~isfinite(signal))

                    signal(~isfinite(signal))=0;

                end



                %% Bandpass filter


                filt_order = ...
                    3*fix(fs/f_low);



                filtered_signal = eegfilt(...
                    signal,...
                    fs,...
                    f_low,...
                    f_high,...
                    0,...
                    filt_order);



                %% Sliding window


                for w = 1:nWindow



                    start_idx = ...
                        (w-1)*step+1;



                    end_idx = ...
                        start_idx+win_samples-1;



                    segment = filtered_signal(...
                        start_idx:end_idx);



                    pe = perm(...
                        segment,...
                        m,...
                        tau);



                    PE_values(c,w)=...
                        pe/PE_norm_factor;


                end


            end



            %% =================================================
            %% Subject level average
            %% =================================================


            PE_subject = mean(...
                PE_values(:),...
                'omitnan');



            %% Save row


            Result{row,1}=files(s).name;

            Result{row,2}=current_state;

            Result{row,3}=ROI_label;

            Result{row,4}=band_name;

            Result{row,5}=tau;

            Result{row,6}=win_sec;

            Result{row,7}=overlap_ratio;

            Result{row,8}=PE_subject;


            row=row+1;



        end


    end


end



%% =========================================================
%% ================= Convert table =========================
%% =========================================================


PE_table = cell2table(...
    Result,...
    'VariableNames',...
    {

    'Subject'

    'State'

    'ROI'

    'Band'

    'Tau'

    'Window_seconds'

    'Overlap'

    'Normalized_PE'

    });



%% =========================================================
%% ================= Save parameters =======================
%% =========================================================


PE_parameters.fs = fs;

PE_parameters.embedding_dimension = m;

PE_parameters.normalization = ...
    'PE/log(m!)';

PE_parameters.freq_bands = freq_bands;

PE_parameters.band_names = band_names;

PE_parameters.tau_values = tau_values;

PE_parameters.window_seconds = window_seconds;

PE_parameters.overlap_ratio = overlap_ratio;

PE_parameters.ROI = ROI_label;



%% =========================================================
%% ================= Save file =============================
%% =========================================================


save_file = fullfile(...
    output_dir,...
    'Hippocampal_NormalizedPE_AdaptiveTau.mat');



save(save_file,...
    'PE_table',...
    'PE_parameters',...
    '-v7');



%% =========================================================
%% ================= Finish ================================
%% =========================================================


fprintf('\n============================================\n');

fprintf('PE analysis completed.\n');

fprintf('ROI: Hippocampus\n');

fprintf('Results saved:\n');

fprintf('%s\n',save_file);

fprintf('============================================\n');