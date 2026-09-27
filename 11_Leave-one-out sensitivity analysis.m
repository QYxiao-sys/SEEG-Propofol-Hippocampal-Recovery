clc;
clear;
close all;


%% =====================================================
% Symmetric PAC Change and Cognitive Correlation
%
% PAC_sym = (PAC_AWA - PAC_WARD) /
%           ((PAC_AWA + PAC_WARD)/2)
%
% Statistics:
%   Pearson correlation
%   Spearman correlation
%   Leave-one-out sensitivity analysis
%
% MATLAB R2020b
%
%% =====================================================


%% =====================================================
%% ================== Global settings ==================
%% =====================================================

set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');
set(0,'DefaultLegendFontName','Times New Roman');


%% =====================================================
%% ================= Project paths =====================
%% =====================================================

projectDir = pwd;


dataFile = fullfile( ...
    projectDir,...
    'data',...
    'multivariate_regression.xlsx');


resultDir = fullfile( ...
    projectDir,...
    'results');


statDir = fullfile( ...
    resultDir,...
    'statistics');


figDir = fullfile( ...
    resultDir,...
    'figures');


if ~exist(resultDir,'dir')
    mkdir(resultDir);
end


if ~exist(statDir,'dir')
    mkdir(statDir);
end


if ~exist(figDir,'dir')
    mkdir(figDir);
end



%% =====================================================
%% ================= Read Excel ========================
%% =====================================================

T = readtable( ...
    dataFile,...
    'VariableNamingRule','preserve');



%% =====================================================
%% ================= Extract variables =================
%% =====================================================

FSIQ = T.FSIQ;

PAC_AWA = T.PAC_AWA;

PAC_WARD = T.PAC_WARD;



%% =====================================================
%% ================= Column vectors ====================
%% =====================================================

FSIQ = FSIQ(:);

PAC_AWA = PAC_AWA(:);

PAC_WARD = PAC_WARD(:);



%% =====================================================
%% ================= Data quality check ================
%% =====================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('Data quality check\n');
fprintf('========================================\n');


fprintf('Total samples = %d\n',length(FSIQ));


valid = isfinite(FSIQ) & ...
        isfinite(PAC_AWA) & ...
        isfinite(PAC_WARD);



fprintf('Valid samples = %d\n',sum(valid));


if sum(valid)<4

    error('Insufficient valid samples.');

end



FSIQ = FSIQ(valid);

PAC_AWA = PAC_AWA(valid);

PAC_WARD = PAC_WARD(valid);



%% =====================================================
%% ================= PAC symmetric index ===============
%% =====================================================


denominator = ...
    (PAC_AWA + PAC_WARD)/2;



if any(denominator==0)

    error('Zero denominator detected.');

end



PAC_sym = ...
    (PAC_AWA - PAC_WARD) ./ denominator;



%% Remove invalid PAC values

valid2 = isfinite(PAC_sym);


FSIQ = FSIQ(valid2);

PAC_AWA = PAC_AWA(valid2);

PAC_WARD = PAC_WARD(valid2);

PAC_sym = PAC_sym(valid2);



N = length(FSIQ);



fprintf('Final N = %d\n',N);



%% =====================================================
%% ================= Correlation analysis ==============
%% =====================================================


[r,p] = corr( ...
    FSIQ,...
    PAC_sym,...
    'type','Pearson');


R2 = r^2;



[rho,p_spearman] = corr( ...
    FSIQ,...
    PAC_sym,...
    'type','Spearman');



fprintf('\n');
fprintf('========================================\n');
fprintf('Correlation results\n');
fprintf('========================================\n');


fprintf('Pearson r = %.4f\n',r);

fprintf('Pearson p = %.6f\n',p);

fprintf('R2 = %.4f\n',R2);


fprintf('\n');

fprintf('Spearman rho = %.4f\n',rho);

fprintf('Spearman p = %.6f\n',p_spearman);



%% =====================================================
%% ================= Leave-one-out =====================
%% =====================================================


LOO_r = nan(N,1);

LOO_R2 = nan(N,1);

LOO_p = nan(N,1);


LOO_rho = nan(N,1);

LOO_p_spearman = nan(N,1);



for i = 1:N


    idx = true(N,1);

    idx(i)=false;



    x_temp = FSIQ(idx);

    y_temp = PAC_sym(idx);



    [r_temp,p_temp]=corr( ...
        x_temp,...
        y_temp,...
        'type','Pearson');



    LOO_r(i)=r_temp;

    LOO_R2(i)=r_temp^2;

    LOO_p(i)=p_temp;



    [rho_temp,p_rho_temp]=corr( ...
        x_temp,...
        y_temp,...
        'type','Spearman');


    LOO_rho(i)=rho_temp;

    LOO_p_spearman(i)=p_rho_temp;


end



%% =====================================================
%% ================= LOO summary =======================
%% =====================================================


delta_r = abs(LOO_r-r);


