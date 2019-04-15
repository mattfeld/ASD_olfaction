#!/bin/bash


### Written by Nathan Muncy on 4/02/2018


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory/Template
refDir=/Volumes/Yorick/Templates/old_templates/mni_icbm152_nlin_sym_09c_nifti/mni_icbm152_nlin_sym_09c



cd $workDir

DIM=3
ITER=30x90x30
TRANS=GR
SIM=CC
CON=2
PROC=6
REF=${refDir}/mni_icbm152_t1_tal_nlin_sym_09c.nii

${ANTSPATH}/buildtemplateparallel.sh \
-d $DIM \
-m $ITER \
-t $TRANS \
-s $SIM \
-c $CON \
-j $PROC \
-o TEST_ \
-z $REF \
ants*_Warped.nii.gz
