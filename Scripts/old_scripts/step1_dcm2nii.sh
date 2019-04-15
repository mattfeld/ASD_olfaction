#!/bin/bash


# Written by Nathan Muncy on 4/2/18


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
rawDir=${workDir}/De_Identified_BO_Data


cd $rawDir
for i in South_Bo_*; do

	## Set up output dirs
	subj=BO${i##*_}
	subjDir=${workDir}/$subj

	if [ ! -d $subjDir ]; then
		mkdir $subjDir
	fi

	for j in {t1,ppi,dti}_data; do
		if [ ! -d ${subjDir}/$j ]; then
			mkdir ${subjDir}/$j
		fi
	done


	## construct data
	dataDir=${rawDir}/${i}/Res*
	cd $dataDir

	t1Dir=${subjDir}/t1_data
	ppiDir=${subjDir}/ppi_data
	dtiDir=${subjDir}/dti_data


	# T1
	if [ ! -f ${t1Dir}/struct_raw.nii.gz ]; then

		cd ${dataDir}/t1*
		dcm2nii -a y -g y -x n *.dcm
		mv 20*.nii.gz ${t1Dir}/struct_raw.nii.gz
		rm *.nii.gz
		cd $dataDir
	fi


	# T2*
	if [ ! -f ${ppiDir}/BORun1.nii.gz ]; then

		# do only normal data, fix oddities manually
		num=`find BO* -maxdepth 0 -type d | wc -l`
		if [ $num == 3 ]; then
			for j in BO_Run*; do
				cd $j

					# Exclude last 3 TRs
					dcmList=(`ls | head -141`)
					dcm2nii -o ./. -a y -g Y -d N -r N -e N -v N ${dcmList[@]}
					mv BO* $ppiDir

				cd $dataDir
			done
		fi
	fi


	# DTI
# 	if [ ! -f ${dtiDir}/dti.nii.gz ]; then

		# determine appropriate dir
# 		tmp=`find . -name 'ep2d*p2_[[:digit:]]*'`
# 		dir=${tmp#*\/}
# 		cd $dir
#
# 		dcm2nii -a y -g y -x y *.dcm
# 		mv *.bval dti.bval
# 		mv *.bvec dti.bvec
# 		mv *ep2d*.nii.gz dti.nii.gz
# 		mv dti* $dtiDir
#
# 		cd $dataDir
# 	fi

cd $rawDir
done



















