%% =========================================================
% Ripple_Spectrogram_Analysis.m
%
% Event-triggered time-frequency analysis of hippocampal ripple
% events using spectrogram analysis
%
% Software:
%       MATLAB R2020b 
%
% Dependencies:
%       EEGLAB
%       RIPPLELAB
%
% =========================================================
clear;
clc;
close all;


%% =========================================================
%% ================= Global Figure Setting =================
%% =========================================================

set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultAxesFontSize',14);
set(groot,'defaultTextFontSize',14);

rng(1);

%% =========================================================
%% ===================== Path Setting ======================
%% =========================================================

%
% Modify ONLY this path before running
%

project_root = pwd;

%% ================= EEGLAB ================================

eeglab_path = fullfile( ...
    project_root,...
    'external',...
    'eeglab');
%% ================= Input Data =============================

awa_rhfe_dir = fullfile( ...
    project_root,...
    'data',...
    'AWA',...
    'rhfe');

ward_rhfe_dir = fullfile( ...
    project_root,...
    'data',...
    'WARD',...
    'rhfe');

awa_set_dir = fullfile( ...
    project_root,...
    'data',...
    'AWA',...
    'set');

ward_set_dir = fullfile( ...
    project_root,...
    'data',...
    'WARD',...
    'set');
%% ================= Output ================================

out_dir = fullfile( ...
    project_root,...
    'results');


if ~exist(out_dir,'dir')
    mkdir(out_dir);
end

%% =========================================================
%% ===================== Load EEGLAB =======================
%% =========================================================

if ~exist(eeglab_path,'dir')

    error(['EEGLAB folder not found: ' eeglab_path]);

end


addpath(genpath(eeglab_path));

eeglab;

%% =========================================================
%% ===================== Check Input ========================
%% =========================================================

input_dirs = {
    awa_rhfe_dir
    ward_rhfe_dir
    awa_set_dir
    ward_set_dir
    };


for k = 1:length(input_dirs)

    if ~exist(input_dirs{k},'dir')

        error(['Missing folder: ' input_dirs{k}]);

    end

end

%% =========================================================
%% ======================= Parameters ======================
%% =========================================================

Fs = 1024;

% ripple-centered window

win_sec = 0.5;

win_samp = round(win_sec * Fs);


% frequency range

freq_range = [70 160];

%% spectrogram parameters

window   = 128;

noverlap = 120;

nfft     = 256;
%% =========================================================
%% ======================= Files ===========================
%% =========================================================


awa_files = dir(fullfile(awa_rhfe_dir,'*.rhfe'));

ward_files = dir(fullfile(ward_rhfe_dir,'*.rhfe'));



fprintf('AWA ripple files: %d\n',length(awa_files));

fprintf('WARD ripple files: %d\n',length(ward_files));


%% =========================================================
%% ===================== Subject List ======================
%% =========================================================

get_subj = @(x) regexp(x,'^\d+','match','once');

awa_subj = cellfun(@(x)get_subj(x),...
    {awa_files.name},...
    'uni',0);

ward_subj = cellfun(@(x)get_subj(x),...
    {ward_files.name},...
    'uni',0);

subjects = intersect(...
    unique(awa_subj),...
    unique(ward_subj));

fprintf('Subjects included: %d\n',length(subjects));

%% =========================================================
%% ================= Initialization ========================
%% =========================================================

AWA_all_tf = [];

WARD_all_tf = [];


%% =========================================================
%% ===================== Main Loop =========================
%% =========================================================


