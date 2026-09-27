%% =========================================================
% 09_Hippocampal_KLMI_statistics_figure.m
%
% Statistics and visualization of hippocampal KLMI
%
% Predefined PAC window:
%   Low-frequency phase:
%       3-7 Hz
%
%   High-frequency amplitude:
%       60-150 Hz
%
% Conditions:
%   AWA  : after consciousness recovery following propofol
%   WARD : physiological baseline
%
% Statistical test:
%   Wilcoxon signed-rank test
%
% Effect size:
%   r = Z / sqrt(N)
%
%% =========================================================


clear;
clc;
close all;



%% =========================================================
%% ===================== Font =============================
%% =========================================================


set(groot,...
    'defaultAxesFontName',...
    'Times New Roman');


set(groot,...
    'defaultTextFontName',...
    'Times New Roman');


set(groot,...
    'defaultAxesFontSize',...
    14);



%% =========================================================
%% ===================== Project path =====================
%% =========================================================


project_dir = 'YOUR_PROJECT_PATH';



data_dir = fullfile(...
    project_dir,...
    'results',...
    'KLMI');



figure_dir = fullfile(...
    project_dir,...
    'figures',...
    'KLMI');



if ~exist(figure_dir,'dir')

    mkdir(figure_dir);

end



%% =========================================================
%% ===================== Load data ========================
%% =========================================================


AWA = load(fullfile(...
    data_dir,...
    'Hippocampal_KLMI_AWA.mat'));


WARD = load(fullfile(...
    data_dir,...
    'Hippocampal_KLMI_WARD.mat'));



awa_cell = AWA.KLMI_H;

ward_cell = WARD.KLMI_H;



%% =========================================================
%% ===================== Frequency axis ===================
%% =========================================================


lf = AWA.lf_lower;

hf = AWA.hf_lower;



%% =========================================================
%% ===================== PAC window =======================
%% =========================================================


lf_range = [3 7];

hf_range = [60 150];



lf_idx = find(...
    lf >= lf_range(1) & ...
    lf <= lf_range(2));



hf_idx = find(...
    hf >= hf_range(1) & ...
    hf <= hf_range(2));



fprintf('\n====================================\n');
fprintf('PAC frequency window\n');
fprintf('====================================\n');

fprintf('LF phase: %.2f - %.2f Hz\n',...
    lf(lf_idx(1)),...
    lf(lf_idx(end)));

fprintf('HF amplitude: %.2f - %.2f Hz\n',...
    hf(hf_idx(1)),...
    hf(hf_idx(end)));



%% =========================================================
%% ================= Subject extraction ===================
%% =========================================================


nSubj = min(...
    length(awa_cell),...
    length(ward_cell));



AWA_value = nan(nSubj,1);

WARD_value = nan(nSubj,1);



for s = 1:nSubj


    if isempty(awa_cell{s}) || ...
       isempty(ward_cell{s})

        continue;

    end



    %% AWA

    pac_awa = awa_cell{s}(...
        lf_idx,...
        hf_idx);


    AWA_value(s)=median(...
        pac_awa(:));



    %% WARD

    pac_ward = ward_cell{s}(...
        lf_idx,...
        hf_idx);


    WARD_value(s)=median(...
        pac_ward(:));


end



%% =========================================================
%% ================= Remove missing =======================
%% =========================================================


valid = ...
    ~isnan(AWA_value) & ...
    ~isnan(WARD_value);



AWA_value = AWA_value(valid);

WARD_value = WARD_value(valid);



N = length(AWA_value);



fprintf('\nValid subjects: %d\n',N);



%% =========================================================
%% ================= Statistics ===========================
%% =========================================================


[p,h,stats] = signrank(...
    AWA_value,...
    WARD_value);



%% Z value compatibility

if isfield(stats,'zval')

    Z = stats.zval;

else

    Z = NaN;

end



%% Effect size

effect_r = Z / sqrt(N);

effect_r_abs = abs(effect_r);



%% =========================================================
%% ================= Print results ========================
%% =========================================================


fprintf('\n====================================\n');
fprintf('Hippocampal KLMI statistics\n');
fprintf('3-7 Hz phase × 60-150 Hz amplitude\n');
fprintf('====================================\n');


fprintf('N = %d\n',N);


fprintf('\nMedian KLMI\n');

fprintf('AWA  = %.6e\n',...
    median(AWA_value));


