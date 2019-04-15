#!/bin/bash


### This is just a request for supercomputer resources

#SBATCH --time=05:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "AOppi7.3"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE



# Written by Nathan Muncy on 7/19/18


### Notes:
#
# Another deconvolution script, to combine Mask/FBO/UBO into the same sub-brik for a CA x Odor comparison
#
# Based on step7_sbatch




### Set Up
subj=$1


# general variables
workDir=~/compute/AutismOlfactory
tempDir=${workDir}/Template
scriptDir=${workDir}/Scripts


# arrays
funcList=(BORun{1..3})


# subject-specific variables
ppiDir=${workDir}/${subj}/ppi_data
timingDir=${workDir}/TimingFiles



cd $ppiDir

# Make new behVectors - TF Col1 = CA, Col2 = Odor
if [ ! -f ${subj}_CA_Odor_behVect.01.1D ]; then

	string=${subj/BO}

	if [ ! -f ${string}_CA_Odor.txt ]; then
		cp ${timingDir}/${string}_CA_Odor.txt .
	fi

	PRE=${subj}_CA_Odor_behVect
	TR=0.1
	NRUN=3
	NT=2820

	make_stim_times.py -files ${string}_CA_Odor.txt -prefix $PRE -tr $TR -nruns $NRUN -nt $NT
fi






### Make new deconv file to add Mask info
if [ ! -f stats_AODecon3+tlrc.HEAD ]; then

	input="scale_BORun1_ANTS_resampled+tlrc scale_BORun2_ANTS_resampled+tlrc scale_BORun3_ANTS_resampled+tlrc"

	TF1=${subj}_TF_behVect.01.1D; L1=ENI1
	TF2=${subj}_TF_behVect.02.1D; L2=RI
	TF3=${subj}_TF_behVect.03.1D; L3=RP
	TF4=${subj}_CA_Odor_behVect.01.1D; L4=CA
	TF5=${subj}_CA_Odor_behVect.02.1D; L5=Odor

	string=${subj/BO}
	TF6=${string}_Jit1.txt; L6=ENI2

	out=AODecon3

	3dDeconvolve \
	-input $input \
	-mask Template_mask+tlrc \
	-polort A \
	-num_stimts 12 \
	-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
	-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
	-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
	-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
	-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
	-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
	-stim_times  7  ${TF1} "BLOCK(0.1,1)"  -stim_label 7 $L1 \
	-stim_times  8  ${TF2} "BLOCK(0.1,1)"  -stim_label 8 $L2 \
	-stim_times  9  ${TF3} "BLOCK(0.1,1)"  -stim_label 9 $L3 \
	-stim_times  10  ${TF4} "BLOCK(0.1,1)"  -stim_label 10 $L4 \
	-stim_times  11  ${TF5} "BLOCK(0.1,1)"  -stim_label 11 $L5 \
	-stim_times_AM1  12  ${TF6} "dmBLOCK(1)"  -stim_label 12 $L6 \
	-num_glt 1 \
	-gltsym "SYM: 1*${L5} -1*${L6}" -glt_label 1 ${L5}-${L6} \
	-censor "motion_censor_vector_All.txt[0]" \
	-fout -tout -x1D ${out}.xmat.1D \
	-bucket stats_${out} -cbucket cstats_${out} \
	-jobs 6
fi










