%% Step 0 - Set enviro

% workDir
workDir = ['/Volumes/Yorick/Nate_work/AutismOlfactory'];
dataDir1 = [workDir, '/Analyses/dtiAnalysis/AFQ'];
dataDir2 = [workDir, '/Analyses/dtiAnalysis/AFQ-CC'];

addpath(genpath(workDir));
addpath(genpath(dataDir1));
addpath(genpath(dataDir2));

% Get home directory:
var = getenv('HOME');

% Add modules to MATLAB. Do not change the order of these programs:
SPM8Path = [var,'/matlab/spm8'];
vistaPath = [var,'/matlab/vistasoft'];
AFQPath = [var,'/matlab/afq'];
LHON2Path = [var,'/matlab/LHON2'];

addpath(genpath(SPM8Path));
addpath(genpath(vistaPath));
addpath(genpath(AFQPath));
addpath(genpath(LHON2Path));


% % get gen data
% cd(dataDir1)
% load afq_analysis.mat


% get CC data
cd(dataDir2)
load step5_afq_cc_job.mat


%% Step 1 - graph fibers

% % fiber names
% afq.fgnames

% Graph all paths
% all = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...
%   11, 12, 13, 14, 15, 16, 17, 18, 19, 20, ...
%   21, 22, 23, 24, 25, 26, 27, 28];
% AFQ_plot('Lo', afq.patient_data, ...
%   'Hi', afq.control_data, ...
%   'tracts', all, ...
%   'group', ...
%   'property', 'fa');


