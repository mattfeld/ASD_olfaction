#!/bin/bash


### This is just a request for supercomputer resources

#SBATCH --time=05:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "AOppi8.3"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE



# Written by Nathan Muncy on 7/20/18

### Notes:
#
# This is a variation of 8.2, written for analyses on concatenated Odors vs CA




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
seedCoord=("20 0 -20" "-26 1 -20" "17 42 -5" "27 -58 26" "41 50 23" "20 -20 41" "17 -84 46" "-32 -80 41" "-40 -75 38" "-63 -13 27" "54 -54 -22" "15 -50 53")
seedName=({1,2,3,4,5,6,7,8a,8b,9,10,11}_d3)
seedLen=${#seedCoord[@]}

TR=2
allRuns="scale_BORun1_ANTS_resampled+tlrc scale_BORun2_ANTS_resampled+tlrc scale_BORun3_ANTS_resampled+tlrc"
string=${subj/BO}


### Do work
cd $ppiDir


if [ ! -f CleanData3+tlrc.HEAD ]; then

	### Create volume of unwanted data
	# replace censored TRs with mean of neighbors
	select="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 17"
	3dSynthesize -prefix effNoInt_AODecon3 -matrix AODecon3.xmat.1D \
	-cbucket cstats_AODecon3+tlrc -select $select -cenfill nbhr


	### Create cleaned data by subtracting out unwanted regressors
	# This is used to extract desired time series
	3dTcat -prefix all_runs3 -tr $TR $allRuns
	3dcalc -a all_runs3+tlrc -b effNoInt_AODecon3+tlrc -expr 'a-b' -prefix CleanData3
fi



### Make regressors for CA, Odor
if [ ! -f Beh_OD_CAO_contrast.1D ]; then

	cat ${string}_CA_Odor.txt | awk '{print $1}' > tmp_CA_CAO.txt
	cat ${string}_CA_Odor.txt | awk '{print $2}' > tmp_OD_CAO.txt

	ConvertDset -o_1D -input tmp_CA_CAO.txt -prefix Beh_CA_CAO_contrast
	ConvertDset -o_1D -input tmp_OD_CAO.txt -prefix Beh_OD_CAO_contrast

	mv Beh_CA_CAO_contrast.1D.dset Beh_CA_CAO_contrast.1D
	mv Beh_OD_CAO_contrast.1D.dset Beh_OD_CAO_contrast.1D
fi



c=0; while [ $c -lt $seedLen ]; do

	### Make seeds
	seed=Seed_${seedName[$c]}
	ref=scale_BORun1_ANTS_resampled+tlrc

	if [ ! -f ${seed}+tlrc.HEAD ]; then

		echo ${seedCoord[$c]} > ${seed}.txt
		3dUndump -prefix $seed -master $ref -srad 3 -xyz ${seed}.txt
	fi


	### Get seed TS, separate BOLD from neural response
	if [ ! -f ${seed}_neural.1D ]; then

		3dmaskave -quiet -mask ${seed}+tlrc CleanData3+tlrc > ${seed}_timeSeries.1D
		3dTfitter -RHS ${seed}_timeSeries.1D -FALTUNG ClassicBold.1D ${seed}_neural 012 0
	fi


	### get context-dependant seed TS
	if [ ! -f ${seed}_bold_beh_Mask.1D ]; then

		1dtranspose ${seed}_neural.1D > Trans_${seed}_neural.1D
		data=(`cat Trans_${seed}_neural.1D`)
		dataLen=${#data[@]}


		# Resample seed TS to high-res time (to match Beh time)
		> HRes_${seed}.txt
		cc=0; while [ $cc -lt $dataLen ]; do
			for((i=1; i<=20; i++)); do
				echo ${data[$cc]} >> HRes_${seed}.txt
			done
			let cc=$[$cc+1]
		done
		ConvertDset -o_1D -input HRes_${seed}.txt -prefix HRes_${seed}_neural
		mv HRes_${seed}_neural.1D.dset HRes_${seed}_neural.1D


		num=`cat Trans_${seed}_neural.1D | wc -l`
		for x in Mask {CA,OD}_CAO; do

			# extract behavioral TS for seed
			1deval -a HRes_${seed}_neural.1D -b Beh_${x}_contrast.1D -expr 'a*b' > ${seed}_neural_${x}_beh.1D

			# sample back to normal res time
			cat ${seed}_neural_${x}_beh.1D | awk -v n=20 'NR%n==0' > NRes_${seed}_${x}.txt
			ConvertDset -o_1D -input NRes_${seed}_${x}.txt -prefix NRes_${seed}_neural_${x}
			mv NRes_${seed}_neural_${x}.1D.dset NRes_${seed}_neural_${x}.1D

			# add BOLD back
			waver -GAM -peak 1 -dt $TR -input NRes_${seed}_neural_${x}.1D -numout $num > ${seed}_bold_beh_${x}.1D
		done
	fi

	let c=$[$c+1]
done



### Do second Deconvolution
a=0; while [ $a -lt $seedLen ]; do

	TF1=${subj}_TF_behVect.01.1D; L1=ENI1
	TF2=${subj}_TF_behVect.02.1D; L2=RI
	TF3=${subj}_TF_behVect.03.1D; L3=RP
	TF4=${subj}_CA_Odor_behVect.01.1D; L4=CA
	TF5=${subj}_CA_Odor_behVect.02.1D; L5=Odor

	string=${subj/BO}
	TF6=${string}_Jit1.txt; L6=ENI2

	seed=Seed_${seedName[$a]}
	roiTS=${seed}_timeSeries.1D;
	CABeh=${seed}_bold_beh_CA_CAO.1D
	ODBeh=${seed}_bold_beh_OD_CAO.1D


	output3=FINAL_Indiv_${seed#*_}

	if [ ! -f ${output3}+tlrc.HEAD ]; then

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
		-stim_times  10  ${TF4} "BLOCK(0.1,1)"  -stim_label 10 $L4 \
		-stim_times  11  ${TF5} "BLOCK(0.1,1)"  -stim_label 11 $L5 \
		-stim_times_AM1  12  ${TF6} "dmBLOCK(1)"  -stim_label 12 $L6 \
		-stim_file   	 13  $roiTS               -stim_label 13 Seed \
		-stim_file   	 14  $CABeh               -stim_label 14 Int.CA \
		-stim_file   	 15  $ODBeh               -stim_label 15 Int.OD \
		-censor "motion_censor_vector_All.txt[0]" \
		-bucket $output3 \
		-errts errts_$output3 \
		-rout -tout \
		-jobs 6 -GOFORIT 12
	fi

	let a=$[$a+1]
done





