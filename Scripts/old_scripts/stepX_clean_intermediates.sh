#!/bin/bash


if [ $(whoami) == nmuncy ]; then
workDir=~/compute/AutismOlfactory
elif [ $(whoami) == nate ]; then
workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
fi


cd $workDir
for i in BO*; do

	ppiDir=${workDir}/${i}/ppi_data

	cd $ppiDir

	rm FINAL_Indiv_{?,??}+tlrc*
	rm FINAL_Indiv_{?,??}.REML*
	rm FINAL_Indiv_{?,??}.xmat*

	rm FINAL_Indiv_{?,??}.?+tlrc*
	rm FINAL_Indiv_{?,??}.?.REML*
	rm FINAL_Indiv_{?,??}.?.xmat.1D
	rm errts_FINAL_Indiv_{?,??}.?+*

	rm *Seed_{?,??}.?_*
	rm Seed_{?,??}.?+tlrc.*
	rm Seed_{?,??}.?.txt

	rm HRes_Seed_{?,??}.?.txt



cd $workDir
done
