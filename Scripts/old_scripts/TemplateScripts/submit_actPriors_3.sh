#!/bin/bash


# written by Nathan Muncy


workDir=~/compute/AutismOlfactory
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/temp3_priors_${time}
mkdir -p $outDir


sbatch \
-o ${outDir}/output_temp3.txt \
-e ${outDir}/error_temp3.txt \
sbatch_actPriors_3.sh
