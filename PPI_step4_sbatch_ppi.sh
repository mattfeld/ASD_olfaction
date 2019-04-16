#!/bin/bash


### This is just a request for supercomputer resources

#SBATCH --time=05:00:00   # walltime
#SBATCH --ntasks=4   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=4gb   # memory per CPU core
#SBATCH -J "PPI4"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE




# Written by Nathan Muncy on 7/26/18

### Notes:
#
# This script will do basic pre-processing and deconvolution of the data
# in preparation for the PPI analysis.
#
# Each major step (###) is annotated, and some additional notes (#) are left as well.




# General Variables
workDir=~/compute/AutismOlfactory
tempDir=${workDir}/Template
scriptDir=${workDir}/Scripts
timingDir=${workDir}/derivatives/TimingFiles


# Subject Variables
subj=$1
string=${subj#*-}
ppiDir=${workDir}/derivatives/${subj}


# Arrays
deconList=(FUMC FUMvC FUvC)
behInterest=(MASK FBO UBO CA Odor)

seedCoord=("-27 -14 -22")
seedName=(LHC)
seedLen=${#seedCoord[@]}




### Functions
MatchString () {

	local e match="$1"

	shift
	for e; do
		[[ "$e" == "$match" ]] && return 0
	done
	return 1
}




### --- Set up --- ###
#
# Create a clean version of each deconvolution by remove effects of no interest.
# Simulate an ideal BOLD response, and generate behavioral contrasts.


cd $ppiDir

# determine input
unset input
for a in *scale+tlrc.HEAD; do
	file=${a%.*}
	input+="$file "
done


# set reference variables
firstScale="$(set -- *scale+tlrc.HEAD; echo "$1")"
ref=${firstScale%.*}
TR=`3dinfo -tr $ref`


### Make clean data
for i in ${deconList[@]}; do
	if [ ! -f tmp_CleanData_${i}+tlrc.HEAD ]; then

		# Determine effects of no interest - those not in $behInterest
		hold=`grep ColumnLabels X.${i}.xmat.1D | sed 's/\#//g' | sed 's/\;//g'`
		tmp=${hold#*\"}; colLab=(${tmp%\"*})

		unset sel
		for j in ${!colLab[@]}; do
			tmp1=${colLab[$j]#*_}; test=${tmp1%?*}
			MatchString $test "${behInterest[@]}"
			if [ $? == 1 ]; then
				sel+="$j "
			fi
		done


		# remove extra sub-brick added by 3dREMlfit
		sub=`3dinfo -nv ${i}_cbucket_REML+tlrc`
		less=$(($sub-2))
		3dTcat -prefix tmp_${i}_cbucket -tr $TR "${i}_cbucket_REML+tlrc[0..${less}]"


		# create file of unwanted data, replace censored TRs w/mean of neighbors
		3dSynthesize -prefix tmp_effNoInt_AO_${i} -matrix X.${i}.xmat.1D \
		-cbucket tmp_${i}_cbucket+tlrc -select $sel -cenfill nbhr


		# remove unwanted regressors from combined run to produce Clean Data
		3dTcat -prefix tmp_all_runs_${i} -tr $TR $input
		3dcalc -a tmp_all_runs_${i}+tlrc -b tmp_effNoInt_AO_${i}+tlrc -expr 'a-b' -prefix tmp_CleanData_${i}
	fi
done


# Create ideal response function
if [ ! -f ClassicBold.1D ]; then
	waver -dt $TR -GAM -inline 1@1 > ClassicBold.1D
fi


### Create behavior vectors
if [ ! -s Beh_FUBO_contrast.1D ]; then

	cp ${timingDir}/Contrast/${string}_ppi.txt .
	count=`cat ${string}_ppi.txt | wc -l`

	> FBO_contrast.txt
	> UBO_contrast.txt
	> FUBO_contrast.txt


	# Extract ppi.txt info
	for(( a=1; a<=$count; a++ )); do

		value=`sed -n ${a}p ${string}_ppi.txt`


		# FBO & UBO
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


		# FUBO
		if [ $value != 0 ]; then
			echo "1" >> FUBO_contrast.txt
		else
			echo "0" >> FUBO_contrast.txt
		fi
	done

	ConvertDset -o_1D -input FBO_contrast.txt -prefix Beh_FBO_contrast && mv Beh_FBO_contrast.1D.dset Beh_FBO_contrast.1D
	ConvertDset -o_1D -input UBO_contrast.txt -prefix Beh_UBO_contrast && mv Beh_UBO_contrast.1D.dset Beh_UBO_contrast.1D
	ConvertDset -o_1D -input FUBO_contrast.txt -prefix Beh_FUBO_contrast && mv Beh_FUBO_contrast.1D.dset Beh_FUBO_contrast.1D
fi


# CA & Mask
if [ ! -f Beh_Mask_contrast.1D ]; then

	cp ${timingDir}/${string}_TF_* .
	ConvertDset -o_1D -input ${string}_TF_Mask.txt -prefix Beh_Mask_contrast && mv Beh_Mask_contrast.1D.dset Beh_Mask_contrast.1D
	ConvertDset -o_1D -input ${string}_TF_CA.txt -prefix Beh_CA_contrast && mv Beh_CA_contrast.1D.dset Beh_CA_contrast.1D
fi


# Odor
if [ ! -f Beh_OD_contrast.1D ]; then

	cp ${timingDir}/${string}_CA_Odor.txt .
	cat ${string}_CA_Odor.txt | awk '{print $2}' > tmp_OD.txt
	ConvertDset -o_1D -input tmp_OD.txt -prefix Beh_OD_contrast && mv Beh_OD_contrast.1D.dset Beh_OD_contrast.1D
fi


# Make list of contrasts
c=0; for a in Beh*contrast.1D; do

	tmp=${a#*_}
	conList[$c]=${tmp%_*}
	let c=$[$c+1]
done




### --- Extract Seed Time Series --- ###
#
# Construct seeds, and extract mean time series (TS) from Clean Data.
# TS is deconvolved for BOLD response, rendering "neural" TS.
# Functional TR = 2000 ms, stimulus duration is measured in 100 ms,
# so the TS is upsampled in order to extract "neural" TS associated
# w/the behavior.
# Then the TS is downsampled and reconvolved with BOLD to generate
# a task-associated BOLD TS.


# Get seed TS from e/deconvolution
c=0; while [ $c -lt $seedLen ]; do


	# Make seeds
	seed=Seed_${seedName[$c]}

	if [ ! -f ${seed}+tlrc.HEAD ]; then
		echo ${seedCoord[$c]} > tmp_${seed}.txt
		3dUndump -prefix $seed -master $ref -srad 3 -xyz tmp_${seed}.txt
	fi

	for j in ${deconList[@]}; do
		if [ ! -f tmp_HRes_${seed}_${j}_neural.1D ] && [ ! -f ${seed}_${j}_TS_CA.1D ]; then


			# Get seed TS from each CleanData, solve RHS for neural
			3dmaskave -quiet -mask ${seed}+tlrc tmp_CleanData_${j}+tlrc > ${seed}_${j}_timeSeries.1D
			3dTfitter -RHS ${seed}_${j}_timeSeries.1D -FALTUNG ClassicBold.1D tmp_${seed}_${j}_neural 012 0


			# Resample seed TS from 2s to 0.1s resolution (HRes)
			> tmp_HRes_${seed}_${j}.txt
			1dtranspose tmp_${seed}_${j}_neural.1D > tmp_Trans_${seed}_${j}_neural.1D
			data=(`cat tmp_Trans_${seed}_${j}_neural.1D`)
			dataLen=${#data[@]}

			cc=0; while [ $cc -lt $dataLen ]; do
				for((i=1; i<=20; i++)); do
					echo ${data[$cc]} >> tmp_HRes_${seed}_${j}.txt
				done
				let cc=$[$cc+1]
			done


			# Create 1D file
			ConvertDset -o_1D -input tmp_HRes_${seed}_${j}.txt -prefix tmp_HRes_${seed}_${j}_neural
			mv tmp_HRes_${seed}_${j}_neural.1D.dset tmp_HRes_${seed}_${j}_neural.1D
		fi
	done

	let c=$[$c+1]
done




#### Extract behavior TS from appropriate deconv from e/seed
#for i in ${seedName[@]}; do
	#for j in ${conList[@]}; do

		## Determine deconv
		#if [ $j == CA ]; then
				#arr=(2 3 4)
			#elif [ $j == FUBO ]; then
				#arr=(4)
			#elif [ $j == OD ]; then
				#arr=(3)
			#else
				#arr=(2)
		#fi

		#for k in ${arr[@]}; do
			#if [ ! -f Seed_${i}_d${k}_TS_${j}.1D ]; then

				## Extract seed beh neural timeseries, resample back to 2s (LRes)
				#1deval -a tmp_HRes_Seed_${i}_d${k}_neural.1D -b Beh_${j}_contrast.1D -expr 'a*b' > tmp_Seed_${i}_d${k}_neural_${j}_beh.1D
				#cat tmp_Seed_${i}_d${k}_neural_${j}_beh.1D | awk -v n=20 'NR%n==0' > tmp_LRes_Seed_${i}_d${k}_${j}.txt
				#ConvertDset -o_1D -input tmp_LRes_Seed_${i}_d${k}_${j}.txt -prefix tmp_LRes_Seed_${i}_d${k}_neural_${j}
				#mv tmp_LRes_Seed_${i}_d${k}_neural_${j}.1D.dset tmp_LRes_Seed_${i}_d${k}_neural_${j}.1D

				## add BOLD back to TS
				#num=`cat tmp_Trans_Seed_${i}_d${k}_neural.1D | wc -l`
				#waver -GAM -peak 1 -dt $TR -input tmp_LRes_Seed_${i}_d${k}_neural_${j}.1D -numout $num > Seed_${i}_d${k}_TS_${j}.1D
			#fi
		#done
	#done
#done


## Clean
#if [ $2 != T ]; then
	#rm tmp*
#fi




#### Deconvolve again, with new interaction terms, for each seed
#for i in ${seedName[@]}; do
	#for j in ${deconList[@]}; do

		#output=FINAL_${i#*_}_d${j}

		#if [ $j == 2 ]; then

			## Compare all Stimuli (decon2)
			#TF1=${string}_ENI1.txt;		L1=ENI1
			#TF2=${string}_RI.txt; 		L2=RI
			#TF3=${string}_RP.txt; 		L3=RP
			#TF4=${string}_Jit1.txt;		L4=ENI2
			#TF5=${string}_MASK.txt;		L5=Mask
			#TF6=${string}_FBO.txt; 		L6=FBO
			#TF7=${string}_UBO.txt; 		L7=UBO
			#TF8=${string}_CA.txt;  		L8=CA

			#seedTS=Seed_${i}_d2_timeSeries.1D
			#fboBeh=Seed_${i}_d2_TS_FBO.1D
			#uboBeh=Seed_${i}_d2_TS_UBO.1D
			#MaskBeh=Seed_${i}_d2_TS_Mask.1D
			#CABeh=Seed_${i}_d2_TS_CA.1D

			#if [ ! -f ${output}+tlrc.HEAD ]; then

				#3dDeconvolve \
				#-input $input \
				#-mask Template_mask+tlrc \
				#-polort A \
				#-num_stimts 19 \
				#-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
				#-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
				#-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
				#-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
				#-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
				#-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
				#-stim_times		  7  ${TF1} "BLOCK(0.5,1)" -stim_label  7 $L1 \
				#-stim_times		  8  ${TF2} "BLOCK(6,1)"   -stim_label  8 $L2 \
				#-stim_times		  9  ${TF3} "BLOCK(6,1)"   -stim_label  9 $L3 \
				#-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"   -stim_label 10 $L4 \
				#-stim_times_AM2  11  ${TF5} "dmBLOCK(1)"   -stim_label 11 $L5 \
				#-stim_times_AM2  12  ${TF6} "dmBLOCK(1)"   -stim_label 12 $L6 \
				#-stim_times_AM2  13  ${TF7} "dmBLOCK(1)"   -stim_label 13 $L7 \
				#-stim_times_AM2  14  ${TF8} "dmBLOCK(1)"   -stim_label 14 $L8 \
				#-stim_file   	 15  $seedTS               -stim_label 15 Seed \
				#-stim_file   	 16  $fboBeh               -stim_label 16 Int.FBO \
				#-stim_file   	 17  $uboBeh               -stim_label 17 Int.UBO \
				#-stim_file   	 18  $MaskBeh              -stim_label 18 Int.Mask \
				#-stim_file   	 19  $CABeh                -stim_label 19 Int.CA \
				#-censor "motion_censor_vector_All.txt[0]" \
				#-bucket $output \
				#-errts errts_$output \
				#-rout -tout \
				#-jobs 6 -GOFORIT 12
			#fi

		#elif [ $j == 3 ]; then

			## Compare Odors (Mask+FBO+UBO) to CA (decon3)
			#TF1=${string}_ENI1.txt;		L1=ENI1
			#TF2=${string}_RI.txt; 		L2=RI
			#TF3=${string}_RP.txt; 		L3=RP
			#TF4=${string}_Jit1.txt;		L4=ENI2
			#TF5=${string}_CA.txt;		L5=CA
			#TF6=${string}_Odor.txt; 	L6=Odor

			#seedTS=Seed_${i}_d3_timeSeries.1D
			#CABeh=Seed_${i}_d3_TS_CA.1D
			#ODBeh=Seed_${i}_d3_TS_OD.1D

			#if [ ! -f ${output}+tlrc.HEAD ]; then

				#3dDeconvolve \
				#-input $input \
				#-mask Template_mask+tlrc \
				#-polort A \
				#-num_stimts 15 \
				#-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
				#-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
				#-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
				#-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
				#-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
				#-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
				#-stim_times		  7  ${TF1} "BLOCK(0.5,1)"  -stim_label  7 $L1 \
				#-stim_times		  8  ${TF2} "BLOCK(6,1)"    -stim_label  8 $L2 \
				#-stim_times		  9  ${TF3} "BLOCK(6,1)"    -stim_label  9 $L3 \
				#-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"    -stim_label 10 $L4 \
				#-stim_times_AM2	 11  ${TF5} "dmBLOCK(1)"  	-stim_label 11 $L5 \
				#-stim_times_AM2	 12  ${TF6} "dmBLOCK(1)"	-stim_label 12 $L6 \
				#-stim_file   	 13  $seedTS               	-stim_label 13 Seed \
				#-stim_file   	 14  $CABeh               	-stim_label 14 Int.CA \
				#-stim_file   	 15  $ODBeh               	-stim_label 15 Int.OD \
				#-censor "motion_censor_vector_All.txt[0]" \
				#-bucket $output \
				#-errts errts_$output \
				#-rout -tout \
				#-jobs 6 -GOFORIT 12
			#fi

		#elif [ $j == 4 ]; then

			## Compare Body odors (FBO+UBO) to CA (decon4)
			#TF1=${string}_ENI1.txt;		L1=ENI1
			#TF2=${string}_RI.txt; 		L2=RI
			#TF3=${string}_RP.txt; 		L3=RP
			#TF4=${string}_Jit1.txt;		L4=ENI2
			#TF5=${string}_CA.txt;		L5=CA
			#TF6=${string}_MASK.txt; 	L6=Mask
			#TF7=${string}_FUBO.txt; 	L7=FUBO

			#seedTS=Seed_${i}_d4_timeSeries.1D
			#CABeh=Seed_${i}_d4_TS_CA.1D
			#FUBeh=Seed_${i}_d4_TS_FUBO.1D

			#if [ ! -f ${output}+tlrc.HEAD ]; then

				#3dDeconvolve \
				#-input $input \
				#-mask Template_mask+tlrc \
				#-polort A \
				#-num_stimts 16 \
				#-stim_file   1  "motion_All[0]" -stim_label 1 "Roll"  -stim_base 1 \
				#-stim_file   2  "motion_All[1]" -stim_label 2 "Pitch" -stim_base 2 \
				#-stim_file   3  "motion_All[2]" -stim_label 3 "Yaw"   -stim_base 3 \
				#-stim_file   4  "motion_All[3]" -stim_label 4 "dS"    -stim_base 4 \
				#-stim_file   5  "motion_All[4]" -stim_label 5 "dL"    -stim_base 5 \
				#-stim_file   6  "motion_All[5]" -stim_label 6 "dP"    -stim_base 6 \
				#-stim_times		  7  ${TF1} "BLOCK(0.5,1)"  -stim_label  7 $L1 \
				#-stim_times		  8  ${TF2} "BLOCK(6,1)"    -stim_label  8 $L2 \
				#-stim_times		  9  ${TF3} "BLOCK(6,1)"    -stim_label  9 $L3 \
				#-stim_times_AM2  10  ${TF4} "dmBLOCK(1)"    -stim_label 10 $L4 \
				#-stim_times_AM2	 11  ${TF5} "dmBLOCK(1)"  	-stim_label 11 $L5 \
				#-stim_times_AM2  12  ${TF6} "dmBLOCK(1)"    -stim_label 12 $L6 \
				#-stim_times_AM2  13  ${TF7} "dmBLOCK(1)"    -stim_label 13 $L7 \
				#-stim_file   	 14  $seedTS               	-stim_label 14 Seed \
				#-stim_file   	 15  $CABeh               	-stim_label 15 Int.CA \
				#-stim_file   	 16  $FUBeh               	-stim_label 16 Int.FU \
				#-censor "motion_censor_vector_All.txt[0]" \
				#-bucket $output \
				#-errts errts_$output \
				#-rout -tout \
				#-jobs 6 -GOFORIT 12
			#fi
		#fi
	#done
#done
