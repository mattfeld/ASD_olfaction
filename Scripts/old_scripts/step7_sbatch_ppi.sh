#!/bin/bash


### This is just a request for supercomputer resources

#SBATCH --time=30:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "AOppi7"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE



# Written by Nathan Muncy on 4/13/18


### Notes:
#
# This script will do basic pre-processing and deconvolution of the data
# in preparation for the PPI analysis.
#
# Each major step (###) is annotated, and some additional notes (#) are left as well.




### Set Up
subj=$1


# general variables
workDir=~/compute/AutismOlfactory
tempDir=${workDir}/Template
scriptDir=${workDir}/Scripts


# ants variables
dim=3
struct=struct_rotated.nii.gz
temp=${tempDir}/AO_template.nii.gz
mask=${tempDir}/priors_ACT/Template_BrainCerebellumBinaryMask.nii.gz
out=ants_


# arrays
funcList=(BORun{1..3})


# subject-specific variables
ppiDir=${workDir}/${subj}/ppi_data
timingDir=${workDir}/TimingFiles




### Find outliers, despike, and align volume to middle TR
cd $ppiDir

for j in ${funcList[@]}; do
    if [ ! -f volreg_${j}+orig.HEAD ] && [ ! -f scale_${j}+orig.HEAD ]; then

		tr_count=`fslhd ${j}.nii.gz | grep "dim4" | awk 'FNR == 1 {print $2}'`
        base="$(($tr_count / 2))"

		3dcopy ${j}.nii.gz ${j}+orig
        3dToutcount -automask -fraction -polort 6 -legendre ${j}+orig > outcount_${j}.1D
        3dDespike -NEW -nomask -prefix despike_$j ${j}+orig
        3dvolreg -zpad 1 -base despike_${j}+orig"[${base}]" \
        -prefix volreg_$j -1Dfile motion_$j -cubic despike_${j}+orig
    fi
done


### Motion files - 6 df
cat outcount_BORun*.1D > outcount_all.1D

for a in {1..3}; do
	cp motion_BORun${a} motion_${a}
done

${scriptDir}/move_censor.pl
mv motion_censor_vector.txt motion_censor_vector_All.txt
rm motion_?
> motion_All
cat motion_BORun? >> motion_All


### Timing files
# There are two types of timing. A) Fixed duration, which can be measured in .5 seconds
# and B) Variable duration, which is measured in .1 seconds. This difference is compounded
# with the fact that the TR = 2 seconds, where a single TR could have both A and B types
# of information.
# So, timing files are built with a temporal resolution of 0.1 seconds
# in order to not have A and B overlap. Original timing files were built in R.

if [ ! -f ${subj}_TF_behVect.01.1D ]; then

	string=${subj/BO}

	if [ ! -f ${string}_TF.txt ]; then
		cp ${timingDir}/${string}_*.txt .
	fi

	PRE=${subj}_TF_behVect
	TR=0.1
	NRUN=3
	NT=2820

	make_stim_times.py -files ${string}_TF.txt -prefix $PRE -tr $TR -nruns $NRUN -nt $NT
fi




### Several steps
# 		a) Align runs into same (Run1) space - I'm assuming Run1 was closest in time to the T1
#		b) Blur data to suppress noise & augment signal, collapse for node differences
#			This has been updated (Nate May 02 2018)
#		c) Scale data

for j in ${funcList[@]}; do
	if [ ! -f scale_${j}+orig.HEAD ]; then
		if [ $j != BORun1 ]; then

			3dvolreg -base volreg_BORun1+orig'[0]' -prefix aligned_${j} volreg_${j}+orig
			3dmerge -1blur_fwhm 5.0 -doall -prefix blur_${j} aligned_${j}+orig
		else
			3dmerge -1blur_fwhm 5.0 -doall -prefix blur_${j} volreg_${j}+orig
		fi

		3dTstat -prefix tmp.mean_$j blur_${j}+orig
		3dcalc -a blur_${j}+orig -b tmp.mean_${j}+orig \
		-expr 'min(200, a/b*100)*step(a)*step(b)' \
		-prefix scale_$j
	fi
