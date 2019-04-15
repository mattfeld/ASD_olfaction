#!/bin/bash


### Written by Nathan Muncy on 7/25/18

# Create Template Brain, GM priors



tempDir=/Volumes/Yorick/Templates/old_templates/mni_colin27_2008_nifti
cd $tempDir

# Whole brain mask
c3d colin27_cls_tal_hires.nii -thresh 0.5 3.1 1 0 -o colin27_brain_mask.nii

# GM mask
c3d colin27_cls_tal_hires.nii -thresh 1.9 2.1 1 0 -o colin27_GM_mask.nii
