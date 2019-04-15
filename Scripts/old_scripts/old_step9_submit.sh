#!/bin/bash

# written by Nathan Muncy on 8/11/17


workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/Scripts
slurmDir=${workDir}/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/ppi9_MN_${time}
subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})

mkdir -p $outDir


cd $workDir
for i in ${subjList[@]}; do

	sbatch \
	-o ${outDir}/output_MN_${i}.txt \
	-e ${outDir}/error_MN_${i}.txt \
	${scriptDir}/step9_model_noise.sh $i

	sleep 1
done