% Graph specific FA paths (L/R IFOF, ILF
specific = [11,12,13,14];
AFQ_plot('Autism', afq.patient_data, ...
  'Control', afq.control_data, ...
  'tracts', specific, ...
  'group', ...
  'property', 'fa');


% % graph right arcuate (20) FA
% AFQ_plot('Lo', afq.patient_data, ...
%   'Hi', afq.control_data, ...
%   'tracts', [20], ...
%   'group', ...
%   'property', 'fa');
% 
% % control group heatmap
% AFQ_plot(afq, 'colormap', 'tracts', specific)



%% Step 2 - build fibers for an individual subject, BO1048 - LR arcuate fasc

subjData = [workDir, '/BO1048/dti_data/dti30trilin'];
tempData = [var, '/matlab/vistasoft/mrDiffusion/templates'];

fg = dtiReadFibers(fullfile([subjData, '/fibers/MoriGroups_clean_D5_L4.mat']));
fg1 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Sup_Frontal_clean_D5_L4.mat']));
dt = dtiLoadDt6(fullfile([subjData, '/dt6.mat']));
t1 = readFileNifti([tempData, '/MNI_JHU_FA.nii.gz']);

AFQ_RenderFibers(fg(19), 'numfibers', 500, 'color', [1 0 0], 'subplot', [1 2 1]);
title(fg(19).name, 'fontsize', 18)
% 
% AFQ_RenderFibers(fg(20), 'numfibers', 500, 'color', [1 0 0], 'subplot', [1 2 2]);
% title(fg(20).name, 'fontsize', 18)
% 
% AFQ_RenderFibers(fg1(1), 'numfibers', 500, 'color', [1 0 0], 'subplot', [1 2 2]);
% title(fg1(1).name, 'fontsize', 18)


%% Step 3 - Heatmap of tracts for individuals

% % L arcuate fasc
% crange = [.3 .6]; numfibers = 200; radius = 5; subdivs = 100; cmap = 'jet'; newfig = 0;
% Profile = SO_FiberValsInTractProfiles(fg(19), dt, 'SI', 100, 1);
% AFQ_RenderFibers(fg(19), 'numfibers', 500, 'color', [.5 .5 .5], 'alpha', 0.5);
% AFQ_RenderTractProfile(Profile.coords.acpc, radius, Profile.vals.fa, subdivs, cmap, crange, newfig);
% AFQ_AddImageTo3dPlot(t1, [-5, 0, 0]);
% 
% % R arcuate fasc
% crange = [.3 .6]; numfibers = 200; radius = 5; subdivs = 100; cmap = 'jet'; newfig = 0;
% Profile = SO_FiberValsInTractProfiles(fg(20), dt, 'SI', 100, 1);
% AFQ_RenderFibers(fg(20), 'numfibers', 500, 'color', [.5 .5 .5], 'alpha', 0.5);
% AFQ_RenderTractProfile(Profile.coords.acpc, radius, Profile.vals.fa, subdivs, cmap, crange, newfig);
% AFQ_AddImageTo3dPlot(t1, [-5, 0, 0]);

% % CC motor
% crange = [.3 .6]; numfibers = 200; radius = 5; subdivs = 100; cmap = 'jet'; newfig = 0;
% Profile = SO_FiberValsInTractProfiles(fg1(1), dt, 'SI', 100, 1);
% AFQ_RenderFibers(fg1(1), 'numfibers', 500, 'color', [.5 .5 .5], 'alpha', 0.5);
% AFQ_RenderTractProfile(Profile.coords.acpc, radius, Profile.vals.fa, subdivs, cmap, crange, newfig);
% AFQ_AddImageTo3dPlot(t1, [-5, 0, 0]);


%% Step 4 - build corpus callosum for a subject 

 % Load Fiber Groups
fgA1 = dtiReadFibers(fullfile([subjData, '/fibers/MoriGroups_clean_D5_L4.mat']));


 % Create Figure
AFQ_RenderFibers(fgA1(11), 'numfibers', 500, 'color', [1 0 0], 'camera', 'sagittal');
AFQ_RenderFibers(fgA1(12), 'numfibers', 500, 'color', [1 .5 0], 'newfig', '0');
AFQ_RenderFibers(fgA1(13), 'numfibers', 500, 'color', [1 0 .5], 'newfig', '0');
AFQ_RenderFibers(fgA1(14), 'numfibers', 500, 'color', [0 1 0], 'newfig', '0');
AFQ_AddImageTo3dPlot(t1, [-1, 0, 0]);
set(gcf, 'Position', [100, 100, 780, 650]);
set(gca, 'XTick', [], 'YTick', [], 'ZTick', [], 'xlabel', [], 'ylabel', [], 'zlabel', []);
set(gca, 'LooseInset', get(gca, 'TightInset'))


%  % Load Fiber Groups
% fg1 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Orb_Frontal_clean_D5_L4.mat']));
% fg2 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Ant_Frontal_clean_D5_L4.mat']));
% fg3 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Sup_Frontal_clean_D5_L4.mat']));
% fg4 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Motor_clean_D5_L4.mat']));
% fg5 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Sup_Parietal_clean_D5_L4.mat']));
% fg6 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Post_Parietal_clean_D5_L4.mat']));
% fg7 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Occipital_clean_D5_L4.mat']));
% fg8 = dtiReadFibers(fullfile([subjData, '/fibers/CC_Temporal_clean_D5_L4.mat']));
% 
%  % Create Figure
% AFQ_RenderFibers(fg1, 'numfibers', 500, 'color', [1 0 0], 'camera', 'sagittal');
% AFQ_RenderFibers(fg2, 'numfibers', 500, 'color', [1 .5 0], 'newfig', '0');
% AFQ_RenderFibers(fg3, 'numfibers', 500, 'color', [1 0 .5], 'newfig', '0');
% AFQ_RenderFibers(fg4, 'numfibers', 500, 'color', [0 1 0], 'newfig', '0');
% AFQ_RenderFibers(fg5, 'numfibers', 500, 'color', [0 0 1], 'newfig', '0');
% AFQ_RenderFibers(fg6, 'numfibers', 500, 'color', [.6 0 .8275], 'newfig', '0');
% AFQ_RenderFibers(fg7, 'numfibers', 500, 'color', [1 .2 .6], 'newfig', '0');
% AFQ_RenderFibers(fg8, 'numfibers', 500, 'color', [0 1 1], 'newfig', '0');
% AFQ_AddImageTo3dPlot(t1, [-1, 0, 0]);
% set(gcf, 'Position', [100, 100, 780, 650]);
% set(gca, 'XTick', [], 'YTick', [], 'ZTick', [], 'xlabel', [], 'ylabel', [], 'zlabel', []);
% set(gca, 'LooseInset', get(gca, 'TightInset'))



%% Step 5 - Group renderings

% Tract profiles, for visualization 
 
 for jj = 1:20
    [hAD(jj, :), pAD(jj, :), ~, TstatsAD(jj)] = ttest2(afq.patient_data(jj).AD, afq.control_data(jj).AD);
    [hFA(jj, :), pFA(jj, :), ~, TstatsFA(jj)] = ttest2(afq.patient_data(jj).FA, afq.control_data(jj).FA);
    [hMD(jj, :), pMD(jj, :), ~, TstatsMD(jj)] = ttest2(afq.patient_data(jj).MD, afq.control_data(jj).MD);
    [hRD(jj, :), pRD(jj, :), ~, TstatsRD(jj)] = ttest2(afq.patient_data(jj).RD, afq.control_data(jj).RD);
 end

 

numNodes = 100;
[fa, md, rd, ad, cl, volume, TractProfile] = AFQ_ComputeTractProperties(fg, dt, numNodes);

for jj = 1:20
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'pADval', pAD(jj, :));
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'pFAval', pFA(jj, :));
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'pMDval', pMD(jj, :));
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'pRDval', pRD(jj, :));
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'TstatAD', TstatsAD(jj).tstat);
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'TstatFA', TstatsFA(jj).tstat);
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'TstatMD', TstatsMD(jj).tstat);
    TractProfile(jj) = AFQ_TractProfileSet(TractProfile(jj), 'vals', 'TstatRD', TstatsRD(jj).tstat);
