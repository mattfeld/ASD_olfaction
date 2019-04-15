#!/bin/bash

# written by Nathan Muncy on 8/11/17


workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/Scripts
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/dtiInit_job2_${time}

mkdir $outDir


cd $workDir

for i in B*; do
	if [ ! -d ${i}/dti_scan/dti64trilin ]; then

		sbatch \
		-o ${outDir}/output_${i}.txt \
		-e ${outDir}/error_${i}.txt \
		${scriptDir}/step2_dtiInit_job.sh $i $scriptDir

		sleep 1
	fi
done
