#!/bin/bash


parDir=/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/grpAnalysis/4COV_analysis
workDir=${parDir}/MVM_betas
statsDir=${parDir}/MVM_stats
mkdir $statsDir


# This portion is over built, since there are usually multiple types of analyses
compList=(FUMC_{1,2,5,8a,RPF})

arrFUMC_1=(LAG)
arrFUMC_2=(LINS)
arrFUMC_5=(LPCU)
arrFUMC_8a=(LPCG)
arrFUMC_RPF=(LRSP)


cd $workDir

for i in ${compList[@]}; do

	# Rename cluster to anat
	out=All_Betas_${i}.txt
	> $out
	eval arrHold=(\${arr${i}[@]})

	for k in Betas_${i}_c*; do

		tmp=${k%.*}
		num=${tmp##*_c}
		arrNum=$(($num-1))

		cat $k > Betas_${i}_${arrHold[${arrNum}]}.txt
		echo Betas_${i}_${arrHold[${arrNum}]}.txt >> $out
	done
done


> All_list.txt
for i in All_Betas*; do
	echo $i >> All_list.txt
done
