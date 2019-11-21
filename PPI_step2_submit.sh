#!/bin/bash





workDir=~/compute/AutismOlfactory
slurmDir=${workDir}/derivatives/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/PPI2_${time}

mkdir -p $outDir


sbatch \
-o ${outDir}/output_PPI2.txt \
-e ${outDir}/error_PPI2.txt \
PPI_step2_grpAnalysis.sh
