#!/bin/bash

#SBATCH --time=00:10:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=4gb   # memory per CPU core
#SBATCH -J "BID2"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE




subj=$1
subjDir=~/compute/AutismOlfactory/rawdata/$subj
tempDir=~/bin/Templates




### Check for jq
# jq will be used to append Json files

which jq >/dev/null 2>&1

if [ $? != 0 ]; then
	echo >&2
	echo "Software jq is required: download from https://stedolan.github.io/jq/ and add it to your \$PATH. Exit 1" >&2
	echo >&2
	exit 1
fi




### BIDS-afy the anat/func data

# Anat - deface
cd ${subjDir}/anat

pref=sub-South_Bo_${subj#*-}
3dAllineate -base tmp_${pref}_T1w.nii.gz -input ${tempDir}/mean_reg2mean.nii.gz -prefix tmp_mean_reg2mean_aligned.nii -1Dmatrix_save tmp_allineate_matrix
3dAllineate -base tmp_${pref}_T1w.nii.gz -input ${tempDir}/facemask.nii.gz -prefix tmp_facemask_aligned.nii -1Dmatrix_apply tmp_allineate_matrix.aff12.1D
3dcalc -a tmp_facemask_aligned.nii -b tmp_sub-${subj}_T1w.nii.gz -prefix sub-${subj}_T1w.nii.gz -expr "step(a)*b"
mv tmp_${pref}_T1w.json ${subj}_T1w.json

if [ -f ${subj}_T1w.nii.gz ]; then
	rm tmp*
else
	echo >&2
	echo "Defaced output not detected. Exit 2" >&2
	echo >&2
	exit 2
fi


# Func - append Json
cd ${subjDir}/func

for i in *json; do
	taskExist=$(cat $i | jq '.TaskName')
	if [ "$taskExist" == "null" ]; then
		jq '. |= . + {"TaskName":"AutismOlfactory"}' $i > tasknameadd.json
		rm $i && mv tasknameadd.json $i
	fi
fi
