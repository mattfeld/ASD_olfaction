#!/bin/bash


### Written by Nathan Muncy on 4/16/18


### Set variables, arrays
workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
outDir=${ppiDir}/mvm_stats
clustDir=${ppiDir}/mvm_clusters
refDir=${workDir}/BO1048/ppi_data


subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})

cd $workDir
c=0; for i in Seed_{?,??}.txt; do
	seedList[$c]=${i%.*}
	let c=$[$c+1]
done



### Organize
cd $ppiDir

mkdir $outDir
mkdir $clustDir
mv Clust* $clustDir

# build list of clusters
cd $clustDir

c=0; for a in Clust_{?,??}_*mask+tlrc.HEAD; do
    clust[$c]=${a%+*}
    let c=$[$c+1]
done



### pull number of labels per mask, split masks by label
for b in ${clust[@]}; do
	if [ ! -f ${b%+*}_1+tlrc.HEAD ]; then

		3dcopy ${b}+tlrc ${b}.nii.gz
		num=`3dinfo ${b}+tlrc | grep "At sub-brick #0 '#0' datum type is short" | sed 's/[^0-9]*//g' | sed 's/^...//'`

		for (( c=1; c<=$num; c++ )); do
			if [ ! -f ${b}_${c}+tlrc.HEAD ]; then

				c3d ${b}.nii.gz -thresh $c $c 1 0 -o ${b}_${c}.nii.gz
				3dcopy ${b}_${c}.nii.gz ${b}_${c}+tlrc
			fi
		done
		rm *.nii.gz
	fi
done

# build list of masks
c=0; for d in Clust_{?,??}_*mask_*HEAD; do
	mask[$c]=${d%.*}
	let c=$[$c+1]
done



### get, print betas
for e in ${mask[@]}; do

	tmp=${e%+*}
	tmp2=${tmp#*_}
    > ${outDir}/Betas_Seed_${tmp2/_k??}.txt
done


cd $workDir

for i in ${subjList[@]}; do
	cd ${i}/ppi_data

    for j in ${mask[@]}; do

		tmp1=${j%+*}
		tmp2=${tmp1#*_}
		tmp3=${j#*_}
		tmp4=${tmp3#*_}

        print=${outDir}/Betas_Seed_${tmp2/_k??}.txt
        deconFile=FINAL_Indiv_${tmp3%%_*}+tlrc
        string=${tmp4%%_*}

		if [ $string == G.M ]; then
			beta=32
        elif [ $string == G.UF ]; then
			beta=26,29
		elif [ $string == G.CUF ]; then
			beta=26,29,35
		elif [ $string == G.C ]; then
			beta=35
		elif [ $string == G.MUF ]; then
			beta=26,29,32
		fi

        stats=`3dROIstats -mask ${clustDir}/${j} "${deconFile}[${beta}]"`
        echo "$i $stats" >> $print
        echo >> $print
    done

	cd $workDir
done





 ### Make master lists
 #cd $outDir

 #for i in {FBO,UBO}_{LPF,REC}; do
 	#> Master_${i}.txt
 #done


 #for i in TT*.txt; do

 	#tmp=${i#*_}
 	#tmp2=${tmp%_b*}
 	#mask=mask_${tmp2##*_}
 	#print=Master_${tmp%_m*}.txt

 	#echo $mask >> $print
 	#cat $i >> $print
 	#echo >> $print
 #done



 ### Make master coord
 cd $clustDir

 print=${outDir}/Master_coord.txt
 > $print

 for i in *table.1D; do

 	tmp=${i#*_}
 	con=${tmp%_*}

 	echo $con >> $print
 	cat $i >> $print
 	echo >> $print
 done















