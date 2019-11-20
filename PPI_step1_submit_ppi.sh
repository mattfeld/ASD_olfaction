#!/bin/bash



## Set up variables, and output dirs
parDir=~/compute/AutismOlfactory
workDir=${parDir}/derivatives
scriptDir=${parDir}/code
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/PPI1_${time}

mkdir -p $outDir
cd $workDir

for i in sub*; do

	[ $i == sub-1048 ]; clean=$?

    sbatch \
    -o ${outDir}/output_PPI1_${i}.txt \
    -e ${outDir}/error_PPI1_${i}.txt \
    ${scriptDir}/PPI_step1_sbatch_ppi.sh $i $clean

    sleep 1
done