max_delta = max(delta_r);



n_positive = sum(LOO_r>0);

n_significant = sum(LOO_p<0.05);



fprintf('\n');
fprintf('========================================\n');
fprintf('LOO sensitivity analysis\n');
fprintf('========================================\n');


fprintf('LOO r range: %.4f - %.4f\n',...
    min(LOO_r),...
    max(LOO_r));


fprintf('Mean LOO r: %.4f\n',...
    mean(LOO_r));


fprintf('Positive correlations: %d/%d\n',...
    n_positive,N);


fprintf('Significant correlations: %d/%d\n',...
    n_significant,N);


fprintf('Maximum change in r: %.4f\n',...
    max_delta);



%% =====================================================
%% ================= Save statistics ===================
%% =====================================================


LOO_Table = table( ...
    (1:N)',...
    FSIQ,...
    PAC_sym,...
    LOO_r,...
    LOO_R2,...
    LOO_p,...
    LOO_rho,...
    LOO_p_spearman,...
    'VariableNames',...
    {'RemovedSample',...
    'FSIQ',...
    'PAC_sym',...
    'Pearson_r',...
    'R_squared',...
    'Pearson_p',...
    'Spearman_rho',...
    'Spearman_p'});



save(fullfile(statDir,...
    'PAC_sym_FSIQ_LOO_statistics.mat'),...
    'FSIQ',...
    'PAC_AWA',...
    'PAC_WARD',...
    'PAC_sym',...
    'r',...
    'p',...
    'R2',...
    'rho',...
    'p_spearman',...
    'LOO_r',...
    'LOO_R2',...
    'LOO_p',...
    'LOO_rho',...
    'LOO_p_spearman',...
    'LOO_Table');



writetable( ...
    LOO_Table,...
    fullfile(statDir,...
    'PAC_sym_FSIQ_LOO_statistics.xlsx'));



%% =====================================================
%% ================= Scatter plot ======================
%% =====================================================


figure('Color','w');


scatter(FSIQ,...
    PAC_sym,...
    120,...
    'filled');


hold on;


P = polyfit(FSIQ,PAC_sym,1);


xfit = linspace(min(FSIQ),...
    max(FSIQ),200);


yfit = polyval(P,xfit);



plot(xfit,...
    yfit,...
    'LineWidth',3);



xlabel('Wechsler Full Scale IQ',...
    'FontSize',16,...
    'FontWeight','bold');


ylabel('Symmetric PAC Change',...
    'FontSize',16,...
    'FontWeight','bold');


title('IQ vs Symmetric PAC Change',...
    'FontSize',18,...
    'FontWeight','bold');



text(min(FSIQ),...
    max(PAC_sym),...
    sprintf('N=%d\nr=%.3f\np=%.4f\nR^2=%.3f',...
    N,r,p,R2),...
    'FontSize',14,...
    'FontWeight','bold',...
    'VerticalAlignment','top');



set(gca,...
    'FontSize',14,...
    'LineWidth',1.5,...
    'Box','off');



print(gcf,...
    fullfile(figDir,...
    'PAC_sym_FSIQ_correlation.tiff'),...
    '-dtiff',...
    '-r300');



saveas(gcf,...
    fullfile(figDir,...
    'PAC_sym_FSIQ_correlation.png'));



%% =====================================================
%% ================= LOO sensitivity figure ============
%% =====================================================


figure('Color','w');


plot(1:N,...
    LOO_r,...
    'o-',...
    'LineWidth',2,...
    'MarkerSize',8);



hold on;


plot([1 N],...
    [r r],...
    '--',...
    'LineWidth',2);



plot([1 N],...
    [0 0],...
    ':',...
    'LineWidth',1.5);



xlabel('Removed sample',...
    'FontSize',16,...
    'FontWeight','bold');


ylabel('Pearson r',...
    'FontSize',16,...
    'FontWeight','bold');



title('Leave-One-Out Sensitivity Analysis',...
    'FontSize',18,...
    'FontWeight','bold');



legend(...
    'LOO Pearson r',...
    sprintf('Original r=%.3f',r),...
    'r=0',...
    'Location','best');



set(gca,...
    'FontSize',14,...
    'LineWidth',1.5,...
    'Box','off');



print(gcf,...
    fullfile(figDir,...
    'PAC_sym_FSIQ_LOO_sensitivity.tiff'),...
    '-dtiff',...
    '-r300');


saveas(gcf,...
    fullfile(figDir,...
    'PAC_sym_FSIQ_LOO_sensitivity.png'));



%% =====================================================
%% ================= Finish ============================
%% =====================================================


fprintf('\n');
fprintf('========================================\n');
fprintf('PAC symmetric correlation analysis completed\n');
fprintf('========================================\n');

fprintf('N = %d\n',N);

fprintf('Pearson r = %.4f\n',r);

fprintf('p = %.6f\n',p);

fprintf('========================================\n');