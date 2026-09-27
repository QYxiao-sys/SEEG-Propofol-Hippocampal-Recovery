%% =========================================================
% Hippocampal PSD analysis for SEEG
%
% Purpose:
% Estimate hippocampal power spectral density
%
% Data:
% Continuous SEEG epochs
%
% Conditions:
% AWA: after consciousness recovery
% WARD: resting physiological baseline
%
% Method:
% Welch PSD estimation
%
% Parameters:
% Fs = 1024 Hz
% Epoch = 4 s
% Window = Hamming
% Overlap = 50%
% Frequency range = 1-250 Hz
%
% MATLAB R2020b
% EEGLAB 2021.1
%
%% =========================================================


clear;
clc;
close all;



%% ================= USER SETTINGS ==========================

project_dir = 'YOUR_PROJECT_PATH';


eeglab_path = fullfile(project_dir,...
    'external',...
    'eeglab2021.1');


addpath(genpath(eeglab_path));

eeglab nogui;



%% ================= PARAMETERS =============================


Fs = 1024;

epoch_length = 4;

L = epoch_length*Fs;

NFFT = 2^nextpow2(L);


freq = Fs/2*linspace(0,1,NFFT/2+1);


freq_idx = freq>=1 & freq<=250;

freq_used = freq(freq_idx);



states = {'AWA','WARD'};


state_paths = {
    fullfile(project_dir,'1024final_set','AWA','epoch')
    fullfile(project_dir,'1024final_set','WARD','epoch')
};



save_dir = fullfile(project_dir,...
    'results',...
    'PSD');


if ~exist(save_dir,'dir')
    mkdir(save_dir)
end



%% ================= INITIALIZE ==============================


results = struct();

results.PSD.AWA=[];
results.PSD.WARD=[];


results.freq = freq_used;


results.parameters.Fs = Fs;
results.parameters.epoch = epoch_length;
results.parameters.window='Hamming';
results.parameters.overlap=0.5;
results.parameters.range=[1 250];



%% ================= ANALYSIS ================================


for s=1:length(states)


    fprintf('\n%s\n',states{s});


    files=dir(fullfile(state_paths{s},'*.set'));


    for subj=1:length(files)


        fprintf('Subject %d/%d\n',...
            subj,length(files));


        EEG=pop_loadset(...
            'filename',files(subj).name,...
            'filepath',state_paths{s});


        labels={EEG.chanlocs.labels};



        %% Hippocampal contacts

        idx_H=find(cellfun(@(x)...
            strncmpi(x,'H-',2),labels));



        if isempty(idx_H)

            warning('No hippocampal channels: %s',...
                files(subj).name);

            continue

        end



        subj_psd=[];



        for ch=idx_H


            for ep=1:EEG.trials


                signal=double(...
                    squeeze(EEG.data(ch,:,ep)));



                [Pxx,~]=pwelch(...
                    signal,...
                    hamming(L),...
                    L/2,...
                    NFFT,...
                    Fs);



                subj_psd(end+1,:)=...
                    10*log10(Pxx(freq_idx)+eps);



            end

        end



        % average within participant

        results.PSD.(states{s})(end+1,:)=...
            mean(subj_psd,1);



    end

end



%% ================= SAVE ================================


save(fullfile(save_dir,'Hippocampus_PSD.mat'),...
    'results',...
    '-v7');



disp('Hippocampal PSD completed.')