end

save(dataDir1,'TractProfile');



% Show where the groups differ, for FA, AD, MD, RD
% Requires variables from Step 2

mymap = [1 0 0
1 1 1];
crange = [0 1]; numfibers = 200; radius = 5; subdivs = 100; cmap = mymap;

AFQ_RenderFibers(fg(19), 'color', [.75 .75 .75], 'tractprofile', TractProfile(5), 'val', 'pADval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 1]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
title('Left Cingulum Cingulate', 'fontsize', 18)
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('AD');
ylabel([]);
zl1 = zlim;
yl1 = ylim;

AFQ_RenderFibers(fg(20), 'color', [.75 .75 .75], 'tractprofile', TractProfile(6), 'val', 'pADval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 2], 'camera', [90 0]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
title('Right Cingulum Cingulate', 'fontsize', 18)
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('AD');
ylabel([]);
zlim(zl1);

AFQ_RenderFibers(fg(19), 'color', [.75 .75 .75], 'tractprofile', TractProfile(5), 'val', 'pFAval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 3]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('FA');
ylabel([]);
zlim(zl1);

AFQ_RenderFibers(fg(20), 'color', [.75 .75 .75], 'tractprofile', TractProfile(6), 'val', 'pFAval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 4], 'camera', [90 0]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('FA');
ylabel([]);
zlim(zl1);

AFQ_RenderFibers(fg(19), 'color', [.75 .75 .75], 'tractprofile', TractProfile(5), 'val', 'pMDval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 5]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('MD');
ylabel([]);

AFQ_RenderFibers(fg(20), 'color', [.75 .75 .75], 'tractprofile', TractProfile(6), 'val', 'pMDval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 6], 'camera', [90 0]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('MD');
ylabel([]);
zlim(zl1);

AFQ_RenderFibers(fg(19), 'color', [.75 .75 .75], 'tractprofile', TractProfile(5), 'val', 'pRDval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 7]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('RD');
ylabel([]);
zlim(zl1);

AFQ_RenderFibers(fg(20), 'color', [.75 .75 .75], 'tractprofile', TractProfile(6), 'val', 'pRDval', 'numfibers', numfibers, 'cmap', cmap, 'crange', crange, 'radius', [1 5], 'subplot', [4 2 8], 'camera', [90 0]);
AFQ_AddImageTo3dPlot(t1, [1, 0, 0], [], [0]);
colorbar('delete');
set(gca, 'ZTickLabel', [], 'YTickLabel', []);
set(gca, 'CLim', [0, 0.05]);
zlabel('RD');
ylabel([]);
zlim(zl1);


%% Step 5 - Make Tables

load step5_afq_cc_job.mat

fgname={'left_thalamic_radiation', 'right_thalamic_radiation', 'left_corticospinal', 'right_corticospinal', 'left_cingulum_cingulate', 'right_cingulum_cingulate', 'left_cingulum_hippocampus', 'right_cingulum_hippocampus', 'callosum_forceps_major', 'callosum_forceps_minor', 'left_ifof', 'right_ifof', 'left_ilf', 'right_ilf', 'left_slf', 'right_slf', 'left_uncinate', 'right_uncinate', 'left_arcuate', 'right_arcuate'};
% outdir=fullfile('/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/dtiAnalysis/AFQ/stats/');
outdir=fullfile('~/Desktop/');

for n = 1:20  %% n = label value from afq.fgnames
csvwrite(fullfile(outdir,strcat('Aut_',fgname{n},'_fa.csv')),afq.patient_data(n).FA)
%csvwrite(fullfile(outdir,strcat('lo_',fgname{n},'_rd.csv')),afq.patient_data(n).RD)
%csvwrite(fullfile(outdir,strcat('lo_',fgname{n},'_md.csv')),afq.patient_data(n).MD)
%csvwrite(fullfile(outdir,strcat('lo_',fgname{n},'_ad.csv')),afq.patient_data(n).AD)
csvwrite(fullfile(outdir,strcat('Con_',fgname{n},'_fa.csv')),afq.control_data(n).FA)
%csvwrite(fullfile(outdir,strcat('hi_',fgname{n},'_rd.csv')),afq.control_data(n).RD)
%csvwrite(fullfile(outdir,strcat('hi_',fgname{n},'_md.csv')),afq.control_data(n).MD)
%csvwrite(fullfile(outdir,strcat('hi_',fgname{n},'_ad.csv')),afq.control_data(n).AD)
end


fgccname={'cc_occipital', 'cc_post_parietal', 'cc_sup_parietal', 'cc_motor', 'cc_sup_frontal', 'cc_ant_frontal', 'cc_orb_frontal', 'cc_temporal'};
% outdir=fullfile('/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/dtiAnalysis/AFQ-CC/stats/');
outdir=fullfile('~/Desktop/');

for n = 21:28
csvwrite(fullfile(outdir,strcat('Aut_',fgccname{n-20},'_fa.csv')),afq.patient_data(n).FA)
%csvwrite(fullfile(outdir,strcat('lo_',fgccname{n-20},'_rd.csv')),afq.patient_data(n).RD)
%csvwrite(fullfile(outdir,strcat('lo_',fgccname{n-20},'_md.csv')),afq.patient_data(n).MD)
%csvwrite(fullfile(outdir,strcat('lo_',fgccname{n-20},'_ad.csv')),afq.patient_data(n).AD)
csvwrite(fullfile(outdir,strcat('Con_',fgccname{n-20},'_fa.csv')),afq.control_data(n).FA)
%csvwrite(fullfile(outdir,strcat('hi_',fgccname{n-20},'_rd.csv')),afq.control_data(n).RD)
%csvwrite(fullfile(outdir,strcat('hi_',fgccname{n-20},'_md.csv')),afq.control_data(n).MD)
%csvwrite(fullfile(outdir,strcat('hi_',fgccname{n-20},'_ad.csv')),afq.control_data(n).AD)
end