for s = 1:length(subjects)


    subj = subjects{s};


    fprintf('\n=================================\n');
    fprintf('Processing Subject %s\n',subj);
    fprintf('=================================\n');

    %% =====================================================
    %% ================= Subject Folder ====================
    %% =====================================================


    subj_dir = fullfile(out_dir,subj);


    if ~exist(subj_dir,'dir')
        mkdir(subj_dir);
    end

    %% =====================================================
    %% ======================== AWA ========================
    %% =====================================================

    awa_idx = find(strcmp(awa_subj,subj));


    subj_tf = [];

    for i = 1:length(awa_idx)
        %% Load ripple file

        rhfe_file = fullfile( ...
            awa_rhfe_dir,...
            awa_files(awa_idx(i)).name);
        try

            S = load(rhfe_file,'-mat');

        catch ME

            fprintf('Cannot load %s : %s\n',...
                awa_files(awa_idx(i)).name,...
                ME.message);

            continue;

        end

        vars = fieldnames(S);
        %% Corresponding EEGLAB dataset

        setname = regexprep(...
            awa_files(awa_idx(i)).name,...
            '_STE\.rhfe',...
            '_bipolar.set');

        setfile = fullfile(awa_set_dir,setname);

        if ~exist(setfile,'file')

            fprintf('Missing SET: %s\n',setname);

            continue;

        end

        EEG = pop_loadset(setfile);



        %% =================================================
        %% ================= Channel Loop ==================
        %% =================================================

        for v = 1:length(vars)

            try

                st = S.(vars{v}).st_HFOInfo;

                if ~isfield(st,'m_EvtLims')

                    continue;

                end



                evt = st.m_EvtLims;



                if isempty(evt)

                    continue;

                end



                %% channel label

                chLabel = st.str_ChLabel;



                chIdx = find(strcmpi(...
                    {EEG.chanlocs.labels},...
                    chLabel));



                if isempty(chIdx)

                    continue;

                end



                sig = double(EEG.data(chIdx,:));



                %% =========================================
                %% ============= Ripple Loop ===============
                %% =========================================

                ch_tf = [];

                for e = 1:size(evt,1)

                    center = round(mean(evt(e,:)));

                    s1 = center - win_samp;

                    s2 = center + win_samp;

                    if s1 < 1 || s2 > length(sig)

                        continue;

                    end

                    ripple_seg = sig(s1:s2);


                    %% Spectrogram

                    [~,F,T,P] = spectrogram(...
                        ripple_seg,...
                        window,...
                        noverlap,...
                        nfft,...
                        Fs);

                    %% Convert power to dB

                    P = 10*log10(abs(P)+eps);
                    %% Frequency selection

                    idxF = F >= freq_range(1) & ...
                           F <= freq_range(2);

                    F2 = F(idxF);
                    P = P(idxF,:);
                    %% Baseline correction

                    T_ms = linspace(...
                        -500,...
                        500,...
                        size(P,2));

                    base_idx = T_ms >= -500 & ...
                               T_ms <= -200;
                    baseline = mean(P(:,base_idx),2);
                    P = P - baseline;
                    ch_tf(:,:,end+1)=P;
                end
                %% Channel average
                if ~isempty(ch_tf)

                    ch_tf_mean = mean(ch_tf,3);

                    subj_tf(:,:,end+1)=ch_tf_mean;
                end
            catch ME
                fprintf('AWA skipped: %s\n',ME.message);
            end
        end
    end
    %% =====================================================
    %% ================= AWA Subject Average ===============
    %% =====================================================


    if ~isempty(subj_tf)



        subj_AWA_mean = mean(subj_tf,3);



        AWA_all_tf(:,:,end+1)=subj_AWA_mean;



        save(fullfile(subj_dir,...
            [subj '_AWA_spectrogram.mat']),...
            'subj_AWA_mean',...
            '-v7.3');



        figure('Color','w');



        imagesc(T_ms,F2,subj_AWA_mean);



        axis xy;



        xlabel('Time (ms)');

        ylabel('Frequency (Hz)');



        title([subj ' AWA']);



        colorbar;



        saveas(gcf,...
            fullfile(subj_dir,...
            [subj '_AWA_spectrogram.png']));



        close;



    end




    %% =====================================================
    %% ======================== WARD =======================
    %% =====================================================


    ward_idx = find(strcmp(ward_subj,subj));



    subj_tf = [];



    for i = 1:length(ward_idx)



        rhfe_file = fullfile(...
            ward_rhfe_dir,...
            ward_files(ward_idx(i)).name);



        try

            S = load(rhfe_file,'-mat');


        catch ME


            fprintf('Cannot load %s : %s\n',...
                ward_files(ward_idx(i)).name,...
                ME.message);


            continue;


        end



        vars = fieldnames(S);



        %% Corresponding SET


        setname = regexprep(...
            ward_files(ward_idx(i)).name,...
            '_STE\.rhfe',...
            '_bipolar.set');



        setfile = fullfile(ward_set_dir,setname);



        if ~exist(setfile,'file')


            fprintf('Missing SET: %s\n',setname);


            continue;


        end



        EEG = pop_loadset(setfile);




        %% =================================================
        %% ================= Channel Loop ==================
        %% =================================================


        for v = 1:length(vars)



            try



                st = S.(vars{v}).st_HFOInfo;



                if ~isfield(st,'m_EvtLims')

                    continue;

                end



                evt = st.m_EvtLims;



                if isempty(evt)

                    continue;

                end



                chLabel = st.str_ChLabel;



                chIdx = find(strcmpi(...
                    {EEG.chanlocs.labels},...
                    chLabel));



                if isempty(chIdx)

                    continue;

                end



                sig = double(EEG.data(chIdx,:));



                ch_tf=[];



                for e = 1:size(evt,1)



                    center = round(mean(evt(e,:)));



                    s1 = center-win_samp;

                    s2 = center+win_samp;



                    if s1<1 || s2>length(sig)

                        continue;

                    end



                    ripple_seg=sig(s1:s2);



                    [~,F,T,P]=spectrogram(...
                        ripple_seg,...
                        window,...
                        noverlap,...
                        nfft,...
                        Fs);



                    P=10*log10(abs(P)+eps);



                    idxF = F>=freq_range(1) & ...
                           F<=freq_range(2);



                    F2=F(idxF);



                    P=P(idxF,:);



                    T_ms=linspace(...
                        -500,...
                        500,...
                        size(P,2));



                    base_idx=T_ms>=-500 & ...
                             T_ms<=-200;



                    baseline=mean(P(:,base_idx),2);



                    P=P-baseline;



                    ch_tf(:,:,end+1)=P;



                end



                if ~isempty(ch_tf)



                    ch_tf_mean=mean(ch_tf,3);


                    subj_tf(:,:,end+1)=ch_tf_mean;


                end



            catch ME


                fprintf('WARD skipped: %s\n',ME.message);


            end



        end



    end
    %% =====================================================
    %% ================= WARD Subject Average ==============
    %% =====================================================


    if ~isempty(subj_tf)


        subj_WARD_mean = mean(subj_tf,3);



        WARD_all_tf(:,:,end+1)=subj_WARD_mean;



        save(fullfile(subj_dir,...
            [subj '_WARD_spectrogram.mat']),...
            'subj_WARD_mean',...
            '-v7.3');



        figure('Color','w');



        imagesc(T_ms,F2,subj_WARD_mean);



        axis xy;



        xlabel('Time (ms)');

        ylabel('Frequency (Hz)');



        title([subj ' WARD']);



        colorbar;



        saveas(gcf,...
            fullfile(subj_dir,...
            [subj '_WARD_spectrogram.png']));



        close;



    end



