#!/bin/bash

#SBATCH --time=10:00:00   # walltime
#SBATCH --ntasks=2   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "AOtc1"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE




subj=$1

workDir=~/compute/AutismOlfactory
dataDir=${workDir}/${subj}/t1_data
conDir=${workDir}/Template

tempDir=~/bin/Templates/old_templates/mni_icbm152_nlin_sym_09c_nifti/mni_icbm152_nlin_sym_09c
fix=${tempDir}/mni_icbm152_t1_tal_nlin_sym_09c.nii
out=ants_${subj}_
dim=3
moving=${subj}_raw.nii.gz


# check for data
cd $conDir
if [ ! -f $moving ]; then

	cp ${dataDir}/struct_raw.nii.gz ${conDir}/$moving
fi


# normalize
if [ ! -f ants_${subj}_0GenericAffine.mat ]; then

    antsRegistrationSyN.sh \
    -d $dim \
    -f $fix \
    -m $moving \
    -o $out
fi