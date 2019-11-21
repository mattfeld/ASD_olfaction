#!/bin/bash

#SBATCH --time=05:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=8gb   # memory per CPU core
#SBATCH -J "TS4"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE





# Written by Nathan Muncy on 11/2/18




### --- Set up --- ###										###??? update variables/arrays
#
# This is where the script will orient itself.
# Notes are supplied, and is the only section
# that really needs to be changed for each
# experiment.


# General variables
parDir=~/compute/AutismOlfactory
workDir=${parDir}/derivatives								# par dir of data
outDir=${parDir}/Analyses/grpAnalysis						# where output will be written (should match step3)
refFile=${workDir}/sub-1048/run-3_AO_scale+tlrc				# reference file, for finding dimensions etc

tempDir=${parDir}/Template									# desired template
priorDir=${tempDir}/priors_ACT								# location of atropos priors
mask=Intersection_GM_mask+tlrc								# this will be made, just specify name for the interesection gray matter mask

thr=0.3														# thresh value for Group_EPI_mask, ref Group_EPI_mean
blurM=2														# blur multiplier, float/int

compList=(All{FUMC,OC,SMC})										# matches decon prefixes, and will be prefix of output files
compLen=${#compList[@]}




### --- Functions --- ###

# search array for string
MatchString () {

	local e match="$1"

	shift
	for e; do
		[[ "$e" == "$match" ]] && return 0
	done
	return 1
}




### --- Create Masks --- ###
#
# This section will create a group mean intersection mask
# then threshold it at $thr to create a binary intersection mask.
# A gray matter mask will be constructed, and then the GM mask
# will be multiplied with the intersection mask to create a
# single GM intersection mask


cd $outDir

# intersection mask
if [ ! -f Group_epi_mask.nii.gz ]; then

	for i in ${workDir}/s*; do
		subj=${i##*\/}
		MatchString "$subj" "${arrRem[@]}"
		if [ $? == 1 ]; then
			list+="${i}/mask_epi_anat+tlrc "
		fi
	done

	3dMean -prefix ${outDir}/Group_epi_mean.nii.gz $list
	3dmask_tool -input $list -frac $thr -prefix ${outDir}/Group_epi_mask.nii.gz
fi


# make $mask
if [ ! -f ${mask}.HEAD ]; then

	# GM mask
	c3d ${priorDir}/Prior2.nii.gz ${priorDir}/Prior4.nii.gz -add -o tmp_Prior_GM.nii.gz
	3dresample -master $refFile -rmode NN -input tmp_Prior_GM.nii.gz -prefix tmp_Template_GM_mask.nii.gz

	# combine GM and intersection mask
	c3d tmp_Template_GM_mask.nii.gz Group_epi_mask.nii.gz -multiply -o tmp_Intersection_GM_prob_mask.nii.gz
	c3d tmp_Intersection_GM_prob_mask.nii.gz -thresh 0.1 1 1 0 -o tmp_Intersection_GM_mask.nii.gz
	3dcopy tmp_Intersection_GM_mask.nii.gz $mask
	rm tmp*
fi

if [ ! -f ${mask}.HEAD ]; then
	echo >&2
	echo "Could not construct $mask. Exit 5" >&2
	echo >&2
	exit 5
fi


# get template
if [ ! -f vold2_mni_brain+tlrc.HEAD ]; then
	cp ${tempDir}/AO_template_brain+tlrc* .
fi





### --- Set up for MVM --- ###
#
# This section will conduct noise simulations
# to model false positives using the updated version.
# Simulations will be conducted only on the GM-intersection mask


arrCount=0; while [ $arrCount -lt $compLen ]; do

	pref=${compList[$arrCount]}
	print=ACF_raw_${pref}.txt
	outPre=${pref}_MVM_REML

	# make subj list
	unset subjList
	for j in ${workDir}/s*; do

		arrRem=(`cat info_rmSubj_${pref/All}.txt`)
		subj=${j##*\/}
		MatchString "$subj" "${arrRem[@]}"
		if [ $? == 1 ]; then
			subjList+=("$subj ")
		fi
	done


	# blur, determine parameter estimate
	gridSize=`3dinfo -dk $refFile`
	blurH=`echo $gridSize*$blurM | bc`
	blurInt=`printf "%.0f" $blurH`

	if [ ! -s $print ]; then
		for k in ${subjList[@]}; do
			for m in stats errts; do

				hold=${workDir}/${k}/${pref}_${m}_REML

				# blur
				if [ ! -f ${hold}_blur${blurInt}+tlrc.HEAD ]; then
					3dmerge -prefix ${hold}_blur${blurInt} -1blur_fwhm $blurInt -doall ${hold}+tlrc
				fi
			done

			# parameter estimate
			file=${workDir}/${k}/${pref}_errts_REML_blur${blurInt}+tlrc
			3dFWHMx -mask $mask -input $file -acf >> $print
		done
	fi


	# simulate noise, determine thresholds
	if [ ! -s ACF_MC_${pref}.txt ]; then

		sed '/ 0  0  0    0/d' $print > tmp

		xA=`awk '{ total += $1 } END { print total/NR }' tmp`
		xB=`awk '{ total += $2 } END { print total/NR }' tmp`
		xC=`awk '{ total += $3 } END { print total/NR }' tmp`

		3dClustSim -mask $mask -LOTS -iter 10000 -acf $xA $xB $xC > ACF_MC_${pref}.txt
		rm tmp
	fi

	let arrCount=$[$arrCount+1]
done

