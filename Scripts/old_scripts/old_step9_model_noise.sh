#!/bin/bash

#SBATCH --time=30:00:00   # walltime
#SBATCH --ntasks=1   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=12gb   # memory per CPU core
#SBATCH -J "AOMN"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE



subj=$1
workDir=~/compute/AutismOlfactory/${subj}/ppi_data


cd $workDir

# Run on all residual files
for j in errts*.HEAD; do

	file=${j%.*}
	tmp=${file#*_}
	string=${tmp%+*}
	print=error_${string}.txt
	mask=Template_mask+tlrc

	3dFWHMx -mask $mask -input $file -acf > $print
done












