#!/bin/bash


### This is just a request for supercomputer resources

#SBATCH --time=30:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "AO2"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE



# Written by Nathan Muncy on 7/25/18


### Notes:
#
# This script will do basic pre-processing and deconvolution of the data
# in preparation for the PPI analysis.
#
# Each major step (###) is annotated, and some additional notes (#) are left as well.




### Set Up
subj=$1
string=${subj/BO}

# general variables
workDir=~/compute/AutismOlfactory
tempDir=~/bin/Templates/old_templates/mni_colin27_2008_nifti
scriptDir=${workDir}/Scripts

# subject-specific variables
ppiDir=${workDir}/${subj}/ppi_data
timingDir=${workDir}/TimingFiles
TR_time=2

# arrays
funcList=(BORun{1..3})




### Find outliers, despike, and align volume to middle TR
cd $ppiDir

for j in ${funcList[@]}; do
    if [ ! -f volreg_${j}+orig.HEAD ] && [ ! -f scale_${j}+orig.HEAD ]; then

		tr_count=`fslhd ${j}.nii.gz | grep "dim4" | awk 'FNR == 1 {print $2}'`
        base="$(($tr_count / 2))"

		#3dcopy ${j}.nii.gz ${j}+orig
        3dToutcount -automask -fraction -polort 6 -legendre ${j}+orig > outcount_${j}.1D
        3dDespike -NEW -nomask -prefix despike_$j ${j}+orig
        3dvolreg -zpad 1 -base despike_${j}+orig"[${base}]" \
        -prefix volreg_$j -1Dfile motion_$j -cubic despike_${j}+orig
    fi
done




### Motion files - 6 df
if [ ! -f motion_All ] || [ ! -s motion_All ]; then

	cat outcount_BORun*.1D > outcount_all.1D

	for a in {1..3}; do
		cp motion_BORun${a} motion_${a}
	done

	${scriptDir}/move_censor.pl
	mv motion_censor_vector.txt motion_censor_vector_All.txt
	rm motion_?
	> motion_All
	cat motion_BORun? >> motion_All
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




### Warp data to Talairach space
dim=3
struct=struct_rotated.nii.gz
temp=${tempDir}/colin27_t1_tal_hires.nii
mask=${tempDir}/colin27_brain_mask.nii
out=ants_

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




### Fix headers
for i in {1..3}; do
	hold=`3dinfo -tr scale_BORun${i}_ANTS_resampled+tlrc`
	if [ ${hold%.*} != $TR_time ]; then
		3drefit -TR $TR_time scale_BORun${i}_ANTS_resampled+tlrc
	fi
done




### Make exclusion mask for deconvolution, exclude non-cerebral voxels
if [ ! -f Template_mask+tlrc.HEAD ]; then

    3dcopy $mask tmp_Template_brain_mask+tlrc
    3dfractionize -template scale_BORun1_ANTS_resampled+tlrc -prefix tmp_Template_brain_mask_resampled+tlrc -input tmp_Template_brain_mask+tlrc
    3dcalc -a tmp_Template_brain_mask_resampled+tlrc -prefix Template_mask+tlrc -expr "step(a)"
    rm tmp*
fi



### Do Deconvolutions
# All timing files were built in R by Ari

input="scale_BORun1_ANTS_resampled+tlrc scale_BORun2_ANTS_resampled+tlrc scale_BORun3_ANTS_resampled+tlrc"

if [ ! -f ${string}_FUBO.txt ]; then
	cp ${timingDir}/${string}_*.txt .
fi


## Deconv1 - Mask = baseline, Briks for UBO, FBO, CA
# This was not used in final paper, just including it for history

#if [ ! -f stats_AODecon1+tlrc.HEAD ]; then

	#TF1=${subj}_TF_behVect.01.1D; 	L1=ENI1
	#TF2=${subj}_TF_behVect.02.1D; 	L2=RI
	#TF3=${subj}_TF_behVect.03.1D; 	L3=RP
	#TF4=${string}_Jit1.txt; 		L4=ENI2
	#TF5=${string}_FBO.txt;  		L5=FBO
	#TF6=${string}_UBO.txt;  		L6=UBO
	#TF7=${string}_CA.txt;   		L7=CA

	#out=AODecon1

	#3dDeconvolve \
	#-input $input \
	#-mask Template_mask+tlrc \
	#-polort A \
	#-num_stimts 13 \
	#-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
	#-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
	#-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
	#-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
	#-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
	#-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
	#-stim_times  7  ${TF1} "BLOCK(0.1,1)"  -stim_label 7 $L1 \
	#-stim_times  8  ${TF2} "BLOCK(0.1,1)"  -stim_label 8 $L2 \
	#-stim_times  9  ${TF3} "BLOCK(0.1,1)"  -stim_label 9 $L3 \
	#-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"  -stim_label 10 $L4 \
	#-stim_times_AM2  11  ${TF5} "dmBLOCK(1)"  -stim_label 11 $L5 \
	#-stim_times_AM2  12  ${TF6} "dmBLOCK(1)"  -stim_label 12 $L6 \
	#-stim_times_AM2  13  ${TF7} "dmBLOCK(1)"  -stim_label 13 $L7 \
	#-censor "motion_censor_vector_All.txt[0]" \
	#-fout -tout -x1D ${out}.xmat.1D \
	#-bucket stats_${out} -cbucket cstats_${out} \
	#-jobs 6
