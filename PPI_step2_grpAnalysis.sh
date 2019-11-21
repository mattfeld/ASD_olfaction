#!/bin/bash

#SBATCH --time=20:00:00   # walltime
#SBATCH --ntasks=10   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=6gb   # memory per CPU core
#SBATCH -J "PPI2"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE




### --- Set up --- ###										###??? update variables/arrays
#
# This is where the script will orient itself.
# Notes are supplied, and is the only section
# that really needs to be changed for each
# experiment.


# General variables
parDir=~/compute/AutismOlfactory

workDir=${parDir}/derivatives								# par dir of data
stimDir=${parDir}/stimuli
outDir=${parDir}/Analyses/grpAnalysis						# where output will be written (should match step3)
ppiDir=${parDir}/Analyses/ppiAnalysis
refFile=${workDir}/sub-1048/run-1_AO_scale+tlrc				# reference file, for finding dimensions etc

tempDir=${parDir}/Template									# desired template
priorDir=${tempDir}/priors_ACT								# location of atropos priors
mask=${outDir}/Intersection_GM_mask+tlrc								# this will be made, just specify name for the interesection gray matter mask


# Decon Vars
compList=(All{FUMC,OC,SMC})												# matches decon prefixes, and will be prefix of output files

arrAllFUMC=(9 11 13 15)
arrAllOC=(9 11)
arrAllSMC=(9 11 13)

namAllFUMC=(Mask FBO UBO CA)
namAllOC=(CA Odor)
namAllSMC=(CA Mask FUBO)


# PPI vars
seedName=(LPF RPF LAmg RAmg)


# MVM vars/arrs
blurM=2														# blur multiplier, float/int

covSubj=(`tail -n +2 ${stimDir}/Cov_list.txt | awk '{print $1}'`)
covGroup=(`tail -n +2 ${stimDir}/Cov_list.txt | awk '{print $2}'`)




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




### --- Set up --- ###

mkdir $ppiDir

# subject, group arrays
arrRem=(`cat ${outDir}/info_rmSubj_AllFUMC.txt`)   # they are all the same

unset {subj,group}List
c=0; for i in ${!covSubj[@]}; do

	subj=sub-${covSubj[$i]}
	MatchString "$subj" "${arrRem[@]}"

	if [ $? == 1 ] && [ -d ${workDir}/$subj ]; then
		subjList[$c]=$subj
		groupList[$c]=${covGroup[$i]}
	fi
	let c+=1
done


# blur ppi
cd $workDir

gridSize=`3dinfo -dk $refFile`
blurH=`echo $gridSize*$blurM | bc`
blurInt=`printf "%.0f" $blurH`

for i in ${subjList[@]}; do
	for j in ${i}/PPI*stats_REML+tlrc.HEAD; do
		file=${j%+*}
		if [ ! -f ${file}_blur${blurInt}+tlrc.HEAD ]; then
			3dmerge -prefix ${file}_blur${blurInt} -1blur_fwhm $blurInt -doall ${j%.*}
		fi
	done
done




### --- MVM --- ###
#
# Rather than generate entire MVM scripts, I'm going to hard-code some sections


### Generate variables that are dynamically named (e.g. dataFUMC_LPF) which
# contains the input dataTable for each PPI comparison X seed X behavior
# to feed to 3dMVM
for i in ${compList[@]}; do

	unset hold{Brick,Name}
	holdBrick=($(eval echo \${arr${i}[@]}))
	holdName=($(eval echo \${nam${i}[@]}))

	for j in ${seedName[@]}; do

		unset holdList
		c=0; while [ $c -lt ${#subjList[@]} ]; do

			subj=${subjList[$c]}
			group=${groupList[$c]}
			file=${workDir}/${subj}/PPI_${i}_${j}_stats_REML_blur${blurInt}+tlrc

			if [ -f $file ]; then
				cc=0; while [ $cc -lt ${#holdName[@]} ]; do

					beh=${holdName[$cc]}
					brick=${holdBrick[$cc]}

					holdList+="$subj $group $beh ${file}'[$brick]' "
					let cc+=1
				done
			else
				echo >&2
				echo "File not found: $file" >&2
				echo "Exiting..." >&2
				echo >&2
			fi
			let c+=1
		done

		declare $(eval echo data${i}_$j)="$holdList"
	done
done



### MVM scripts for each Seed X comparison.
# Invidual comparisons are hardcoded
cd $ppiDir

for i in ${seedName[@]}; do

	# get datasets - partially unpack dynamic vars
	inputFUMC=$(eval echo \$dataFUMC_$i)
	inputOC=$(eval echo \$dataOC_$i)
	inputSMC=$(eval echo \$dataSMC_$i)


	# Write scripts
	cat > MVM_PPI_AllFUMC_${i}.sh << EOF
module load r/3.6

3dMVM -prefix MVM_PPI_AllFUMC_${i} \
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


	cat > MVM_PPI_AllOC_${i}.sh << EOF
module load r/3.6

3dMVM -prefix MVM_PPI_AllOC_${i} \
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


	cat > MVM_PPI_AllSMC_${i}.sh << EOF
module load r/3.6

3dMVM -prefix MVM_AllSMC_${i} \
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

done


# ### run scripts
# for i in MVM*.sh; do
# 	if [ ! -f ${i%.*}+tlrc.HEAD ]; then
# 		source $i
# 	fi

# 	# check
# 	if [ ! -f ${i%.*}+tlrc.HEAD ]; then
# 		echo >&2
# 		echo "Error: ${i%.*}+tlrc not detected. Exiting..." >&2
# 		echo >&2
# 	fi
# done
