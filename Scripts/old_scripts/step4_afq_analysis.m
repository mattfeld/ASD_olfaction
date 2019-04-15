% Get home directory:
var = getenv('HOME');

% Add modules to MATLAB. ORDER IS IMPORTANT! Do not change the order of these programs:
SPM8Path = [var, '/apps/matlab/spm8'];
addpath(genpath(SPM8Path));
vistaPath = [var, '/apps/matlab/vistasoft'];
addpath(genpath(vistaPath));
AFQPath = [var, '/apps/matlab/AFQ'];
addpath(genpath(AFQPath));

load ~/compute/AutismOlfactory/Analyses/dtiAnalysis/AFQ/sub_dirs.mat
load ~/compute/AutismOlfactory/Analyses/dtiAnalysis/AFQ/sub_group.mat
outdir = fullfile([var, '/compute/AutismOlfactory/Analyses/dtiAnalysis/AFQ/']);
outname = fullfile([outdir, 'afq_analysis']);
afq = AFQ_Create('sub_dirs', sub_dirs, 'sub_group', sub_group, 'showfigs', false);
[afq, patient_data, control_data, norms, abn, abnTracts] = AFQ_run(sub_dirs, sub_group, afq);
save(outname, 'afq');
