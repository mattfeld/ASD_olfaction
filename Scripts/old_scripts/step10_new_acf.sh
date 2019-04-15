#!/bin/bash


# Written by Nathan Muncy on 6/7/18


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
mask=${ppiDir}/Template_GM_mask+tlrc


# Make lists
subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})

stimList=(FBO UBO)
stimBrik=(26 29)
stimLen=${#stimList[@]}


cd ${workDir}/BO1048/ppi_data

c=0; for i in FINAL_Indiv*tlrc.HEAD; do
    tmp=${i%+*}
    fiList[$c]=${i%.*}
    printList[$c]=Error_${tmp#*_}
    let c=$[$c+1]
done
fiLen=${#fiList[@]}



# Create/zero print files
cd $ppiDir

for a in ${printList[@]}; do
	for b in ${stimList[@]}; do
		> ${a}_${b}.txt
	done
done



# Calc ACF estimates
for i in ${subjList[@]}; do
	c=0; while [ $c -lt $fiLen ]; do
		d=0; while [ $d -lt $stimLen ]; do

			subjDir=${workDir}/${i}/ppi_data
			file=${subjDir}/${fiList[$c]}
			brik=${stimBrik[$d]}
			print=${ppiDir}/${printList[$c]}_${stimList[$d]}.txt

			3dFWHMx -mask $mask -input ${file}"[$brik]" -acf >> $print

		let d=$[$d+1]
		done
	let c=$[$c+1]
	done
done



# clean, calc avgs, run simulations
for i in Error*.txt; do

	sed '/ 0  0  0    0/d' $i > tmp_${i#*_}

	xA=`awk '{ total += $1 } END { print total/NR }' tmp_${i#*_}`
	xB=`awk '{ total += $2 } END { print total/NR }' tmp_${i#*_}`
	xC=`awk '{ total += $3 } END { print total/NR }' tmp_${i#*_}`

	3dClustSim -mask $mask -LOTS -iter 2000 -acf $xA $xB $xC > MC_${i#*_}

	rm tmp*
done







#### Old troubleshooting code


# print=${tempDir}/TEST_ACF_Indiv_LPF_26.txt
# > $print
#
#
# for i in ${subjList[@]}; do
#
# 	subjDir=${workDir}/${i}/ppi_data
#
# 	3dFWHMx \
# 	-mask ${tempDir}/Template_GM_mask+tlrc \
# 	-input ${subjDir}/FINAL_Indiv_LPF+tlrc'[26]' \
# 	-acf >> $print
# done


#
# # Clean
# cd $tempDir
# sed '/ 0  0  0    0/d' TEST_ACF_Indiv_LPF_26.txt > cleaned.txt
#
#
#
# # Calc avgs
# xA=`awk '{ total += $1 } END { print total/NR }' cleaned.txt`
# xB=`awk '{ total += $2 } END { print total/NR }' cleaned.txt`
# xC=`awk '{ total += $3 } END { print total/NR }' cleaned.txt`
#
# echo "$xA $xB $xC" > Avg.txt
#


#
# # Run simulations
#
# arr=(`cat Avg.txt`)
# 3dClustSim -mask Template_GM_mask+tlrc -LOTS -iter 1000 -acf ${arr[0]} ${arr[1]} ${arr[2]} > ACF.txt

