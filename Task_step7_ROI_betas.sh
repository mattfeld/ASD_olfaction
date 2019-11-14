#!/bin/bash

#SBATCH --time=02:00:00   # walltime
#SBATCH --ntasks=6   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=4gb   # memory per CPU core
#SBATCH -J "TS7"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE





# Written by Nathan Muncy on 12/14/18


### --- Notes
#
# 1) This script will pull mean betas from L/R CA1, CA2/3/DG (called Multi), and Sub.
#		- maybe I'll update this in the future for other MTL regions
#		- also, maybe I'll update this to support more than 2 betas p/comparison
#				or...you could
#
# 2) Specifically, each mask for each hemisphere will be resampled,
#		binarized, and voxels defined by mutliple over-lapping masks
#		will be excluded.
#
# 3) A print out of the number of voxels in/excluded is supplied (info_*.txt)
#
# 4) Again, betas will not be extracted from participants who moved too much





# general vars											###??? Update these
parDir=~/compute/AutismOlfactory
workDir=${parDir}/derivatives
roiDir=${parDir}/Analyses/roiAnalysis
betaDir=${roiDir}/sub_betas
grpDir=${parDir}/Analyses/grpAnalysis


jlfDir=${parDir}/Template/priors_JLF
jlfLabel=(18 54 {1,2}{012,014,002,010,023,026})
jlfName=({L,R}_Amyg {L,R}_{{L,M}OFC,{CA,IS,P,RA}Cing})


compList=(FUMC OC SMC)									# matches decon prefix
refFile=${workDir}/sub-1048/${compList[0]}_stats_REML+tlrc

brikFUMC=1,3,5,7										# setA beh sub-brik for etacList
brikOC=1,3												# steB
brikSMC=1,3,5




# function - search array for string
MatchString (){
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}




### Make JLF masks
mkdir -p $betaDir
cd $roiDir

c=0; while [ $c -lt ${#jlfLabel[@]} ]; do

	name=${jlfName[$c]}
	label=${jlfLabel[$c]}

	if [ ! -f ${name}+tlrc.HEAD ]; then

		c3d ${jlfDir}/JLF_Labels.nii.gz -thresh $label $label 1 0 -o tmp_${name}.nii.gz
		3dresample -master $refFile -rmode NN -input tmp_${name}.nii.gz -prefix tmp_res_${name}.nii.gz
		c3d ${grpDir}/Group_epi_mask.nii.gz tmp_res_${name}.nii.gz -multiply -o tmp_clean_${name}.nii.gz
		c3d tmp_clean_${name}.nii.gz -thresh 0.1 1 1 0 -o tmp_thresh_${name}.nii.gz
		3dcopy tmp_thresh_${name}.nii.gz ${name}+tlrc
		rm tmp*
	fi
	let c+=1
done




### Pull Betas
for i in ${compList[@]}; do

	scan=${i}_stats_REML+tlrc
	betas=$(eval echo \$brik$i)
	arrRem=(`cat ${grpDir}/info_rmSubj_${i}.txt`)

	for j in ${jlfName[@]}; do

		print=${betaDir}/Betas_${i}_${j}_sub.txt
		echo $j > $print

		for k in ${workDir}/s*; do

			subj=${k##*\/}
			MatchString $subj "${arrRem[@]}"
			if [ $? == 1 ]; then

				stats=`3dROIstats -mask ${j}+tlrc "${k}/${scan}[${betas}]"`
				echo "$subj $stats" >> $print
			fi
		done
	done
done


# organize output
cd $betaDir
> Master_list.txt

for i in Betas*; do
	echo $i >> Master_list.txt
done
