#!/bin/bash


### Written by Nathan Muncy on 8/06/18


### Set variables, arrays
workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
outDir=${ppiDir}/mvm_stats
clustDir=${ppiDir}/mvm_clusters


subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})




### Organize
cd $ppiDir

mkdir $outDir
mkdir $clustDir
mv Clust* $clustDir

# build list of clusters
cd $clustDir

c=0; for a in Clust*d?_*mask+tlrc.HEAD; do
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
c=0; for d in Clust_*d?_*mask_*HEAD; do
	mask[$c]=${d%.*}
	let c=$[$c+1]
done



### get, print betas
for e in ${mask[@]}; do

	tmp=${e%+*}
	tmp2=${tmp#*_}
    > ${outDir}/Betas_s${tmp2}.txt
done


cd $workDir

for i in ${subjList[@]}; do
	cd ${i}/ppi_data

    for j in ${mask[@]}; do

		tmp1=${j%+*}
		tmp2=${tmp1#*_}
		seed=${tmp2%%_*}
		tmp3=${tmp2#*_}
		decon=${tmp3%%_*}

        print=${outDir}/Betas_s${tmp2}.txt
        deconFile=FINAL_${seed}_${decon}+tlrc
		beta=29    # this is hard coded since only 1 cluster survived MC

        stats=`3dROIstats -mask ${clustDir}/${j} "${deconFile}[${beta}]"`
        echo "$i $stats" >> $print
        echo >> $print
    done

	cd $workDir
done




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















