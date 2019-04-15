#!/bin/bash


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
outDir=${workDir}/Analyses/Error_model
subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})


# make output
cd ${workDir}/BO1048/ppi_data

for i in error*; do
	> ${outDir}/${i#*_}
done



# Collapse
cd $workDir

for i in ${subjList[@]}; do
cd ${i}/ppi_data

	for j in error*; do

		print=${outDir}/${j#*_}
		cat $j >> $print
	done

cd $workDir
done



# Clean
cd $outDir

for i in FINAL*; do
	sed '/ 0  0  0    0/d' $i > cleaned_$i
done



# Calc avgs
for j in cleaned*; do

	xA=`awk '{ total += $1 } END { print total/NR }' $j`
	xB=`awk '{ total += $2 } END { print total/NR }' $j`
	xC=`awk '{ total += $3 } END { print total/NR }' $j`

	string=${j#*_}
	echo "$xA $xB $xC" > Avg_$string
done