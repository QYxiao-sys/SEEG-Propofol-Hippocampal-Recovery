%% =========================================================
% Ripple_Parameter_Analysis.m
%
% Ripple event parameter analysis using RIPPLELAB detections
%
% Software:
%   MATLAB R2020b 
%
% Dependencies:
%   EEGLAB
%   RIPPLELAB
%
% =========================================================


clear;
clc;
close all;

%% =========================================================
%% ===================== 全局字体 ===========================
%% =========================================================

set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');

%% =========================================================
%% ===================== 加载 EEGLAB ========================

project_root = pwd;

%% =========================================================

eeglab_path = ...
fullfile(project_root,'external','eeglab');

addpath(genpath(eeglab_path));
eeglab;

%% =========================================================
%% ======================== 路径 ============================
%% =========================================================

awa_dir = ...
fullfile(project_root,'data','AWA','rhfe');

ward_dir = ...
fullfile(project_root,'data','WARD','rhfe');

%% ===== 原始set路径 =====

awa_set_dir = ...
fullfile(project_root,'data','AWA','set');

ward_set_dir = ...
fullfile(project_root,'data','WARD','set');

%% =========================================================
%% ======================== 参数 ============================
%% =========================================================

Fs = 1024;

record_time = 300;

ripple_band = [70 160];

%% =========================================================
%% ======================== 文件 ============================
%% =========================================================

awa_files  = dir(fullfile(awa_dir, '*.rhfe'));
ward_files = dir(fullfile(ward_dir, '*.rhfe'));

%% =========================================================
%% ======================== 被试 ============================
%% =========================================================

get_subj = @(x) regexp(x, '^\d+', 'match', 'once');

awa_subj = cellfun(@(x)get_subj(x), ...
    {awa_files.name}, 'uni', 0);

ward_subj = cellfun(@(x)get_subj(x), ...
    {ward_files.name}, 'uni', 0);

subjects = intersect(unique(awa_subj), unique(ward_subj));

%% =========================================================
%% ======================= 初始化 ===========================
%% =========================================================

Results = table;

%% =========================================================
%% ======================= 主循环 ===========================
%% =========================================================

