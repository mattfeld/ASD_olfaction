#!/bin/bash

#SBATCH --time=10:00:00   # walltime
#SBATCH --ntasks=4   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=4gb   # memory per CPU core
#SBATCH -J "PPI6"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE






# Written by Nathan Muncy on 11/28/18


###--- Notes, in no particular order
#
# 1) the script will split the cluster file into multiple masks, and pull betas from each participant.
#
# 2) assumes clusters from step4 output have been saved in Clust_$fileArr format
#		will use the comparisonString portion to keep different group analyses straight
#		comparisonString should match the decon prefix (step4 $etacList)
#
# 3) assumes that decon files exist locally (bring them back from the supercomputer)
#
# 4) Written for the output of ETAC - will pull betas from each cluster



# Variables
parDir=~/compute/AutismOlfactory
workDir=${parDir}/derivatives										###??? Update this section
grpDir=${parDir}/Analyses/grpAnalysis
clustDir=${grpDir}/MVM_clusters
outDir=${grpDir}/MVM_betas
refDir=${workDir}/sub-1048											# reference file for dimensions etc


clustList=(FUMC_{1,RPF,2,5,8a})										# a list of comparisons that have a meaningful difference


unset tmp
varFUMC=(`echo 35$tmp{1..3}`)										# sub-brick(s) of sig behavior - only built for 1 right now
clust1=(`echo 20$tmp{1..2} 16$tmp{1..3}`)							# overlay sub-brick, for extracting clusters
clust2=(`echo 21$tmp{1..2} 17$tmp{1..3}`)							# threshold sub-brick
anBrick=32,35														# patch for multiple betas (to deal with line 53)



# function - search array for string
MatchString (){
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}





### make clusters, tables
mkdir $outDir $clustDir
cd $grpDir


c=0; while [ $c -lt ${#clustList[@]} ]; do

	pref=${clustList[$c]}
	file=MVM_${pref}+tlrc

	if [ ! -s ${clustDir}/Clust_${pref}_table.txt ]; then

		3dclust -1Dformat -nosum -1dindex ${clust1[$c]} \
		-1tindex ${clust2[$c]} -2thresh -3.558 3.558 -dxyz=1 \
		-savemask Clust_${pref}_mask \
		1.01 9 $file > Clust_${pref}_table.txt

		mv Clust* $clustDir
	fi

	let c=$[$c+1]
done




### pull mean beta-coeff
cd $clustDir

c=0; while [ $c -lt ${#clustList[@]} ]; do

	hold=${clustList[$c]}
	pref=${hold%_*}
	arrRem=(`cat ${grpDir}/info_rmSubj_${pref}.txt`)


	# patch to pull multiple sub-bricks
	if [ $hold != FUMC_1 ] && [ $hold != FUMC_RPF ]; then
		betas=$(eval echo \${var${pref}})
	else
		betas=$anBrick
	fi


	# split clust masks
	if [ -f Clust_${hold}_mask+tlrc.HEAD ]; then
		if [ ! -f Clust_${hold}_c1+tlrc.HEAD ]; then

			3dcopy Clust_${hold}_mask+tlrc ${hold}.nii.gz
			num=`3dinfo Clust_${hold}_mask+tlrc | grep "At sub-brick #0 '#0' datum type is short" | sed 's/[^0-9]*//g' | sed 's/^...//'`

			for (( j=1; j<=$num; j++ )); do
				if [ ! -f Clust_${hold}_c${j}+tlrc.HEAD ]; then

					c3d ${hold}.nii.gz -thresh $j $j 1 0 -o ${hold}_${j}.nii.gz
					3dcopy ${hold}_${j}.nii.gz Clust_${hold}_c${j}+tlrc
				fi
			done
			rm *.nii.gz
		fi


		# pull betas
		for i in Clust_${hold}_c*+tlrc.HEAD; do

			tmp=${i##*_}; cnum=${tmp%+*}
			print=${outDir}/Betas_${hold}_${cnum}.txt
			> $print

			for j in ${workDir}/s*; do

				subj=${j##*\/}
				MatchString "$subj" "${arrRem[@]}"

				if [ $? == 1 ]; then

					file=${j}/PPI_${hold}_stats_REML+tlrc
					stats=`3dROIstats -mask ${i%.*} "${file}[${betas}]"`
					echo "$subj $stats" >> $print
				fi
			done
		done
	fi

	let c=$[$c+1]
done
