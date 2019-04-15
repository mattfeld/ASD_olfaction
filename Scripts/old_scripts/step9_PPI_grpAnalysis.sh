#!/bin/bash


# Written by Nathan Muncy on 4/15/18


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
tempDir=${workDir}/Template
actDir=${tempDir}/priors_ACT
errDir=${workDir}/Analyses/Error_model
refDir=${workDir}/BO1048/ppi_data

subjList=(BO{670,699,674,632,694,698,700,703,709,710,676,701,606,683,712,608,915,618,695,704,930,625,696,705,976,706,999,708,1109,1138,1113,1140,1048,1127,1131,1133,1115,1128,1116,1130,1055,1117,1063,1118,1065,1119,1086,1120,1134,1104,1121,1135,1108,1126,1137})


if [ ! -d $ppiDir ]; then
    mkdir $ppiDir
fi


### Make masks
cd $ppiDir

# whole brain
for a in {Template_mask,AO_template}+tlrc; do
    if [ ! -f $a ]; then

        cp ${tempDir}/${a}* .
    fi
done


# whole brain GM mask
if [ ! -f Template_GM_mask+tlrc.HEAD ]; then

	# get gm, stitch, binarize
	c3d ${actDir}/Template_AtroposSegmentation.nii.gz -thresh 2 2 1 0 -o tmp_cgm.nii.gz
	c3d ${actDir}/Template_AtroposSegmentation.nii.gz -thresh 4 4 1 0 -o tmp_sgm.nii.gz
	c3d *gm.nii.gz -accum -add -endaccum -o tmp_gm_stitched.nii.gz
	c3d tmp_gm_stitched.nii.gz -thresh 1 inf 1 0 -o tmp_gm_bin.nii.gz

	# resample etc
	3dcopy tmp_gm_bin.nii.gz tmp_gm_bin+tlrc
	3dfractionize -template ${workDir}/BO1048/ppi_data/FINAL_Indiv_LPF+tlrc -prefix tmp_gm_resample -input tmp_gm_bin+tlrc
	3dcalc -a tmp_gm_resample+tlrc -prefix tmp_gm_resample_bin -expr "step(a)"

	# match up
	3dcopy tmp_gm_resample_bin+tlrc tmp1.nii.gz
	3dcopy Template_mask+tlrc tmp_Template_mask.nii.gz
	c3d tmp1.nii.gz tmp_Template_mask.nii.gz -multiply -o tmp2.nii.gz
	3dcopy tmp2.nii.gz Template_GM_mask+tlrc
	rm tmp*
fi
mask=${ppiDir}/Template_GM_mask+tlrc




### For each seed compare 'Inter' coefficients between groups
## T-tests per behavior - newer methods
cd $refDir

c=0; for i in FINAL_Indiv*tlrc.HEAD; do
    fiList[$c]=${i%.*}
    let c=$[$c+1]
done