for s = 1:length(subjects)

    subj = subjects{s};

    fprintf('\nProcessing Subject %s...\n', subj);

    %% =====================================================
    %% ========================= AWA ========================
    %% =====================================================

    awa_idx = find(strcmp(awa_subj, subj));

    awa_rates = [];
    awa_durs  = [];
    awa_peakf = [];
    awa_amp   = [];
    awa_cycle = [];

    for i = 1:length(awa_idx)

        %% ===== rhfe =====
        rhfe_file = fullfile(awa_dir,...
            awa_files(awa_idx(i)).name);

        S = load(rhfe_file,'-mat');

        vars = fieldnames(S);

        %% ===== set文件 =====
        setname = regexprep( ...
            awa_files(awa_idx(i)).name,...
            '_STE\.rhfe',...
            '_bipolar.set');

        setfile = fullfile(awa_set_dir,setname);

        if ~exist(setfile,'file')
            continue;
        end

        EEG = pop_loadset(setfile);

        %% ===== channel循环 =====
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

                %% ===== ripple数量 =====
                nRipple = size(evt,1);

                ripple_rate = ...
                    nRipple / (record_time/60);

                awa_rates(end+1) = ripple_rate;

                %% ===== channel =====
                chLabel = st.str_ChLabel;

                chIdx = find(strcmpi( ...
                    {EEG.chanlocs.labels},...
                    chLabel));

                if isempty(chIdx)
                    continue;
                end

                sig = double(EEG.data(chIdx,:));

                ripple_peakf = [];
                ripple_durs  = [];
                ripple_amp   = [];
                ripple_cycle = [];

                %% ===== ripple循环 =====
                for e = 1:nRipple

                    s1 = evt(e,1);
                    s2 = evt(e,2);

                    ripple_seg = sig(s1:s2);

                    %% ===== duration =====
                    dur_ms = ...
                        (s2-s1)/Fs*1000;

                    ripple_durs(end+1) = dur_ms;

                    %% ===== amplitude =====
                    amp = max(abs(ripple_seg));

                    ripple_amp(end+1) = amp;

                    %% ===== FFT =====
                    N = length(ripple_seg);

                    Y = fft(ripple_seg);

                    P2 = abs(Y/N);

                    P1 = P2(1:floor(N/2)+1);

                    f = Fs*(0:floor(N/2))/N;

                    %% ===== ripple频段 =====
                    idx = f >= ripple_band(1) & ...
                          f <= ripple_band(2);

                    f2 = f(idx);
                    P3 = P1(idx);

                    if isempty(P3)
                        continue;
                    end

                    %% ===== peak frequency =====
                    [~,midx] = max(P3);

                    peakf = f2(midx);

                    ripple_peakf(end+1) = peakf;

                    %% ===== cycles =====
                    cycles = dur_ms/1000 * peakf;

                    ripple_cycle(end+1) = cycles;

                end

                %% ===== channel平均 =====
                awa_durs(end+1)  = mean(ripple_durs,'omitnan');
                awa_peakf(end+1) = mean(ripple_peakf,'omitnan');
                awa_amp(end+1)   = mean(ripple_amp,'omitnan');
                awa_cycle(end+1) = mean(ripple_cycle,'omitnan');

            catch ME
                fprintf('Skipped: %s\n',ME.message);
            end
        end
    end

    %% ===== 被试平均 =====
    AWA_rate  = mean(awa_rates,'omitnan');
    AWA_dur   = mean(awa_durs,'omitnan');
    AWA_peakf = mean(awa_peakf,'omitnan');
    AWA_amp   = mean(awa_amp,'omitnan');
    AWA_cycle = mean(awa_cycle,'omitnan');

    %% =====================================================
    %% ======================== WARD ========================
    %% =====================================================

    ward_idx = find(strcmp(ward_subj, subj));

    ward_rates = [];
    ward_durs  = [];
    ward_peakf = [];
    ward_amp   = [];
    ward_cycle = [];

    for i = 1:length(ward_idx)

        rhfe_file = fullfile(ward_dir,...
            ward_files(ward_idx(i)).name);

        S = load(rhfe_file,'-mat');

        vars = fieldnames(S);

        setname = regexprep( ...
            ward_files(ward_idx(i)).name,...
            '_STE\.rhfe',...
            '_bipolar.set');

        setfile = fullfile(ward_set_dir,setname);

        if ~exist(setfile,'file')
            continue;
        end

        EEG = pop_loadset(setfile);

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

                nRipple = size(evt,1);

                ripple_rate = ...
                    nRipple / (record_time/60);

                ward_rates(end+1) = ripple_rate;

                chLabel = st.str_ChLabel;

                chIdx = find(strcmpi( ...
                    {EEG.chanlocs.labels},...
                    chLabel));

                if isempty(chIdx)
                    continue;
                end

                sig = double(EEG.data(chIdx,:));

                ripple_peakf = [];
                ripple_durs  = [];
                ripple_amp   = [];
                ripple_cycle = [];

                for e = 1:nRipple

                    s1 = evt(e,1);
                    s2 = evt(e,2);

                    ripple_seg = sig(s1:s2);

                    %% ===== duration =====
                    dur_ms = ...
                        (s2-s1)/Fs*1000;

                    ripple_durs(end+1) = dur_ms;

                    %% ===== amplitude =====
                    amp = max(abs(ripple_seg));

                    ripple_amp(end+1) = amp;

                    %% ===== FFT =====
                    N = length(ripple_seg);

                    Y = fft(ripple_seg);

                    P2 = abs(Y/N);

                    P1 = P2(1:floor(N/2)+1);

                    f = Fs*(0:floor(N/2))/N;

                    %% ===== ripple频段 =====
                    idx = f >= ripple_band(1) & ...
                          f <= ripple_band(2);

                    f2 = f(idx);
                    P3 = P1(idx);

                    if isempty(P3)
                        continue;
                    end

                    %% ===== peak frequency =====
                    [~,midx] = max(P3);

                    peakf = f2(midx);

                    ripple_peakf(end+1) = peakf;

                    %% ===== cycles =====
                    cycles = dur_ms/1000 * peakf;

                    ripple_cycle(end+1) = cycles;

                end

                ward_durs(end+1)  = mean(ripple_durs,'omitnan');
                ward_peakf(end+1) = mean(ripple_peakf,'omitnan');
                ward_amp(end+1)   = mean(ripple_amp,'omitnan');
                ward_cycle(end+1) = mean(ripple_cycle,'omitnan');

            catch ME
                fprintf('Skipped: %s\n',ME.message);
            end
        end
    end

    %% ===== 被试平均 =====
    WARD_rate  = mean(ward_rates,'omitnan');
    WARD_dur   = mean(ward_durs,'omitnan');
    WARD_peakf = mean(ward_peakf,'omitnan');
    WARD_amp   = mean(ward_amp,'omitnan');
    WARD_cycle = mean(ward_cycle,'omitnan');

    %% ===== 保存 =====
    newRow = table( ...
        {subj}, ...
        AWA_rate, WARD_rate, ...
        AWA_dur, WARD_dur, ...
        AWA_peakf, WARD_peakf,...
        AWA_amp, WARD_amp,...
        AWA_cycle, WARD_cycle,...
        'VariableNames',...
        {'Subject',...
        'AWA_Rate','WARD_Rate',...
        'AWA_Duration','WARD_Duration',...
        'AWA_PeakFreq','WARD_PeakFreq',...
        'AWA_Amplitude','WARD_Amplitude',...
        'AWA_Cycles','WARD_Cycles'});

    Results = [Results; newRow];

