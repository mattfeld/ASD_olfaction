#!/bin/bash


### This is just a request for supercomputer resources

#SBATCH --time=05:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "AOppi8"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE



# Written by Nathan Muncy on 4/15/18

### Notes:
#
# This script will do basic pre-processing and deconvolution of the data
# in preparation for the PPI analysis.
#
# Each major step (###) is annotated, and some additional notes (#) are left as well.




### Set Up

# General Variables
workDir=~/compute/AutismOlfactory
tempDir=${workDir}/Template
scriptDir=${workDir}/Scripts
timingDir=${workDir}/TimingFiles


# Subject Variables
subj=$1
ppiDir=${workDir}/${subj}/ppi_data


# Arrays, other variables
seedCoord=("-29 1 -18" "27 2 -21" "16 41 -2" "26 -58 28")
seedName=(LPF RPF RAWM RPWM)	  		 				      # L/RPF = left/right piriform
seedLen=${#seedCoord[@]}

TR=2
allRuns="scale_BORun1_ANTS_resampled+tlrc scale_BORun2_ANTS_resampled+tlrc scale_BORun3_ANTS_resampled+tlrc"
string=${subj/BO}



### Do work
cd $ppiDir

if [ ! -f CleanData+tlrc.HEAD ]; then

	### Create volume of unwanted data
	# replace censored TRs with mean of neighbors
	select="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 18"
	3dSynthesize -prefix effNoInt_AODecon1 -matrix AODecon1.xmat.1D \
	-cbucket cstats_AODecon1+tlrc -select $select -cenfill nbhr


	### Create cleaned data by subtracting out unwanted regressors
	# This is used to extract desired time series
	3dTcat -prefix all_runs -tr $TR $allRuns
	3dcalc -a all_runs+tlrc -b effNoInt_AODecon1+tlrc -expr 'a-b' -prefix CleanData
fi


### Create ideal response function
if [ ! -f ClassicBold.1D ]; then

	waver -dt $TR -GAM -inline 1@1 > ClassicBold.1D
fi


### Create contrast vector and adjust the file
#
# Explanation: The contrast vector will extract Behavior1 via 1 x timeseries, Behavior2 via -1 x timeseries
# 	and exclude irrelevant signal via 0 x timeseries. Since Behavior2 may not necessarily have an
# 	opposite BOLD signal of Behavior1, I multiply the data by the contrast matrix again (Adjust),
# 	so -1 x -1 will allow Behavior2 to have positive values.

if [ ! -f Beh_FUBO_contrast.1D ]; then

	cp ${timingDir}/Contrast/${string}_ppi.txt .

	ConvertDset -o_1D -input ${string}_ppi.txt -prefix Beh_FUBO_contrast
	ConvertDset -o_1D -input ${string}_ppi.txt -prefix Adjust_FUBO

	mv Beh_FUBO_contrast.1D.dset Beh_FUBO_contrast.1D
	mv Adjust_FUBO.1D.dset Adjust_FUBO.1D
fi


### New part: creating single behavior regressors
if [ ! -f FBO_contrast.1D ]; then

	count=`cat ${string}_ppi.txt | wc -l`

	> FBO_contrast.txt
	> UBO_contrast.txt

	for(( a=1; a<=$count; a++ )); do

		value=`sed -n ${a}p ${string}_ppi.txt`

		if [ $value == 1 ]; then

			echo "1" >> FBO_contrast.txt
			echo "0" >> UBO_contrast.txt

		elif [ $value == -1 ]; then

			echo "0" >> FBO_contrast.txt
			echo "1" >> UBO_contrast.txt

		else
			echo "0" >> FBO_contrast.txt
			echo "0" >> UBO_contrast.txt
		fi
	done

	ConvertDset -o_1D -input FBO_contrast.txt -prefix Beh_FBO_contrast
	ConvertDset -o_1D -input UBO_contrast.txt -prefix Beh_UBO_contrast

	mv Beh_FBO_contrast.1D.dset Beh_FBO_contrast.1D
	mv Beh_UBO_contrast.1D.dset Beh_UBO_contrast.1D
fi




c=0; while [ $c -lt $seedLen ]; do

	### Make seeds
	seed=Seed_${seedName[$c]}
	ref=scale_BORun1_ANTS_resampled+tlrc

	if [ ! -f ${seed}+tlrc.HEAD ]; then

		echo ${seedCoord[$c]} > ${seed}.txt
		3dUndump -prefix $seed -master $ref -srad 3 -xyz ${seed}.txt
	fi


	### Get timeseries of seed, separate BOLD from neural response
	if [ ! -f ${seed}_neural.1D ]; then

		3dmaskave -quiet -mask ${seed}+tlrc CleanData+tlrc > ${seed}_timeSeries.1D
		3dTfitter -RHS ${seed}_timeSeries.1D -FALTUNG ClassicBold.1D ${seed}_neural 012 0
	fi


	if [ ! -f ${seed}_bold_beh_FBO.1D ]; then

		number=`cat ${string}_ppi.txt | wc -l`
		1dtranspose ${seed}_neural.1D > Trans_${seed}_neural.1D


		### Patch:
		# Trans*_neural.1D has a temporal resolution of 2 seconds, Beh*_contrast.1D
		# has a resolution of 0.1 seconds, so I'm going to resample Trans into a higher
		# resolution (0.1s) so it lines up with Beh*. This will allow me to extract
		# the relevant data.

		data=(`cat Trans_${seed}_neural.1D`)
		dataLen=${#data[@]}

		> HRes_${seed}.txt
		cc=0; while [ $cc -lt $dataLen ]; do
			for((i=1; i<=20; i++)); do
				echo ${data[$cc]} >> HRes_${seed}.txt
			done
			let cc=$[$cc+1]
		done
		ConvertDset -o_1D -input HRes_${seed}.txt -prefix HRes_${seed}_neural
		mv HRes_${seed}_neural.1D.dset HRes_${seed}_neural.1D


		### Extract relevant timeseries, adjust it
		1deval -a HRes_${seed}_neural.1D -b Beh_FUBO_contrast.1D -expr 'a*b' > ${seed}_neural_FUBO_beh.1D
		1deval -a ${seed}_neural_FUBO_beh.1D -b Adjust_FUBO.1D -expr 'a*b' > ${seed}_neural_FUBO_beh_adjusted.1D

		for x in {F,U}BO; do
			1deval -a HRes_${seed}_neural.1D -b Beh_${x}_contrast.1D -expr 'a*b' > ${seed}_neural_${x}_beh.1D
		done


		### Resample back into 2s resolution, pull only appropriate data
		cat ${seed}_neural_FUBO_beh_adjusted.1D | awk -v n=20 'NR%n==0' > NRes_${seed}_FUBO.txt
		ConvertDset -o_1D -input NRes_${seed}_FUBO.txt -prefix NRes_${seed}_neural_FUBO
		mv NRes_${seed}_neural_FUBO.1D.dset NRes_${seed}_neural_FUBO.1D


		### add BOLD back to timeseries
		num=`cat Trans_${seed}_neural.1D | wc -l`
		waver -GAM -peak 1 -dt $TR -input NRes_${seed}_neural_FUBO.1D -numout $num > ${seed}_bold_beh_FUBO.1D


		### Repeat previous 2 steps for F/UBO
		for x in {F,U}BO; do

			cat ${seed}_neural_${x}_beh.1D | awk -v n=20 'NR%n==0' > NRes_${seed}_${x}.txt
			ConvertDset -o_1D -input NRes_${seed}_${x}.txt -prefix NRes_${seed}_neural_${x}
			mv NRes_${seed}_neural_${x}.1D.dset NRes_${seed}_neural_${x}.1D
			waver -GAM -peak 1 -dt $TR -input NRes_${seed}_neural_${x}.1D -numout $num > ${seed}_bold_beh_${x}.1D
		done
	fi

	let c=$[$c+1]
done




### Do second Deconvolution, for each seed. Very similar to 1st deconvolution
# The effect of interest is labeled Int.*, which is where any voxels with a
# similar time series will load.

a=0; while [ $a -lt $seedLen ]; do

	TF1=${subj}_TF_behVect.01.1D; L1=ENI1
	TF2=${subj}_TF_behVect.02.1D; L2=RI
	TF3=${subj}_TF_behVect.03.1D; L3=RP

	TF4=${string}_Jit1.txt; L4=ENI2
	TF5=${string}_FBO.txt;  L5=Fam
	TF6=${string}_UBO.txt;  L6=NFam
	TF7=${string}_CA.txt;   L7=CA

	seed=Seed_${seedName[$a]}
	bothBeh=${seed}_bold_beh_FUBO.1D
	fboBeh=${seed}_bold_beh_FBO.1D
	uboBeh=${seed}_bold_beh_UBO.1D
	roiTS=${seed}_timeSeries.1D

	output1=FINAL_Both_${seed#*_}
	output2=FINAL_Indiv_${seed#*_}


	# Do one for FUBO - I think this method is now outdated
	if [ ! -f ${output1}+tlrc.HEAD ]; then

		3dDeconvolve \
		-input $allRuns \
		-mask Template_mask+tlrc \
		-polort A \
		-num_stimts 15 \
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
		-stim_file   	 14  $roiTS               -stim_label 14 Seed \
		-stim_file   	 15  $bothBeh             -stim_label 15 Int.FUBO \
		-censor "motion_censor_vector_All.txt[0]" \
		-bucket $output1 \
		-errts errts_$output1 \
		-rout -tout \
		-jobs 6 -GOFORIT 12
	fi


	# Do one where behaviors are modeled separately - this is the more modern approach
	if [ ! -f ${output2}+tlrc.HEAD ]; then

		3dDeconvolve \
		-input $allRuns \
		-mask Template_mask+tlrc \
		-polort A \
		-num_stimts 16 \
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
		-stim_file   	 14  $roiTS               -stim_label 14 Seed \
		-stim_file   	 15  $fboBeh              -stim_label 15 Int.FBO \
		-stim_file   	 16  $uboBeh              -stim_label 16 Int.UBO \
		-censor "motion_censor_vector_All.txt[0]" \
		-bucket $output2 \
		-errts errts_$output2 \
		-rout -tout \
		-jobs 6 -GOFORIT 12
	fi

	let a=$[$a+1]
done





