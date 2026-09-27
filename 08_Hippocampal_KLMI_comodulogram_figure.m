%% =========================================================
% 08_Hippocampal_KLMI_comodulogram_figure.m
%
% Visualization of hippocampal KLMI comodulograms
%
% Conditions:
%   AWA  : after consciousness recovery following propofol
%   WARD : resting physiological baseline
%
% Display:
%   WARD
%   AWA
%   AWA-WARD difference
%
% Frequency:
%   LF phase: 1-13 Hz
%   HF amplitude: 30-150 Hz
%
%% =========================================================


clear;
clc;
close all;



%% =========================================================
%% ================= Figure settings ======================
%% =========================================================


set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');

set(0,'DefaultAxesFontSize',14);
set(0,'DefaultTextFontSize',14);



%% =========================================================
%% ================= Project path ==========================
%% =========================================================


project_dir='YOUR_PROJECT_PATH';



data_dir=fullfile(...
    project_dir,...
    'results',...
    'KLMI');



figure_dir=fullfile(...
    project_dir,...
    'figures',...
    'KLMI');



if ~exist(figure_dir,'dir')

    mkdir(figure_dir);

end



%% =========================================================
%% ================= Parameters ============================
%% =========================================================


smooth_sigma=1.0;


ROI_name='Hippocampus';



%% =========================================================
%% ================= Load data =============================
%% =========================================================


AWA=load(fullfile(...
    data_dir,...
    'Hippocampal_KLMI_AWA.mat'));


WARD=load(fullfile(...
    data_dir,...
    'Hippocampal_KLMI_WARD.mat'));



lf=AWA.lf_lower;

hf=AWA.hf_lower;



%% =========================================================
%% ================= HF cutoff =============================
%% =========================================================


hf_max=150;


hf_idx=find(hf<=hf_max);


hf_plot=hf(hf_idx);



%% =========================================================
%% ================= Extract KLMI ==========================
%% =========================================================


awa_cell=AWA.KLMI_H;

ward_cell=WARD.KLMI_H;



valid_awa=~cellfun(@isempty,awa_cell);

valid_ward=~cellfun(@isempty,ward_cell);



awa_data=cat(3,awa_cell{valid_awa});

ward_data=cat(3,ward_cell{valid_ward});



awa_data=awa_data(:,hf_idx,:);

ward_data=ward_data(:,hf_idx,:);



awa_mean=mean(awa_data,3);

ward_mean=mean(ward_data,3);



%% =========================================================
%% ================= Smoothing =============================
%% =========================================================


awa_smooth=imgaussfilt(...
    awa_mean,...
    smooth_sigma);


ward_smooth=imgaussfilt(...
    ward_mean,...
    smooth_sigma);



diff_map=awa_smooth-ward_smooth;



%% =========================================================
%% ================= Color limits ==========================
%% =========================================================


clim_main=[0.5e-4 4.5e-4];


maxDiff=max(abs(diff_map(:)));

clim_diff=[-maxDiff maxDiff];



%% =========================================================
%% ================= Create figure =========================
%% =========================================================


figure(...
    'Color','w',...
    'Position',[100 100 1500 450]);



%% =========================================================
%% ================= WARD ================================
%% =========================================================


subplot(1,3,1);


imagesc(...
    lf,...
    hf_plot,...
    ward_smooth');


axis xy;
axis tight;


xlabel('Low-frequency phase (Hz)');

ylabel('High-frequency amplitude (Hz)');


title('WARD');


caxis(clim_main);

colorbar;

ylim([30 150]);


set(gca,...
    'FontName','Times New Roman',...
    'LineWidth',1.2);



%% =========================================================
%% ================= AWA =================================
%% =========================================================


subplot(1,3,2);


imagesc(...
    lf,...
    hf_plot,...
    awa_smooth');


axis xy;
axis tight;


xlabel('Low-frequency phase (Hz)');

ylabel('High-frequency amplitude (Hz)');


title('AWA');


caxis(clim_main);

colorbar;

ylim([30 150]);


set(gca,...
    'FontName','Times New Roman',...
    'LineWidth',1.2);



%% =========================================================
%% ================= Difference ============================
%% =========================================================


subplot(1,3,3);


imagesc(...
    lf,...
    hf_plot,...
    diff_map');


axis xy;
axis tight;


xlabel('Low-frequency phase (Hz)');

ylabel('High-frequency amplitude (Hz)');


title('AWA - WARD');


caxis(clim_diff);

colorbar;

ylim([30 150]);


set(gca,...
    'FontName','Times New Roman',...
    'LineWidth',1.2);



%% =========================================================
%% ================= Colormap ==============================
%% =========================================================


colormap jet;



sgtitle(...
    'Hippocampal KLMI comodulogram',...
    'FontSize',18,...
    'FontWeight','bold');



%% =========================================================
%% ================= Save figure ===========================
%% =========================================================


fig_name=fullfile(...
    figure_dir,...
    'Figure_Hippocampal_KLMI_comodulogram');



savefig([fig_name '.fig']);



exportgraphics(...
    gcf,...
    [fig_name '.tiff'],...
    'Resolution',600);



%% =========================================================
%% ================= Save parameters ======================
%% =========================================================


KLMI_figure_parameters.smooth_sigma=smooth_sigma;

KLMI_figure_parameters.HF_cutoff=hf_max;

KLMI_figure_parameters.ROI=ROI_name;


save(fullfile(...
    figure_dir,...
    'KLMI_figure_parameters.mat'),...
    'KLMI_figure_parameters');



fprintf('\n========================================\n');
fprintf('KLMI figure completed.\n');
fprintf('Saved to:\n%s\n',figure_dir);
fprintf('========================================\n');