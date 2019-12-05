#!/bin/bash





workDir=~/compute/AutismOlfactory
slurmDir=${workDir}/derivatives/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/PPI6_${time}

mkdir -p $outDir


sbatch \
-o ${outDir}/output_PPI6.txt \
-e ${outDir}/error_PPI6.txt \
PPI_step6_meanBetas.sh
