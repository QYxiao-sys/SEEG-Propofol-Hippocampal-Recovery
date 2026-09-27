%% =========================================================
% 04_Hippocampal_PSD_statistics_figure.m
%
% Hippocampal PSD group comparison between AWA and WARD
%
% Purpose:
%   Statistical comparison and visualization of hippocampal PSD
%
% Input:
%   Hippocampus_PSD.mat
%
% Analysis:
%   Paired Wilcoxon signed-rank test at each frequency bin
%   Significant clusters defined as consecutive frequencies
%   exceeding 4 Hz
%
% Conditions:
%   AWA  : after consciousness recovery following propofol anesthesia
%   WARD : resting physiological baseline
%
% MATLAB:
%   R2020b
%
% =========================================================


clear;
clc;
close all;



%% =========================================================
%% ===================== Figure style ======================
%% =========================================================


set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');
set(0,'DefaultLegendFontName','Times New Roman');

set(0,'DefaultAxesFontSize',16);
set(0,'DefaultTextFontSize',16);
set(0,'DefaultLegendFontSize',16);



%% =========================================================
%% ===================== USER SETTINGS =====================
%% =========================================================


project_dir = 'YOUR_PROJECT_PATH';


input_file = fullfile(...
    project_dir,...
    'results',...
    'PSD',...
    'Hippocampus_PSD.mat');


stat_dir = fullfile(...
    project_dir,...
    'results',...
    'statistics');


figure_dir = fullfile(...
    project_dir,...
    'figures');



if ~exist(stat_dir,'dir')
    mkdir(stat_dir);
end


if ~exist(figure_dir,'dir')
    mkdir(figure_dir);
end



%% =========================================================
%% ===================== Parameters ========================
%% =========================================================


ROI_name = 'Hippocampus';

ROI_label = 'Hippocampal PSD';


alpha_level = 0.05;


% minimum significant cluster width

min_cluster_hz = 4;



%% =========================================================
%% ===================== Load data =========================
%% =========================================================


load(input_file);



% Expected variables:
% PSD.AWA
% PSD.WARD
% freq


data_AWA  = PSD.AWA;

data_WARD = PSD.WARD;



fprintf('\n====================================\n');
fprintf('Hippocampal PSD statistics\n');
fprintf('====================================\n');


fprintf('AWA subjects  : %d\n',size(data_AWA,1));
fprintf('WARD subjects : %d\n',size(data_WARD,1));



%% =========================================================
%% ===================== Statistics ========================
%% =========================================================


nFreq = length(freq);


pvals = nan(1,nFreq);



for fidx = 1:nFreq


    % paired Wilcoxon signed-rank test

    pvals(fidx)=signrank(...
        data_AWA(:,fidx),...
        data_WARD(:,fidx));


end



%% =========================================================
%% ================= Significant clusters ==================
%% =========================================================


sig_mask = pvals < alpha_level;



freq_resolution = mean(diff(freq));


min_cluster_points = ceil(...
    min_cluster_hz / freq_resolution);



d = diff([0 sig_mask 0]);


cluster_start = find(d==1);

cluster_end = find(d==-1)-1;



valid_mask=zeros(size(sig_mask));


significant_ranges=[];



fprintf('\nSignificant frequency clusters:\n');


for k=1:length(cluster_start)


    cluster_length = ...
        cluster_end(k)-cluster_start(k)+1;


    if cluster_length >= min_cluster_points


        valid_mask(...
            cluster_start(k):cluster_end(k))=1;


        range=[...
            freq(cluster_start(k)),...
            freq(cluster_end(k))];


        significant_ranges(end+1,:)=range;


        fprintf(...
            '%.2f - %.2f Hz\n',...
            range(1),range(2));


    end

end



%% =========================================================
%% ================= Save statistics ======================
%% =========================================================


PSD_statistics.freq = freq;

PSD_statistics.pvals = pvals;

PSD_statistics.significant_mask = valid_mask;

PSD_statistics.significant_ranges = significant_ranges;

PSD_statistics.alpha = alpha_level;

PSD_statistics.cluster_threshold = min_cluster_hz;


save(...
    fullfile(stat_dir,...
    'Hippocampal_PSD_statistics.mat'),...
    'PSD_statistics');



%% =========================================================
%% ===================== Plot ==============================
%% =========================================================


figure(...
    'Position',[100 100 900 600],...
    'Color','w');


hold on;



colors.AWA=[1 0 0];

colors.WARD=[0 0 0];



states={'AWA','WARD'};


plot_handles=gobjects(2,1);



for s=1:length(states)


    state=states{s};


    if strcmp(state,'AWA')

        data=data_AWA;

    else

        data=data_WARD;

    end



    meanPSD=mean(data,1);


    stdPSD=std(data,0,1);


    nSub=size(data,1);


    ci95=1.96*stdPSD./sqrt(nSub);



    upper=meanPSD+ci95;

    lower=meanPSD-ci95;



    x=freq;



    % confidence interval

    patch(...
        [x fliplr(x)],...
        [upper fliplr(lower)],...
        colors.(state),...
        'FaceAlpha',0.2,...
        'EdgeColor','none',...
        'HandleVisibility','off');



    % mean curve

    plot_handles(s)=plot(...
        x,...
        meanPSD,...
        'Color',colors.(state),...
        'LineWidth',2.5,...
        'DisplayName',state);

end



%% =========================================================
%% ================ Significant line ======================
%% =========================================================


current_ylim=ylim;


y_sig=current_ylim(1)+...
    0.05*(current_ylim(2)-current_ylim(1));



d2=diff([0 valid_mask 0]);


sig_start=find(d2==1);

sig_end=find(d2==-1)-1;



for k=1:length(sig_start)


    plot(...
        [freq(sig_start(k)) freq(sig_end(k))],...
        [y_sig y_sig],...
        'b',...
        'LineWidth',4,...
        'HandleVisibility','off');

end



%% =========================================================
%% ================= Figure formatting ====================
%% =========================================================


xlabel(...
    'Frequency (Hz)',...
    'FontSize',16);



ylabel(...
    'Power spectral density (dB)',...
    'FontSize',16);



title(...
    ROI_label,...
    'FontWeight','bold',...
    'FontSize',20);



xlim([1 250]);


box off;


grid off;



ax=gca;

ax.LineWidth=1.5;

ax.FontSize=16;

ax.XTick=0:20:250;



legend(...
    plot_handles,...
    states,...
    'Location','northeast',...
    'FontSize',16);



%% =========================================================
%% ================= Export figure ========================
%% =========================================================


output_fig = fullfile(...
    figure_dir,...
    'Figure_Hippocampal_PSD_AWA_vs_WARD.tiff');



exportgraphics(...
    gcf,...
    output_fig,...
    'Resolution',600);



fprintf('\n====================================\n');
fprintf('PSD figure completed.\n');
fprintf('Saved figure:\n%s\n',output_fig);
fprintf('====================================\n');