#!/bin/bash

# written by Nathan Muncy on 8/11/17

workDir=~/compute/AutismOlfactory
anaDir=${workDir}/Analyses/dtiAnalysis
scriptDir=${workDir}/Scripts

mkdir -p ${anaDir}/AFQ
mkdir ${anaDir}/AFQ-CC


cd $scriptDir

module load matlab
matlab -nodisplay -nojvm -nosplash -r step3_afq_parameters
module unload matlab
