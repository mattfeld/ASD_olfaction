%%%%%%%
function step2_subjID(x)

% Display participant ID:
display(x);

% Get home directory:
var = getenv('HOME');

% Add modules to MATLAB. ORDER IS IMPORTANT! Do not change the order of these programs:
SPM8Path = [var, '/apps/matlab/spm8'];
addpath(genpath(SPM8Path));
vistaPath = [var, '/apps/matlab/vistasoft'];
addpath(genpath(vistaPath));
AFQPath = [var, '/apps/matlab/AFQ'];
addpath(genpath(AFQPath));

% Set file names:
subjDir = [var, '/compute/AutismOlfactory/', x];
dtiFile = [subjDir, '/dti_data/dti.nii.gz'];
cd (subjDir);

% Do it:
ni = readFileNifti(dtiFile);
ni = niftiSetQto(ni, ni.sto_xyz);
writeFileNifti(ni, dtiFile);

% Determine phase encode dir:
% > info=dicominfo([var,'/compute/AutismOlfactory/Analyses/ref_dir/IM-0868-0001.dcm']);
% To get the manufacturer information:
% > info.(dicomlookup('0008','0070'))
% To get the axis of phase encoding with respect to the image:
% > info.(dicomlookup('0018','1312'))
% If phase encode dir is 'COL', then set 'phaseEncodeDir' to '2'
% If phase encode dir is 'ROW', then set 'phaseEncodeDir' to '1'
% For Siemens / Philips specific code we need to add 'rotateBvecsWithCanXform',
% AND ALWAYS DOUBLE CHECK phaseEncodeDir:
% > dwParams = dtiInitParams('rotateBvecsWithCanXform',1,'phaseEncodeDir',2,'clobber',1);
% For GE specific code,
% AND ALWAYS DOUBLE CHECK phaseEncodeDir:
% > dwParams = dtiInitParams('phaseEncodeDir',2,'clobber',1);
dwParams = dtiInitParams('rotateBvecsWithCanXform', 1, 'phaseEncodeDir', 2, 'clobber', 1);

% Here's the one line of code to do the DTI preprocessing:
dtiInit(dtiFile, 'MNI', dwParams);

% Clean up files and exit:
movefile('dti_a*', 'dti_data/');
movefile('dti_b*', 'dti_data/');
movefile('dtiInitLog.mat', 'dti_data/');
movefile('ROIs', '*trilin');
movefile('*trilin', 'dti_data/');
movefile('dti6*', 'dti_data/');
movefile('MNI_EPI.nii.gz', 'dti_data/');

exit;
