#!/bin/bash

#SBATCH --time=40:00:00   # walltime
#SBATCH --ntasks=10   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=10gb   # memory per CPU core
#SBATCH -J "PPI5"   # job name

# Compatibility variables for PBS. Delete if not needed.
export PBS_NODEFILE=`/fslapps/fslutils/generate_pbs_nodefile`
export PBS_JOBID=$SLURM_JOB_ID
export PBS_O_WORKDIR="$SLURM_SUBMIT_DIR"
export PBS_QUEUE=batch

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE





# Written by Nathan Muncy on 11/2/18


###--- Notes, in no particular order
#







### --- Set up --- ###										###??? update variables/arrays
#
# This is where the script will orient itself.
# Notes are supplied, and is the only section
# that really needs to be changed for each
# experiment.


# General variables
parDir=~/compute/AutismOlfactory
workDir=${parDir}/derivatives								# par dir of data
outDir=${parDir}/Analyses/grpAnalysis						# where output will be written (should match step3)
refFile=${workDir}/sub-1048/run-1_AO_scale+tlrc				# reference file, for finding dimensions etc

tempDir=${parDir}/Template									# desired template
priorDir=${tempDir}/priors_ACT								# location of atropos priors
mask=Intersection_GM_mask+tlrc								# this will be made, just specify name for the interesection gray matter mask


# grpAnalysis
runIt=0														# whether ETAC/MVM scripts actually run (and not just written) (1)
thr=0.3														# thresh value for Group_EPI_mask, ref Group_EPI_mean

