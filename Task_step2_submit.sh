#!/bin/bash




###??? update these
workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/code
slurmDir=${workDir}/derivatives/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/PPI2_${time}

mkdir -p $outDir

cd ${workDir}/derivatives
for i in sub*; do

	[ $i == sub-1048 ]; test=$?

    sbatch \
    -o ${outDir}/output_PPI2_${i}.txt \
    -e ${outDir}/error_PPI2_${i}.txt \
    ${scriptDir}/Task_step2_sbatch_regress.sh $i $test

    sleep 1
done
