#!/bin/bash

# written by Nathan Muncy on 8/11/17

workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/Scripts
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/afq_cc_job5_${time}

mkdir $outDir


sbatch \
-o ${outDir}/output_afq_job5.txt \
-e ${outDir}/error_afq_job5.txt \
${scriptDir}/step5_afq_cc_job.sh $scriptDir