compList=(FUMC FUMvC FUvC)									# matches decon prefixes, and will be prefix of output files
compLen=${#compList[@]}

arrFUMC=(29 32 35 38)
arrFUMvC=(23 26)
arrFUvC=(26 29 32)

namFUMC=(Mask FBO UBO CA)
namFUMvC=(CA Odor)
namFUvC=(CA Mask FUBO)

#arrA=(29 23 26)												# setA beh sub-brik for compList. Must be same length as compList
#arrB=(32 26 29)												# setB
#arrC=(35 x 32)
#arrD=(38 x x)
#listX=ABCD													# list of arr? used, for building permutations (e.g. listX=ABC)

#namA=(Mask CA CA)											# names of behaviors from arrA. Must be same length as arrA
#namB=(FBO Odor Mask)
#namC=(UBO x FUBO)
#namD=(CA x x)


### MVM vars/arrs
blurM=2														# blur multiplier, float/int
bsArr=(Aut Con)												# Bx-subject variables (groups)

## bs group
#cd $workDir
#> ${outDir}/Group_list.txt

#for i in s*; do
	#tmp=${i/sub-}; group=${tmp%??}
	#if [[ $group == 1? ]]; then
		#echo -e "$i \t Con" >> ${outDir}/Group_list.txt;
	#else
		#echo -e "$i \t Aut" >> ${outDir}/Group_list.txt;
	#fi
#done
#bsList=${outDir}/Group_list.txt								# Needed when bsArr > 1. List where col1 = subj identifier, col2 = group membership (e.g. s1295 Con)


# group, covariates
covHead=(`head -n 1 ${outDir}/Cov_list.txt`)
covSubj=(`tail -n +2 ${outDir}/Cov_list.txt | awk '{print $1}'`)
covGroup=(`tail -n +2 ${outDir}/Cov_list.txt | awk '{print $2}'`)
covSnif=(`tail -n +2 ${outDir}/Cov_list.txt | awk '{print $3}'`)
covSPA=(`tail -n +2 ${outDir}/Cov_list.txt | awk '{print $4}'`)




### --- Functions --- ###

# search array for string
MatchString () {

	local e match="$1"

	shift
	for e; do
		[[ "$e" == "$match" ]] && return 0
	done
	return 1
}


# make perumtations of length 2
MakePerm () {

	local items=$1
	local string i j hArr

	for ((i=0; i<${#items}; i++)); do

		string=${items:$i+1}
		for ((j=0; j<${#string}; j++)); do

			hArr+="${items:$i:1}${string:$j:1} "
		done
	done
	echo $hArr
}




### --- Set up --- ###

# make permutation lists
arr=(`MakePerm $listX`)
alpha=(`echo {A..Z}`)
wsList=(${alpha[@]:0:${#listX}})

for ((a=0; a<${#bsArr[@]}; a++)); do
	tmpList+=$a
done
arrBS=(`MakePerm $tmpList`)


# make ppi list
cd ${refFile%run*}

c=0; for i in PPI*stats_REML+tlrc.HEAD; do

	ppiList[$c]=${i$.*}
	let c=$[$c+1]
done




### --- Create Masks --- ###
#
# This section will create a group mean intersection mask
# then threshold it at $thr to create a binary intersection mask.
# A gray matter mask will be constructed, and then the GM mask
# will be multiplied with the intersection mask to create a
# single GM intersection mask


cd $outDir

if [ $runIt == 1 ]; then

	# intersection mask
	if [ ! -f Group_epi_mask.nii.gz ] && [ ! -f etac_extra/Group_epi_mask.nii.gz ]; then

		for i in ${workDir}/s*; do
			list+="${i}/mask_epi_anat+tlrc "
		done

		3dMean -prefix ${outDir}/Group_epi_mean.nii.gz $list
		3dmask_tool -input $list -frac $thr -prefix ${outDir}/Group_epi_mask.nii.gz
	fi


	# make $mask
	if [ ! -f ${mask}.HEAD ]; then

		# GM mask
		c3d ${priorDir}/Prior2.nii.gz ${priorDir}/Prior4.nii.gz -add -o tmp_Prior_GM.nii.gz
		3dresample -master $refFile -rmode NN -input tmp_Prior_GM.nii.gz -prefix tmp_Template_GM_mask.nii.gz

		# combine GM and intersection mask
		c3d tmp_Template_GM_mask.nii.gz Group_epi_mask.nii.gz -multiply -o tmp_Intersection_GM_prob_mask.nii.gz
		c3d tmp_Intersection_GM_prob_mask.nii.gz -thresh 0.1 1 1 0 -o tmp_Intersection_GM_mask.nii.gz
		3dcopy tmp_Intersection_GM_mask.nii.gz $mask
		rm tmp*
	fi

	if [ ! -f ${mask}.HEAD ]; then
		echo >&2
		echo "Could not construct $mask. Exit 5" >&2
		echo >&2
		exit 5
	fi


	# get template
	if [ ! -f vold2_mni_brain+tlrc.HEAD ]; then
		cp ${tempDir}/AO_template_brain+tlrc* .
	fi
fi




### --- MVM --- ###
#
# This will blur both stats and errts files according to $blurM, and
# then the blurred errts files will be used to model noise with
# an auto-correlation function. MVM scripts will be written and run,
# and none of this will happen on participants who move too much.
# A variable number of bx/wi subj variables is accepted, but this
# will not run a t-test.
#
# Currently, MVM post-hoc comparisons are permutations of bx/wi-subj
# variables. I.e. Behaviors A B C for groups Aut Con will yield
# comparisons of Aut-Con A-B, Aut-Con A-C, Aut-Con B-C. I could build
# more comparisons in the future.


arrCount=0; while [ $arrCount -lt $compLen ]; do

	pref=${compList[$arrCount]}
	print=ACF_raw_${pref}.txt
	outPre=${pref}_MVM_REML

	# make subj list
	unset subjList

	for j in ${workDir}/s*; do

		arrRem=(`cat info_rmSubj_${pref}.txt`)
		subj=${j##*\/}
		MatchString "$subj" "${arrRem[@]}"

		if [ $? == 1 ]; then
			subjList+=("$subj ")
		fi
	done


	# blur, determine parameter estimate
	gridSize=`3dinfo -dk $refFile`
	blurH=`echo $gridSize*$blurM | bc`
	blurInt=`printf "%.0f" $blurH`

	if [ $runIt == 1 ]; then
		if [ ! -s $print ]; then
			for k in ${subjList[@]}; do
				for m in stats errts; do

					hold=${workDir}/${k}/${pref}_${m}_REML
					file=${workDir}/${k}/${pref}_errts_REML_blur${blurInt}+tlrc

					# blur
					if [ ! -f ${hold}_blur${blurInt}+tlrc.HEAD ]; then
						3dmerge -prefix ${hold}_blur${blurInt} -1blur_fwhm $blurInt -doall ${hold}+tlrc
					fi
				done

				# parameter estimate
				3dFWHMx -mask $mask -input $file -acf >> $print
			done
		fi


		# simulate noise, determine thresholds
		if [ ! -s ACF_MC_${pref}.txt ]; then

			sed '/ 0  0  0    0/d' $print > tmp

			xA=`awk '{ total += $1 } END { print total/NR }' tmp`
			xB=`awk '{ total += $2 } END { print total/NR }' tmp`
			xC=`awk '{ total += $3 } END { print total/NR }' tmp`

			3dClustSim -mask $mask -LOTS -iter 10000 -acf $xA $xB $xC > ACF_MC_${pref}.txt
			rm tmp
		fi
	fi
	let arrCount=$[$arrCount+1]
done


#### Rather than generate entire MVM scripts, I'm going to hard-code some sections

# loop through lists of desired ppis
for i in ${ppiList[@]}; do

	scan=$i
	tmp=${i%_errts*}
	decon=${tmp##*_}


	# determine behvaiors, sub-bricks
	arrBrick=($(eval echo \${arr${decon}[@]}))
	arrName=($(eval echo \${nam${decon}[@]}))
	arrRemove=(`cat ${outDir}/info_rmSubj_${decon}.txt`)


	# generate contrasts
	unset conMatrix
	for j in ${!arrName[@]}; do

		num=$(($j+1))
		conMatrix+="-gltLabel $num G.${arrName[$j]} -gltCode $num 'Group: 1*Con -1*Aut Stim: 1*${${arrName[$j]} Snif: SPA: "
	done
	numGlt=$num


	### set up dataframe
	dataMatrixHead="Subj Group Stim Snif SPA InputFile"

	unset dataMatrix

	# loop through covariates
	c=0; while [ $c -lt ${#covSubj[@]} ]; do     #### add a part to replace missing values w/mean of column

		subj=sub-${covSubj[$c]}
		if [ -f ${workDir}/${subj}/${i}.HEAD ]; then

			MatchString "$subj" "${arrRemove[@]}"
			if [ $? == 1 ]; then


				# loop through behaviors/sub-bricks
				d=0; while [ $d -lt ${#arrName[@]} ]; then

					dataMatrix+="${subj} ${covGroup[$c]} ${arrName[$d]} ${covSnif[$c]} ${covSPA[$c]} ${workDir}/${subj}/\"${i}[${arrBrick[$d]}]\" "
					let d=$[$d+1]
				done
			fi
		fi
		let c=$[$c+1]
	done


	# generate script
	tmp2=${i#*_}
	echo " module load r/3/5

	3dMVM -prefix MVM_${tmp2%_stat*} -jobs 10 -mask $mask \\
	-bsVars 'Group' \\
	-wsVars 'Stim' \\
	-qVars 'Snif,SPA' \\
	-num_glt $numGlt \\
	$conMatrix \\
	-dataTable \\
	$dataMatrixHead \\
	$dataMatrix" > MVM_${tmp2%_stat*}.sh
done












## set up - determine/construct variables for script
#unset conVar gltCount dataFrame

#if [ ${#bsArr[@]} -gt 1 ]; then


	## header, bx-subj title
	#bsVars=BSVARS
	#header="Subj $bsVars WSVARS InputFile"


	## make $conVar (post-hoc comparisons)
	#for x in ${!arrBS[@]}; do

		#h1=${arrBS[$x]:0:1}
		#h2=${arrBS[$x]:1:1}

		#bsCon="1*${bsArr[$h1]} -1*${bsArr[$h2]}"
		#bsLab=${bsArr[$h1]}-${bsArr[$h2]}

		#for y in ${!arr[@]}; do

			#gltCount=$[$gltCount+1]
			#ws1h=${arr[$y]:0:1}
			#ws2h=${arr[$y]:1:1}

			#eval declare -a nam1=(nam${ws1h})
			#eval declare -a nam2=(nam${ws2h})
			#name1=$(eval echo \${${nam1}[$arrCount]})
			#name2=$(eval echo \${${nam2}[$arrCount]})

			#conVar+="-gltLabel $gltCount ${bsLab}_${name1}-${name2} -gltCode $gltCount '${bsVars}: $bsCon WSVARS: 1*$name1 -1*$name2' "
		#done
	#done


	## determine group membership, write dataframe
	#bsSubj=(`cat $bsList | awk '{print $1}'`)
	#bsGroup=(`cat $bsList | awk '{print $2}'`)

	#scan=${pref}_stats_REML_blur${blurInt}+tlrc

	#for m in ${subjList[@]}; do
		#for n in ${!bsSubj[@]}; do
			#if [ $m == ${bsSubj[$n]} ]; then
				#for o in ${wsList[@]}; do

					#brik=$(eval echo \${arr${o}[$arrCount]})
					#name=$(eval echo \${nam${o}[$arrCount]})

					#dataFrame+="$m ${bsGroup[$n]} $name ${workDir}/${m}/'${scan}[${brik}]' "
				#done
			#fi
		#done
	#done

#else
	##bsVars=1
	##header="Subj WSVARS InputFile"

	##for y in ${!arr[@]}; do

		##gltCount=$[$gltCount+1]
		##ws1h=${arr[$y]:0:1}
		##ws2h=${arr[$y]:1:1}

		##eval declare -a nam1=(nam${ws1h})
		##eval declare -a nam2=(nam${ws2h})
		##name1=$(eval echo \${${nam1}[$arrCount]})
		##name2=$(eval echo \${${nam2}[$arrCount]})

		##conVar+="-gltLabel $gltCount ${name1}-${name2} -gltCode $gltCount 'WSVARS: 1*$name1 -1*$name2' "
	##done

	##for m in ${subjList[@]}; do
		##for n in ${wsList[@]}; do

			##brik=$(eval echo \${arr${n}[$arrCount]})
			##name=$(eval echo \${nam${n}[$arrCount]})

			##dataFrame+="$m $name ${workDir}/${m}/'${scan}[${brik}]' "
		##done
	##done
#fi


## write script
#echo "module load r/3/5

	#3dMVM -prefix $outPre \\
	#-jobs 10 \\
	#-mask $mask \\
	#-bsVars $bsVars \\
	#-wsVars 'WSVARS' \\
	#-num_glt $gltCount \\
	#$conVar \\
	#-dataTable \\
	#$header \\
	#$dataFrame" > ${outDir}/${outPre}.sh


## run MVM
#if [ $runIt == 1 ]; then
	#if [ ! -f ${outPre}+tlrc.HEAD ]; then
		#source ${outDir}/${outPre}.sh
	#fi

	## Check
	#if [ ! -f ${outPre}+tlrc.HEAD ]; then
		#echo >&2
		#echo "MVM failed on $outPre. Exiting. Exit 8" >&2
		#echo >&2
		#exit 8
	#fi
#fi