fprintf('WARD = %.6e\n',...
    median(WARD_value));


fprintf('\nWilcoxon signed-rank test\n');

fprintf('p = %.6f\n',p);

fprintf('Signed rank = %.3f\n',...
    stats.signedrank);


fprintf('Z = %.4f\n',Z);



fprintf('\nEffect size\n');

fprintf('r = Z / sqrt(N)\n');

fprintf('r = %.4f\n',...
    effect_r);


fprintf('|r| = %.4f\n',...
    effect_r_abs);



%% =========================================================
%% ================= Log transform ========================
%% =========================================================


AWA_plot = log10(AWA_value);

WARD_plot = log10(WARD_value);



%% =========================================================
%% ================= Figure ===============================
%% =========================================================


figure(...
    'Color','w',...
    'Position',[450 100 450 600]);

hold on;



data_all = [...
    AWA_plot;...
    WARD_plot];


group_all = [...
    ones(length(AWA_plot),1);...
    2*ones(length(WARD_plot),1)];



%% Boxplot

boxplot(...
    data_all,...
    group_all,...
    'Widths',0.5,...
    'Colors','k',...
    'Symbol','');



%% Find box handles

box_handle=findobj(gca,...
    'Tag',...
    'Box');



%% AWA red

patch(...
    get(box_handle(2),'XData'),...
    get(box_handle(2),'YData'),...
    [1 0 0],...
    'FaceAlpha',0.65,...
    'EdgeColor','k');



%% WARD black

patch(...
    get(box_handle(1),'XData'),...
    get(box_handle(1),'YData'),...
    [0 0 0],...
    'FaceAlpha',0.65,...
    'EdgeColor','k');



%% Scatter

rng(1);



x1 = 1 + ...
    0.08*randn(length(AWA_plot),1);



scatter(...
    x1,...
    AWA_plot,...
    55,...
    [0.6 0.6 0.6],...
    'filled',...
    'MarkerFaceAlpha',0.75);



x2 = 2 + ...
    0.08*randn(length(WARD_plot),1);



scatter(...
    x2,...
    WARD_plot,...
    55,...
    [0.6 0.6 0.6],...
    'filled',...
    'MarkerFaceAlpha',0.75);



%% Paired lines


for i=1:N

    plot([1 2],...
        [AWA_plot(i),WARD_plot(i)],...
        '-',...
        'Color',[0.82 0.82 0.82],...
        'LineWidth',1);

end



%% Axis


set(gca,...
    'XTick',[1 2],...
    'XTickLabel',{'AWA','WARD'},...
    'FontName','Times New Roman',...
    'FontSize',14,...
    'LineWidth',1.5,...
    'TickDir','out',...
    'Box','off');



ylabel(...
    'log_{10}(KLMI)',...
    'FontSize',15);



title({...
    'Hippocampal KLMI',...
    '3-7 Hz phase × 60-150 Hz amplitude'},...
    'FontSize',16,...
    'FontWeight','bold');



%% p value


if p < 0.001

    p_text='p < 0.001';

else

    p_text=sprintf('p = %.4f',p);

end



text(1.5,...
    max(ylim)*0.92,...
    p_text,...
    'HorizontalAlignment',...
    'center',...
    'FontSize',...
    16,...
    'FontWeight',...
    'bold');



%% =========================================================
%% ================= Save statistics ======================
%% =========================================================


statistics.N = N;

statistics.p = p;

statistics.h = h;

statistics.Z = Z;

statistics.effect_r = effect_r;

statistics.effect_r_abs = effect_r_abs;

statistics.AWA_value = AWA_value;

statistics.WARD_value = WARD_value;

statistics.frequency_window.LF = lf_range;

statistics.frequency_window.HF = hf_range;



save(fullfile(...
    data_dir,...
    'Hippocampal_KLMI_theta_gamma_statistics.mat'),...
    'statistics');



%% =========================================================
%% ================= Save figure ==========================
%% =========================================================


fig_name = fullfile(...
    figure_dir,...
    'Figure_Hippocampal_KLMI_theta_gamma');



savefig([fig_name '.fig']);



exportgraphics(...
    gcf,...
    [fig_name '.tiff'],...
    'Resolution',600);



fprintf('\n====================================\n');
fprintf('KLMI statistics completed.\n');
fprintf('Saved figure:\n%s\n',fig_name);
fprintf('====================================\n');