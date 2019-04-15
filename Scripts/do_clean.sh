#!/bin/bash


if [ $(whoami) == nmuncy ]; then
	workDir=~/compute/AutismOlfactory
elif [ $(whoami) == nate ]; then
	workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
fi

cd $workDir

for i in BO*; do
cd ${i}/ppi_data

	rm Seed*
	rm tmp*
	rm stats*
	rm cstats*

cd $workDir
done
