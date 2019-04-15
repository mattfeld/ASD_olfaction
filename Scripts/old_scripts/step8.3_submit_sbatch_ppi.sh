#!/bin/bash


# written by Nathan Muncy on 7/20/18


### Notes:
# This is a wrapper script used to submit the step8.3_sbatch job


### Set up variables and output dirs
workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/Scripts
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/ppi8.3_${time}

mkdir -p $outDir


# use same scans from Valentina list
subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})


### submit jobs
cd $workDir
for i in ${subjList[@]}; do

    sbatch \
    -o ${outDir}/output_ppi8.3_${i}.txt \
    -e ${outDir}/error_ppi8.3_${i}.txt \
    ${scriptDir}/step8.3_sbatch_ppi.sh $i

    sleep 1
done
