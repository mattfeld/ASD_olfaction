#!/bin/bash

# written by Nathan Muncy on 8/11/17

# use this to submit sbatch_preproc_2.sh


workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/Scripts/TemplateScripts
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/tc1_${time}

mkdir -p $outDir


cd $workDir
for i in B*; do

	sbatch \
	-o ${outDir}/tc1_${i}.txt \
	-e ${outDir}/tc1_${i}.txt \
	${scriptDir}/Template_step1_sbatch_normalize.sh $i

    sleep 1
done
