#!/bin/bash

# written by Nathan Muncy on 8/11/17

workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/Scripts
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/afq_job4_${time}
mkdir $outDir


sbatch \
-o ${outDir}/output_afq_job4.txt \
-e ${outDir}/error_afq_job4.txt \
${scriptDir}/step4_afq_job.sh $scriptDir
