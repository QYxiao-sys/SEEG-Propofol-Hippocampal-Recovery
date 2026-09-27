%% =========================================================
% 10_Hippocampal_PAC_behavior_correlation.m
%
% Correlation between hippocampal PAC recovery index
% and Wechsler Full Scale IQ
%
% PAC change index:
%
% PAC_ci=
% (PAC_AWA - PAC_WARD) /
% ((PAC_AWA + PAC_WARD)/2)
%
% AWA:
% after consciousness recovery following propofol anesthesia
%
% WARD:
% physiological baseline
%
%% =========================================================


clc;
clear;
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



excel_file = fullfile(...
    project_dir,...
    'behavior',...
    'multivariable_regression.xlsx');



output_dir = fullfile(...
    project_dir,...
    'figures',...
    'PAC_behavior');



if ~exist(output_dir,'dir')

    mkdir(output_dir);

end



%% =========================================================
%% ===================== Load Excel =======================
%% =========================================================


T = readtable(...
    excel_file,...
    'VariableNamingRule',...
    'preserve');



%% =========================================================
%% ===================== Extract variables ================
%% =========================================================


% Wechsler Full Scale IQ

IQ = T.('智力全表');



% Hippocampal PAC

PAC_AWA = T.('PAC-AWA');

PAC_WARD = T.('PAC-WARD');



%% =========================================================
%% ================= Symmetric PAC index ==================
%% =========================================================


if any((PAC_AWA + PAC_WARD)==0)

    error(...
        'PAC_AWA + PAC_WARD contains zero value.');

end



PAC_ci = ...
    (PAC_AWA - PAC_WARD) ./ ...
    ((PAC_AWA + PAC_WARD)/2);



%% =========================================================
%% ================= Remove missing values ================
%% =========================================================


valid = ...
    ~isnan(IQ) & ...
    ~isnan(PAC_ci);



IQ = IQ(valid);

PAC_ci = PAC_ci(valid);



N = length(IQ);



%% =========================================================
%% ================= Pearson correlation ==================
%% =========================================================


[r,p] = corr(...
    IQ,...
    PAC_ci,...
    'type',...
    'Pearson');



R2 = r^2;



%% =========================================================
%% ================= Spearman correlation =================
%% =========================================================


[rho,p_spear] = corr(...
    IQ,...
    PAC_ci,...
    'type',...
    'Spearman');



%% =========================================================
%% ================= Print results ========================
%% =========================================================


fprintf('\n========================================\n');

fprintf('Hippocampal PAC vs Wechsler FSIQ\n');

fprintf('PAC_sym = (PAC_AWA-PAC_WARD)/((PAC_AWA+PAC_WARD)/2)\n');

fprintf('N = %d\n',N);


fprintf('\nPearson correlation\n');

fprintf('r = %.3f\n',r);

fprintf('R2 = %.3f\n',R2);

fprintf('p = %.4f\n',p);



fprintf('\nSpearman correlation\n');

fprintf('rho = %.3f\n',rho);

fprintf('p = %.4f\n',p_spear);



fprintf('========================================\n');



%% =========================================================
%% ================= Regression figure ====================
%% =========================================================


figure(...
    'Color','w',...
    'Position',[400 200 650 550]);



scatter(...
    IQ,...
    PAC_ci,...
    120,...
    'filled');

hold on;



%% linear regression

P = polyfit(...
    IQ,...
    PAC_ci,...
    1);



xfit = linspace(...
    min(IQ),...
    max(IQ),...
    100);



yfit = polyval(...
    P,...
    xfit);



plot(...
    xfit,...
    yfit,...
    'LineWidth',...
    3);



%% =========================================================
%% ================= Figure labels ========================
%% =========================================================


xlabel(...
    'Wechsler Full Scale IQ Score',...
    'FontSize',...
    16,...
    'FontWeight',...
    'bold');



ylabel(...
    'Symmetric PAC Change Index',...
    'FontSize',...
    16,...
    'FontWeight',...
    'bold');



title({...
    'IQ vs Hippocampal PAC Recovery Index'},...
    'FontSize',...
    18,...
    'FontWeight',...
    'bold');



%% =========================================================
%% ================= Statistics annotation ================
%% =========================================================


text(...
    min(IQ)+0.05*range(IQ),...
    max(PAC_ci),...
    sprintf(...
    'Pearson r = %.3f\np = %.4f\nR^2 = %.3f\nN = %d',...
    r,...
    p,...
    R2,...
    N),...
    'FontSize',...
    14,...
    'FontWeight',...
    'bold',...
    'VerticalAlignment',...
    'top');



%% =========================================================
%% ================= Axis style ===========================
%% =========================================================


set(gca,...
    'LineWidth',...
    1.5,...
    'FontSize',...
    14,...
    'Box',...
    'off',...
    'TickDir',...
    'out');



%% =========================================================
%% ================= Save results =========================
%% =========================================================


PAC_behavior_statistics.N = N;

PAC_behavior_statistics.Pearson_r = r;

PAC_behavior_statistics.Pearson_p = p;

PAC_behavior_statistics.R2 = R2;

PAC_behavior_statistics.Spearman_rho = rho;

PAC_behavior_statistics.Spearman_p = p_spear;

PAC_behavior_statistics.IQ = IQ;

PAC_behavior_statistics.PAC_sym = PAC_ci;



save(fullfile(...
    output_dir,...
    'Hippocampal_PAC_IQ_correlation_statistics.mat'),...
    'PAC_behavior_statistics');



%% =========================================================
%% ================= Save figure ==========================
%% =========================================================


fig_name = fullfile(...
    output_dir,...
    'Figure_Hippocampal_PAC_IQ_correlation');



savefig([fig_name '.fig']);



exportgraphics(...
    gcf,...
    [fig_name '.tiff'],...
    'Resolution',...
    600);



fprintf('\n========================================\n');
fprintf('PAC behavior correlation finished.\n');
fprintf('Saved:\n%s\n',...
    fig_name);
fprintf('========================================\n');