end

%% =========================================================
%% ====================== 统计检验 ==========================
%% =========================================================

p_rate = signrank(Results.AWA_Rate,...
                  Results.WARD_Rate);

p_dur = signrank(Results.AWA_Duration,...
                 Results.WARD_Duration);

p_peak = signrank(Results.AWA_PeakFreq,...
                  Results.WARD_PeakFreq);

p_amp = signrank(Results.AWA_Amplitude,...
                 Results.WARD_Amplitude);

p_cycle = signrank(Results.AWA_Cycles,...
                   Results.WARD_Cycles);

%% =========================================================
%% ======================== 输出 ============================
%% =========================================================

fprintf('\n=========== RESULTS ===========\n');

fprintf('\nRate p = %.4f\n', p_rate);
fprintf('Duration p = %.4f\n', p_dur);
fprintf('PeakFreq p = %.4f\n', p_peak);
fprintf('Amplitude p = %.4f\n', p_amp);
fprintf('Cycles p = %.4f\n', p_cycle);

%% =========================================================
%% ======================== 绘图 ============================
%% =========================================================

figure('Color','w','Position',[100 100 2200 450])

param_names = { ...
    'Rate',...
    'Duration',...
    'PeakFreq',...
    'Amplitude',...
    'Cycles'};

ylabels = { ...
    'Events/min',...
    'ms',...
    'Hz',...
    '\muV',...
    'Cycles'};

pvals = [ ...
    p_rate,...
    p_dur,...
    p_peak,...
    p_amp,...
    p_cycle];

AWA_all = { ...
    Results.AWA_Rate,...
    Results.AWA_Duration,...
    Results.AWA_PeakFreq,...
    Results.AWA_Amplitude,...
    Results.AWA_Cycles};

WARD_all = { ...
    Results.WARD_Rate,...
    Results.WARD_Duration,...
    Results.WARD_PeakFreq,...
    Results.WARD_Amplitude,...
    Results.WARD_Cycles};

for k = 1:5

    subplot(1,5,k)

    AWA_data  = AWA_all{k};
    WARD_data = WARD_all{k};

    data = [AWA_data WARD_data];

    boxplot(data,...
        'Labels',{'AWA','WARD'},...
        'Widths',0.5,...
        'Colors','k',...
        'Symbol','');

    hold on

    %% ===== 箱体 =====
    h = findobj(gca,'Tag','Box');

    patch(get(h(2),'XData'), ...
          get(h(2),'YData'), ...
          [1 0 0], ...
          'FaceAlpha',0.65);

    patch(get(h(1),'XData'), ...
          get(h(1),'YData'), ...
          [0 0 0], ...
          'FaceAlpha',0.65);

    %% ===== 散点 =====
    rng(1)

    x1 = 1 + 0.08*randn(length(AWA_data),1);

    scatter(x1,...
        AWA_data,...
        55,...
        [0.6 0.6 0.6],...
        'filled',...
        'MarkerFaceAlpha',0.75,...
        'MarkerEdgeAlpha',0.75);

    x2 = 2 + 0.08*randn(length(WARD_data),1);

    scatter(x2,...
        WARD_data,...
        55,...
        [0.6 0.6 0.6],...
        'filled',...
        'MarkerFaceAlpha',0.75,...
        'MarkerEdgeAlpha',0.75);

    %% ===== 配对线 =====
    for i = 1:length(AWA_data)

        p1 = plot([1 2],...
             [AWA_data(i) WARD_data(i)],...
             '-',...
             'LineWidth',1);

        p1.Color = [0.8 0.8 0.8 0.5];

    end

    ylabel(ylabels{k},...
        'FontSize',13,...
        'FontName','Times New Roman')

    title(sprintf('%s\np = %.4f',...
        param_names{k},...
        pvals(k)),...
        'FontWeight','bold',...
        'FontSize',14)

    set(gca,...
        'FontSize',13,...
        'FontName','Times New Roman',...
        'LineWidth',1.5,...
        'Box','off',...
        'TickDir','out');

end

%% =========================================================
%% ======================== 保存图 ==========================
%% =========================================================

saveDir = fullfile(project_root,'results');

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% ===== PNG =====
saveas(gcf, ...
    fullfile(saveDir, ...
    'Ripple_Boxplots.png'));

%% ===== FIG =====
saveas(gcf, ...
    fullfile(saveDir, ...
    'Ripple_Boxplots.fig'));

%% ===== TIFF 300dpi =====
print(gcf, ...
    fullfile(saveDir, ...
    'Ripple_Boxplots.tif'), ...
    '-dtiff', ...
    '-r300');

fprintf('\nFigure saved to:\n%s\n', saveDir);