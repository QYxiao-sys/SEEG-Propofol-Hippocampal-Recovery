%% =========================================================
% 06_Hippocampal_PE_statistics_figure.m
%
% Statistical comparison of hippocampal normalized PE
%
% Frequency:
%   Low Gamma (30-80 Hz)
%
% Statistics:
%   Paired Wilcoxon signed-rank test
%
% Output:
%   Statistics MAT file
%   Publication-quality TIFF figure
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
set(0,'DefaultLegendFontName','Times New Roman');

set(0,'DefaultAxesFontSize',16);
set(0,'DefaultTextFontSize',16);



%% =========================================================
%% ================= USER SETTINGS =========================
%% =========================================================


project_dir='YOUR_PROJECT_PATH';



input_file=fullfile(...
    project_dir,...
    'results',...
    'PE',...
    'Hippocampal_NormalizedPE_AdaptiveTau.mat');



output_dir=fullfile(...
    project_dir,...
    'figures');


stat_dir=fullfile(...
    project_dir,...
    'results',...
    'statistics');



if ~exist(output_dir,'dir')
    mkdir(output_dir);
end


if ~exist(stat_dir,'dir')
    mkdir(stat_dir);
end



%% =========================================================
%% ================= Load data =============================
%% =========================================================


load(input_file);



%% =========================================================
%% ================= Select band ===========================
%% =========================================================


band_name='LowGamma';


idx_band=strcmp(...
    PE_table.Band,...
    band_name);



T=PE_table(idx_band,:);



%% =========================================================
%% ================= Paired subjects ======================
%% =========================================================


subs_AWA=T.Subject(strcmp(T.State,'AWA'));

subs_WARD=T.Subject(strcmp(T.State,'WARD'));


common_subs=intersect(...
    subs_AWA,...
    subs_WARD);



awa_values=[];

ward_values=[];



for i=1:length(common_subs)


    sub=common_subs{i};


    idx1=strcmp(T.Subject,sub) & ...
         strcmp(T.State,'AWA');


    idx2=strcmp(T.Subject,sub) & ...
         strcmp(T.State,'WARD');



    awa_values(end+1)=...
        T.Normalized_PE(idx1);


    ward_values(end+1)=...
        T.Normalized_PE(idx2);


end



%% =========================================================
%% ================= Statistics =============================
%% =========================================================


[p,~,stats]=signrank(...
    awa_values,...
    ward_values);



N=length(awa_values);



if isfield(stats,'zval')

    z=stats.zval;

else

    z=NaN;

end



effect_r=z/sqrt(N);



fprintf('\n====================================\n');

fprintf('Band: %s\n',band_name);

fprintf('N = %d\n',N);

fprintf('Wilcoxon p = %.5f\n',p);

fprintf('Effect size r = %.3f\n',effect_r);

fprintf('====================================\n');



%% =========================================================
%% ================= Save statistics =======================
%% =========================================================


PE_statistics.band=band_name;

PE_statistics.N=N;

PE_statistics.p=p;

PE_statistics.z=z;

PE_statistics.effect_size_r=effect_r;

PE_statistics.AWA=awa_values;

PE_statistics.WARD=ward_values;



save(fullfile(stat_dir,...
    'Hippocampal_LowGamma_PE_statistics.mat'),...
    'PE_statistics');



%% =========================================================
%% ================= Figure ================================
%% =========================================================


color_AWA=[0.85 0.2 0.2];

color_WARD=[0.15 0.15 0.15];

gray_point=[0.5 0.5 0.5];



figure(...
    'Color','w',...
    'Position',[300 200 450 650]);

hold on;



%% Boxplot


all_values=[awa_values ward_values];


groups=[...
    ones(size(awa_values)),...
    2*ones(size(ward_values))];



boxplot(...
    all_values,...
    groups,...
    'Positions',[1 2],...
    'Widths',0.55,...
    'Symbol','');



h=findobj(gca,'Tag','Box');



for j=1:length(h)


    if j==2

        c=color_AWA;

    else

        c=color_WARD;

    end


    patch(...
        get(h(j),'XData'),...
        get(h(j),'YData'),...
        c,...
        'FaceAlpha',0.45,...
        'EdgeColor',c,...
        'LineWidth',1.5);

end



%% Paired lines


for i=1:N

    plot([1 2],...
        [awa_values(i) ward_values(i)],...
        '-',...
        'Color',[0.8 0.8 0.8],...
        'LineWidth',0.8);

end



%% Scatter


scatter(...
    1+randn(size(awa_values))*0.03,...
    awa_values,...
    55,...
    gray_point,...
    'filled',...
    'MarkerFaceAlpha',0.4);



scatter(...
    2+randn(size(ward_values))*0.03,...
    ward_values,...
    55,...
    gray_point,...
    'filled',...
    'MarkerFaceAlpha',0.4);



%% Text


yl=ylim;


text(1.5,...
    yl(2),...
    sprintf('p = %.4f',p),...
    'HorizontalAlignment','center',...
    'FontSize',18,...
    'FontWeight','bold',...
    'FontName','Times New Roman');



%% Axis


xticks([1 2]);

xticklabels({'AWA','WARD'});


ylabel('Normalized PE',...
    'FontSize',18,...
    'FontWeight','bold');



title('Low-Gamma Permutation Entropy',...
    'FontSize',20,...
    'FontWeight','bold');



set(gca,...
    'FontName','Times New Roman',...
    'FontSize',16,...
    'LineWidth',1.5);



box off;



%% =========================================================
%% ================= Export ================================
%% =========================================================


exportgraphics(...
    gcf,...
    fullfile(output_dir,...
    'Figure_Hippocampal_LowGamma_PE_AWA_vs_WARD.tiff'),...
    'Resolution',600);



fprintf('\nFigure saved.\n');