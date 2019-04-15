#!/bin/bash

#SBATCH --time=30:00:00   # walltime
#SBATCH --ntasks=4   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=16gb   # memory per CPU core
#SBATCH -J "AOpriors"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE




workDir=~/compute/AutismOlfactory/Template
tempDir=~/bin/Templates/old_templates/oasis_30


dim=3
mov=AO_template.nii.gz
fixed=${tempDir}/T_template0.nii.gz
bfixed=${tempDir}/T_template0_BrainCerebellum.nii.gz
pmask=${tempDir}/T_template0_BrainCerebellumProbabilityMask.nii.gz
emask=${tempDir}/T_template0_BrainCerebellumExtractionMask.nii.gz
prior=${tempDir}/Priors2/priors%d.nii.gz
out=ss_



### Skull-strip
cd $workDir

antsCorticalThickness.sh \
-d $dim \
-a $mov \
-e $fixed \
-t $bfixed \
-m $pmask \
-f $emask \
-p $prior \
-o $out



### Make priors
base=Template_BrainCerebellumBinaryMask.nii.gz

cp ss_BrainExtractionMask.nii.gz $base
cp ss_BrainSegmentation.nii.gz Template_AtroposSegmentation.nii.gz
cp ss_ExtractedBrain0N4.nii.gz Template_SkullStrippedBrain.nii.gz

for j in {1..6}; do
    cp ss_BrainSegmentationPosteriors${j}.nii.gz Prior${j}.nii.gz
done


SmoothImage 3 $base 1 "${base/Binary/Probability}"
c3d $base -dilate 1 28x28x28vox -o "${base/Binary/Extraction}"
c3d $base -dilate 1 18x18x18vox -o  "${base/Binary/Registration}"