#fi




## Deconv2 - Brik for each Odorant (Mask, CA, FBO, UBO)
if [ ! -f stats_AODecon2+tlrc.HEAD ]; then

	TF1=${string}_ENI1.txt;		L1=ENI1
	TF2=${string}_RI.txt; 		L2=RI
	TF3=${string}_RP.txt; 		L3=RP
	TF4=${string}_Jit1.txt;		L4=ENI2
	TF5=${string}_MASK.txt;		L5=Mask
	TF6=${string}_FBO.txt; 		L6=FBO
	TF7=${string}_UBO.txt; 		L7=UBO
	TF8=${string}_CA.txt;  		L8=CA

	out=AODecon2

	3dDeconvolve \
	-input $input \
	-mask Template_mask+tlrc \
	-polort A \
	-num_stimts 14 \
	-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
	-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
	-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
	-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
	-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
	-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
	-stim_times		  7  ${TF1} "BLOCK(0.5,1)" -stim_label  7 $L1 \
	-stim_times		  8  ${TF2} "BLOCK(6,1)"   -stim_label  8 $L2 \
	-stim_times		  9  ${TF3} "BLOCK(6,1)"   -stim_label  9 $L3 \
	-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"   -stim_label 10 $L4 \
	-stim_times_AM2  11  ${TF5} "dmBLOCK(1)"   -stim_label 11 $L5 \
	-stim_times_AM2  12  ${TF6} "dmBLOCK(1)"   -stim_label 12 $L6 \
	-stim_times_AM2  13  ${TF7} "dmBLOCK(1)"   -stim_label 13 $L7 \
	-stim_times_AM2  14  ${TF8} "dmBLOCK(1)"   -stim_label 14 $L8 \
	-censor "motion_censor_vector_All.txt[0]" \
	-fout -tout -x1D ${out}.xmat.1D \
	-bucket stats_${out} -cbucket cstats_${out} \
	-jobs 6
fi




## Deconv3 - Mask+FBO+UBO vs CA
# Make new behVectors - TF Col1 = CA, Col2 = Odor

#if [ ! -f ${subj}_CA_Odor_behVect.01.1D ]; then

	#if [ ! -f ${string}_CA_Odor.txt ]; then
		#cp ${timingDir}/${string}_CA_Odor.txt .
	#fi

	#PRE=${subj}_CA_Odor_behVect
	#TR=0.1
	#NRUN=3
	#NT=2820

	#make_stim_times.py -files ${string}_CA_Odor.txt -prefix $PRE -tr $TR -nruns $NRUN -nt $NT
#fi


if [ ! -f stats_AODecon3+tlrc.HEAD ]; then

	TF1=${string}_ENI1.txt;		L1=ENI1
	TF2=${string}_RI.txt; 		L2=RI
	TF3=${string}_RP.txt; 		L3=RP
	TF4=${string}_Jit1.txt;		L4=ENI2
	TF5=${string}_CA.txt;		L5=CA
	TF6=${string}_Odor.txt; 	L6=Odor

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
	-stim_times		  7  ${TF1} "BLOCK(0.5,1)"  -stim_label  7 $L1 \
	-stim_times		  8  ${TF2} "BLOCK(6,1)"    -stim_label  8 $L2 \
	-stim_times		  9  ${TF3} "BLOCK(6,1)"    -stim_label  9 $L3 \
	-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"    -stim_label 10 $L4 \
	-stim_times_AM2	 11  ${TF5} "dmBLOCK(1)"  	-stim_label 11 $L5 \
	-stim_times_AM2	 12  ${TF6} "dmBLOCK(1)"	-stim_label 12 $L6 \
	-censor "motion_censor_vector_All.txt[0]" \
	-fout -tout -x1D ${out}.xmat.1D \
	-bucket stats_${out} -cbucket cstats_${out} \
	-jobs 6
fi




## Deconv4 - FBO+UBO vs CA, Brik for Mask
if [ ! -f stats_AODecon4+tlrc.HEAD ]; then

	TF1=${string}_ENI1.txt;		L1=ENI1
	TF2=${string}_RI.txt; 		L2=RI
	TF3=${string}_RP.txt; 		L3=RP
	TF4=${string}_Jit1.txt;		L4=ENI2
	TF5=${string}_CA.txt;		L5=CA
	TF6=${string}_MASK.txt; 	L6=Mask
	TF7=${string}_FUBO.txt; 	L7=FUBO

	out=AODecon4

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
	-stim_times		  7  ${TF1} "BLOCK(0.5,1)"  -stim_label  7 $L1 \
	-stim_times		  8  ${TF2} "BLOCK(6,1)"    -stim_label  8 $L2 \
	-stim_times		  9  ${TF3} "BLOCK(6,1)"    -stim_label  9 $L3 \
	-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"    -stim_label 10 $L4 \
	-stim_times_AM2	 11  ${TF5} "dmBLOCK(1)"  	-stim_label 11 $L5 \
	-stim_times_AM2  12  ${TF6} "dmBLOCK(1)"    -stim_label 12 $L6 \
	-stim_times_AM2  13  ${TF7} "dmBLOCK(1)"    -stim_label 13 $L7 \
	-censor "motion_censor_vector_All.txt[0]" \
	-fout -tout -x1D ${out}.xmat.1D \
	-bucket stats_${out} -cbucket cstats_${out} \
	-jobs 6
fi










