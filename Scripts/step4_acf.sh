#!/bin/bash


# Written by Nathan Muncy on 7/31/18


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
acfDir=${ppiDir}/MC_output
tempDir=/Volumes/Yorick/Templates/old_templates/mni_colin27_2008_nifti

mkdir -p $acfDir


### Make lists
subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})

# FINAL, PRINT lists
cd ${workDir}/BO1048/ppi_data

c=0; for i in FINAL_*_d?+tlrc.HEAD; do
    tmp=${i%+*}
    finalList[$c]=${i%.*}
    printList[$c]=Error_${tmp#*_}
    let c=$[$c+1]
done
finalLen=${#finalList[@]}




### Make GM mask
cd $ppiDir

if [ ! -f colin_GM_mask+tlrc.HEAD ]; then
	cp ${tempDir}/colin27_t1_tal_hires+tlrc* .

	3dcopy ${tempDir}/colin27_GM_mask.nii tmp_gm_bin+tlrc
	3dfractionize -template ${workDir}/BO1048/ppi_data/FINAL_LPF_d2+tlrc -prefix tmp_gm_resample -input tmp_gm_bin+tlrc
	3dcalc -a tmp_gm_resample+tlrc -prefix colin_GM_mask -expr "step(a)"
	rm tmp*
fi
mask=${ppiDir}/colin_GM_mask+tlrc




### Create/zero print files
cd $acfDir

for a in ${printList[@]}; do
	> ${a}.txt
done




### Calc ACF estimates
for i in ${subjList[@]}; do
	c=0; while [ $c -lt $finalLen ]; do

		subjDir=${workDir}/${i}/ppi_data
		file=${finalList[$c]}
		input=${subjDir}/$file

		print=${acfDir}/${printList[$c]}.txt

		tmp2=${file%+*}
		decon=${tmp2##*_}

		if [ $decon == d2 ]; then
				arr=(29 32 35 38)
			elif [ $decon == d3 ]; then
				arr=(23 26)
			else
				arr=(26 29)
		fi

		for j in ${arr[@]}; do
			3dFWHMx -mask $mask -input ${input}"[$j]" -acf >> $print
		done

	let c=$[$c+1]
	done
done




#### clean, calc avgs, run simulations
for i in Error*.txt; do

	sed '/ 0  0  0    0/d' $i > tmp_${i#*_}

	xA=`awk '{ total += $1 } END { print total/NR }' tmp_${i#*_}`
	xB=`awk '{ total += $2 } END { print total/NR }' tmp_${i#*_}`
	xC=`awk '{ total += $3 } END { print total/NR }' tmp_${i#*_}`

	3dClustSim -mask $mask -LOTS -iter 2000 -acf $xA $xB $xC > MC_${i#*_}

	rm tmp*
done
