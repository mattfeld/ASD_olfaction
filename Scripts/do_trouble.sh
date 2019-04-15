#!/bin/bash



workDir=/Volumes/Yorick/Nate_work/AutismOlfactory/BO699/ppi_data
cd $workDir



subj=BO699
string=699
input="scale_BORun1_ANTS_resampled+tlrc scale_BORun2_ANTS_resampled+tlrc scale_BORun3_ANTS_resampled+tlrc"


TF1=${subj}_TF_behVect.01.1D; 	L1=ENI1
TF2=${subj}_TF_behVect.02.1D; 	L2=RI
TF3=${subj}_TF_behVect.03.1D; 	L3=RP
TF4=${string}_Jit1.txt; 		L4=ENI2
TF5=${string}_MASK.txt; 		L5=Mask
TF6=${string}_FBO.txt;  		L6=FBO
TF7=${string}_UBO.txt;  		L7=UBO
TF8=${string}_CA.txt;   		L8=CA

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
-stim_times  7  ${TF1} "BLOCK(0.1,1)"  -stim_label 7 $L1 \
-stim_times  8  ${TF2} "BLOCK(0.1,1)"  -stim_label 8 $L2 \
-stim_times  9  ${TF3} "BLOCK(0.1,1)"  -stim_label 9 $L3 \
-stim_times_AM1  10  ${TF4} "dmBLOCK(1)"  -stim_label 10 $L4 \
-stim_times_AM1  11  ${TF5} "dmBLOCK(1)"  -stim_label 11 $L5 \
-stim_times_AM1  12  ${TF6} "dmBLOCK(1)"  -stim_label 12 $L6 \
-stim_times_AM1  13  ${TF7} "dmBLOCK(1)"  -stim_label 13 $L7 \
-stim_times_AM1  14  ${TF8} "dmBLOCK(1)"  -stim_label 14 $L8 \
-censor "motion_censor_vector_All.txt[0]" \
-fout -tout -x1D ${out}.xmat.1D \
-bucket stats_${out} -cbucket cstats_${out} \
-jobs 6