stimList=(FBO UBO)
stimBrik=(26 29)
stimLen=${#stimList[@]}


cd $ppiDir

for i in ${fiList[@]}; do
	c=0; while [ $c -lt $stimLen ]; do

		brik=${stimBrik[$c]}
		name=${stimList[$c]}

	    scan=$i
		tmp=${i%+*}
		out=TTEST_${tmp#*_}_$name

	    if [ ! -f ${out}+tlrc.HEAD ]; then

	        3dttest++ -prefix $out \
	        -mask $mask \
	        -resid res_$out \
	        -ACF \
	        -Clustsim \
	        -setA Con \
	        BO1048	${workDir}/BO1048/ppi_data/"${scan}[$brik]" \
			BO1055	${workDir}/BO1055/ppi_data/"${scan}[$brik]" \
			BO1063	${workDir}/BO1063/ppi_data/"${scan}[$brik]" \
			BO1065	${workDir}/BO1065/ppi_data/"${scan}[$brik]" \
			BO1086	${workDir}/BO1086/ppi_data/"${scan}[$brik]" \
			BO1104	${workDir}/BO1104/ppi_data/"${scan}[$brik]" \
			BO1108	${workDir}/BO1108/ppi_data/"${scan}[$brik]" \
			BO1109	${workDir}/BO1109/ppi_data/"${scan}[$brik]" \
			BO1113	${workDir}/BO1113/ppi_data/"${scan}[$brik]" \
			BO1115	${workDir}/BO1115/ppi_data/"${scan}[$brik]" \
			BO1116	${workDir}/BO1116/ppi_data/"${scan}[$brik]" \
			BO1117	${workDir}/BO1117/ppi_data/"${scan}[$brik]" \
			BO1118	${workDir}/BO1118/ppi_data/"${scan}[$brik]" \
			BO1119	${workDir}/BO1119/ppi_data/"${scan}[$brik]" \
			BO1120	${workDir}/BO1120/ppi_data/"${scan}[$brik]" \
			BO1121	${workDir}/BO1121/ppi_data/"${scan}[$brik]" \
			BO1126	${workDir}/BO1126/ppi_data/"${scan}[$brik]" \
			BO1127	${workDir}/BO1127/ppi_data/"${scan}[$brik]" \
			BO1128	${workDir}/BO1128/ppi_data/"${scan}[$brik]" \
			BO1130	${workDir}/BO1130/ppi_data/"${scan}[$brik]" \
			BO1131	${workDir}/BO1131/ppi_data/"${scan}[$brik]" \
			BO1133	${workDir}/BO1133/ppi_data/"${scan}[$brik]" \
			BO1134	${workDir}/BO1134/ppi_data/"${scan}[$brik]" \
			BO1135	${workDir}/BO1135/ppi_data/"${scan}[$brik]" \
			BO1137	${workDir}/BO1137/ppi_data/"${scan}[$brik]" \
			BO1138	${workDir}/BO1138/ppi_data/"${scan}[$brik]" \
			BO1140	${workDir}/BO1140/ppi_data/"${scan}[$brik]" \
			-setB Aut \
			BO606	${workDir}/BO606/ppi_data/"${scan}[$brik]" \
			BO608	${workDir}/BO608/ppi_data/"${scan}[$brik]" \
			BO618	${workDir}/BO618/ppi_data/"${scan}[$brik]" \
			BO625	${workDir}/BO625/ppi_data/"${scan}[$brik]" \
			BO632	${workDir}/BO632/ppi_data/"${scan}[$brik]" \
			BO670	${workDir}/BO670/ppi_data/"${scan}[$brik]" \
			BO674	${workDir}/BO674/ppi_data/"${scan}[$brik]" \
			BO676	${workDir}/BO676/ppi_data/"${scan}[$brik]" \
			BO683	${workDir}/BO683/ppi_data/"${scan}[$brik]" \
			BO694	${workDir}/BO694/ppi_data/"${scan}[$brik]" \
			BO695	${workDir}/BO695/ppi_data/"${scan}[$brik]" \
			BO696	${workDir}/BO696/ppi_data/"${scan}[$brik]" \
			BO698	${workDir}/BO698/ppi_data/"${scan}[$brik]" \
			BO699	${workDir}/BO699/ppi_data/"${scan}[$brik]" \
			BO700	${workDir}/BO700/ppi_data/"${scan}[$brik]" \
			BO701	${workDir}/BO701/ppi_data/"${scan}[$brik]" \
			BO703	${workDir}/BO703/ppi_data/"${scan}[$brik]" \
			BO704	${workDir}/BO704/ppi_data/"${scan}[$brik]" \
			BO705	${workDir}/BO705/ppi_data/"${scan}[$brik]" \
			BO706	${workDir}/BO706/ppi_data/"${scan}[$brik]" \
			BO708	${workDir}/BO708/ppi_data/"${scan}[$brik]" \
			BO709	${workDir}/BO709/ppi_data/"${scan}[$brik]" \
			BO710	${workDir}/BO710/ppi_data/"${scan}[$brik]" \
			BO712	${workDir}/BO712/ppi_data/"${scan}[$brik]" \
			BO915	${workDir}/BO915/ppi_data/"${scan}[$brik]" \
			BO930	${workDir}/BO930/ppi_data/"${scan}[$brik]" \
			BO976	${workDir}/BO976/ppi_data/"${scan}[$brik]" \
			BO999	${workDir}/BO999/ppi_data/"${scan}[$brik]"
		fi

	let c=$[$c+1]
	done
done


















### Old code


### run new Monte Carlo ACF simulations, on each mask
#
#
# This is now accomplished by the next script in the pipeline
#
#
# for i in Template*.HEAD; do
#
# 	mask=${i%.*}
# 	stringM=${i%_mask*}
#
# 	for j in ${errDir}/Avg*; do
#
# 		stringE=${j#*FINAL_}
# 		print=MC_${stringM}_${stringE}
# 		arr=(`cat $j`)
#
# 		3dClustSim -mask $mask -LOTS -iter 10000 -acf ${arr[0]} ${arr[1]} ${arr[2]} > $print
# 	done
# done


#
# c=0; for i in FINAL_Both*tlrc.HEAD; do
#     fbList[$c]=${i%.*}
#     let c=$[$c+1]
# done


# BS-ANOVA - This method seems to be outdated
# for i in ${fbList[@]}; do
#
# 	scan=$i
# 	out=MVM_${i#*_}
# 	a=26
#
# 	if [ ! -f ${out}+tlrc.HEAD ]; then
#
# 		3dMVM -prefix $out -jobs 6 -mask $mask \
# 		-bsVars 'Group' \
# 		-num_glt 1 \
# 		-gltLabel 1 C-A -gltCode 1 'Group: 1*C -1*A' \
# 		-dataTable \
# 		Subj	Group	InputFile \
# 		BO1048	C	${workDir}/BO1048/ppi_data/"${scan}[$a]" \
# 		BO1055	C	${workDir}/BO1055/ppi_data/"${scan}[$a]" \
# 		BO1063	C	${workDir}/BO1063/ppi_data/"${scan}[$a]" \
# 		BO1065	C	${workDir}/BO1065/ppi_data/"${scan}[$a]" \
# 		BO1086	C	${workDir}/BO1086/ppi_data/"${scan}[$a]" \
# 		BO1104	C	${workDir}/BO1104/ppi_data/"${scan}[$a]" \
# 		BO1108	C	${workDir}/BO1108/ppi_data/"${scan}[$a]" \
# 		BO1109	C	${workDir}/BO1109/ppi_data/"${scan}[$a]" \
# 		BO1113	C	${workDir}/BO1113/ppi_data/"${scan}[$a]" \
# 		BO1115	C	${workDir}/BO1115/ppi_data/"${scan}[$a]" \
# 		BO1116	C	${workDir}/BO1116/ppi_data/"${scan}[$a]" \
# 		BO1117	C	${workDir}/BO1117/ppi_data/"${scan}[$a]" \
# 		BO1118	C	${workDir}/BO1118/ppi_data/"${scan}[$a]" \
# 		BO1119	C	${workDir}/BO1119/ppi_data/"${scan}[$a]" \
# 		BO1120	C	${workDir}/BO1120/ppi_data/"${scan}[$a]" \
# 		BO1121	C	${workDir}/BO1121/ppi_data/"${scan}[$a]" \
# 		BO1126	C	${workDir}/BO1126/ppi_data/"${scan}[$a]" \
# 		BO1127	C	${workDir}/BO1127/ppi_data/"${scan}[$a]" \
# 		BO1128	C	${workDir}/BO1128/ppi_data/"${scan}[$a]" \
# 		BO1130	C	${workDir}/BO1130/ppi_data/"${scan}[$a]" \
# 		BO1131	C	${workDir}/BO1131/ppi_data/"${scan}[$a]" \
# 		BO1133	C	${workDir}/BO1133/ppi_data/"${scan}[$a]" \
# 		BO1134	C	${workDir}/BO1134/ppi_data/"${scan}[$a]" \
# 		BO1135	C	${workDir}/BO1135/ppi_data/"${scan}[$a]" \
# 		BO1137	C	${workDir}/BO1137/ppi_data/"${scan}[$a]" \
# 		BO1138	C	${workDir}/BO1138/ppi_data/"${scan}[$a]" \
# 		BO1140	C	${workDir}/BO1140/ppi_data/"${scan}[$a]" \
# 		BO606	A	${workDir}/BO606/ppi_data/"${scan}[$a]" \
# 		BO608	A	${workDir}/BO608/ppi_data/"${scan}[$a]" \
# 		BO618	A	${workDir}/BO618/ppi_data/"${scan}[$a]" \
# 		BO625	A	${workDir}/BO625/ppi_data/"${scan}[$a]" \
# 		BO632	A	${workDir}/BO632/ppi_data/"${scan}[$a]" \
# 		BO670	A	${workDir}/BO670/ppi_data/"${scan}[$a]" \
# 		BO674	A	${workDir}/BO674/ppi_data/"${scan}[$a]" \
# 		BO676	A	${workDir}/BO676/ppi_data/"${scan}[$a]" \
# 		BO683	A	${workDir}/BO683/ppi_data/"${scan}[$a]" \
# 		BO694	A	${workDir}/BO694/ppi_data/"${scan}[$a]" \
# 		BO695	A	${workDir}/BO695/ppi_data/"${scan}[$a]" \
# 		BO696	A	${workDir}/BO696/ppi_data/"${scan}[$a]" \
# 		BO698	A	${workDir}/BO698/ppi_data/"${scan}[$a]" \
# 		BO699	A	${workDir}/BO699/ppi_data/"${scan}[$a]" \
# 		BO700	A	${workDir}/BO700/ppi_data/"${scan}[$a]" \
# 		BO701	A	${workDir}/BO701/ppi_data/"${scan}[$a]" \
# 		BO703	A	${workDir}/BO703/ppi_data/"${scan}[$a]" \
# 		BO704	A	${workDir}/BO704/ppi_data/"${scan}[$a]" \
# 		BO705	A	${workDir}/BO705/ppi_data/"${scan}[$a]" \
# 		BO706	A	${workDir}/BO706/ppi_data/"${scan}[$a]" \
# 		BO708	A	${workDir}/BO708/ppi_data/"${scan}[$a]" \
# 		BO709	A	${workDir}/BO709/ppi_data/"${scan}[$a]" \
# 		BO710	A	${workDir}/BO710/ppi_data/"${scan}[$a]" \
# 		BO712	A	${workDir}/BO712/ppi_data/"${scan}[$a]" \
# 		BO915	A	${workDir}/BO915/ppi_data/"${scan}[$a]" \
# 		BO930	A	${workDir}/BO930/ppi_data/"${scan}[$a]" \
# 		BO976	A	${workDir}/BO976/ppi_data/"${scan}[$a]" \
# 		BO999	A	${workDir}/BO999/ppi_data/"${scan}[$a]"
#
# 	fi
# done






#### Use betas, not z-scores.



### R-to-Z conversion
#cd $workDir

#for i in ${subjList[@]}; do
#cd ${i}/ppi_data

	#c=0; while [ $c -lt $stimLen ]; do
		#for j in ${fiList[@]}; do

			#sub=${stimBrik[$c]}
			#name=${stimList[$c]}
			#file=${j}"[$sub]"
			#tmp=${j%+*}

			#if [ ! -f ZTrans_${tmp#*_}_${name}+tlrc.HEAD ]; then
				#3dcalc -a $file -expr 'log((1+a)/(1-a))/2' -prefix ZTrans_${tmp#*_}_$name
			#fi
		#done

	#let c=$[$c+1]
	#done

#cd $workDir
#done