done




### Warp data to MNI space
# This uses a study-specific heterogeneous Template that I constructed using
# all participant scans. A single heterogeneous template is ideal in this sense
# that it minimizes the Jacobian of the transformation, atypical (Autistic) data is
# represented in the template, and confounds are not introduced by using multiple
# templates.
#
# Warp = symmetric, non-linear diffeomorphic transformation.
#
# Registration is done with the MPRAGE, and then the composed warp vectors are
# applied to the functional data to move it into template space.

if [ ! -f ants_0GenericAffine.mat ]; then

    3dWarp -oblique_parent scale_BORun1+orig -prefix struct_rotated struct_raw.nii.gz
    3dcopy struct_rotated+orig $struct

    antsRegistrationSyN.sh \
    -d $dim \
    -f $temp \
    -m $struct \
    -o $out
fi

for a in ${funcList[@]}; do
    if [ ! -f scale_${a}_ANTS_resampled+tlrc.HEAD ]; then

        ${scriptDir}/antifyFunctional_nate.sh -a $out -t $temp -i scale_${a}+orig
    fi
done




### First deconvolution
# make exclusion mask, exclude non-cerebral voxels
if [ ! -f Template_brain_mask_resampled+tlrc.HEAD ]; then

    3dcopy $mask tmp_Template_brain_mask+tlrc
    3dfractionize -template scale_BORun1_ANTS_resampled+tlrc -prefix tmp_Template_brain_mask_resampled+tlrc -input tmp_Template_brain_mask+tlrc
    3dcalc -a tmp_Template_brain_mask_resampled+tlrc -prefix Template_mask+tlrc -expr "step(a)"
    rm tmp*
fi


# Polynomial, motion, and behavioral regressors are used in the deconvolution.
# We are using both fixed and random duration behavioral regressors.
# Baseline is "Mask" stimulus, blank screens are in Effects of No Interest (ENI)
# Censor includes any TR with movement > 0.3 mm or 4 degrees rotation relative to previous TR.

if [ ! -f stats_AODecon1+tlrc.HEAD ]; then

	input="scale_BORun1_ANTS_resampled+tlrc scale_BORun2_ANTS_resampled+tlrc scale_BORun3_ANTS_resampled+tlrc"

	TF1=${subj}_TF_behVect.01.1D; L1=ENI1
	TF2=${subj}_TF_behVect.02.1D; L2=RI
	TF3=${subj}_TF_behVect.03.1D; L3=RP

	string=${subj/BO}
	TF4=${string}_Jit1.txt; L4=ENI2
	TF5=${string}_FBO.txt;  L5=Fam
	TF6=${string}_UBO.txt;  L6=NFam
	TF7=${string}_CA.txt;   L7=CA

	out=AODecon1

	3dDeconvolve \
	-input $input \
	-mask Template_mask+tlrc \
	-polort A \
	-num_stimts 13 \
	-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
	-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
	-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
	-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
	-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
	-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
	-stim_times  7  ${TF1} "BLOCK(0.1,1)"  -stim_label 7 $L1 \
	-stim_times  8  ${TF2} "BLOCK(0.1,1)"  -stim_label 8 $L2 \
	-stim_times  9  ${TF3} "BLOCK(0.1,1)"  -stim_label 9 $L3 \
	-stim_times_AM1  10  ${TF4} "dmBLOCK(1)"  -stim_label 10 $L4 \
	-stim_times_AM1  11  ${TF5} "dmBLOCK(1)"  -stim_label 11 $L5 \
	-stim_times_AM1  12  ${TF6} "dmBLOCK(1)"  -stim_label 12 $L6 \
	-stim_times_AM1  13  ${TF7} "dmBLOCK(1)"  -stim_label 13 $L7 \
	-num_glt 1 \
	-gltsym "SYM: 1*${L5} -1*${L6}" -glt_label 1 ${L5}-${L6} \
	-censor "motion_censor_vector_All.txt[0]" \
	-fout -tout -x1D ${out}.xmat.1D \
	-bucket stats_${out} -cbucket cstats_${out} \
	-jobs 6
fi