end   % ===== Subject loop end =====
%% =========================================================
%% ===================== Group Average =====================
%% =========================================================
if isempty(AWA_all_tf) || isempty(WARD_all_tf)

    error('No valid spectrogram data found.');

end
AWA_group_mean = mean(AWA_all_tf,3);
WARD_group_mean = mean(WARD_all_tf,3);
%% =========================================================
%% ===================== Group Figure ======================
%% =========================================================
figure(...
    'Color','w',...
    'Position',[100 100 1200 500]);
subplot(1,2,1)
imagesc(T_ms,F2,AWA_group_mean);
axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title('AWA Group Average Ripple Spectrogram',...
    'FontName','Times New Roman',...
    'FontSize',16,...
    'FontWeight','bold');
colorbar;
subplot(1,2,2)
imagesc(T_ms,F2,WARD_group_mean);
axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title('WARD Group Average Ripple Spectrogram',...
    'FontName','Times New Roman',...
    'FontSize',16,...
    'FontWeight','bold');
colorbar;
saveas(gcf,...
    fullfile(out_dir,...
    'Group_Spectrogram.png'));
close;

%% =========================================================
%% ===================== Difference Map ====================
%% =========================================================
figure('Color','w');
imagesc(...
    T_ms,...
    F2,...
    WARD_group_mean - AWA_group_mean);

axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title('WARD - AWA Ripple Spectrogram',...
    'FontName','Times New Roman',...
    'FontSize',16,...
    'FontWeight','bold');
colorbar;
saveas(gcf,...
    fullfile(out_dir,...
    'WARD_minus_AWA.png'));
close;
%% =========================================================
%% ===================== Save Group Data ===================
%% =========================================================
save(fullfile(out_dir,...
    'Group_Ripple_Spectrogram.mat'),...
    'AWA_group_mean',...
    'WARD_group_mean',...
    'T_ms',...
    'F2',...
    '-v7.3');

fprintf('\n=================================\n');
fprintf('Ripple spectrogram analysis done.\n');
fprintf('Results saved in:\n%s\n',out_dir);
fprintf('=================================\n');
