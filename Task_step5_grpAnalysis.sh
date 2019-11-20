#!/bin/bash

#SBATCH --time=05:00:00   # walltime
#SBATCH --ntasks=10   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=6gb   # memory per CPU core
#SBATCH -J "TS5"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE




### Set General variables
parDir=~/compute/AutismOlfactory
workDir=${parDir}/derivatives								# par dir of data
stimDir=${parDir}/stimuli
outDir=${parDir}/Analyses/grpAnalysis						# where output will be written (should match step3)
mask=${outDir}/Intersection_GM_mask+tlrc								# this will be made, just specify name for the interesection gray matter mask
refFile=${workDir}/sub-1048/run-3_AO_scale+tlrc				# reference file, for finding dimensions etc
blurM=2


## arrays
# all prefices
prefArr=(All{FUMC,OC,SMC})

# sub-bricks
arrAllFUMC=(9 11 13 15)
arrAllOC=(9 11)
arrAllSMC=(9 11 13)

# name assoc w/sub-brick
namAllFUMC=(Mask FBO UBO CA)
namAllOC=(CA Odor)
namAllSMC=(CA Mask FUBO)




### load arrays - group and covariates
subjAll=(`tail -n +2 ${stimDir}/Cov_list.txt | awk '{print $1}'`)
groupAll=(`tail -n +2 ${stimDir}/Cov_list.txt | awk '{print $2}'`)
# snifAll=(`tail -n +2 ${stimDir}/Cov_list.txt | awk '{print $3}'`)
# spaAll=(`tail -n +2 ${stimDir}/Cov_list.txt | awk '{print $4}'`)




### Functions
MatchString () {

	local e match="$1"

	shift
	for e; do
		[[ "$e" == "$match" ]] && return 0
	done
	return 1
}




### Make data tables
#
# Exclude necessary participants
# Only inlcude particiapnts who have the data
# Include covariates (not mean-centered) in data table
# Generates dynamic variables dataSMC, dataFUMC, dataOC via declare


gridSize=`3dinfo -dk $refFile`
blurH=`echo $gridSize*$blurM | bc`
blurInt=`printf "%.0f" $blurH`

for i in ${prefArr[@]}; do

	unset hold{Brick,Name} arrRem holdList
	holdBrick=($(eval echo \${arr${i}[@]}))
	holdName=($(eval echo \${nam${i}[@]}))

	c=0; while [ $c -lt ${#subjAll[@]} ]; do

		subj=sub-${subjAll[$c]}
		file=${workDir}/${subj}/${i}_stats_REML_blur${blurInt}+tlrc
		arrRem=(`cat ${outDir}/info_rmSubj_${i/All}.txt`)

		MatchString "$subj" "${arrRem[@]}"
		if [ $? == 1 ] && [ -f ${file}.HEAD ]; then
			cc=0; while [ $cc -lt ${#holdName[@]} ]; do

				# holdList+="$subj ${groupAll[$c]} ${holdName[$cc]} ${snifAll[$c]} ${spaAll[$c]} ${file}'[${holdBrick[$cc]}]' "
				holdList+="$subj ${groupAll[$c]} ${holdName[$cc]} ${file}'[${holdBrick[$cc]}]' "
				let cc+=1
			done
		fi
		let c+=1
	done

	declare $(eval echo data$i)="$holdList"
done




### Write scripts
#
# Each analysis is written individually to make
#    adjustments easier down the road.
# Scripts are written for (a) review and (b) because
#    AFNI struggles interpreting variables sometimes.

cd $outDir


# # build FUMC - with covariates
# inputFUMC=$(eval echo \$dataFUMC)

# cat > MVM_FUMC.sh << EOF
# module load r/3.6

# 3dMVM -prefix MVM_FUMC \
# -jobs 10 \
# -mask $mask \
# -bsVars 'Group*Snif+Group*SPA' \
# -wsVars Stim \
# -qVars 'Snif,SPA' \
# -num_glt 4 \
# -gltLabel 1 G_Mask -gltCode 1 'Group : 1*Aut -1*Con Stim : 1*Mask' \
# -gltLabel 2 G_FBO -gltCode 2 'Group : 1*Aut -1*Con Stim : 1*FBO' \
# -gltLabel 3 G_UBO -gltCode 3 'Group : 1*Aut -1*Con Stim : 1*UBO' \
# -gltLabel 4 G_CA -gltCode 4 'Group : 1*Aut -1*Con Stim : 1*CA' \
# -dataTable \
# Subj Group Stim Snif SPA InputFile \
# $inputFUMC
# EOF


# build FUMC - w/o covariates
inputFUMC=$(eval echo \$dataAllFUMC)

cat > MVM_AllFUMC.sh << EOF
module load r/3.6

3dMVM -prefix MVM_AllFUMC \
-jobs 10 \
-mask $mask \
-bsVars 'Group' \
-wsVars Stim \
-num_glt 4 \
-gltLabel 1 G_Mask -gltCode 1 'Group : 1*Aut -1*Con Stim : 1*Mask' \
-gltLabel 2 G_FBO -gltCode 2 'Group : 1*Aut -1*Con Stim : 1*FBO' \
-gltLabel 3 G_UBO -gltCode 3 'Group : 1*Aut -1*Con Stim : 1*UBO' \
-gltLabel 4 G_CA -gltCode 4 'Group : 1*Aut -1*Con Stim : 1*CA' \
-dataTable \
Subj Group Stim InputFile \
$inputFUMC
EOF


# build OC
inputOC=$(eval echo \$dataAllOC)

cat > MVM_AllOC.sh << EOF
module load r/3.6

3dMVM -prefix MVM_AllOC \
-jobs 10 \
-mask $mask \
-bsVars 'Group' \
-wsVars Stim \
-num_glt 2 \
-gltLabel 1 G_Odor -gltCode 1 'Group : 1*Aut -1*Con Stim : 1*Odor' \
-gltLabel 2 G_CA -gltCode 2 'Group : 1*Aut -1*Con Stim : 1*CA' \
-dataTable \
Subj Group Stim InputFile \
$inputOC
EOF


# build SMC
inputSMC=$(eval echo \$dataAllSMC)

cat > MVM_AllSMC.sh << EOF
module load r/3.6

3dMVM -prefix MVM_AllSMC \
-jobs 10 \
-mask $mask \
-bsVars 'Group' \
-wsVars Stim \
-num_glt 3 \
-gltLabel 1 G_Mask -gltCode 1 'Group : 1*Aut -1*Con Stim : 1*Mask' \
-gltLabel 2 G_CA -gltCode 2 'Group : 1*Aut -1*Con Stim : 1*CA' \
-gltLabel 3 G_FUBO -gltCode 3 'Group : 1*Aut -1*Con Stim : 1*FUBO' \
-dataTable \
Subj Group Stim InputFile \
$inputSMC
EOF




### Run MVMs
for i in All{FUMC,OC,SMC}; do
	if [ ! -f MVM_${i}+tlrc.HEAD ]; then
		source MVM_${i}.sh
	fi
done
