% Get home directory:
var = getenv('HOME');

% Add modules to MATLAB. ORDER IS IMPORTANT! Do not change the order of these programs:
SPM8Path = [var, '/apps/matlab/spm8'];
addpath(genpath(SPM8Path));
vistaPath = [var, '/apps/matlab/vistasoft'];
addpath(genpath(vistaPath));
AFQPath = [var, '/apps/matlab/AFQ'];
addpath(genpath(AFQPath));

load ~/compute/AutismOlfactory/Analyses/dtiAnalysis/AFQ/afq_analysis.mat
outdir = fullfile([var, '/compute/AutismOlfactory/Analyses/dtiAnalysis/AFQ-CC/']);
outname = fullfile([outdir, 'step5_afq_cc_job']);
afq = AFQ_SegmentCallosum(afq, 0)
save(outname, 'afq');
